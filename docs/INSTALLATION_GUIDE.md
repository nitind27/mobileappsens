# FieldPilot — Complete Installation & Setup Guide

This guide covers setting up the MySQL database, running the PHP backend server, and launching the Flutter mobile application.

---

## 1. System Requirements

- **PHP**: 8.2+ (Included with XAMPP or standalone)
- **MySQL / MariaDB**: 10.4+ or MySQL 8.0+
- **Flutter SDK**: 3.24+ (Dart 3.5+)
- **Android Studio / VS Code**: For running the Flutter mobile app

---

## 2. Database Setup (phpMyAdmin / MySQL)

### Step 2.1: Start MySQL in XAMPP
1. Open **XAMPP Control Panel**.
2. Click **Start** on the **MySQL** module.
3. Open your browser and navigate to: `http://localhost/phpmyadmin`

### Step 2.2: Import `schema.sql`
1. In phpMyAdmin, click on the **Import** tab at the top.
2. Click **Choose File** and select:
   `e:\app mo\database\schema.sql`
3. Click **Import** at the bottom.
4. The database `fieldpilot_db` will be created with all 16 normalized tables and initial seed data.

*Alternatively, import via MySQL CLI:*
```bash
mysql -u root -p < "e:\app mo\database\schema.sql"
```

---

## 3. Backend Setup & Startup

### Step 3.1: Environment Configuration
Copy the template file to `.env`:
```powershell
cd "e:\app mo\backend"
copy .env.example .env
```

Verify your database settings in `backend/.env`:
```env
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=fieldpilot_db
DB_USER=root
DB_PASS=
```

### Step 3.2: Start the PHP Development Server
Run the built-in development router:
```powershell
cd "e:\app mo\backend"
php -S 0.0.0.0:8000 server.php
```
*(If using XAMPP's PHP directly: `& "C:\xampp\php\php.exe" -S 0.0.0.0:8000 server.php`)*

Verify that the API is alive by opening in your browser:
`http://localhost:8000/api/health`
You should see:
```json
{
  "success": true,
  "app": "FieldPilot API",
  "status": "operational",
  "version": "1.0.0"
}
```

---

## 4. Mobile Application Setup (Flutter)

### Step 4.1: Install Dependencies
```powershell
cd "e:\app mo\mobile"
flutter pub get
```

### Step 4.2: Configure Backend Server URL
When launching the app, the base URL can be customized right from the login screen (top right gear icon ⚙️) or left at default:
- **Android Emulator:** Uses `http://10.0.2.2:8000` (built-in loopback alias to host machine)
- **Physical Device:** Connect phone to the same Wi-Fi as your PC, find PC's IP (`ipconfig`), and enter `http://<YOUR-PC-IP>:8000`
- **Chrome / Web / Desktop:** Uses `http://localhost:8000`

### Step 4.3: Launch Mobile Application
```powershell
# Run on connected Android phone or emulator
flutter run

# Or run in Chrome browser
flutter run -d chrome
```

---

## 5. Default User Credentials

| Role | Username | Password | Features Accessible |
|---|---|---|---|
| **Admin / Shop Owner** | `admin` | `admin123` | Dashboard, Employee Map, Assignment Creation, Verification, Analytics |
| **Field Agent (Amit)** | `amit_patel` | `employee123` | My Tasks, Punch In/Out, Payment Collection, Digital Signatures, Location Sharing |
| **Field Agent (Priya)** | `priya_singh` | `employee123` | Assigned Tasks, Field Visit Verification |

*Both profiles have 1-click quick login buttons directly on the login screen for instant testing.*
