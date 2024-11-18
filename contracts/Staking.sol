// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Staking is ERC20, Ownable, ReentrancyGuard {
    IERC20 public xoraToken;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public stakedfromTS;

    uint256 public constant SECONDS_IN_YEAR = 365 * 24 * 60 * 60;

    uint256 public constant REWARD_RATE = 15;
    uint256 public constant EARLY_REWARD_RATE = 165; //10% of 15% = 16.5%
    uint256 stakingStart;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 reward);

    constructor() Ownable(msg.sender) ERC20("staked Xora", "stXORA") {
        stakingStart = block.timestamp;
    }

    function stake(uint256 amount, address _xoraToken) external nonReentrant {
        require(amount > 0, "Cannot stake 0 tokens");

        xoraToken = IERC20(_xoraToken);
        balances[msg.sender] += amount;
        stakedfromTS[msg.sender] = block.timestamp;

        uint256 allowance = xoraToken.allowance(msg.sender, address(this));
        require(allowance >= amount, "Insufficient allowance for transferFrom");

        require(
            xoraToken.transferFrom(msg.sender, address(this), amount),
            "Failed to transferr staking amount"
        );
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount, address _xoraToken) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        xoraToken = IERC20(_xoraToken);
        balances[msg.sender] -= amount;

        require(xoraToken.transfer(msg.sender, amount), "Failed to transfer withdrawn amount");
        emit Withdrawn(msg.sender, amount);
    }

    function claimRewards() public nonReentrant {
        require(balances[msg.sender] > 0, "you donot have enouph balance");

        uint256 currentTime = block.timestamp;

        uint256 secondsStaked = currentTime - stakedfromTS[msg.sender];
        uint256 secondsStakedFromInitial = currentTime - stakingStart;

        uint256 reward;
        if (secondsStakedFromInitial < (3 * 30 days)) {
            reward =
                (balances[msg.sender] * EARLY_REWARD_RATE * secondsStaked) /
                (1000 * SECONDS_IN_YEAR);
        } else {
            reward =
                (balances[msg.sender] * REWARD_RATE * secondsStaked) /
                (100 * SECONDS_IN_YEAR);
        }
        require(reward > 0, "No rewards to claim");
        _mint(msg.sender, reward);
        stakedfromTS[msg.sender] = block.timestamp;
        emit RewardsClaimed(msg.sender, reward);
    }

    // Function to check rewards for the user (no state change)
    function checkRewards(address user) external view returns (uint256) {
        require(balances[user] > 0, "User has no staked balance");

        uint256 currentTime = block.timestamp;
        uint256 secondsStaked = currentTime - stakedfromTS[msg.sender];
        uint256 secondsStakedFromInitial = currentTime - stakingStart;

        uint256 reward;
        // Calculate rewards based on whether staking is early or not
        if (secondsStakedFromInitial < (3 * 30 days)) {
            reward =
                (balances[user] * EARLY_REWARD_RATE * secondsStaked) /
                (1000 * SECONDS_IN_YEAR);
        } else {
            reward =
                (balances[user] * REWARD_RATE * secondsStaked) /
                (100 * SECONDS_IN_YEAR);
        }
        return reward;
    }
}
