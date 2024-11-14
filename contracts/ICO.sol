// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ICO is Ownable(msg.sender), ReentrancyGuard {
    IERC20 public xoraToken;
    enum StageName {
        PrivateSale,
        PreSale,
        PublicSale
    }

    struct Stage {
        StageName name;
        uint256 allocation;
        uint256 price; // Price in wei
        uint256 targetRaise;
        uint256 cliff; // Vesting cliff in seconds
        uint256 vestingDuration; // Total vesting time in seconds
        uint256 tokensSold;
        uint256 bonusPercentage; // Bonus as percentage
        uint256 startTime; //start time
    }

    Stage[3] public stages;
    mapping(address => uint256) public vestedTokens;
    mapping(address => uint256) public claimedTokens;
    mapping(address => uint256) public purchases;
    mapping(address => uint256) public initialPurchased;
    mapping(address => uint256) public purchasesInStableCoin;

    uint256 public totalTokensSold;
    uint8 public currentStage;
    uint8 claimedStage;

    address[] public investors_and_partner;
    address[] public whitelistedPartner;

    event TokensClaimed(address indexed buyer, uint256 amount);
    event TokensPurchased(address indexed buyer, uint256 amount);
    event StageAdvanced(uint8 newStageIndex);

    constructor(
        address[] memory _investors,
        address[] memory _whitelistedPartner
    ) {
        currentStage = 0;
        claimedStage = 0;
        // lastClaimTimestamp[msg.sender] = 0;
        for (uint256 i = 0; i < _investors.length; i++) {
            investors_and_partner.push(_investors[i]);
        }
        for (uint256 i = 0; i < _whitelistedPartner.length; i++) {
            whitelistedPartner.push(_whitelistedPartner[i]);
        }
        // Define stages
        stages[0] = Stage({
            name: StageName.PrivateSale,
            allocation: 20_000_000 * 10**18,
            price: 0.04 * 10**18,
            targetRaise: 800000,
            cliff: 0,
            vestingDuration: 10 * 30 days,
            tokensSold: 0,
            bonusPercentage: 15,
            startTime: block.timestamp
        });

        stages[1] = Stage({
            name: StageName.PreSale,
            allocation: 30_000_000 * 10**18,
            price: 0.06 * 10**18,
            targetRaise: 1800000,
            cliff: 30 days,
            vestingDuration: 6 * 30 days,
            tokensSold: 0,
            bonusPercentage: 10,
            startTime: 0
        });

        stages[2] = Stage({
            name: StageName.PublicSale,
            allocation: 50_000_000 * 10**18,
            price: 0.08 * 10**18,
            targetRaise: 4000000,
            cliff: 0,
            vestingDuration: 0,
            tokensSold: 0,
            bonusPercentage: 0,
            startTime: 0
        });
    }

    function buyTokens(uint256 amount, address stablecoin)
        external
        payable
        nonReentrant
    {
        uint256 bonusAmount = 0;
        require(currentStage < stages.length, "ICO stages completed");
        require(amount > 0, "Invalid purchase amount");
        Stage storage stage = stages[currentStage];
        if (
            stage.tokensSold >= stage.allocation ||
            (block.timestamp >=
                (stage.startTime + stage.cliff + stage.vestingDuration))
        ) {
            currentStage++;
            require(currentStage < stages.length, "ICO stages completed");
            stage = stages[currentStage];
            stage.startTime = block.timestamp;
            emit StageAdvanced(currentStage);
        }

        uint256 xoraAmount = (amount * 10**18) / stage.price;

        if (stage.name == StageName.PrivateSale) {
            require(isInvestor(msg.sender), "Not investor nor partner");
            if (block.timestamp < (180 days + stage.startTime)) {
                bonusAmount = (xoraAmount * stage.bonusPercentage) / 100;
            }
        }
        if (stage.name == StageName.PreSale) {
            require(isWhitelisted(msg.sender), "Not in whitelisted partner");
            bonusAmount = (xoraAmount * stage.bonusPercentage) / 100;
        }
        xoraAmount += bonusAmount;
        require(
            xoraAmount <= stage.allocation - stage.tokensSold,
            "Stage allocation exceeded"
        );
        stage.tokensSold += xoraAmount;
        purchases[msg.sender] += xoraAmount;
        initialPurchased[msg.sender] += xoraAmount;
        purchasesInStableCoin[msg.sender] += amount;
        IERC20(stablecoin).transferFrom(msg.sender, address(this), amount);
        claimedStage = currentStage;
    }

    // function _calculateVEstedAmount()
    function claimTokens(address _xoraToken) external nonReentrant {
        uint256 totalPurchased = initialPurchased[msg.sender];
        require(totalPurchased > 0, "No tokens available for release");
        xoraToken = IERC20(_xoraToken);
        Stage storage stage = stages[claimedStage];
        require(
            block.timestamp >= stage.startTime + stage.cliff,
            "Cliff period not finished"
        );

        uint256 elapsedTime = block.timestamp - (stage.startTime + stage.cliff);
        uint256 vestedAmount;

        if (claimedStage == 0) {
            // Calculate vested amount based on elapsed time and total vesting duration for this stage
            uint256 totalVestingDuration = 10 * 30 days; // Example: 10 months vesting duration
            vestedAmount =
                (totalPurchased * elapsedTime) /
                totalVestingDuration;
        } else if (claimedStage == 1) {
            uint256 totalVestingDuration = 6 * 30 days; // Example: 6 months vesting duration
            vestedAmount =
                (totalPurchased * elapsedTime) /
                totalVestingDuration;
        } else if (claimedStage == 2) {
            // For final stage, all remaining tokens become available
            vestedAmount = purchases[msg.sender];
        }

        uint256 claimableAmount = vestedAmount - claimedTokens[msg.sender];
        require(claimableAmount > 0, "No tokens available for claim");

        claimedTokens[msg.sender] += claimableAmount;
        // Transfer tokens
        xoraToken.transfer(msg.sender, claimableAmount);
        purchases[msg.sender] -= claimableAmount;
        uint256 amountInStableCoin = (claimableAmount * stage.price)/(10**18);
        purchasesInStableCoin[msg.sender] -= amountInStableCoin;
        emit TokensClaimed(msg.sender, claimableAmount);
    }

    function widthdrawfunds(address stablecoin, uint256 amount)
        external
        nonReentrant
    {
        uint256 stableCoinAmount = purchasesInStableCoin[msg.sender];
        require(stableCoinAmount >= amount, "Not enough deposited amount");
        Stage storage stage = stages[claimedStage];

        uint256 xoraAmount = (amount * 10**18) / stage.price;
        purchases[msg.sender] -= xoraAmount;
        initialPurchased[msg.sender] -= xoraAmount;
        IERC20(stablecoin).transfer(msg.sender, amount);
        
        purchasesInStableCoin[msg.sender] -= amount;
    }

    function isInvestor(address account) internal view returns (bool) {
        for (uint256 i = 0; i < investors_and_partner.length; i++) {
            if (investors_and_partner[i] == account) {
                return true;
            }
        }
        return false;
    }

    function isWhitelisted(address account) internal view returns (bool) {
        for (uint256 i = 0; i < whitelistedPartner.length; i++) {
            if (whitelistedPartner[i] == account) {
                return true;
            }
        }
        return false;
    }
}
