# Token Vesting Challenge

This challenge involves creating a smart contract for token vesting with configurable schedules. You'll learn about time-based operations, token handling, and access control in Solidity.

## 🎯 Challenge Overview

Create a token vesting contract that allows an admin to:
- Create vesting schedules for beneficiaries
- Configure cliff periods and vesting durations
- Revoke unvested tokens
- Allow beneficiaries to claim their vested tokens

## 🚀 Getting Started

### Prerequisites
- [Remix IDE](https://remix.ethereum.org/)
- MetaMask or another web3 wallet
- Connect to Asset Hub Westend Testnet:

```bash
  - Network name: Asset-Hub Westend Testnet 
  - RPC URL URL: `https://westend-asset-hub-eth-rpc.polkadot.io` 
  - Chain ID: `420420421` - Currency Symbol: `WND` - Block Explorer URL: `https://assethub-westend.subscan.io`
```

- Request Westend tokens from the [Westend Faucet](https://faucet.polkadot.io/westend?parachain=1000).

### Setup Steps

1. **Create the Test Token**
```solidity
// TestToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor() ERC20("Test Token", "TEST") {
        _mint(msg.sender, 1000000 * 10**decimals());
    }
}
```

2. **Deploy the Contracts**
   - Open Remix IDE
   - Create two files: `TestToken.sol` and `TokenVesting.sol`
   - Paste the challenge code into `TokenVesting.sol`
   - Compile both contracts
   - Deploy `TestToken` first
   - Deploy `TokenVesting` using the TestToken address as constructor parameter

3. **Test Setup**
   - Approve the TokenVesting contract to spend your tokens:
     ```solidity
     // On TestToken contract
     approve(VESTING_CONTRACT_ADDRESS, 1000000 * 10**18)
     ```

## 📝 Example Usage

Here's an example of how to test your implementation:

1. **Create a Vesting Schedule**
```solidity
// Parameters:
// beneficiary: 0x... (recipient address)
// amount: 1000000000000000000000 (1000 tokens with 18 decimals)
// cliffDuration: 600 (10 minutes)
// vestingDuration: 3600 (1 hour)
// startTime: Current timestamp
createVestingSchedule(beneficiary, amount, cliffDuration, vestingDuration, startTime)
```

2. **Check Vested Amount**
```solidity
// After cliff period
calculateVestedAmount(beneficiary)
// Should return partial amount based on time passed
```

3. **Claim Tokens**
```solidity
// As beneficiary
claimVestedTokens()
```

4. **Revoke Vesting**
```solidity
// As admin
revokeVesting(beneficiary)
```

## ✅ Expected Results

### After Creating Schedule
```solidity
// Events emitted:
VestingScheduleCreated(beneficiary, 1000000000000000000000)

// Token balances:
Contract: 1000 TEST
Beneficiary: 0 TEST
```

### After Cliff (10 minutes)
```solidity
// Vested amount calculation:
calculateVestedAmount(beneficiary) => ~166 TEST (16.6% of total)

// After claiming:
Contract: ~834 TEST
Beneficiary: ~166 TEST
```

### After Full Duration (1 hour)
```solidity
// Vested amount calculation:
calculateVestedAmount(beneficiary) => 1000 TEST (100%)

