// Challenge: Token Vesting Contract
/*
Create a token vesting contract with the following requirements:

1. The contract should allow an admin to create vesting schedules for different beneficiaries
2. Each vesting schedule should have:
   - Total amount of tokens to be vested
   - Cliff period (time before any tokens can be claimed)
   - Vesting duration (total time for all tokens to vest)
   - Start time
3. After the cliff period, tokens should vest linearly over time
4. Beneficiaries should be able to claim their vested tokens at any time
5. Admin should be able to revoke unvested tokens from a beneficiary

Bonus challenges:
- Add support for multiple token types
- Implement a whitelist for beneficiaries
- Add emergency pause functionality

Here's your starter code:
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TokenVesting is Ownable(msg.sender), Pausable, ReentrancyGuard {
    struct VestingSchedule {
    // TODO: Define the vesting schedule struct
        uint256 totalAmount;
        uint256 startTime;
        uint256 cliffDuration;
        uint256 vestingDuration;
        uint256 amountClaimed;
        bool revoked;
    }

    // Token being vested
    // TODO: Add state variables
    IERC20 public token;

    // Mapping from beneficiary to vesting schedule
    // TODO: Add state variables
    mapping(address => VestingSchedule) public vestingSchedules;

    // Whitelist of beneficiaries
    // TODO: Add state variables
    mapping(address => bool) public whitelist;

    // Events
    event VestingScheduleCreated(address indexed beneficiary, uint256 amount);
    event TokensClaimed(address indexed beneficiary, uint256 amount);
    event VestingRevoked(address indexed beneficiary);
    event BeneficiaryWhitelisted(address indexed beneficiary);
    event BeneficiaryRemovedFromWhitelist(address indexed beneficiary);

    constructor(address tokenAddress) {
           // TODO: Initialize the contract
        token = IERC20(tokenAddress);
    }

    // Modifier to check if beneficiary is whitelisted
    modifier onlyWhitelisted(address beneficiary) {
        require(whitelist[beneficiary], "Beneficiary not whitelisted");
        _;
    }

    function addToWhitelist(address beneficiary) external onlyOwner {
        require(beneficiary != address(0), "Invalid address");
        whitelist[beneficiary] = true;
        emit BeneficiaryWhitelisted(beneficiary);
    }

    function removeFromWhitelist(address beneficiary) external onlyOwner {
        whitelist[beneficiary] = false;
        emit BeneficiaryRemovedFromWhitelist(beneficiary);
    }

    function createVestingSchedule(
        address beneficiary,
        uint256 amount,
        uint256 cliffDuration,
        uint256 vestingDuration,
        uint256 startTime
    ) external onlyOwner onlyWhitelisted(beneficiary) whenNotPaused {
        // TODO: Implement vesting schedule creation
        require(vestingSchedules[beneficiary].totalAmount == 0, "Vesting schedule already exists");
        require(amount > 0, "Amount cannot be 0");
        require(vestingDuration > 0, "Vesting duration cannot be 0");
        require(cliffDuration < vestingDuration, "Cliff duration must be less than vesting duration");
        require(startTime > 0, "Start time must be in the future");

        VestingSchedule memory schedule = VestingSchedule(
            amount,
            startTime,
            cliffDuration,
            vestingDuration,
            0,
            false
        );

        vestingSchedules[beneficiary] = schedule;

        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        emit VestingScheduleCreated(beneficiary, amount);
    }

    function calculateVestedAmount(
        address beneficiary
    ) public view returns (uint256) {
        // TODO: Implement vested amount calculation
        VestingSchedule storage schedule = vestingSchedules[beneficiary];

        if (block.timestamp < schedule.startTime + schedule.cliffDuration) {
            return 0;
        } else if (schedule.revoked) {
            return 0;
        } else {
            // uint256 elapsedTime = block.timestamp - (schedule.startTime + schedule.cliffDuration);
            // uint256 vestingPeriod = schedule.vestingDuration - schedule.cliffDuration;
            // uint256 vestedAmount = (schedule.totalAmount * elapsedTime) / vestingPeriod;
            // if (vestedAmount > schedule.totalAmount) {
            //     vestedAmount = schedule.totalAmount;
            // }
            // return vestedAmount - schedule.amountClaimed;

            uint256 duration = block.timestamp - schedule.startTime;
            uint256 vestedAmount = (schedule.totalAmount * duration) /
                schedule.vestingDuration;

            if (vestedAmount > schedule.totalAmount) {
                vestedAmount = schedule.totalAmount;
            }

            return vestedAmount - schedule.amountClaimed;
        }
    }

    function claimVestedTokens() external nonReentrant whenNotPaused {
           // TODO: Implement token claiming
        VestingSchedule storage schedule = vestingSchedules[msg.sender];
        uint256 vestedAmount = calculateVestedAmount(msg.sender);
        require(vestedAmount > 0, "No tokens to claim");

        schedule.amountClaimed += vestedAmount;

        require(token.transfer(msg.sender, vestedAmount), "Transfer failed");

        emit TokensClaimed(msg.sender, vestedAmount);
    }

    function revokeVesting(address beneficiary) external onlyOwner {
        // TODO: Implement vesting revocation
        VestingSchedule storage schedule = vestingSchedules[beneficiary];

        require(!schedule.revoked, "Vesting already revoked");

        uint256 vestedAmount = calculateVestedAmount(beneficiary);

        uint256 unvestedAmount = schedule.totalAmount - vestedAmount;

        if (unvestedAmount > 0)
        {
            schedule.amountClaimed += unvestedAmount;
            require(token.transfer(msg.sender, unvestedAmount), "Transfer failed");
        }

        schedule.revoked = true;

        emit TokensClaimed(beneficiary, unvestedAmount);
        emit VestingRevoked(beneficiary);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}

/*
Solution template (key points to implement):

1. VestingSchedule struct should contain:
   - Total amount
   - Start time
   - Cliff duration
   - Vesting duration
   - Amount claimed
   - Revoked status

2. State variables needed:
   - Mapping of beneficiary address to VestingSchedule
   - ERC20 token reference
   - Owner/admin address

3. createVestingSchedule should:
   - Validate input parameters
   - Create new vesting schedule
   - Transfer tokens to contract
   - Emit event

4. calculateVestedAmount should:
   - Check if cliff period has passed
   - Calculate linear vesting based on time passed
   - Account for already claimed tokens
   - Handle revoked status

5. claimVestedTokens should:
   - Calculate claimable amount
   - Update claimed amount
   - Transfer tokens
   - Emit event

6. revokeVesting should:
   - Only allow admin
   - Calculate and transfer unvested tokens back
   - Mark schedule as revoked
   - Emit event
*/