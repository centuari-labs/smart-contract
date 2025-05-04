# 📖 Centuari Protocol

Centuari is an innovative decentralized lending protocol powered by a **deCentralized Lending Order Book (CLOB)** system. It enables both retail and institutional users to access fixed-rate loans.

---

## 📌 Overview

Centuari introduces a robust decentralized lending marketplace with the following key features:

- 📝 **CLOB-based lending market**: A Central Limit Order Book model for efficient loan matching.
- 💸 **Tokenized bond system**: Tokenized representations of fixed-rate loans.
- 📊 **Yield-optimizing vaults**: Maximizing returns for liquidity providers.

---

## 📂 Project Structure

The repository is organized as follows:

- **`src/`**: Core smart contracts, interfaces, libraries, and types.
  - `core/`: Implements the main protocol logic, including [`Centuari.sol`](src/core/Centuari.sol).
  - `interfaces/`: Defines interfaces for modularity and extensibility.
  - `libraries/`: Shared utility libraries.
  - `mocks/`: Mock contracts for testing.
  - `types/`: Custom data types used across the protocol.

- **`script/`**: Deployment scripts for the protocol.
  - Includes scripts like `DeployCentuariCore.s.sol` and deployment data files.

- **`test/`**: Unit and integration tests.
  - `BaseTest.sol`: Base test setup.
  - `integration/`: Integration tests for end-to-end scenarios.
  - `mocks/`: Mock-based testing utilities.

- **`lib/`**: External dependencies.
  - Includes `forge-std` and `openzeppelin-contracts`.

---

## ⚙️ Key Components

| 📦 Module         | 📖 Description                             |
|--------------------|--------------------------------------------|
| **CLOB Engine**    | On-chain decentralized matching engine.    |
| **Tokenized Bonds**| Tokenized fixed-rate loan representations. |

---

## 🛠 Tech Stack

- **Solidity**: Smart contract development.
- **Foundry**: Testing, deployment, and debugging framework.

---

## 🚀 Development Workflow

### 1. Clone the Repository

```sh
git clone https://github.com/CentuariLabs/smart-contract.git
cd smart-contract
```

### 2. Install Dependencies

```sh
forge install
```

### 3. Build Contracts

```sh
forge build
```

### 4. Run Tests

```sh
forge test
```

### 5. Deploy Contracts

Deployment scripts are located in the `script/` directory. Example:

```sh
forge script script/DeployCentuariCore.s.sol --rpc-url <YOUR_RPC_URL> --private-key <YOUR_PRIVATE_KEY> --broadcast
```

### 6. Linting

Ensure code quality with:

```sh
forge fmt
```

---

## 🧪 Testing

- All tests are located in the `test/` directory.
- Use `forge test` for running the full test suite.
- Integration tests are under `test/integration/`.

---

## 📈 Continuous Integration

This repository uses GitHub Actions for CI:

- **Build & Test**: On every push and pull request, contracts are built and tested automatically.
- **Linting**: Code formatting is checked.

You can find workflow files in `.github/workflows/`.

---

## 🤝 Contribute & Connect

We welcome contributions! Feel free to open issues or submit pull requests.

- 🐦 [Twitter](https://x.com/CentuariLabs)
- 💬 [Discord](https://discord.gg/XU2hUG4Uuz)

---

## 📜 License

This project is licensed under the MIT License.
