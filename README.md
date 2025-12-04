📊 FinanceTracker

A personal finance management app built with Flutter (BLoC) and a FastAPI + SQLModel backend. FinanceTracker helps users track accounts, categories, and transactions with clean UI, charts, filters, and secure authentication.

📸 Preview

![Screen_Recording_20251203_080959(1)](https://github.com/user-attachments/assets/a47e6245-bbce-4375-8937-38840f3d6b8e)

🚀 Overview

FinanceTracker is designed as a practical, real-world application showcasing:

Backend Skills

JWT Authentication (access + refresh tokens)

SQL relations (1-to-N)

Pagination & search

Scheduled jobs (e.g., monthly summaries)

Caching for frequently accessed data

Frontend (Flutter) Skills

Modular feature-based architecture

BLoC state management

Repository + service layer

Complex forms and filtering

Responsive layouts

Clean UI with financial dashboards

BLoC & Cubit Layers Used

AuthCubit

AccountsBloc

TransactionsBloc

CategoriesBloc 

✨ Core Features
👤 User Accounts

Individual user data

Secure login/register
<img width="250" height="500" alt="image" src="https://github.com/user-attachments/assets/1c78a5f9-f563-4d00-b186-3aa5aacbe865" />
<img width="250" height="500" alt="image" src="https://github.com/user-attachments/assets/be9f84ae-c1aa-493b-9636-217671635693" />

Password hashing

JWT authentication with refresh flow

💼 Accounts

Represents where the user's money is stored.
Examples: Cash, Bank Account, Savings, Credit Card

Fields:

name

type (cash, bank, wallet, credit, etc.)

balance

currency (USD, ETB, EUR, etc.)

💸 Transactions

Records movement of money.

Types:

Income (+)

Expense (–)

Linked to an account and optionally to a category.

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

http

Flutter charts library

FutterSecureStorage / for storing access and refresh token's

GoogleSignIn / to allow user to sign in with their google account

SharedPreferences / Local caching

Backend

FastAPI

SQLModel

pydantic

Alembic (for data base migrations)

Database

PostgreSQL

📦 Folder Structure (High-Level)
backend/
  alembic/
  app/
    api/
    accounts/
      tests/
    auth/
      tests/
    categories/
      tests/
    core/
    db/
    models/
    transactions/
    tests/

frontend/
  lib/
    features/
      auth/
        data/
        domain/
        presentation/
      accounts/
        data/
        domain/
        presentation/
      categories/
        data/
        domain/
        presentation/
      transactions/
        data/
        domain/
        presentation/
    core/
    themes/
    widgets/
  tests/
    features/
      auth/
      accounts/
      categories/
      transactions/
