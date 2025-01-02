// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

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
    }

    // Token being vested
    // Token being vested
    IERC20 public immutable i_token;

    // Mapping from beneficiary to vesting schedule
    mapping(address => VestingSchedule) public vestingSchedules;

    // Whitelist of beneficiaries
    mapping(address => bool) public whitelist;

    // Events
    event VestingScheduleCreated(address indexed beneficiary, uint256 amount);
    event TokensClaimed(address indexed beneficiary, uint256 amount);
    event VestingRevoked(address indexed beneficiary);
    event BeneficiaryWhitelisted(address indexed beneficiary);
    event BeneficiaryRemovedFromWhitelist(address indexed beneficiary);

    error ZeroAddress(string field);
    error ZeroValue(string field);
    error VestingDurationMustGteThanCliffDuration();
    error ExistedVesting();
    error TooEarly();
    error TransferFailed();
    error NoVesting();
    error Revoked();

    constructor(address vestingToken_) {
        if (vestingToken_ == address(0)) revert ZeroAddress("vestingToken_");
        i_token = IERC20(vestingToken_);
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
        if (beneficiary == address(0)) revert ZeroAddress("beneficiary");
        if (amount == 0) revert ZeroValue("amount");
        if (vestingDuration == 0) revert ZeroValue("vestingDuration");
        if (vestingDuration < cliffDuration) revert VestingDurationMustGteThanCliffDuration();
        if (vestingSchedules[beneficiary].totalAmount > 0) revert ExistedVesting();
        if (startTime <= block.timestamp) revert TooEarly();

        vestingSchedules[beneficiary] = VestingSchedule({
            totalAmount: amount,
            startTime: startTime,
            cliffDuration: cliffDuration,
            vestingDuration: vestingDuration,
            amountClaimed: 0,
            revoked: false
        });

        if (i_token.allowance(msg.sender, address(this)) < amount) {
            i_token.approve(address(this), amount);
        }
        if (i_token.transferFrom(msg.sender, address(this), amount) == false) {
            revert TransferFailed();
        }
        emit VestingScheduleCreated(beneficiary, amount);
    }

    function calculateVestedAmount(
        address beneficiary
    ) public view returns (uint256) {
        VestingSchedule memory schedule = vestingSchedules[beneficiary];

        if (schedule.totalAmount == 0 || schedule.revoked == true) {
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
        address sender = msg.sender;
        VestingSchedule storage schedule = vestingSchedules[sender];
        if (schedule.totalAmount == 0) revert NoVesting();
        if (schedule.revoked == true) revert Revoked();

        uint256 vestedAmount = calculateVestedAmount(sender);
        uint256 claimableAmount = vestedAmount - schedule.amountClaimed;
        if (claimableAmount == 0) revert ZeroValue("claimableAmount");

        schedule.amountClaimed += claimableAmount;
        if (i_token.transfer(sender, claimableAmount) == false) revert TransferFailed();

        emit TokensClaimed(sender, claimableAmount);
    }

    function revokeVesting(address beneficiary) external onlyOwner {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        if (schedule.totalAmount == 0) revert NoVesting();
        if (schedule.revoked == true) revert Revoked();

        uint256 vestedAmount = calculateVestedAmount(beneficiary);
        uint256 unclaimedAmount = schedule.totalAmount - vestedAmount;

        schedule.revoked = true;

        if (unclaimedAmount > 0 && i_token.transfer(owner(), unclaimedAmount) == false) {
            revert TransferFailed();
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
