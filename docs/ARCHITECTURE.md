# FieldPilot — System Architecture & Technical Specifications

## 1. High-Level Architecture Overview

FieldPilot is engineered using a decoupled, enterprise-grade architecture:
- **Mobile Client:** Flutter 3 with Clean Architecture (Presentation, Domain/State, Data, Core layers), Riverpod state management, GoRouter, and Dio networking.
- **Backend Service:** PHP 8.2+ RESTful API built on MVC principles with pure PHP JWT authentication (zero external dependency footprint), prepared statements PDO database layer, and multi-part upload streaming.
- **Database Engine:** MySQL 8.0+ / MariaDB 10.4+ with 16 normalized tables, foreign key constraints, composite indexes, and audit logging.

```
+--------------------------------------------------------------------+
|                         FIELDPILOT SYSTEM                          |
+--------------------------------------------------------------------+
                                 |
        +------------------------+------------------------+
        |                                                 |
+-------------------+                           +--------------------+
|   Admin Web/App   |                           | Field Agent Mobile |
| - Live Map        |                           | - Daily Target Ring|
| - Task Creation   |                           | - Punch In / Out   |
| - Verifications   |                           | - Payment Receipt  |
| - Team Analytics  |                           | - Consent Tracking |
+-------------------+                           +--------------------+
        |                                                 |
        +------------------------+------------------------+
                                 | HTTPS / REST / WebRTC
                                 v
+--------------------------------------------------------------------+
|                    PHP 8.2+ REST API GATEWAY                       |
|  - AuthMiddleware (JWT HS256)                                      |
|  - CorsMiddleware & Rate Limiter                                   |
|  - FileUploadService (MIME Verification, UUID Renaming)            |
|  - AuditLogger (Captures Action, IP, Old vs New values)            |
+--------------------------------------------------------------------+
                                 |
                                 v
+--------------------------------------------------------------------+
|              MYSQL 8.0+ / MARIADB NORMALIZED DATABASE             |
|  - users, employees, roles, customers                              |
|  - collection_tasks, collection_transactions                      |
|  - attendance, location_sharing_sessions, employee_locations        |
|  - customer_visits, task_attachments, notifications               |
|  - chat_messages, call_sessions, audit_logs, business_settings     |
+--------------------------------------------------------------------+
```

---

## 2. Transparent Location Sharing & Privacy Consent Model

In strict accordance with Section 4 of the project specifications:
1. **Explicit Consent:** Location tracking **never** occurs silently or in the background without explicit employee opt-in.
2. **Session-Bound Breadcrumbs:** Location pings are only accepted by the backend if an active `location_sharing_sessions` record exists with `status = 'active'` and `consent_granted_at` timestamp.
3. **Working Hours Enforcement:** When an employee checks out (punches out), their active location session is automatically terminated (`status = 'completed'`).
4. **Persistent In-App Indicator:** Whenever tracking is active, a prominent `LocationBanner` widget is permanently rendered at the top of the mobile screen with an immediate "PAUSE / STOP" toggle.
5. **No Hidden Tracking:** Android permissions (`ACCESS_FINE_LOCATION`) are requested with runtime dialogs explaining exact business purpose.

---

## 3. Financial Collection Lifecycle

```
[Admin Creates Task]
       |
       v
[Assigned to Agent with Target Amount]
       |
       v
[Agent Visits Customer Shop]
       |
       +--> Check-in Geo-Verified (Within 200m geofence)
       |
       v
[Payment Collected]
       |
       +--> Select Method (Cash / UPI / Cheque / Transfer)
       +--> Attach Photo of Receipt / Voucher
       +--> Capture Customer Digital Touch Signature
       |
       v
[Backend Auto-Calculations]
       |
       +--> Collected Amount Incremented
       +--> Pending Amount Decremented
       +--> Completion % Updated
       +--> Transaction status: 'pending_verification'
       |
       v
[Admin Verification Console]
       |
       +--> Admin Inspects Receipt Photo & Signature
       +--> Approve ('verified') or Reject with notes
       +--> Customer Outstanding Balance Adjusted
```

---

## 4. Database Schema Structure (16 Normalized Tables)

1. `roles`: Role definition and permissions JSON.
2. `users`: Credentials, BCRYPT password hash, contact, role reference.
3. `employees`: Employee code, targets, work shift timings, tracking status, battery level.
4. `customers`: Business name, contact person, phone, GPS coordinates, credit limit, balance.
5. `collection_tasks`: Assignments, deadlines, priority levels, pending/collected amounts.
6. `collection_transactions`: Financial collections, payment method, receipt URL, signature URL, verification status.
7. `attendance`: Daily punch in/out timestamps, check-in coordinates, reverse-geocode address, duration.
8. `location_sharing_sessions`: Tracking sessions with consent grant timestamp and stop reasons.
9. `employee_locations`: GPS coordinates breadcrumbs (latitude, longitude, speed, heading, accuracy).
10. `customer_visits`: Field visit check-in/out timestamps and outcomes.
11. `task_attachments`: Digital documents, invoices, receipt photos.
12. `notifications`: In-app system alerts and task updates.
13. `chat_messages`: Text messages and audio voice notes.
14. `call_sessions`: Audio and video calling sessions with WebRTC SDP offer/answer states.
15. `audit_logs`: Immutable tracking of admin updates, approvals, logins, and settings changes.
16. `business_settings`: Dynamic business configuration parameters.