// After claiming:
Contract: 0 TEST
Beneficiary: 1000 TEST
```

## 🧪 Test Cases

1. **Basic Vesting Flow**
   - Create schedule ✓
   - Wait for cliff ✓
   - Claim partial tokens ✓
   - Wait for full duration ✓
   - Claim all tokens ✓

2. **Edge Cases**
   - Try to claim before cliff ✗
   - Create schedule with zero amount ✗
   - Create schedule for zero address ✗
   - Revoke after partial vesting ✓

## 📋 Validation Checklist

- [ ] Contract compiles without warnings
- [ ] All functions have proper access control
- [ ] Events are emitted correctly
- [ ] Time calculations are accurate
- [ ] Token transfers succeed
- [ ] Revocation works as expected
- [ ] No funds can be locked permanently

## 🔍 Common Issues

1. **Time Calculations**: Make sure to handle timestamps correctly and consider block.timestamp precision
2. **Token Decimals**: Remember to account for token decimals in calculations
3. **Rounding**: Be careful with division operations and potential rounding issues
4. **Gas Optimization**: Consider gas costs in loops and calculations

## 🎉 Success Criteria

Your implementation should:
1. Pass all test cases
2. Handle edge cases gracefully
3. Emit appropriate events
4. Maintain accurate token accounting
5. Implement proper access control
6. Include comprehensive input validation

Good luck with the challenge! 🚀

---

# 🔐 What's token vesting?

## ✨ Introduction

Token vesting is a mechanism used to gradually distribute tokens over time according to a predefined schedule. This practice helps align long-term interests, ensure commitment, and prevent market disruption from sudden large token releases.

## 📚 Historical Context

### 🏢 Traditional Equity Vesting
The concept of vesting originated in traditional finance with restricted stock units (RSUs) and stock options. Companies like Microsoft, Apple, and Google popularized equity vesting in the tech industry, typically using 4-year schedules with a 1-year cliff.

### 🌐 Adaptation to Crypto
When blockchain projects began issuing tokens, they adapted vesting mechanisms to the cryptocurrency ecosystem. Notable early implementations include:
- 💎 Ethereum Foundation (2014): Used for team and developer allocations
- 📂 Filecoin (2017): Implemented sophisticated vesting schedules for investors and team members
- 🦄 Uniswap (2020): Introduced team token vesting with 4-year schedules

## 🎯 Use Cases

### 👥 1. Team Token Allocation
- 🤝 Ensures long-term commitment from founding team and employees
- ⏳ Typically involves longer vesting periods (2-4 years)
- 🎯 Often includes cliff periods to ensure initial project delivery

Example Schedule:
```
💰 Total Amount: 1,000,000 tokens
⏰ Cliff: 12 months
⌛ Vesting Period: 48 months
📈 Release: Linear after cliff
```

### 💼 2. Investor Token Distribution
- 📊 Prevents immediate selling pressure after token generation events (TGEs)
- 🔄 Different schedules for different investment rounds
- ⚡ May include shorter cliff periods than team allocations

Common Structure:
```
🌱 Seed Round: 24-36 months vesting
🔒 Private Sale: 18-24 months vesting
🌐 Public Sale: 6-12 months vesting
```

### 🎓 3. Advisor Allocations
- ⏱️ Moderate vesting periods (12-24 months)
- 🎯 May include performance-based unlocking criteria
- 📊 Often smaller allocations compared to team/investor portions

### 🌍 4. Community Rewards
- ⚡ Shorter vesting periods (3-12 months)
- 💧 Used for liquidity mining rewards
- 🤝 Community development incentives

## 🛠️ Technical Overview

### 📊 Vesting Calculation Formula
The basic linear vesting formula:
```
💫 vestedAmount = (totalAmount * timeElapsed) / vestingDuration
```

Additional considerations:
- ⏰ Cliff period: No tokens available until cliff duration passes
- 🔄 Multiple claims: Track released amounts
- ⚠️ Revocation: Handle partial vesting scenarios

### 🔧 Key Components

1. **📝 Schedule Creation**
   - 💰 Total token amount
   - ⏰ Start time
   - ⌛ Cliff duration
   - 📅 Vesting duration
   - 👤 Beneficiary address

2. **💫 Token Release Mechanism**
   - 📈 Linear distribution
   - 🔒 Cliff enforcement
   - 💸 Partial claims support
   - ⚠️ Revocation handling

## 🌟 Features

### 💎 Core Features
1. **📊 Schedule Management**
   - ➕ Create multiple schedules per beneficiary
   - 🔄 Modify schedules (if supported)
   - ❌ Revoke unvested tokens
   - 🔍 Query vesting status

2. **💰 Claim System**
   - 🧮 Calculate vested amounts
   - 💸 Process partial claims
   - 📝 Track released tokens
   - 🔄 Handle multiple claims

3. **🔑 Administrative Controls**
   - 📝 Schedule creation
   - 🚨 Emergency revocation
   - 🔄 Contract upgrades (if implemented)
   - 💰 Token recovery

## 🔒 Security Considerations

### 1. 🔑 Access Control
- 👥 Clear separation of roles (admin, beneficiary)
- ✅ Proper permission checks
- 🔐 Multi-signature support (optional)

### 2. 🛡️ Smart Contract Security
- 🔒 Reentrancy protection
- 🧮 Safe math operations
- ✅ Input validation
- 📝 Event emission

### 3. 💎 Token Handling
- 🔒 SafeERC20 implementation
- ✅ Token approval checks
- 🔄 Transfer verification
- 💰 Balance validation

## 💡 Best Practices

### 1. 🧪 Testing
- ✅ Comprehensive test coverage
- ⏰ Time manipulation tests
- 🎯 Edge case verification
- ⚡ Gas optimization checks

### 2. 🚀 Deployment
- ✅ Parameter verification
- 📈 Gradual rollout
- 🚨 Emergency procedures
- 🔄 Upgrade paths

### 3. 📊 Monitoring
- 📝 Event logging
- 📊 Analytics integration
- 🚨 Alert systems
- 🔍 Regular audits

## 📖 Implementation Guide

### 🔧 Contract Setup
```solidity
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
```

### 🔑 Key Functions

1. **📝 Schedule Creation**
```solidity
function createVestingSchedule(
    address beneficiary,
    uint256 amount,
    uint256 startTime,
    uint256 cliff,
    uint256 duration
) external;
```

2. **🧮 Vesting Calculation**
```solidity
function calculateVestedAmount(bytes32 scheduleId) 
    public 
    view 
    returns (uint256);
```

3. **💰 Token Claims**
```solidity
function claimVestedTokens(bytes32 scheduleId) 
    external 
    nonReentrant;
```

### ⚡ Gas Optimization Tips
1. 🔧 Use efficient data structures
2. 📦 Batch operations when possible
3. 💾 Optimize storage usage
4. 📝 Consider using events for off-chain tracking
