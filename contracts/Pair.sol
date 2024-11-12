
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Pair is ReentrancyGuard {
    address public token0;
    address public token1;
    uint256 public reserve0;
    uint256 public reserve1;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1);
    event Swap(address indexed sender, uint256 amountIn, uint256 amountOut, address indexed tokenIn, address indexed tokenOut);

    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
    }

    function addLiquidity(address to, uint256 amount0, uint256 amount1) external nonReentrant {
        reserve0 += amount0;
        reserve1 += amount1;
        IERC20(token0).transferFrom(to, address(this), amount0);
        IERC20(token1).transferFrom(to, address(this), amount1);
        emit Mint(to, amount0, amount1);
    }

    function removeLiquidity(address to, uint256 amount0, uint256 amount1) external nonReentrant {
        require(reserve0 >= amount0 && reserve1 >= amount1, "Pair: INSUFFICIENT_LIQUIDITY");
        reserve0 -= amount0;
        reserve1 -= amount1;
        IERC20(token0).transfer(to, amount0);
        IERC20(token1).transfer(to, amount1);
        emit Burn(to, amount0, amount1);
    }
}