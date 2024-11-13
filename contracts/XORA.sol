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

    event RewardHalved(uint256 newRewardRate);
    event TokensBurned(uint256 amount);
    event BuyBackAndBurn(uint256 amount);
    event RewardParametersInitialized(
        uint256 initialRewardRate,
        address stablecoin
    );

    address public constant PLAY_TO_EARN =
        0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
    address public constant LIQUIDITY_POOL =
        0x583031D1113aD414F02576BD6afaBfb302140225;
    address public constant TEAM_AND_DEVELOPMENT =
        0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
    address public constant COMMUNITY_GROWTH_AND_MARKETING =
        0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C;
    address public constant STRADEGIC_RESERVE =
        0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
    address public constant ICO_ALLOCATION =
        0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC;

    // address public constant AIRDROP = 0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C;

    constructor() Ownable(msg.sender) ERC20("XORA Token", "XORA") {
        _mint(PLAY_TO_EARN, 450_000_000 * (10**18)); //45%
        _mint(LIQUIDITY_POOL, 150_000_000 * (10**18)); //15%
        _mint(TEAM_AND_DEVELOPMENT, 100_000_000 * (10**18)); //10%
        _mint(COMMUNITY_GROWTH_AND_MARKETING, 100_000_000 * (10**18)); //10%
        _mint(STRADEGIC_RESERVE, 100_000_000 * (10**18)); //10%
        _mint(ICO_ALLOCATION, 100_000_000 * (10**18)); //10%
    }

    function initializeRewardParameters(
        uint256 _initialRewardRate,
        address _stablecoin
    ) external onlyOwner {
        rewardRate = _initialRewardRate;
        stablecoin = IERC20(_stablecoin);
        lastHalvingTime = block.timestamp;
        emit RewardParametersInitialized(_initialRewardRate, _stablecoin);
    }

    // ** Annual Reward Halving **
    function halveRewards() external {
        require(
            block.timestamp >= lastHalvingTime + HALVING_PERIOD,
            "Halving not due yet"
        );

        rewardRate = rewardRate / 2;
        lastHalvingTime = block.timestamp;

        emit RewardHalved(rewardRate);
    }

    // // ** Treasury Buy-Back Program **
    // function buyBackAndBurn(uint256 stablecoinAmount) external onlyOwner {
    //     // Transfer stablecoin to external address for token purchase
    //     stablecoin.transferFrom(address(this), msg.sender, stablecoinAmount);
    //     // Logic for token purchase goes here

    //     uint256 xeroBalance = balanceOf(address(this)); // Check acquired token balance
    //     _burn(address(this), xeroBalance); // Burn acquired tokens

    //     emit BuyBackAndBurn(xeroBalance);
    // }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        uint256 taxAmount = (amount *
            (recipient == address(this) ? sellTax : buyTax)) / 100;
        super._transfer(sender, recipient, amount - taxAmount);
        if (taxAmount > 0) {
            _burn(sender, taxAmount);
        }
    }
}
