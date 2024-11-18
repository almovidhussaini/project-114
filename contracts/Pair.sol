// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Pair is ReentrancyGuard {
    address public token0;
    address public token1;
    uint256 public reserve0;
    uint256 public reserve1;
    uint256 public constant REWARD_RATE = 15;
    uint256 public constant SECONDS_IN_YEAR = 365 * 24 * 60 * 60;
    // uint256 addedTime;

    mapping(address => uint256) public amount0ForUser;
    mapping(address => uint256) public amount1ForUser;
    mapping(address => uint256) public addedTime;
    IERC20 public xoraToken;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1);

    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
    }

    function addLiquidity(
        address to,
        uint256 amount0,
        uint256 amount1
    ) external nonReentrant {
        reserve0 += amount0;
        reserve1 += amount1;

        amount0ForUser[to] += amount0;
        amount1ForUser[to] += amount1;

        if (addedTime[to] == 0) {
            addedTime[to] = block.timestamp;
        }

        require(
            IERC20(token0).transferFrom(to, address(this), amount0),
            " Failed in transferring amount0"
        );
        require(
            IERC20(token1).transferFrom(to, address(this), amount1),
            "Failed in transferring amount1"
        );

        emit Mint(to, amount0, amount1);
    }

    function removeLiquidity(
        address to,
        uint256 amount0,
        uint256 amount1
    ) external nonReentrant {
        require(
            reserve0 >= amount0 && reserve1 >= amount1,
            "Pair: INSUFFICIENT_LIQUIDITY"
        );
        require(
            amount0ForUser[to] >= amount0,
            "Pair: Insufficient token 0 amount"
        );
        require(
            amount1ForUser[to] >= amount1,
            "Pair: Insufficient token 1 amount"
        );

        reserve0 -= amount0;
        reserve1 -= amount1;
        amount0ForUser[to] -= amount0;
        amount1ForUser[to] -= amount1;

        require(
            IERC20(token0).transfer(to, amount0),
            "Pair: Token 0 transfer failed"
        );
        require(
            IERC20(token1).transfer(to, amount1),
            "Pair: Token 1 transfer failed"
        );
        emit Burn(to, amount0, amount1);
    }

    function claimRewards(address to ,address _XORA) public nonReentrant {
        // uint256 totalShares = reserve0 + reserve1;
        uint256 totalShares = amount0ForUser[to] +
            amount1ForUser[to];
        require(totalShares > 0, "Pair: No liquidity added for the user");

        uint256 blockTime = block.timestamp - addedTime[to];

        uint256 reward = (totalShares * blockTime * REWARD_RATE) /
            (100 * SECONDS_IN_YEAR);
        addedTime[to] = block.timestamp;
        xoraToken = IERC20(_XORA);
        require(
            xoraToken.transfer(to, reward),
            "reward token transfer fails"
        );
    }
}
