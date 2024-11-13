// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

 contract USDC is ERC20, Ownable, ReentrancyGuard{
    event Minted(address indexed to, uint256 amount);

    constructor() Ownable(msg.sender)  ERC20(" USDC Token", "USDC")   {
        _mint(msg.sender, 1_000_000 * (10 ** decimals())); // Initial mint of 1 million BUSD
    }

    function mint(address to, uint256 amount) external onlyOwner nonReentrant {
        _mint(to, amount);
        emit Minted(to, amount);
    }
}
