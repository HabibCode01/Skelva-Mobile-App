# 🌿 Skelva: The Ultimate Student Marketplace & Community App

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-ffca28?style=for-the-badge&logo=firebase&logoColor=black)
![Stripe](https://img.shields.io/badge/Stripe-626CD9?style=for-the-badge&logo=Stripe&logoColor=white)
![ZegoCloud](https://img.shields.io/badge/ZegoCloud-Live_Commerce-red?style=for-the-badge)

[cite_start]Skelva is a specialized mobile application developed to promote digital entrepreneurship among FSKTM UTHM students. [cite_start]By bridging the gap between social media and commercial e-commerce, Skelva provides a secure, verified, and interactive "Campus Super-App Ecosystem" tailored for student needs[cite: 74].

---

## 🚀 The Problem We Solve
[cite_start]Existing platforms like Shopee and Lazada are too commercialized and lack support for service-based listings[cite: 72]. [cite_start]Meanwhile, managing sales through WhatsApp or TikTok DMs is disorganized and lacks a trust verification system for campus logistics[cite: 16, 23]. 

[cite_start]**Skelva** solves this by offering a hybrid marketplace where students can monetize both their physical products (e.g., food, thrifted clothes) and technical skills (e.g., PC formatting, coding, design) in a secure, university-verified environment[cite: 76].

---

## ✨ Key Features

* [cite_start]🛒 **Hybrid Listings:** A unified marketplace supporting both physical goods and technical services[cite: 76].
* [cite_start]🎥 **Live Commerce (1080p):** Integrated with ZegoCloud, allowing sellers to broadcast real-time demonstrations of their services or products to build buyer trust[cite: 33].
* [cite_start]💳 **Secure Cashless Payments:** Fully integrated with Stripe for seamless, secure checkout experiences[cite: 39].
* [cite_start]🎮 **Arcade Center (Gamification):** Built-in game loop featuring "Space Defender" (Meteor Shooter) and "Spin & Win" where users play to earn Skelva Coins, driving daily app retention[cite: 40, 255].
* [cite_start]🔐 **Role-Based Access Control (RBAC):** Strict verification using UTHM matrix numbers separates "Buyers" from "Verified Sellers," ensuring a safe campus ecosystem[cite: 42, 78].
* [cite_start]📦 **Professional Order Management:** Real-time tracking of order lifecycles (To Pay, To Ship, To Receive, Completed) mimicking industry standards[cite: 241].
* [cite_start]🤖 **AI Assistant:** "SkelvaBot" provides automated customer support and product recommendations[cite: 247, 248].

---

## 🛠️ Tech Stack

### Frontend
* [cite_start]**Framework:** Flutter (Dart) [cite: 31]
* [cite_start]**State Management:** Provider / setState [cite: 334]
* [cite_start]**UI/UX:** Figma (Prototyping & Wireframing) [cite: 89]

### Backend
* [cite_start]**Database:** Google Cloud Firestore (NoSQL) for real-time data sync[cite: 99].
* [cite_start]**Authentication:** Firebase Auth (Email/Password & Google Sign-In)[cite: 98, 185].
* [cite_start]**Storage:** Firebase Cloud Storage for product and profile images[cite: 58].

### Third-Party APIs
* [cite_start]**ZegoCloud:** Live Streaming SDK for Host/Audience synchronization[cite: 33].
* [cite_start]**Stripe:** Payment Gateway API[cite: 100].

---

## 🏗️ Architecture & Methodology
[cite_start]Skelva was developed using an **Agile Methodology**, utilizing iterative prototype development and User Acceptance Testing (UAT)[cite: 34, 104]. 

The system utilizes a client-server architecture where the Flutter frontend communicates asynchronously with Firebase. [cite_start]Complex operations, such as dynamic Room ID synchronization for live streams and collision detection in the game loop, are handled efficiently to maintain a 60 FPS experience[cite: 168, 343].

---

## 📸 Screenshots
*(Note: Upload your UI screenshots to an `assets` folder in your GitHub repo and link them here)*

| Home Dashboard | Live Commerce | Arcade Center | Checkout & Payment |
| :---: | :---: | :---: | :---: |
| `<img src="assets/home.png" width="200"/>` | `<img src="assets/live.png" width="200"/>` | `<img src="assets/arcade.png" width="200"/>` | `<img src="assets/payment.png" width="200"/>` |

---

## 💻 Getting Started

To run this project locally on your machine:

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/yourusername/skelva.git](https://github.com/yourusername/skelva.git)
