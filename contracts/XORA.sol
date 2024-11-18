// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract XORA is ERC20, Ownable, ReentrancyGuard {
    uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * (10**18);
    IERC20 public stablecoin;

    uint256 public buyTax = 1;
    uint256 public sellTax = 1;
    uint256 public lastHalvingTime;
    uint256 public rewardRate;
    uint256 public constant HALVING_PERIOD = 365 days;

    uint256 startTimestamp;
    uint256 constant TEAM_CLIFF = 18 * 30 days;
    uint256 constant TEAM_VESTING_PERIOD = 4 * 365 days;
    uint256 TEAM_TOTAL_FUND = 100_000_000 * (10**18);

    uint256 public constant MARKETING_INITIAL_UNLOCK = 25;

    uint256 public teamAllocated = 100_000_000 * (10**18);
    uint256 public releasedTeamAmount;
    uint256 MARKETING_VESTING_PERIOD = 12 * 30 days;

    uint256 public marketingAllocated = 75_000_000 * (10**18);
    uint256 public releasedMarketingAmount;

    mapping(address => bool) public isTaxExempt;

    event RewardHalved(uint256 newRewardRate);
    event TokensBurned(uint256 amount);
    event BuyBackAndBurn(uint256 amount);
    event RewardParametersInitialized(
        uint256 initialRewardRate,
        address stablecoin
    );
    event TeamTokensReleased(address indexed recipient, uint256 amount);
    event MarketingTokensReleased(address indexed recipient, uint256 amount);

    address public constant PLAY_TO_EARN =
        0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
    // address public constant LIQUIDITY_POOL =
    //     0x583031D1113aD414F02576BD6afaBfb302140225;
    address public constant TEAM_AND_DEVELOPMENT =
        0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
    address public constant COMMUNITY_GROWTH_AND_MARKETING =
        0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C;
    address public constant STRADEGIC_RESERVE =
        0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;

    constructor(address _icoAllocation)
        Ownable(msg.sender)
        ERC20("XORA Token", "XORA")
    {
        require(_icoAllocation != address(0), "Invalid ICO address");

        _mint(PLAY_TO_EARN, 450_000_000 * (10**18)); //45%
        // _mint(TEAM_AND_DEVELOPMENT, 100_000_000 * (10**18)); //10%
        _mint(
            COMMUNITY_GROWTH_AND_MARKETING,
            (100_000_000 * (10**18) * 25) / 100
        ); //10% initial supply of 25%
        _mint(STRADEGIC_RESERVE, 100_000_000 * (10**18)); //10%
        _mint(_icoAllocation, 100_000_000 * (10**18)); //10%

        startTimestamp = block.timestamp;
        
    }

    function mintToken(address _pairToken) external {
        require(_pairToken != address(0), "Invalid token pair address");
        _mint(_pairToken, 75_000_000 * (10**18)); // 50% of 15% liquidity token xora/usdt and xora/usdc
    }

    function releaseTeamTokens() external onlyOwner nonReentrant {
        require(
            block.timestamp >= startTimestamp + TEAM_CLIFF,
            "Team vesting cliff not reached"
        );
        uint256 elapsedTime = block.timestamp - (startTimestamp + TEAM_CLIFF);
        uint256 vestedAmount = (teamAllocated * elapsedTime) /
            TEAM_VESTING_PERIOD;
        uint256 teamAmount = vestedAmount - releasedTeamAmount;
        releasedTeamAmount += teamAmount;
        require(vestedAmount > 0, "No tokens available for release");
        require(releasedTeamAmount <= teamAllocated, "max token limit reached");
        _mint(TEAM_AND_DEVELOPMENT, teamAmount);
        emit TeamTokensReleased(TEAM_AND_DEVELOPMENT, teamAmount);
    }

    function releaseMarketingTokens() external onlyOwner nonReentrant {
        uint256 elapsedTime = block.timestamp - startTimestamp;
        uint256 vestedAmount = (marketingAllocated * elapsedTime) /
            MARKETING_VESTING_PERIOD;
        uint256 marketingAmount = vestedAmount - releasedMarketingAmount;
        releasedMarketingAmount += marketingAmount;
        require(vestedAmount > 0, "no token available for release");
        require(
            releasedMarketingAmount <= marketingAllocated,
            "max token imit reached"
        );
        _mint(COMMUNITY_GROWTH_AND_MARKETING, marketingAmount);
        emit MarketingTokensReleased(COMMUNITY_GROWTH_AND_MARKETING, marketingAmount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        uint256 taxAmount = (amount *
            (recipient == address(this) ? sellTax : buyTax)) / 100;
        if (isTaxExempt[sender] || isTaxExempt[recipient]) {
            taxAmount = 0;
        }
        super._transfer(sender, recipient, amount - taxAmount);
        if (taxAmount > 0) {
            _burn(sender, taxAmount);
        }
    }

    function addTaxExemptAddress(address _address) external onlyOwner {
        isTaxExempt[_address] = true;
    }

    function removeTaxExemptAddress(address _address) external onlyOwner {
        isTaxExempt[_address] = false;
    }
}
