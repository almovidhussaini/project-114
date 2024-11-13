// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Router.sol";

contract ZapV2 {
    Router public router;

    constructor(address _router) {
        router = Router(_router);
    }

    function zapIn(address tokenA, address tokenB, uint256 amountA, uint256 amountB) external {
        // Allows user to add liquidity in a single transaction
        router.addLiquidity(tokenA, tokenB, amountA, amountB);
    }

    function zapOut(address tokenA, address tokenB, uint256 amountA, uint256 amountB) external {
        // Allows user to remove liquidity in a single transaction
        router.removeLiquidity(tokenA, tokenB, amountA, amountB);
    }
}
