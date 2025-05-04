📖 Centuari Protocol
Welcome to Centuari, an innovative decentralized lending protocol powered by a Central Limit Order Book (CLOB) system. Centuari enables both retail and institutional users to access fixed-rate loans, either with or without collateral, secured by a restaking-based underwriting system.
📌 Overview
Centuari offers a flexible and modular lending infrastructure where users can interact via:

📝 CLOB-based lending market
💸 Tokenized bond system
🛡️ Restaking underwriting for institutions
📊 Yield-optimizing vaults managed by curators

📂 Project Structure
This repository contains three main modules:
1️⃣ Centuari CLOB
A decentralized lending marketplace using a Central Limit Order Book model where borrowers post loan requests, and lenders match offers through limit orders.
✨ Key Features:

Fully on-chain order book system
Flat interest rate model
Tokenized bond system for lenders (ERC20)

📌 Example: Matching Orders
function matchOrders(Id marketId, uint256 maxMatchCount) external onlyOwner {
    MarketConfig storage market = CentuariCLOBDSLib.getMarket(marketId);
    OrderQueueLib.matchOrders(
        market.orderQueue,
        market.priceTickSize,
        maxMatchCount
    );
}

2️⃣ Centuari Vault
A permissionless lending pool where anyone can deposit assets. The funds will automatically fulfill lending orders in the CLOB market.
🚀 Highlights:

Vault Token (VT) minted for each depositor
Interest accrual from lending activities
Custom supply and withdrawal queues per vault

📌 Example: Deposit to Vault
function deposit() external payable {
    require(msg.value > 0, "Zero deposit");
    uint256 shares = calculateShares(msg.value);
    _mint(msg.sender, shares);
}

3️⃣ Centuari Prime (Curator System)
A system for experienced users (curators) to build and manage custom vaults containing curated lending strategies.
💎 Features:

Create personal vaults
Automated fund allocation to CLOB markets
Earn curator performance fees
Flexible withdrawal and deposit mechanisms

📌 Example: Creating a Curated Vault
function createVault(string memory name) external {
    Vault newVault = new Vault(name, msg.sender);
    curatorVaults[msg.sender].push(address(newVault));
}

⚙️ Key Components



📦 Module
📖 Description



CLOB Engine
On-chain decentralized matching engine for loan offers and bids


Centuari Vault
Permissionless lending vaults auto-matching orders


Bond Tokens
ERC20 tokens representing a lender’s claim to repayment and interest


Curator System
Decentralized strategy management layer via curated vaults


📈 How It Works
🔹 Retail Borrowers:

Deposit collateral
Request loan at fixed interest rate via CLOB

🔹 Institutional Borrowers:

Underwrite loans using restaking assets as virtual collateral
Borrow fixed-rate loans without locking base assets

🔹 Lenders:

Place lending offers via CLOB or deposit into Vaults
Receive Bond Tokens for each lending position
Earn fixed interest and optional performance fees

📌 Example: Placing Lending Offer
function placeOrder(
    uint256 marketId, 
    uint256 amount, 
    uint256 interestRate, 
    uint256 maturity
) external {
    require(amount > 0, "Zero amount");
    orderBook[marketId].push(Order(msg.sender, amount, interestRate, maturity));
}

🛠 Tech Stack

Solidity: Smart Contracts
Foundry: Smart Contract Framework
TypeScript: Off-chain scripts & task schedulers
Chainlink Oracles: Price feeds and off-chain data
ERC20 Standard: Tokens

🌐 Vision
Centuari envisions the next-gen decentralized capital markets, where both retail and institutional players can access transparent, fixed-rate, programmable debt markets powered by on-chain infrastructure and restaking underwriting.
🤝 Contribute & Connect
We’re open for collaborations, feedback, and ideas.

🐦 Twitter: [@centuarilabs](https://x.com/CentuariLabs)
💬 Discord: [@centuari](https://discord.gg/XU2hUG4Uuz)
📜 License: Licensed under the MIT License.
