# KamJodo Platform

KamJodo is a **two-sided local-services marketplace** — like Rapido + Rapido Captain for skilled workers.

## Two-App Model

| App | Folder | Target User | Package |
|---|---|---|---|
| **KamJodo** | `frontend/` | Customers (people who need a service) | `com.kamjodo.app` |
| **KamJodo Cap** | `frontend_cap/` | Workers (skilled workers who want jobs) | `com.kamjodo.cap` |

Both apps share the **same backend** (`backend/`).

## How it works

```
KamJodo Cap (Worker posts service)
        ↓
  Post visible in KamJodo (Customer sees it)
        ↓
  Customer books worker
        ↓
  KamJodo Cap notifies worker → Accept / Reject
        ↓
  Worker goes to customer → Completes job → Gets paid
```

## Repository Structure

```
d:\KamJodo\
├── backend\         → Shared Node.js + Express API + MongoDB
├── frontend\        → KamJodo (Customer App) — Flutter
├── frontend_cap\    → KamJodo Cap (Worker App) — Flutter
├── admin-web\       → Admin Panel (Web)
└── agent\           → Product workflow & API docs
```

## Running Locally

### Backend
```bash
cd backend
npm install
node server.js
# Runs at http://localhost:5000
```

### KamJodo (Customer App)
```bash
cd frontend
flutter run
```

### KamJodo Cap (Worker App)
```bash
cd frontend_cap
flutter run
```

## Documentation

- [App Workflow & Product Spec](agent/KAMJODO_APP_WORKFLOW.md)
- [API Documentation](agent/KAMJODO_API_DOCUMENTATION.md)
