## 🌱 Overview

A blockchain-based marketplace for trading environmental credits from urban cooling projects. Fight climate change while earning rewards through rooftop greening, reflective materials, and other heat mitigation initiatives.

## 🚀 Features

- 🏗️ **Project Registration**: Register cooling projects (green roofs, reflective surfaces, etc.)
- 🔍 **Drone Verification**: Third-party verification through drone monitoring and data collection
- 💰 **Credit Tokenization**: Mint UHI credits based on verified temperature reduction
- 🛒 **Marketplace**: Buy and sell credits in a decentralized marketplace
- ♻️ **Credit Retirement**: Permanently retire credits to offset carbon footprint
- 👥 **Verifier Network**: Authorized verifiers ensure project legitimacy
- 🔄 **Project Updates**: Modify project details before verification
- 🔒 **Credit Locking**: Lock credits for bonus rewards and long-term commitment incentives
- � **Allowance Mechanism**: Delegate transfer rights for enhanced flexibility in credit management

## 📋 Contract Functions

### Project Management
```clarity
(register-project project-type location area-sqm expected-credits)
(update-project project-id new-project-type new-location new-area-sqm new-expected-credits)
(verify-project project-id temperature-reduction drone-data-hash)
(mint-credits project-id)
```

### Marketplace
```clarity
(create-sell-offer project-id amount price-per-credit)
(buy-credits project-id seller amount)
(retire-credits amount)
```

### Allowance Mechanism
```clarity
(approve spender amount)
(transfer-from owner recipient amount)
(increase-allowance spender added-amount)
### Credit Locking
```clarity
(lock-credits amount lock-period bonus-rate)
(unlock-credits)
```
(decrease-allowance spender subtracted-amount)
```

### Administration
```clarity
(add-verifier verifier-principal)
(remove-verifier verifier-principal)
(set-verification-fee new-fee)
```

### Read-Only Functions
```clarity
(get-locked-credits account)
(get-project project-id)
(get-verification project-id)
(get-credit-offer project-id seller)
(get-balance account)
(is-verifier verifier)
(get-allowance owner spender)
```

## 🎯 Usage Example

### 1. Register a Project
```clarity
(contract-call? .urban-heat-island-mitigation-credits register-project
  "green-roof"
  "Downtown Building A, Block 5"
  u500
  u1000)
```

### 1.5 Update Project (Optional)
```clarity
(contract-call? .urban-heat-island-mitigation-credits update-project
  u1
  "reflective"
  "Updated Location"
  u600
  u1200)
```

### 2. Verify Project (Verifiers Only)
```clarity
(contract-call? .urban-heat-island-mitigation-credits verify-project
  u1
  u25
  0x1234567890abcdef...)
```

### 3. Mint Credits
```clarity
(contract-call? .urban-heat-island-mitigation-credits mint-credits u1)
```

### 4. Create Sell Offer
```clarity
(contract-call? .urban-heat-island-mitigation-credits create-sell-offer
  u1
  u500
  u1000000)
```

### 5. Buy Credits
```clarity
(contract-call? .urban-heat-island-mitigation-credits buy-credits 
  u1 
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 
  u100)
```

## 🛠️ Development

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet)
- [Node.js](https://nodejs.org/)

### Setup
```bash
npm install
clarinet check
```

### Testing
```bash
clarinet test
```

### Deployment
```bash
clarinet deploy --network testnet
```

## 📊 Token Details

- **Name**: Urban Heat Island Mitigation Credits
- **Symbol**: UHI
- **Decimals**: 6
- **Type**: SIP-010 Fungible Token

## 🌍 Project Types

- **green-roof**: Living rooftops with vegetation
- Credit locking mechanism for long-term commitment incentives
- **reflective**: High-albedo reflective surfaces
- **shade**: Tree planting and shade structures  
- **permeable**: Permeable pavement solutions
- **water**: Cooling water features and systems

## 🔐 Security Features

- Multi-signature verification system
- Drone data hash validation
- Credit retirement prevents double-spending
- Bonus rewards for locked credits to encourage long-term environmental commitment
- Owner-only administrative functions
- Verifier authorization system

## 📈 Impact Measurement

Credits are awarded based on:
- Measured temperature reduction (°C)
- Project area coverage (m²)
- Verification through drone monitoring
- Long-term sustainability metrics

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Add tests for new functionality
4. Submit a pull request

## 📄 License

MIT License - Building a cooler future together! 🌱

## 🆕 Recent Enhancements

### Project Ownership Transfer
- 🔄 **Ownership Transfer**: Enables project owners to transfer project ownership to another principal before verification, facilitating project delegation, sales, or inheritance.
- **Function**: `(transfer-project-ownership project-id new-owner)`
- **Usage Example**:
  ```clarity
  (contract-call? .urban-heat-island-mitigation-credits transfer-project-ownership
    u1
    'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
  ```
- **Benefits**: Enhances project management flexibility and supports secondary project markets.
