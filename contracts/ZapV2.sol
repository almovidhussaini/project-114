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

    function zapOut(address tokenA, address tokenB, uint256 amountA, uint256 amountB, address _XORA) external {
        // Allows user to remove liquidity in a single transaction
        router.removeLiquidity(tokenA, tokenB, amountA, amountB, _XORA);
    }

    function claimReward(address tokenA, address tokenB, address _XORA) external {
        router.claimReward(tokenA, tokenB, _XORA);
    }
}
