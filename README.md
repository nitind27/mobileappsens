# FieldPilot 🚀
### Smart Field Collection & Workforce Management System

FieldPilot is a production-ready mobile and enterprise backend system designed for businesses, retail distributors, finance collection agencies, and field sales teams.

---

## 📁 Repository Structure

```
FieldPilot/
├── backend/                  # Complete PHP 8.2+ RESTful API Backend
│   ├── config/               # Database PDO, JWT secrets, App settings
│   ├── public/               # API Entry Point (index.php) & .htaccess
│   ├── src/                  # Controllers, Middlewares, Services, Router
│   ├── uploads/              # Storage for receipts, signatures, audio notes
│   ├── server.php            # Standalone PHP dev server router
│   └── .env.example          # Environment variables template
│
├── database/
│   └── schema.sql            # Full MySQL/MariaDB schema (16 tables + seed data)
│
├── mobile/                   # Complete Flutter Mobile Application
│   ├── lib/
│   │   ├── core/             # Theme, Colors, Dio client, Storage, Formatters
│   │   ├── models/           # User, Task, Transaction, Location, Attendance models
│   │   ├── providers/        # Riverpod state management & notifiers
│   │   ├── router/           # GoRouter route declarations & role guards
│   │   ├── screens/          # Admin & Field Agent experience screens
│   │   └── widgets/          # KPI cards, Signature pad, Progress bars
│   └── pubspec.yaml          # Flutter dependencies
│
└── docs/                     # Comprehensive System Documentation
    ├── API_DOCUMENTATION.md  # Detailed RESTful API endpoint specifications
    ├── INSTALLATION_GUIDE.md # XAMPP, PHP, MySQL, and Flutter startup guide
    ├── BUILD_APK_GUIDE.md    # Android APK compilation instructions
    └── ARCHITECTURE.md       # Clean architecture, privacy consent & data flows
```

---

## ⚡ Quick Start

### 1. Database
Import `database/schema.sql` into MySQL / phpMyAdmin:
```bash
mysql -u root -p < database/schema.sql
```

### 2. Backend Server
```bash
cd backend
php -S 0.0.0.0:8000 server.php
```

### 3. Mobile Application
```bash
cd mobile
flutter run
```

### 4. Default Demo Logins
- **Admin:** `admin` / `admin123`
- **Field Agent:** `amit_patel` / `employee123`
*(Quick 1-tap demo buttons are available on the app login screen)*
