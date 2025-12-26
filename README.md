# 📊 FinanceTracker

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi)
![Postgres](https://img.shields.io/badge/postgres-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white)

**FinanceTracker** is a comprehensive personal finance management application featuring a **Flutter** frontend and a **FastAPI** backend. It allows users to track accounts, automate transaction recording via SMS, categorize spending, and visualize financial health with detailed analytics.

This project was built to demonstrate full-stack capabilities, focusing on **Clean Architecture**, **State Management (BLoC)**, Automated Parsing Services and secure **Authentication flows**.

---

## 📸 App Preview

### Live Demo
![Screen_Recording_20251203_080959(1)](https://github.com/user-attachments/assets/a47e6245-bbce-4375-8937-38840f3d6b8e)

### UI Screenshots
| Authentication/Login | Authentication/Register | Accounts Overview |
|:---:|:---:|:---:|
| <img src="https://github.com/user-attachments/assets/1c78a5f9-f563-4d00-b186-3aa5aacbe865" width="200"> | <img src="https://github.com/user-attachments/assets/be9f84ae-c1aa-493b-9636-217671635693" width="200"> | <img src="https://github.com/user-attachments/assets/00b007f2-7bc7-4d67-ae56-9812a9144cc8" width="200"> |

| Transactions | Categories |
|:---:|:---:|
| <img src="https://github.com/user-attachments/assets/8d23ed92-b012-43db-a18f-a8e5c22ea378" width="200"> | <img src="https://github.com/user-attachments/assets/1ad24213-9112-4338-bf84-1f534ba16a5c" width="200"> |

---

## 🚀 Architecture & Technical Highlights

This project follows a **Feature-First** architecture with a separation of concerns between Data, Domain, and Presentation layers.

### 📱 Frontend (Flutter)
* **State Management:** BLoC (Business Logic Component) & Cubit.
    * *AuthCubit, AccountsBloc, TransactionsBloc, CategoriesBloc, ReportAnalyticsCubit.*
* **Architecture:** Clean Architecture (Repository Pattern + Service Layer).
* **Automation:** Foreground and Background services to listen for and parse incoming SMS messages.
* **UI/UX:** Custom complex forms, filtering logic, and financial charting.
* **Data Visualization:** Interactive charting and statistical aggregation.
* **Local Storage:** Secure storage for JWTs and Shared Preferences for caching.

### ⚙️ Backend (FastAPI)
* **Authentication:** Full JWT implementation (Access + Refresh token rotation).
* **Database:** PostgreSQL with SQLModel (ORM).
* **Performance:** Pagination, Search implementation, and data caching.
* **Migrations:** Database version control using Alembic.

---

## ✨ Key Features

### 🤖 Smart SMS Parsing
* Auto-Detection: Automatically listens for incoming transaction SMS messages.

* Sync on Open: Scans inbox upon app launch to catch up on missed transactions.

* Parser Engine: Intelligent regex parsing specifically tuned for Telebirr and CBE (Commercial Bank of Ethiopia).

* Seamless Persistence: Converts raw SMS text into structured Transaction entities automatically.

### 📈 Reports & Analytics
* Cash Flow Analysis: Interactive bar charts comparing daily/weekly Income vs Expenses.

* Net Worth Overview: Real-time calculation of total assets across all accounts.

* Category Breakdown: Visual progress bars showing spending distribution by category.

* Monthly Filtering: Drill down into specific months to see historical financial performance.

### 👤 Secure Authentication
* User registration and secure login.
* Password hashing.
* Auto-refreshing JWT tokens for seamless user experience.

### 💼 Account Management
* Track multiple asset types: *Cash, Bank Account, Savings, Credit Cards*.
* Support for multiple currencies (USD, ETB, EUR).
* Real-time balance updates.

### 💸 Transaction Tracking
* Record **Income** and **Expenses**.
* Link transactions to specific accounts and categories.
* Rich data: Amount, Date, Description, Category, Account.

### 🏷 Categorization
* Organize spending with custom categories (e.g., *Food, Transport, Rent, Salary*).
* Visual icons for quick identification.

---

## 🛠 Tech Stack

### Frontend
| Category | Technology | Usage |
| :--- | :--- | :--- |
| **Framework** | Flutter / Dart | UI & Logic |
| **State Mgmt** | flutter_bloc | BLoC pattern implementation |
| **SMS** | telephony_fix | Reading & Listening to SMS |
| **Charts** | syncfusion_flutter_charts | Analytics visualization |
| **Networking** | http | API communication |
| **Storage** | flutter_secure_storage | Storing Access/Refresh Tokens |
| **Caching** | shared_preferences | Local settings caching |
| **Auth** | google_sign_in | Google OAuth integration |

### Backend
| Category | Technology | Usage |
| :--- | :--- | :--- |
| **Framework** | FastAPI | REST API |
| **Language** | Python | Server logic |
| **ORM** | SQLModel | Database interaction |
| **Validation** | Pydantic | Data validation |
| **Database** | PostgreSQL | Relational Data Store |
| **Migrations** | Alembic | Schema management |

---

## 📦 Folder Structure

The project is divided into a dedicated backend and frontend directory.

```bash
├── backend/
│   ├── alembic/              # DB Migrations
│   ├── app/
│   │   ├── api/              # API Routes
│   │   ├── core/             # Config & Security
│   │   ├── db/               # Database connection
│   │   ├── models/           # SQLModel classes
│   │   ├── accounts/         # Account logic & tests
│   │   ├── auth/             # Auth logic & tests
│   │   ├── categories/       # Category logic & tests
│   │   └── transactions/     # Transaction logic & tests
│
├── frontend/
│   ├── lib/
│   │   ├── core/             # Shared utils, themes, widgets
│   │   ├── features/
│   │   │   ├── auth/         # Login/Register (Data, Domain, Presentation)
│   │   │   ├── accounts/     # Account mgmt (Data, Domain, Presentation)
│   │   │   ├── categories/   # Category mgmt (Data, Domain, Presentation)
│   │   │   └── transactions/ # Transaction mgmt (Data, Domain, Presentation)
│   │   └── main.dart
│   └── tests/                # Widget & Unit tests