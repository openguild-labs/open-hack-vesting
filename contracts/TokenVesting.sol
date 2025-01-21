// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TokenVesting is Ownable(msg.sender), Pausable, ReentrancyGuard {
    struct VestingSchedule {

        uint256 totalAmount;
        uint256 startTime;
        uint256 cliffDuration;
        uint256 vestingDuration;
        uint256 amountClaimed;
        bool revoked;
    // TODO: Define the vesting schedule struct
    }

    // Token being vested
    IERC20 public token;
    // TODO: Add state variables


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
    
        require(beneficiary != address(0), "Invalid address");
        require(amount > 0, "Invalid amount");
        require(vestingDuration > 0, "Invalid vesting duration");
        require(vestingDuration >= cliffDuration, "Invalid cliff duration");
        require(vestingSchedules[beneficiary].totalAmount == 0, "Vesting already exists");
        require(startTime > block.timestamp, "Invalid start time");

        VestingSchedule memory schedule = VestingSchedule({
            totalAmount: amount,
            startTime: startTime,
            cliffDuration: cliffDuration,
            vestingDuration: vestingDuration,
            amountClaimed: 0,
            revoked: false
        });

        vestingSchedules[beneficiary] = schedule;

        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        emit VestingScheduleCreated(beneficiary, amount);



    }

    function calculateVestedAmount(
        address beneficiary
        
    ) public view returns (uint256) {




        // TODO: Implement vested amount calculation
        VestingSchedule memory schedule = vestingSchedules[beneficiary];

        if (schedule.totalAmount == 0 || schedule.revoked) {
            return 0;
        }

        if (block.timestamp < schedule.startTime + schedule.cliffDuration) {
            return 0;
        }

        if (block.timestamp >= schedule.startTime + schedule.vestingDuration) {
            return schedule.totalAmount;
        }

        uint256 timeFromStart = block.timestamp - schedule.startTime;

        uint256 vestedAmount = (schedule.totalAmount * timeFromStart) / schedule.vestingDuration;

        return vestedAmount;





    }

    function claimVestedTokens() external nonReentrant whenNotPaused {
           // TODO: Implement token claiming
        address beneficiary = msg.sender;
        VestingSchedule storage schedule = vestingSchedules[beneficiary];

        require(schedule.totalAmount > 0, "No vesting schedule");
        require(!schedule.revoked, "Vesting revoked");

        uint256 vestedAmount = calculateVestedAmount(beneficiary);
        uint256 claimableAmount = vestedAmount - schedule.amountClaimed;

        require(claimableAmount > 0, "No tokens to claim");

        schedule.amountClaimed = vestedAmount;

        require(token.transfer(beneficiary, claimableAmount), "Transfer failed");

        emit TokensClaimed(beneficiary, claimableAmount);



    }

    function revokeVesting(address beneficiary) external onlyOwner {
        // TODO: Implement vesting revocation
        VestingSchedule storage schedule = vestingSchedules[beneficiary];

        require(schedule.totalAmount > 0, "No vesting schedule");
        require(!schedule.revoked, "Vesting already revoked");

        uint256 vestedAmount = calculateVestedAmount(beneficiary);
        uint256 unclaimedAmount = schedule.totalAmount - vestedAmount;

        schedule.revoked = true;

        if (unclaimedAmount > 0) {
            require(token.transfer(owner(), unclaimedAmount), "Transfer failed");
        }

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
