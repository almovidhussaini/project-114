// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./Pair.sol";

interface IXORA {
    function mintToken(address _pairToken) external;
}

contract Factory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    IERC20 public xoraToken;

    event PairCreated(address indexed token0, address indexed token1, address pair);

    function createPair(address tokenA, address tokenB, address _xoraToken) external returns (address pair) {
        require(tokenA != tokenB, "Factory: IDENTICAL_ADDRESSES");
        require(getPair[tokenA][tokenB] == address(0), "Factory: PAIR_EXISTS");
        pair = address(new Pair(tokenA, tokenB));
        IXORA(_xoraToken).mintToken(pair);
        getPair[tokenA][tokenB] = pair;
        allPairs.push(pair);

        emit PairCreated(tokenA, tokenB, pair);
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }
}
