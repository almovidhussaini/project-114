// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TokenVesting is Ownable(msg.sender), ReentrancyGuard {
    IERC20 public token;

    struct VestingSchedule {
        uint256 startTime;
        uint256 cliff; // in seconds
        uint256 duration; // total vesting duration in seconds
        uint256 amount;
        uint256 initialRelease; // percentage for initial release, in basis points (1% = 100 basis points)
        uint256 released;
    }

    mapping(address => VestingSchedule) public teamVesting;
    mapping(address => VestingSchedule) public privatePreSaleVesting;
    mapping(address => VestingSchedule) public marketingVesting;

    event TokensClaimed(address indexed beneficiary, uint256 amount);

    constructor(address _token) {
        token = IERC20(_token);
    }

    // Add a new vesting schedule for team tokens
    function addTeamVesting(address beneficiary, uint256 amount) external onlyOwner {
        uint256 cliff = 18 * 30 days;
        uint256 duration = 4 * 365 days;
        teamVesting[beneficiary] = VestingSchedule(block.timestamp, cliff, duration, amount, 0, 0);
    }

    // Add a new vesting schedule for private & pre-sale tokens
    function addPrivatePreSaleVesting(address beneficiary, uint256 amount) external onlyOwner {
        require(amount>0,"amount is insufficient");
        uint256 cliff = 30 days; // for example, 1-month cliff
        uint256 duration = 6 * 30 days; // 6 months vesting
        privatePreSaleVesting[beneficiary] = VestingSchedule(block.timestamp, cliff, duration, amount, 0, 0);
    }

    // Add a new vesting schedule for marketing tokens with 25% immediate release
    function addMarketingVesting(address beneficiary, uint256 amount) external onlyOwner {
        require(amount>0,"amount is insufficient");
        uint256 initialRelease = (amount * 25) / 100;
        uint256 remainingAmount = amount - initialRelease;
        uint256 cliff = 0;
        uint256 duration = 12 * 30 days; // 12 months
        marketingVesting[beneficiary] = VestingSchedule(block.timestamp, cliff, duration, remainingAmount, initialRelease, 0);

        // Transfer 25% immediately for marketing
        token.transfer(beneficiary, initialRelease);
        emit TokensClaimed(beneficiary, initialRelease);
    }

    // Calculate vested amount based on schedule and time elapsed
    function _calculateVestedAmount(VestingSchedule storage schedule) internal view returns (uint256) {
        if (block.timestamp < schedule.startTime + schedule.cliff) {
            return 0;
        }
        if (block.timestamp >= schedule.startTime + schedule.duration) {
            return schedule.amount;
        }
        uint256 timeElapsed = block.timestamp - schedule.startTime;
        return (schedule.amount * timeElapsed) / schedule.duration;
    }

    // Claim vested tokens for a specific category
    function claimTokens(address beneficiary, uint256 vestingType) external nonReentrant {
        VestingSchedule storage schedule;

        if (vestingType == 1) { // Team
            schedule = teamVesting[beneficiary];
        } else if (vestingType == 2) { // Private & Pre-Sale
            schedule = privatePreSaleVesting[beneficiary];
        } else if (vestingType == 3) { // Marketing
            schedule = marketingVesting[beneficiary];
        } else {
            revert("Invalid vesting type");
        }

        uint256 vestedAmount = _calculateVestedAmount(schedule);
        uint256 claimableAmount = vestedAmount - schedule.released;

        require(claimableAmount > 0, "No tokens available for claim");

        schedule.released += claimableAmount;
        token.transfer(beneficiary, claimableAmount);
        emit TokensClaimed(beneficiary, claimableAmount);
    }
}
