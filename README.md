# 🏛️ Govwatch - Citizen Audit Smart Contract

## 📋 Overview

Govwatch is a blockchain-based transparency platform that enables citizens to track public funds and conduct audits on government spending. Built on the Stacks blockchain using Clarity smart contracts, it provides an immutable ledger for public fund allocation, spending, and citizen oversight.

## ✨ Features

- 💰 **Public Fund Tracking**: Create and monitor government funds with allocated budgets
- 📊 **Transaction Recording**: Log all fund expenditures with detailed information
- 🔍 **Citizen Audits**: Allow citizens to submit audit findings and concerns
- 🗳️ **Community Voting**: Vote on audit findings to build consensus
- 👥 **Official Authorization**: Manage authorized government officials
- 📈 **Fund Analytics**: Track utilization rates and spending patterns

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity smart contracts

### Installation

1. Clone this repository
2. Navigate to the project directory
3. Run Clarinet commands to interact with the contract

```bash
clarinet console
```

## 📖 Usage Guide

### For Government Officials

#### 1. 🏢 Get Authorized
Contract owner must authorize officials:
```clarity
(contract-call? .Govwatch authorize-official 'SP1234... "Treasury")
```

#### 2. 💼 Create Public Fund
```clarity
(contract-call? .Govwatch create-fund "Infrastructure Fund" "Road maintenance and repairs" u1000000 "Public Works")
```

#### 3. 📝 Record Transactions
```clarity
(contract-call? .Govwatch record-transaction u1 u50000 "ABC Construction" "Highway repair contract")
```

### For Citizens

#### 1. 🔍 Submit Audit
```clarity
(contract-call? .Govwatch submit-audit u1 "Overpriced contract detected" "high")
```

#### 2. 🗳️ Vote on Audits
```clarity
(contract-call? .Govwatch vote-on-audit u1 true)
```

### Read-Only Functions

#### 📊 Check Fund Details
```clarity
(contract-call? .Govwatch get-fund u1)
```

#### 📈 View Fund Utilization
```clarity
(contract-call? .Govwatch get-fund-utilization u1)
```

#### 🔍 Get Audit Information
```clarity
(contract-call? .Govwatch get-audit u1)
```

## 🏗️ Contract Structure

### Data Maps
- **public-funds**: Store fund information and spending data
- **fund-transactions**: Record all fund expenditures
- **citizen-audits**: Track citizen audit submissions
- **audit-votes**: Store community votes on audits
- **authorized-officials**: Manage government official permissions

### Key Functions

| Function | Purpose | Access |
|----------|---------|--------|
| `create-fund` | Create new public fund | Authorized Officials |
| `record-transaction` | Log fund expenditure | Authorized Officials |
| `submit-audit` | Submit citizen audit | Anyone |
| `vote-on-audit` | Vote on audit findings | Anyone |
| `get-fund-utilization` | Check spending efficiency | Read-only |

## 🔒 Security Features

- ✅ Authorization checks for official functions
- ✅ Spending limits enforcement
- ✅ Duplicate vote prevention
- ✅ Input validation for all parameters
- ✅ Immutable transaction records

## 🎯 Use Cases

1. **Municipal Budget Tracking** 📊
   - Track city budget allocations
   - Monitor departmental spending
   - Identify budget overruns

2. **Infrastructure Projects** 🏗️
   - Monitor construction contracts
   - Track project expenditures
   - Audit contractor payments

3. **Social Programs** 🤝
   - Track welfare fund distribution
   - Monitor program effectiveness
   - Ensure proper fund allocation

## 🔮 Future Enhancements

- 📱 Web interface for easier interaction
- 📧 Notification system for audit alerts
- 📊 Advanced analytics dashboard
- 🔗 Integration with existing government systems
- 🏆 Reputation system for auditors

## 🤝 Contributing

We welcome contributions! Please feel free to submit issues and pull requests to help improve government transparency.

## 📄 License

This project is open source and available under the MIT License.

---

*Built with ❤️ for government transparency and citizen empowerment*


