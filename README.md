# 📖 Centuari Protocol

Welcome to **Centuari**, an innovative decentralized lending protocol built on top of a Central Limit Order Book (CLOB) system. Centuari enables both retail and institutional users to access fixed-rate loans, either with or without collateral, secured by a unique restaking-based underwriting system.

---

## 📌 Overview

Centuari offers a **flexible lending infrastructure** where users can interact via:

- **CLOB-based lending market**
- **Tokenized bond system**
- **Restaking underwriting for institutions**
- **Yield-optimizing vaults managed by curators**

---

## 📂 Project Structure

This repository contains three core modules:

### 1️⃣ Centuari CLOB
A decentralized lending marketplace based on the Central Limit Order Book (CLOB) model. Borrowers can post loan requests, and lenders can match those offers directly via limit orders.

**Key features:**
- Fully on-chain order book
- Flat interest rate model
- Tokenized bond system for lenders

---

### 2️⃣ Centuari Vault
A permissionless lending pool where anyone can deposit assets. Funds in the vault are used to automatically fulfill lending orders in the CLOB market.

**Highlights:**
- Vault token (VT) minted to represent depositors’ share
- Accrues interest from lending activities
- Custom supply and withdrawal queues per vault

---

### 3️⃣ Centuari Prime (Curator System)
A system that allows experienced users (curators) to create and manage investment vaults containing curated lending strategies.

**Features:**
- Create personal vaults
- Allocate funds automatically to lending markets
- Earn fees based on vault performance
- Customizable withdrawal and deposit mechanisms

---

## ⚙️ Key Components

| Module                         | Description                                                            |
|:-------------------------------|:-----------------------------------------------------------------------|
| **CLOB Engine**                | Decentralized matching of loan offers and bids                         |
| **LendingVault.sol**           | Manages vault deposits, withdrawals, and yield distribution            |
| **CentuariServiceManager.sol** | Task manager for operator actions and lending task validations         |
| **Bond Tokens**                | ERC20 tokens representing a lender’s claim to repayment and interest   |
| **Curator System**             | Vault creation, management, and performance fee handling               |

---

## 📈 How It Works

### 📌 For Retail Borrowers:
- Deposit collateral
- Request loan at a flat interest rate via CLOB

### 📌 For Institutional Borrowers:
- Underwrite loans using restaking assets as virtual collateral
- Access fixed-rate loans without locking base assets

### 📌 For Lenders:
- Place lending offers in CLOB or deposit into vaults
- Receive bond tokens representing the loan position
- Earn fixed interest and optional performance fees from curators

---

## 🛠 Tech Stack

- **Solidity** (Smart Contracts)
- **Foundry** (Smart contract development framework)
- **TypeScript** (Operator and off-chain task management scripts)
- **Chainlink oracles** (Price feeds and off-chain data)
- **ERC20 standard tokens**

---

## 🌐 Vision

Centuari is built for the future of decentralized lending — where both **retail and institutional players** can engage in capital markets with fixed-rate confidence, transparent underwriting, and programmable debt markets.

---

## 📞 Contact & Contribution

We welcome contributions and collaboration!  
For partnerships, questions, or to get involved:

- **Twitter:** [[@centuarilabs]](https://x.com/CentuariLabs)
- **Discord:** [[@centuari]](https://discord.gg/XU2hUG4Uuz)

---

## 📜 License

This project is licensed under the **MIT License**.
