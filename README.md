# 🐄 BIOHERD (बायोहर्ड / पशुसेवा)

> **Livestock Disease Early Detection & Epidemiological Surveillance System**  
> **Smart India Hackathon 2026 — Problem Statement SIH26128**  
> *Sponsored by the Department of Animal Husbandry, Government of Maharashtra*

[![Flutter](https://img.shields.io/badge/Flutter-3.41+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.12+-3776AB?logo=python&logoColor=white)](https://python.org)
[![Backend Tests](https://img.shields.io/badge/Backend%20Tests-39%20Passed-success)](backend/tests)
[![Flutter Tests](https://img.shields.io/badge/Flutter%20Tests-95%20Passed-success)](test)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Project Architecture](#-project-architecture)
- [Prerequisites](#-prerequisites)
- [Setup & Installation](#-setup--installation)
  - [1. Clone Repository](#1-clone-repository)
  - [2. Backend Setup](#2-backend-setup)
  - [3. Frontend Setup (Flutter)](#3-frontend-setup-flutter)
- [Running the Application](#-running-the-application)
  - [Start the Backend Server](#1-start-the-backend-server)
  - [Seed Initial Maharashtra Data](#2-seed-initial-maharashtra-data)
  - [Run the Flutter Frontend](#3-run-the-flutter-frontend)
- [Pre-Seeded Demo Accounts](#-pre-seeded-demo-accounts)
- [Testing & Quality Assurance](#-testing--quality-assurance)
  - [Run Backend Tests](#run-backend-tests)
  - [Run Flutter Tests](#run-flutter-tests)
  - [Run Static Analysis & Linting](#run-static-analysis--linting)
- [Environment Configuration](#-environment-configuration)
- [Production Builds](#-production-builds)

---

## 🌟 Overview

**BIOHERD** is a production-grade, cross-platform livestock bio-surveillance and herd health management platform built specifically for Indian dairy and livestock farmers, field veterinarians, and state animal husbandry authorities.

Designed with an **offline-first** architecture and full multilingual accessibility (**Marathi `मराठी`**, **Hindi `हिंदी`**, and **English**), BIOHERD empowers rural farmers with instant AI symptom analysis while giving government epidemiologists real-time outbreak surveillance heatmaps across all 36 districts of Maharashtra.

---

## ✨ Key Features

- 🏷️ **Digital Livestock Registry & QR/RFID Passports**: Register indigenous cattle, buffalo, goats, and sheep with geo-tagged locations and instant health timeline history.
- 🔬 **Multi-Modal AI Symptom Screening**: Image and symptom analysis for high-threat diseases (Lumpy Skin Disease, Foot & Mouth Disease, Anthrax, Brucellosis, Mastitis, Black Quarter).
- 🗺️ **Statewide Epidemiological Surveillance**: Real-time interactive outbreak heatmaps and alert fan-outs across all 36 Maharashtra districts.
- 🩺 **Veterinary Telemedicine & Workspace**: Triage queue, digital prescriptions, drug inventory tracking, and consultation notes.
- 📴 **Zero-Connectivity Offline First**: Offline SQLite cache with automatic background synchronization when internet connectivity resumes.
- 🌐 **True Cross-Platform**: Runs natively on Android, iOS, Web browsers (Chrome / Edge), and Windows Desktop from a single Flutter codebase.

---

## 🏗️ Project Architecture

```
BIOV1/
├── backend/                      # FastAPI Python 3.12+ backend
│   ├── app/
│   │   ├── api/v1/               # REST API endpoints (auth, animals, cases, symptoms, etc.)
│   │   ├── core/                 # App configurations, logging, security & JWT
│   │   ├── db/                   # SQLAlchemy async engine, models, and district seeders
│   │   ├── schemas/              # Pydantic v2 validation models
│   │   ├── services/             # Business logic (Redis, MinIO, AI diagnostics)
│   │   └── main.py               # FastAPI entry point & lifespan manager
│   ├── tests/                    # Pytest test suites (39 unit & integration tests)
│   └── requirements.txt          # Python dependencies
├── lib/                          # Flutter 3.x cross-platform client
│   ├── core/                     # Layout shells, theme, design tokens, storage
│   ├── features/
│   │   ├── animals/              # Animal registry, profiles & timeline
│   │   ├── auth/                 # Multi-role authentication & language selector
│   │   ├── showcase/             # Interactive design system & feature showcase
│   │   ├── surveillance/         # 36-district GIS outbreak maps & risk charts
│   │   ├── symptoms/             # Multi-modal symptom reporting & AI triage
│   │   └── veterinary/           # Telemedicine workspace & prescriptions
│   └── main.dart                 # Flutter application entry point
├── test/                         # Flutter widget & unit tests (95 tests)
├── pubspec.yaml                  # Flutter package dependencies
├── DESIGN.md                     # Design system & WCAG token guidelines
└── README.md                     # Documentation & setup guide
```

---

## ⚙️ Prerequisites

Before you start, ensure you have the following installed on your system:

| Tool | Recommended Version | Verification Command |
|---|---|---|
| **Flutter SDK** | `3.24.0` or higher (channel stable) | `flutter --version` |
| **Dart SDK** | `3.5.0` or higher | `dart --version` |
| **Python** | `3.11` to `3.14` | `python --version` |
| **Git** | `2.x` | `git --version` |
| **Target Platforms** | Chrome / Edge (Web), Android Studio / Physical Device, or Visual Studio (Windows Desktop) | `flutter doctor` |

---

## 🚀 Setup & Installation

### 1. Clone Repository

```bash
git clone https://github.com/Nithinhelloweb/BIOHERD.git
cd BIOHERD/BIOV1
```

---

### 2. Backend Setup

The backend is built with FastAPI. It comes pre-configured with **zero-configuration SQLite and in-memory fallbacks**, meaning you do **not** need Docker or external PostgreSQL/Redis services running to develop locally!

#### Step 2.1: Navigate to backend directory
```bash
cd backend
```

#### Step 2.2: Create and activate a Python virtual environment

**Windows (PowerShell):**
```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
```

**Windows (Command Prompt):**
```cmd
python -m venv .venv
.venv\Scripts\activate.bat
```

**macOS / Linux:**
```bash
python3 -m venv .venv
source .venv/bin/activate
```

#### Step 2.3: Install backend dependencies
```bash
pip install -r requirements.txt
```

---

### 3. Frontend Setup (Flutter)

Return to the project root directory (`BIOV1`):

```bash
cd ..
```

#### Step 3.1: Verify Flutter health
```bash
flutter doctor
```

#### Step 3.2: Fetch Flutter dependencies
```bash
flutter pub get
```

---

## 💻 Running the Application

### 1. Start the Backend Server

Inside the `backend/` directory (with your virtual environment activated):

```bash
# Windows / macOS / Linux
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Once running:
- **Root Health Check**: [http://localhost:8000/](http://localhost:8000/)
- **Interactive Swagger Docs**: [http://localhost:8000/docs](http://localhost:8000/docs)
- **Alternative ReDoc UI**: [http://localhost:8000/redoc](http://localhost:8000/redoc)
- **Detailed System Health**: [http://localhost:8000/api/v1/health](http://localhost:8000/api/v1/health)

---

### 2. Seed Initial Maharashtra Data

On initial backend startup, the 36 official Maharashtra districts are automatically synchronized. To load the complete demo dataset (authentic indigenous cattle, demo farms, sample cases, and outbreak events):

**Using cURL:**
```bash
curl -X POST http://localhost:8000/api/v1/seeder/run
```

**Using PowerShell:**
```powershell
Invoke-RestMethod -Method Post -Uri "http://localhost:8000/api/v1/seeder/run"
```

Or execute it directly in the interactive Swagger UI at [http://localhost:8000/docs#/System%20Seeder/trigger_seeder_api_v1_seeder_run_post](http://localhost:8000/docs#/System%20Seeder/trigger_seeder_api_v1_seeder_run_post).

---

### 3. Run the Flutter Frontend

From the root `BIOV1/` directory:

#### Check available target devices:
```bash
flutter devices
```

#### Run on Google Chrome (Recommended for fast testing):
```bash
flutter run -d chrome
```

#### Run on Microsoft Edge:
```bash
flutter run -d edge
```

#### Run on Windows Desktop:
```bash
flutter run -d windows
```

#### Run on Android Device / Emulator:
```bash
# To run on any connected Android phone or emulator
flutter run -d android

# Or specify a target device ID from "flutter devices"
flutter run -d <DEVICE_ID>
```

> 💡 **Tip for Android Emulators**: The Flutter app automatically routes API traffic to `http://10.0.2.2:8000/api/v1` when running on Android emulators, and `http://127.0.0.1:8000/api/v1` on Web and Desktop.

---

## 👥 Pre-Seeded Demo Accounts

All pre-seeded demo accounts share the standard password:  
🔑 **Password:** `Bioherd@2026`

| Persona | Name | Phone Number | Email | Role | District |
|---|---|---|---|---|---|
| **Farmer** | Ramesh Patil | `+919876543210` | `farmer.ramesh@bioherd.in` | `FARMER` | Pune |
| **Veterinarian** | Dr. Anjali Deshmukh | `+919876543211` | `dr.anjali@bioherd.in` | `VETERINARIAN` | Pune |
| **District Official** | Rajesh Shinde | `+919876543212` | `official.ahmednagar@bioherd.in` | `DISTRICT_OFFICIAL` | Ahmednagar |
| **State Admin** | Dr. Suresh Kulkarni | `+919876543213` | `state.admin@bioherd.in` | `STATE_ADMIN` | Pune |

---

## 🧪 Testing & Quality Assurance

### Run Backend Tests

The backend includes 39 unit, integration, and security tests covering JWT authentication, AI symptom diagnostics, veterinary telemedicine cases, district seeders, and epidemiological outbreaks.

From the `backend/` directory:

```bash
# Run all backend tests
python -m pytest

# Run with verbose output
python -m pytest -v

# Run with code coverage report
python -m pytest --cov=app --cov-report=term-missing
```

---

### Run Flutter Tests

The frontend includes 95 widget, unit, and BLoC tests covering all design tokens, responsive layouts, multi-language switching, and offline-first repositories.

From the root `BIOV1/` directory:

```bash
# Run all 95 Flutter tests
flutter test

# Run a specific test suite
flutter test test/widget_test.dart
```

---

### Run Static Analysis & Linting

```bash
# Analyze Flutter code
flutter analyze

# Verify Dart formatting
dart format --output=none --set-exit-if-changed .
```

---

## ⚙️ Environment Configuration

The backend reads settings from environment variables or an optional `backend/.env` file. By default, it falls back to lightweight, zero-dependency development modes:

| Variable | Default Value | Description |
|---|---|---|
| `ENVIRONMENT` | `development` | Deployment environment (`development` / `production`) |
| `DATABASE_URL` | `sqlite+aiosqlite:///./bioherd_dev.db` | Async SQLAlchemy database URL (Use PostgreSQL in prod) |
| `SECRET_KEY` | *(Built-in Dev Key)* | Secret key for signing JWT tokens |
| `REDIS_URL` | `redis://localhost:6379/0` | Redis 7 connection string *(falls back to memory if unreachable)* |
| `MINIO_ENDPOINT` | `localhost:9000` | S3-compatible MinIO endpoint *(falls back to memory if unreachable)* |
| `MINIO_ACCESS_KEY`| `minioadmin` | MinIO access key |
| `MINIO_SECRET_KEY`| `minioadmin` | MinIO secret key |
| `MINIO_BUCKET_NAME`| `bioherd-assets` | MinIO bucket name for photos & documents |
| `CORS_ORIGINS` | `["*"]` | Allowed CORS origins for web clients |

### Example `.env` file for Production (PostgreSQL + Redis + MinIO):
```ini
ENVIRONMENT=production
DEBUG=false
SECRET_KEY=generate-a-strong-random-secret-key-here-32-chars-minimum
DATABASE_URL=postgresql+asyncpg://bioherd_user:bioherd_password@localhost:5432/bioherd_db
REDIS_URL=redis://:your_redis_password@localhost:6379/0
MINIO_ENDPOINT=localhost:9000
MINIO_ACCESS_KEY=your_minio_access_key
MINIO_SECRET_KEY=your_minio_secret_key
MINIO_SECURE=true
MINIO_BUCKET_NAME=bioherd-assets
```

---

## 📦 Production Builds

### Build Flutter for Web
```bash
flutter build web --release
```
Artifacts will be generated in `build/web/`, ready to be served by Nginx, Caddy, or any static host.

### Build Android APK
```bash
flutter build apk --release
```
The compiled APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.

### Build Android App Bundle (AAB for Google Play Store)
```bash
flutter build appbundle --release
```

---

## 🤝 Contributing & License

This project was built for the **Smart India Hackathon 2026** under Problem Statement **SIH26128** (Government of Maharashtra).

Licensed under the [MIT License](LICENSE).
