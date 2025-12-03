📊 FinanceTracker

A personal finance management app built with Flutter (BLoC) and a FastAPI + SQLModel backend. FinanceTracker helps users track accounts, categories, and transactions with clean UI, charts, filters, and secure authentication.

📸 Preview

(<video controls src="animation.gif.mp4" title="Title"></video>)


🚀 Overview

FinanceTracker is designed as a practical, real-world application showcasing:

Backend Skills

JWT Authentication (access + refresh tokens)

SQL relations (1-to-N)

Pagination & search

CSV import for transactions

Scheduled jobs (e.g., monthly summaries)

Caching for frequently accessed data

Aggregation queries for charts & analytics

Frontend (Flutter) Skills

Modular feature-based architecture

BLoC state management

Repository + service layer

Complex forms, filtering, and chart UI

Responsive layouts

Clean UI with financial dashboards

BLoC Layers Used

AuthBloc

AccountsBloc

TransactionsBloc

CategoriesBloc 

✨ Core Features
👤 User Accounts

Individual user data

Secure login/register

Password hashing

JWT authentication with refresh flow

💼 Accounts

Represents where the user's money is stored.
Examples: Cash, Bank Account, Savings, Credit Card

Fields:

name

type (cash, bank, wallet, credit, etc.)

balance

currency

💸 Transactions

Records movement of money.

Types:

Income (+)

Expense (–)

Linked to an account and a category.

Fields:

amount

date

description

category

account

Example:

Expense: 50 USD — Category: Food — Account: Cash — Date: 2025-08-22

🏷 Categories

Groups transactions for better organization.

Examples:

Food

Transport

Entertainment

Rent

Salary

Freelance

📱 App Icon Attribution

Icon by Flaticon
Source: https://www.flaticon.com/free-icon/financial-analysis_11568968?term=financial+app&page=1&position=3&origin=tag&related_id=11568968

🛠 Tech Stack
Frontend

Dart & Flutter

BLoC

Dio

Flutter charts library

SharedPreferences / Local caching

Backend

FastAPI

SQLModel

PostgreSQL

APScheduler for scheduled tasks

📦 Folder Structure (High-Level)
backend/
  app/
    accounts/
    auth/
    categories/
    transactions/
    utils/
    tests/

frontend/
  lib/
    features/
      auth/
      accounts/
      categories/
      transactions/
    core/
    data/
    widgets/