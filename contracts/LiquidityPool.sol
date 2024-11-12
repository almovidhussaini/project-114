// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract LiquidityPool is ReentrancyGuard {
    IERC20 public liquidityToken;
    IERC20 public usdt;
    IERC20 public busd;

    uint256 public constant TOTAL_LIQUIDITY_POOL = 150_000_000 * 10 ** 18; // 150 million tokens
    uint256 public liquidityReserved;
    uint256 public usdtReserve;
    uint256 public busdReserve;
    address liquidityProvider = 0x583031D1113aD414F02576BD6afaBfb302140225;

    mapping(address => uint256) public liquidityProvided;

    event LiquidityAdded(address indexed provider, uint256 tokenAmount, uint256 stablecoinAmount, string stablecoin);
    event LiquidityRemoved(address indexed provider, uint256 tokenAmount, uint256 stablecoinAmount, string stablecoin);

    constructor(address _xoraToken, address _usdt, address _busd) {
        liquidityToken = IERC20(_xoraToken);
        usdt = IERC20(_usdt);
        busd = IERC20(_busd);
    }

    // Function to add liquidity with either USDT or BUSD
    function addLiquidity(uint256 tokenAmount, uint256 stablecoinAmount, address stablecoin) external nonReentrant {
        require(stablecoin == address(usdt) || stablecoin == address(busd), "Unsupported stablecoin");
        require(liquidityReserved + tokenAmount <= TOTAL_LIQUIDITY_POOL, "Exceeds liquidity pool");

        // Transfer tokens from user to contract
        liquidityToken.transferFrom(msg.sender, address(this), tokenAmount);
        IERC20(stablecoin).transferFrom(msg.sender, address(this), stablecoinAmount);

        // Update reserves
        liquidityReserved += tokenAmount;
        if (stablecoin == address(usdt)) {
            usdtReserve += stablecoinAmount;
        } else {
            busdReserve += stablecoinAmount;
        }

        liquidityProvided[msg.sender] += tokenAmount;
        emit LiquidityAdded(msg.sender, tokenAmount, stablecoinAmount, stablecoin == address(usdt) ? "USDT" : "BUSD");
    }

    // Function to remove liquidity and withdraw paired stablecoin
    function removeLiquidity(uint256 tokenAmount, address stablecoin) external nonReentrant {
        require(stablecoin == address(usdt) || stablecoin == address(busd), "Unsupported stablecoin");
        require(liquidityProvided[msg.sender] >= tokenAmount, "Insufficient liquidity");

        uint256 stablecoinAmount = (stablecoin == address(usdt)) ? (usdtReserve * tokenAmount) / liquidityReserved : (busdReserve * tokenAmount) / liquidityReserved;

        // Update reserves
        liquidityReserved -= tokenAmount;
        if (stablecoin == address(usdt)) {
            usdtReserve -= stablecoinAmount;
        } else {
            busdReserve -= stablecoinAmount;
        }

        // Transfer tokens back to user
        liquidityToken.transfer(msg.sender, tokenAmount);
        IERC20(stablecoin).transfer(msg.sender, stablecoinAmount);

        liquidityProvided[msg.sender] -= tokenAmount;
        emit LiquidityRemoved(msg.sender, tokenAmount, stablecoinAmount, stablecoin == address(usdt) ? "USDT" : "BUSD");
    }
}
