// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract USDT is ERC20, Ownable, ReentrancyGuard {
    event Minted(address indexed to, uint256 amount);
    // address pairLiquidity;
    // uint256 public transactionFee = 50; // 0.5% feex for every transaction
    address exampleMInt = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;

    constructor() Ownable(msg.sender)  ERC20("Tether USD", "USDT") {
        _mint(msg.sender, 1_000_000 * (10 ** decimals())); // Initial mint of 1 million USDT
        // pairLiquidity = _pairLiquidity;
        _mint(exampleMInt, 1_000_000 * (10 ** decimals()));
    }

    function mint(address to, uint256 amount) external onlyOwner nonReentrant {
        _mint(to, amount);
        emit Minted(to, amount);
    }

    // function _transfer(
    //     address sender,
    //     address recipient,
    //     uint256 amount
    // ) internal override {
    //     uint256 feeAmount = (amount * transactionFee) / 10000;
    //     uint256 amountAfterFee = amount - feeAmount;

    //     // Transfer the amount minus the fee to the recipient
    //     super._transfer(sender, recipient, amountAfterFee);

    //     // Send the fee amount to the fee address
    //     if (feeAmount > 0) {
    //         super._transfer(sender, pairLiquidity, feeAmount);
    //     }
    // }
}