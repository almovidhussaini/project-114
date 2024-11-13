// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Factory.sol";
import "./Pair.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Router is ReentrancyGuard {
    Factory public factory;

    event LiquidityAdded(address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 amountB);
    event LiquidityRemoved(address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 amountB);

    constructor(address _factory) {
        factory = Factory(_factory);
    }

    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired) external nonReentrant {
        address pair = factory.getPair(tokenA, tokenB);
        require(pair != address(0), "Router: Pair does not exist");

        Pair(pair).addLiquidity(msg.sender, amountADesired, amountBDesired);
        emit LiquidityAdded(tokenA, tokenB, amountADesired, amountBDesired);
    }

    function removeLiquidity(address tokenA, address tokenB, uint256 amountA, uint256 amountB) external nonReentrant {
        address pair = factory.getPair(tokenA, tokenB);
        require(pair != address(0), "Router: Pair does not exist");

        Pair(pair).removeLiquidity(msg.sender, amountA, amountB);
        emit LiquidityRemoved(tokenA, tokenB, amountA, amountB);
    }
}