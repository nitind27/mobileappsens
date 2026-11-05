# FieldPilot RESTful API Documentation

**Version:** 1.0.0  
**Base URL:** `http://localhost:8000/api` (Web/Desktop) | `http://10.0.2.2:8000/api` (Android Emulator)  
**Authentication:** HTTP Bearer Token (`Authorization: Bearer <JWT>`)

---

## 1. Authentication Endpoints

### 1.1 User Login
- **Endpoint:** `POST /api/auth/login`
- **Access:** Public
- **Request Body:**
```json
{
  "username": "admin",
  "password": "admin123"
}
```
- **Response (200 OK):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "role_id": 1,
      "role_name": "admin",
      "email": "admin@fieldpilot.com",
      "username": "admin",
      "full_name": "Rajesh Sharma",
      "phone": "+91 98250 11223",
      "avatar_url": "https://...",
      "employee_id": null
    }
  }
}
```

### 1.2 Get Current Profile
- **Endpoint:** `GET /api/auth/me`
- **Access:** Authenticated (Bearer Token)
- **Response (200 OK):** Current user object.

### 1.3 Logout
- **Endpoint:** `POST /api/auth/logout`
- **Access:** Authenticated
- **Response (200 OK):** Sets employee status to offline and terminates active tracking sessions.

---

## 2. Dashboard Endpoints

### 2.1 Admin Dashboard Metrics
- **Endpoint:** `GET /api/dashboard/admin`
- **Access:** Admin only
- **Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "summary": {
      "total_employees": 4,
      "active_employees": 3,
      "on_field_employees": 2,
      "today_collection": 28000.00,
      "monthly_collection": 540000.00,
      "total_pending": 95500.00,
      "total_target": 635500.00,
      "achievement_percent": 84.9,
      "tasks_count": { "total": 18, "completed": 12, "pending": 2 }
    },
    "payment_methods": [
      { "payment_method": "upi", "total_amount": 285000.00, "tx_count": 14 },
      { "payment_method": "cash", "total_amount": 195000.00, "tx_count": 10 }
    ],
    "rankings": [
      { "id": 1, "full_name": "Amit Patel", "total_collected": 245000.00 }
    ],
    "active_field_map": [
      { "employee_id": 1, "latitude": 21.189025, "longitude": 72.836520, "battery_level": 86 }
    ]
  }
}
```

### 2.2 Employee Dashboard Metrics
- **Endpoint:** `GET /api/dashboard/employee`
- **Access:** Field Employee
- **Response (200 OK):** Daily collection target, today collected, pending, current shift attendance status, and scheduled customer visits.

---

## 3. Tasks & Collection Management

### 3.1 List Tasks
- **Endpoint:** `GET /api/tasks`
- **Query Parameters:** `status`, `priority`, `search`, `employee_id`
- **Response (200 OK):** Array of collection assignments.

### 3.2 Create Assignment
- **Endpoint:** `POST /api/tasks`
- **Access:** Admin only
- **Request Body:**
```json
{
  "title": "Monthly Recovery - Rahul Traders",
  "customer_id": 1,
  "assigned_employee_id": 1,
  "target_amount": 25000.00,
  "due_date": "2026-11-10",
  "expected_visit_date": "2026-11-04",
  "priority": "high",
  "additional_instructions": "Collect balance via UPI or Cash."
}
```

---

## 4. Payments & Transactions

### 4.1 Record Payment Collection
- **Endpoint:** `POST /api/transactions`
- **Access:** Field Employee
- **Request Body:**
```json
{
  "task_id": 1,
  "amount_collected": 10000.00,
  "payment_method": "upi",
  "transaction_reference": "UPI/26110488921/HDFC",
  "signature_base64": "data:image/png;base64,...",
  "customer_remarks": "Paid first installment.",
  "latitude": 21.189025,
  "longitude": 72.836520
}
```
- **Auto-Calculations:**
  - Auto-increments task `collected_amount`
  - Auto-decrements task `pending_amount`
  - Updates task `completion_percentage`
  - Auto-sets status to `completed` if balance is 0.

### 4.2 Verify Payment
- **Endpoint:** `POST /api/transactions/{id}/verify`
- **Access:** Admin only
- **Request Body:**
```json
{
  "status": "verified",
  "verification_notes": "Bank credit confirmed on statement."
}
```

---

## 5. Transparent Live Location Tracking

### 5.1 Start Location Sharing Session
- **Endpoint:** `POST /api/location/session/start`
- **Access:** Field Employee (Consent Granted)
- **Response (201 Created):** Returns session ID and timestamp.

### 5.2 Stop Location Sharing Session
- **Endpoint:** `POST /api/location/session/stop`
- **Request Body:** `{ "reason": "Shift ended" }`

### 5.3 Send GPS Location Breadcrumb
- **Endpoint:** `POST /api/location/ping`
- **Request Body:**
```json
{
  "latitude": 21.189025,
  "longitude": 72.836520,
  "accuracy": 4.5,
  "speed": 18.0,
  "heading": 30.0,
  "battery_level": 86
}
```

### 5.4 Live Employees Location (Map)
- **Endpoint:** `GET /api/location/live-employees`
- **Access:** Admin only
- **Response (200 OK):** Latest GPS coordinates, battery level, speed, and status for all active field agents.

---

## 6. Attendance Management

### 6.1 Check-In (Punch In)
- **Endpoint:** `POST /api/attendance/check-in`
- **Request Body:**
```json
{
  "latitude": 21.170240,
  "longitude": 72.831060,
  "address": "Main Office, Ring Road, Surat"
}
```

### 6.2 Check-Out (Punch Out)
- **Endpoint:** `POST /api/attendance/check-out`
- **Auto-Calculates:** Work duration in minutes.

---

## 7. Communication & Calling

### 7.1 Get Chat Messages
- **Endpoint:** `GET /api/chat/{user_id}`

### 7.2 Send Message (Text / Voice Note)
- **Endpoint:** `POST /api/chat/send`
- **Request Body:**
```json
{
  "receiver_id": 1,
  "message_type": "text",
  "content": "Arrived at customer shop."
}
```

### 7.3 Initiate Voice / Video Call
- **Endpoint:** `POST /api/calls/initiate`
- **Request Body:**
```json
{
  "receiver_id": 1,
  "call_type": "video",
  "sdp_offer": "{...}"
}
```
