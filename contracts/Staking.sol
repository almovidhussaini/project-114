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
    uint256 public lockTimestamp;
    uint256 public constant REWARD_RATE = 15;
    uint256 public constant REARLY_REWARD_RATE = 165; //10% of 15% = 16.5%
    uint256 stakingStart;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 reward);

    constructor() Ownable(msg.sender) ERC20("staked Xora", "stXORA") {
        _mint(address(this), 44_280_000 * (10**18));
        stakingStart = block.timestamp;
    }

    function stake(uint256 amount , address _xoraToken)  external nonReentrant {
        xoraToken = IERC20(_xoraToken);
        xoraToken.transferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
        stakedfromTS[msg.sender] = block.timestamp;
        lockTimestamp = block.timestamp;
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount ,address _xoraToken) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        // claimRewards();
        xoraToken = IERC20(_xoraToken);
        balances[msg.sender] -=amount;

        xoraToken.transfer( msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    } 

    function claimRewards() public nonReentrant{
        require(balances[msg.sender] >= 0, "you donot have enouph balance");
        uint256 reward;
        uint256 secondsStaked = block.timestamp - stakedfromTS[msg.sender];
        uint256 secondsStakedFromInitial = block.timestamp - stakingStart;
        if(secondsStakedFromInitial < (3 * 30 days)){
             reward = (balances[msg.sender] * REARLY_REWARD_RATE * secondsStaked)/(1000 * SECONDS_IN_YEAR);
        }
        else {
             reward = (balances[msg.sender] * REWARD_RATE * secondsStaked)/(100 * SECONDS_IN_YEAR);
        }
        require(reward > 0, "No rewards to claim");
        _mint(msg.sender, reward);
        stakedfromTS[msg.sender] = block.timestamp;
        emit RewardsClaimed(msg.sender, reward);

    }

}
