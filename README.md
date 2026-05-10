<div align="center">
  
  <h1>NuRWA: Nusantara Real World Assets</h1>
  <p><b>Tokenizing the Heartbeat of Indonesia's Economy on Solana</b></p>
  <p>Bridging the $150 Billion credit gap for Indonesian MSMEs through Web3 Revenue-Sharing Tokens (RST).</p>

  [![Solana](https://img.shields.io/badge/Solana-14F195?style=for-the-badge&logo=solana&logoColor=black)](#)
  [![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](#)
  [![Rust](https://img.shields.io/badge/Rust-000000?style=for-the-badge&logo=rust&logoColor=white)](#)
  [![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)](#)
</div>

<hr>

## 🚀 Live Demos & Important Links
* 🌐 **Live Web Application (Vercel):** [https://nurwa-app.vercel.app](https://nurwa-app.vercel.app)
* 📱 **Android APK:** [https://github.com/satnodeus77/Nusantara-Real-World-Assets-NuRWA/tree/main/APK]
* ⚙️ **Backend API (Swagger UI):** [https://nurwa-api.vercel.app/docs]
* 📜 **Devnet Program ID:**[`QcoV1YM24NYoWvBeqDgh1AKq3oQXM3ncAnvcVFdW96E`](https://explorer.solana.com/address/QcoV1YM24NYoWvBeqDgh1AKq3oQXM3ncAnvcVFdW96E?cluster=devnet)
* 🎥 **Pitch Video & Demo: [https://drive.google.com/drive/folders/1MW92D-ElK6-O14zahVwUw_wJhxiDzCOz?usp=sharing]
* 📊 **Pitch Deck: [https://drive.google.com/drive/folders/1MW92D-ElK6-O14zahVwUw_wJhxiDzCOz?usp=sharing]

---

## 📖 What is NuRWA?
**NuRWA** is a mobile-first Web3 crowdfunding platform built for the **Frontier Colosseum Hackathon (Superteam Indonesia Track)**. 

Traditional banks reject Indonesian MSMEs (Micro, Small, and Medium Enterprises) due to strict collateral rules, resulting in a massive **$150B credit gap**. NuRWA solves this by tokenizing the future cash flows of these real-world businesses. Investors fund the businesses via trustless Solana smart contracts and, in return, earn real USDC yields generated from actual business revenue—insulated from crypto market volatility.

---

## 🏗️ System Architecture (The 3 Pillars)

This repository is a monorepo containing three interconnected projects:

### 1. The Client Layer (Flutter Mobile & Web) `[/app]`
* **Cross-Platform:** A unified codebase delivering a seamless UI/UX on desktop web (via Phantom Extension) and Android (via Phantom Mobile App).
* **Engineering Highlight (Custom MWA DNS Fallback):** Android OS frequently puts background apps to "network sleep" during Mobile Wallet Adapter (MWA) deep-linking, causing transaction broadcasts to fail with `ECONNREFUSED` or DNS errors. We engineered a custom **DNS Retry Fallback & Socket Warm-up Mechanism** in Dart, guaranteeing a 100% transaction success rate on real Android devices.

### 2. The Oracle & Metadata Layer (FastAPI) `[/backend]`
* **KYB (Know Your Business):** Securely stores off-chain metadata (high-res images, descriptions, and legal documents like Indonesia's NIB) and maps them to on-chain tokens.
* **The Off-Chain Revenue Oracle:** Solves the classic "Oracle Problem." In production, this layer integrates with local Point-of-Sale (POS) systems and the QRIS payment network to verify real-world fiat revenue. It automatically triggers the smart contract to distribute proportional USDC yields.

### 3. The Trust Layer (Rust & Anchor) `[/anchor-program]`
* **Dynamic SPL Token Factory:** Automatically mints isolated, business-specific Revenue-Sharing Tokens (RST).
* **Trustless Escrow Vaults (PDAs):** Replaces centralized treasuries. Investor USDC is securely locked in Program-Derived Addresses.
* **Proportional Yield Distributor:** The core algorithm that mathematically distributes incoming USDC revenue proportionally to all token holders without human intervention.

---

## ⚠️ Technical Transparency Note for Judges

To ensure a flawless evaluation experience, we want to be fully transparent about our engineering decisions for this MVP:

**1. Is the Smart Contract completed?**
**Yes.** Our custom Rust/Anchor Smart Contract is fully written, tested, and deployed on the Solana Devnet. You can review the full source code and logic in the `/anchor-program` directory.

**2. Is the Flutter App fully integrated with the Anchor Program?**
**Hybrid MVP Approach:** Integrating complex custom Anchor instructions (requiring 7+ specific accounts including SPL Mint and ATAs) directly into the Flutter Mobile Wallet Adapter (MWA) within a short hackathon timeframe introduced severe stability risks on Android devices.

To guarantee a crash-free mobile demo, we made a strategic trade-off: 
* The mobile frontend dynamically calculates the unique cryptographic **PDA Vault Address** using our Program ID.
* It executes a **100% real on-chain native Solana transfer** locking the USDC directly into that PDA Vault.
* Our FastAPI backend currently handles the escrow and token accounting logic off-chain to simulate the user flow.

Bridging the robust Flutter UI directly to our deployed Anchor CPI instructions is the immediate next step in our V2 technical sprint.

---

## 🧪 Judge's Testing Guide

Please follow these steps to test the full lifecycle of the NuRWA platform:

### Step 1: Wallet Preparation
1. Install the **Phantom Wallet** (Chrome Extension for Web, or Mobile App for Android).
2. Go to Phantom **Settings** -> **Developer Settings** -> Turn **Testnet Mode ON**.
3. Switch your network to **Solana Devnet**.
4. Obtain Devnet SOL from [faucet.solana.com](https://faucet.solana.com/). *(Note: Our app uses a Rent-Exemption safety net, so transactions will only fail if your wallet has exactly 0 SOL).*

### Step 2: Test the Investment Flow (On-Chain)
1. Open the [Live Web App](https://nurwa-app.vercel.app).
2. Click **Connect Phantom Wallet**.
3. Browse the Marketplace, select an MSME, and enter an amount (e.g., `10` USDC).
4. Notice the app dynamically calculates the **Smart Contract Vault (PDA)** address. Click the text to copy it.
5. Approve the transaction in Phantom.
6. **Proof of Work:** Go to [Solscan Devnet](https://solscan.io/?cluster=devnet), paste the transaction hash or the PDA address, and verify the on-chain transfer!

### Step 3: Test the Oracle & Claim Yield (Simulation)
1. Go to the **Portfolio** tab to view your active investments.
2. Scroll to the bottom and click the red **"Simulate UMKM Revenue (Oracle)"** button. Watch the *Unclaimed Yield* balance update dynamically.
3. Click **"Claim Yield"** to trigger the backend payout mechanism, reflecting the seamless Web3 investor experience.

---
