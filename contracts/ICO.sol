// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol"; // To add pause functionality
import "@openzeppelin/contracts/access/Ownable.sol";

contract ICO is ReentrancyGuard, Ownable, Pausable {
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
    mapping(address => uint256) public purchasesInStableCoin;

    mapping(address => uint8) public claimedStage;
    uint8 public currentStage;

    mapping(address => bool) private investorsAndPartners;
    mapping(address => bool) private whitelistedPartners;

    event TokensClaimed(address indexed buyer, uint256 amount);
    event TokensPurchased(address indexed buyer, uint256 amount);
    event StageAdvanced(uint8 newStageIndex);

    constructor(
        address[] memory _investors,
        address[] memory _whitelistedPartners
    ) Ownable(msg.sender) {
        currentStage = 0;
        // Add investors and partners to the mapping
        for (uint256 i = 0; i < _investors.length; i++) {
            investorsAndPartners[_investors[i]] = true;
        }

        // Add whitelisted partners to the mapping
        for (uint256 i = 0; i < _whitelistedPartners.length; i++) {
            whitelistedPartners[_whitelistedPartners[i]] = true;
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

    modifier onlyActiveStage() {
        require(currentStage < stages.length, "ICO stages completed");
        _;
    }

    function buyTokens(uint256 amount, address stablecoin)
        external
        payable
        onlyActiveStage
        whenNotPaused
        nonReentrant
    {
        uint256 bonusAmount = 0;
        require(currentStage < stages.length, "ICO stages completed");
        require(amount > 0, "Invalid purchase amount");
        Stage storage stage = stages[currentStage];
        require( stage.tokensSold <= stage.allocation,"token sold reached max limit of the current stage");
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
        purchasesInStableCoin[msg.sender] += amount;
        require(
            IERC20(stablecoin).allowance(msg.sender, address(this)) >= amount,
            "Insufficient allowance"
        );
        require(
            IERC20(stablecoin).transferFrom(msg.sender, address(this), amount),
            "Stablecoin transfer failed"
        );
        claimedStage[msg.sender] = currentStage;
    }

    function advanceStage() external onlyOwner {
        Stage storage stage = stages[currentStage];
        // Ensure the current stage is fully completed (either allocation or target raise reached)
        require(
            stage.tokensSold >= stage.allocation ||
                (block.timestamp >=
                    (stage.startTime + stage.cliff + stage.vestingDuration)),
            "Cannot advance, target not meat"
        );

        currentStage++;
        require(currentStage < stages.length, "ICO stages completed");
        stage = stages[currentStage];
        stage.startTime = block.timestamp;

        emit StageAdvanced(currentStage);
    }

    // function _calculateVEstedAmount()
    function claimTokens(address _xoraToken)
        external
        nonReentrant
        whenNotPaused
    {
        uint256 totalPurchased = purchases[msg.sender];
        require(totalPurchased > 0, "No tokens available for release");
        xoraToken = IERC20(_xoraToken);
        uint8 myClaimedStage = claimedStage[msg.sender];
        Stage storage stage = stages[myClaimedStage];
        require(
            block.timestamp >= stage.startTime + stage.cliff,
            "Cliff period not finished"
        );

        uint256 elapsedTime = block.timestamp - (stage.startTime + stage.cliff);
        uint256 vestedAmount;

        if (claimedStage[msg.sender] == 0) {
            // Calculate vested amount based on elapsed time and total vesting duration for this stage
            uint256 totalVestingDuration = 10 * 30 days; // Example: 10 months vesting duration
            vestedAmount =
                (totalPurchased * elapsedTime) /
                totalVestingDuration;
        } else if (claimedStage[msg.sender] == 1) {
            uint256 totalVestingDuration = 6 * 30 days; // Example: 6 months vesting duration
            vestedAmount =
                (totalPurchased * elapsedTime) /
                totalVestingDuration;
        } else if (claimedStage[msg.sender] == 2) {
            // For final stage, all remaining tokens become available
            vestedAmount = purchases[msg.sender];
        }

        uint256 claimableAmount = vestedAmount - claimedTokens[msg.sender];
        require(claimableAmount > 0, "No tokens available for claim");

        claimedTokens[msg.sender] += claimableAmount;
        // purchases[msg.sender] -= claimableAmount;
        // Transfer tokens
        xoraToken.transfer(msg.sender, claimableAmount);

        uint256 amountInStableCoin = (claimableAmount * stage.price) / (10**18);
        purchasesInStableCoin[msg.sender] -= amountInStableCoin;
        emit TokensClaimed(msg.sender, claimableAmount);
    }

    function widthdrawfunds(address stablecoin, uint256 amount)
        external
        nonReentrant
    {
        uint256 stableCoinAmount = purchasesInStableCoin[msg.sender];
        require(stableCoinAmount >= amount, "Not enough deposited amount");
        uint8 myClaimedStage = claimedStage[msg.sender];
        require(myClaimedStage >= 0, "Incvalid cliamed stage");
        Stage storage stage = stages[myClaimedStage];

        uint256 xoraAmount = (amount * 10**18) / stage.price;
        purchases[msg.sender] -= xoraAmount;
        require(
            IERC20(stablecoin).transfer(msg.sender, amount),
            "Transfer failed"
        );
        purchasesInStableCoin[msg.sender] -= amount;
    }

    function isInvestor(address account) internal view returns (bool) {
        return investorsAndPartners[account];
    }

    function isWhitelisted(address account) internal view returns (bool) {
        return whitelistedPartners[account];
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
