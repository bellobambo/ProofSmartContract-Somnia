# ProofSmartContract 📚

Proof is a comprehensive blockchain-based Learning Management System platform that enables tutors to create courses and assessment while providing students with a secure, transparent evaluation system. Built with Solidity and deployed on the Somnia testnet.

## 🎯 What It Does

This smart contract creates a decentralized learning management system where tutors can register, create courses, and design multiple-choice assessment. Students can enroll in courses, take assessment, and receive verifiable scores stored immutably on the blockchain. The system ensures academic integrity through transparent, tamper-proof record keeping while maintaining proper access controls between tutors and students.

## 🚀 Getting Started

### Installation & Testing

```shell
# Github Repo
git clone https://github.com/bellobambo/ProofSmartContract-Somnia

# Install dependencies
npm install

### Deployment
Deploy to Somnia testnet:

# Set environment variable
export SOMNIA_PRIVATE_KEY=your_private_key

# Deploy to Somnia
npx hardhat ignition deploy --network somniaTestnet ignition/modules/ProofSmartContractV2.ts
```

## 📋 Contract Features

- **User Management**: Register as tutor or student with role-based permissions
- **Course Creation**: Tutors can create and manage educational courses  
- **Student Enrollment**: Students can browse and enroll in available courses
- **Exam System**: Create multiple-choice assessment with 4 options per question
- **Secure Assessment**: Take assessment with automatic scoring and result storage
- **Progress Tracking**: View completion status and scores for all enrolled courses

## 🌐 Deployed Addresses

**Somnia Testnet**: `0x2b7f7552E3B5902c2d1dAE65664ABE93F9d45795`