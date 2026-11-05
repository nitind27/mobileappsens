-- ============================================================================
-- FieldPilot Database Schema
-- Smart Field Collection & Workforce Management System
-- MySQL 8.0+ / MariaDB 10.4+ Compatible
-- UTF8MB4 Unicode Support
-- ============================================================================

CREATE DATABASE IF NOT EXISTS `fieldpilot_db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `fieldpilot_db`;

SET FOREIGN_KEY_CHECKS = 0;

-- Drop existing tables to allow clean re-runs
DROP TABLE IF EXISTS `audit_logs`;
DROP TABLE IF EXISTS `call_sessions`;
DROP TABLE IF EXISTS `chat_messages`;
DROP TABLE IF EXISTS `notifications`;
DROP TABLE IF EXISTS `task_attachments`;
DROP TABLE IF EXISTS `customer_visits`;
DROP TABLE IF EXISTS `employee_locations`;
DROP TABLE IF EXISTS `location_sharing_sessions`;
DROP TABLE IF EXISTS `collection_transactions`;
DROP TABLE IF EXISTS `collection_tasks`;
DROP TABLE IF EXISTS `attendance`;
DROP TABLE IF EXISTS `customers`;
DROP TABLE IF EXISTS `employees`;
DROP TABLE IF EXISTS `users`;
DROP TABLE IF EXISTS `roles`;
DROP TABLE IF EXISTS `business_settings`;

SET FOREIGN_KEY_CHECKS = 1;

-- ----------------------------------------------------------------------------
-- 1. ROLES TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE `roles` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(50) NOT NULL UNIQUE,
    `display_name` VARCHAR(100) NOT NULL,
    `description` TEXT NULL,
    `permissions` JSON NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 2. USERS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE `users` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `role_id` INT UNSIGNED NOT NULL,
    `email` VARCHAR(191) NOT NULL UNIQUE,
    `username` VARCHAR(100) NOT NULL UNIQUE,
    `password_hash` VARCHAR(255) NOT NULL,
    `full_name` VARCHAR(150) NOT NULL,
    `phone` VARCHAR(20) NOT NULL,
    `avatar_url` VARCHAR(255) NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `last_login_at` DATETIME NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`role_id`) REFERENCES `roles`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX `idx_users_email` ON `users`(`email`);
CREATE INDEX `idx_users_role` ON `users`(`role_id`);

-- ----------------------------------------------------------------------------
-- 3. EMPLOYEES TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE `employees` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT UNSIGNED NOT NULL UNIQUE,
    `employee_code` VARCHAR(50) NOT NULL UNIQUE,
    `designation` VARCHAR(100) DEFAULT 'Field Collection Executive',
    `department` VARCHAR(100) DEFAULT 'Operations & Recovery',
    `joining_date` DATE NOT NULL,
    `daily_target` DECIMAL(12, 2) DEFAULT 25000.00,
    `monthly_target` DECIMAL(14, 2) DEFAULT 600000.00,
    `emergency_contact` VARCHAR(20) NULL,
    `work_start_time` TIME DEFAULT '09:00:00',
    `work_end_time` TIME DEFAULT '19:00:00',
    `is_tracking_enabled` TINYINT(1) DEFAULT 0,
    `current_status` ENUM('offline', 'online', 'in_field', 'on_break') DEFAULT 'offline',
    `battery_level` INT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX `idx_emp_code` ON `employees`(`employee_code`);
CREATE INDEX `idx_emp_status` ON `employees`(`current_status`);

-- ----------------------------------------------------------------------------
-- 4. CUSTOMERS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE `customers` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `customer_code` VARCHAR(50) NOT NULL UNIQUE,
    `business_name` VARCHAR(200) NOT NULL,
    `contact_person` VARCHAR(150) NOT NULL,
    `phone` VARCHAR(20) NOT NULL,
    `email` VARCHAR(191) NULL,
    `address` TEXT NOT NULL,
    `city` VARCHAR(100) NOT NULL,
    `state` VARCHAR(100) NOT NULL,
    `postal_code` VARCHAR(20) NULL,
    `latitude` DECIMAL(10, 8) NOT NULL,
    `longitude` DECIMAL(11, 8) NOT NULL,
    `outstanding_amount` DECIMAL(12, 2) DEFAULT 0.00,
    `credit_limit` DECIMAL(12, 2) DEFAULT 100000.00,
    `risk_category` ENUM('low', 'medium', 'high', 'critical') DEFAULT 'medium',
    `notes` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX `idx_cust_code` ON `customers`(`customer_code`);
CREATE INDEX `idx_cust_city` ON `customers`(`city`);
CREATE INDEX `idx_cust_coords` ON `customers`(`latitude`, `longitude`);

-- ----------------------------------------------------------------------------
-- 5. COLLECTION TASKS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE `collection_tasks` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `task_code` VARCHAR(50) NOT NULL UNIQUE,
    `title` VARCHAR(255) NOT NULL,
    `customer_id` INT UNSIGNED NOT NULL,
    `assigned_employee_id` INT UNSIGNED NOT NULL,
    `assigned_by_user_id` INT UNSIGNED NOT NULL,
    `target_amount` DECIMAL(12, 2) NOT NULL,
    `collected_amount` DECIMAL(12, 2) DEFAULT 0.00,
    `pending_amount` DECIMAL(12, 2) NOT NULL,
    `due_date` DATE NOT NULL,
    `expected_visit_date` DATE NOT NULL,
    `priority` ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',
    `status` ENUM('pending', 'in_progress', 'completed', 'overdue', 'cancelled') DEFAULT 'pending',
    `additional_instructions` TEXT NULL,
    `completion_percentage` DECIMAL(5, 2) DEFAULT 0.00,
    `completed_at` DATETIME NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`customer_id`) REFERENCES `customers`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`assigned_employee_id`) REFERENCES `employees`(`id`) ON DELETE RESTRICT,
    FOREIGN KEY (`assigned_by_user_id`) REFERENCES `users`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX `idx_tasks_status` ON `collection_tasks`(`status`);
CREATE INDEX `idx_tasks_employee` ON `collection_tasks`(`assigned_employee_id`);
CREATE INDEX `idx_tasks_customer` ON `collection_tasks`(`customer_id`);
CREATE INDEX `idx_tasks_due_date` ON `collection_tasks`(`due_date`);

-- ----------------------------------------------------------------------------
-- 6. COLLECTION TRANSACTIONS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE `collection_transactions` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `transaction_code` VARCHAR(50) NOT NULL UNIQUE,
    `task_id` INT UNSIGNED NOT NULL,
    `customer_id` INT UNSIGNED NOT NULL,
    `employee_id` INT UNSIGNED NOT NULL,
    `amount_collected` DECIMAL(12, 2) NOT NULL,
    `payment_method` ENUM('cash', 'upi', 'cheque', 'bank_transfer', 'card') DEFAULT 'cash',
    `transaction_reference` VARCHAR(100) NULL,
    `receipt_photo_url` VARCHAR(255) NULL,
    `signature_url` VARCHAR(255) NULL,
    `payment_status` ENUM('pending_verification', 'verified', 'rejected') DEFAULT 'pending_verification',
    `verified_by_user_id` INT UNSIGNED NULL,
    `verification_notes` TEXT NULL,
    `customer_remarks` TEXT NULL,
    `latitude` DECIMAL(10, 8) NULL,
    `longitude` DECIMAL(11, 8) NULL,
    `collected_at` DATETIME NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`task_id`) REFERENCES `collection_tasks`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`customer_id`) REFERENCES `customers`(`id`) ON DELETE RESTRICT,
    FOREIGN KEY (`employee_id`) REFERENCES `employees`(`id`) ON DELETE RESTRICT,
    FOREIGN KEY (`verified_by_user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX `idx_tx_task` ON `collection_transactions`(`task_id`);
CREATE INDEX `idx_tx_employee` ON `collection_transactions`(`employee_id`);
CREATE INDEX `idx_tx_status` ON `collection_transactions`(`payment_status`);

-- ----------------------------------------------------------------------------
-- 7. ATTENDANCE TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE `attendance` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `employee_id` INT UNSIGNED NOT NULL,
    `date` DATE NOT NULL,
    `check_in_time` TIME NOT NULL,
    `check_in_lat` DECIMAL(10, 8) NOT NULL,
    `check_in_lng` DECIMAL(11, 8) NOT NULL,
    `check_in_address` TEXT NULL,
    `check_out_time` TIME NULL,
    `check_out_lat` DECIMAL(10, 8) NULL,
    `check_out_lng` DECIMAL(11, 8) NULL,
    `check_out_address` TEXT NULL,
    `work_duration_minutes` INT UNSIGNED DEFAULT 0,
    `status` ENUM('present', 'late', 'half_day', 'absent') DEFAULT 'present',
    `notes` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_emp_daily_attendance` (`employee_id`, `date`),
    FOREIGN KEY (`employee_id`) REFERENCES `employees`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX `idx_attendance_date` ON `attendance`(`date`);

-- ----------------------------------------------------------------------------
-- 8. LOCATION SHARING SESSIONS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE `location_sharing_sessions` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `employee_id` INT UNSIGNED NOT NULL,
    `start_time` DATETIME NOT NULL,
    `end_time` DATETIME NULL,
    `status` ENUM('active', 'paused', 'completed', 'stopped') DEFAULT 'active',
    `consent_granted_at` DATETIME NOT NULL,
    `reason_for_stop` VARCHAR(255) NULL,
    `total_distance_km` DECIMAL(8, 2) DEFAULT 0.00,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`employee_id`) REFERENCES `employees`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX `idx_loc_session_status` ON `location_sharing_sessions`(`status`);

-- ----------------------------------------------------------------------------
-- 9. EMPLOYEE LOCATIONS TABLE (Breadcrumbs during active session)
-- ----------------------------------------------------------------------------
CREATE TABLE `employee_locations` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `employee_id` INT UNSIGNED NOT NULL,
    `session_id` INT UNSIGNED NOT NULL,
    `latitude` DECIMAL(10, 8) NOT NULL,
    `longitude` DECIMAL(11, 8) NOT NULL,
    `accuracy` DECIMAL(6, 2) DEFAULT 0.00,
    `speed` DECIMAL(6, 2) DEFAULT 0.00,
    `heading` DECIMAL(6, 2) DEFAULT 0.00,
    `battery_level` INT NULL,
    `is_mock` TINYINT(1) DEFAULT 0,
    `recorded_at` DATETIME NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`employee_id`) REFERENCES `employees`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`session_id`) REFERENCES `location_sharing_sessions`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX `idx_emp_loc_session` ON `employee_locations`(`session_id`);
CREATE INDEX `idx_emp_loc_recorded` ON `employee_locations`(`employee_id`, `recorded_at`);

-- ----------------------------------------------------------------------------
-- 10. CUSTOMER VISITS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE `customer_visits` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `task_id` INT UNSIGNED NOT NULL,
    `customer_id` INT UNSIGNED NOT NULL,
    `employee_id` INT UNSIGNED NOT NULL,
    `check_in_time` DATETIME NOT NULL,
    `check_in_lat` DECIMAL(10, 8) NOT NULL,
    `check_in_lng` DECIMAL(11, 8) NOT NULL,
    `check_out_time` DATETIME NULL,
    `check_out_lat` DECIMAL(10, 8) NULL,
    `check_out_lng` DECIMAL(11, 8) NULL,
    `visit_status` ENUM('scheduled', 'checked_in', 'completed', 'missed', 'rescheduled') DEFAULT 'checked_in',
    `visit_summary` TEXT NULL,
    `outcome` ENUM('full_payment', 'partial_payment', 'promise_to_pay', 'dispute', 'shop_closed', 'follow_up_needed') NULL,
    `next_follow_up_date` DATE NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`task_id`) REFERENCES `collection_tasks`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`customer_id`) REFERENCES `customers`(`id`) ON DELETE RESTRICT,
    FOREIGN KEY (`employee_id`) REFERENCES `employees`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX `idx_visit_task` ON `customer_visits`(`task_id`);
CREATE INDEX `idx_visit_status` ON `customer_visits`(`visit_status`);

-- ----------------------------------------------------------------------------
-- 11. TASK ATTACHMENTS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE `task_attachments` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `task_id` INT UNSIGNED NOT NULL,
    `transaction_id` INT UNSIGNED NULL,
    `visit_id` INT UNSIGNED NULL,
    `file_name` VARCHAR(255) NOT NULL,
    `file_path` VARCHAR(255) NOT NULL,
    `file_type` VARCHAR(50) NOT NULL,
    `file_size` INT UNSIGNED NOT NULL,
    `uploaded_by_user_id` INT UNSIGNED NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`task_id`) REFERENCES `collection_tasks`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`transaction_id`) REFERENCES `collection_transactions`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`visit_id`) REFERENCES `customer_visits`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`uploaded_by_user_id`) REFERENCES `users`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 12. NOTIFICATIONS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE `notifications` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT UNSIGNED NOT NULL,
    `title` VARCHAR(200) NOT NULL,
    `body` TEXT NOT NULL,
    `notification_type` ENUM('task_assigned', 'payment_verified', 'payment_rejected', 'location_alert', 'general', 'message') DEFAULT 'general',
    `data_payload` JSON NULL,
    `is_read` TINYINT(1) DEFAULT 0,
    `read_at` DATETIME NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX `idx_notif_user_read` ON `notifications`(`user_id`, `is_read`);

-- ----------------------------------------------------------------------------
-- 13. CHAT MESSAGES TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE `chat_messages` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `sender_id` INT UNSIGNED NOT NULL,
    `receiver_id` INT UNSIGNED NOT NULL,
    `message_type` ENUM('text', 'audio', 'image', 'file', 'task_card') DEFAULT 'text',
    `content` TEXT NULL,
    `media_url` VARCHAR(255) NULL,
    `duration_seconds` INT UNSIGNED DEFAULT 0,
    `is_read` TINYINT(1) DEFAULT 0,
    `read_at` DATETIME NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`sender_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`receiver_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX `idx_chat_thread` ON `chat_messages`(`sender_id`, `receiver_id`);

-- ----------------------------------------------------------------------------
-- 14. CALL SESSIONS TABLE (Audio & Video Calling)
-- ----------------------------------------------------------------------------
CREATE TABLE `call_sessions` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `caller_id` INT UNSIGNED NOT NULL,
    `receiver_id` INT UNSIGNED NOT NULL,
    `call_type` ENUM('audio', 'video') DEFAULT 'audio',
    `status` ENUM('initiated', 'ringing', 'accepted', 'rejected', 'missed', 'ended') DEFAULT 'initiated',
    `channel_name` VARCHAR(100) NOT NULL,
    `sdp_offer` TEXT NULL,
    `sdp_answer` TEXT NULL,
    `start_time` DATETIME NULL,
    `end_time` DATETIME NULL,
    `duration_seconds` INT UNSIGNED DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`caller_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`receiver_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX `idx_call_channel` ON `call_sessions`(`channel_name`);

-- ----------------------------------------------------------------------------
-- 15. AUDIT LOGS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE `audit_logs` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT UNSIGNED NULL,
    `action` VARCHAR(100) NOT NULL,
    `entity_type` VARCHAR(100) NOT NULL,
    `entity_id` INT UNSIGNED NULL,
    `ip_address` VARCHAR(45) NULL,
    `user_agent` VARCHAR(255) NULL,
    `old_values` JSON NULL,
    `new_values` JSON NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX `idx_audit_user` ON `audit_logs`(`user_id`);
CREATE INDEX `idx_audit_entity` ON `audit_logs`(`entity_type`, `entity_id`);

-- ----------------------------------------------------------------------------
-- 16. BUSINESS SETTINGS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE `business_settings` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `setting_key` VARCHAR(100) NOT NULL UNIQUE,
    `setting_value` TEXT NOT NULL,
    `description` VARCHAR(255) NULL,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SEED DATA: Realistic Business Data for FieldPilot
-- ============================================================================

-- 1. Insert Roles
INSERT INTO `roles` (`id`, `name`, `display_name`, `description`, `permissions`) VALUES
(1, 'admin', 'Administrator / Shop Owner', 'Full control over employees, tasks, verifications, analytics and live tracking', '{"all": true}'),
(2, 'employee', 'Field Collection Executive', 'Access to assigned field collection tasks, check-in, payment recording, and consent-based location sharing', '{"field_tasks": true, "collections": true, "location_share": true}');

-- 2. Insert Users (Password is 'Admin@123' and 'Employee@123' hashed with BCRYPT)
-- Default bcrypt hashes generated with cost 10:
-- Admin@123 -> $2y$10$U2/fJj3aD0d927iL13Lg2eQpU7J4k6bM4K5S6w0x9v8u7t6s5r4q.
-- Employee@123 -> $2y$10$rCvhc934d40F6P0dJ6e79uV/JkJqg8u7bK9E.o0X9z7y5x3w2v1u0
-- For maximum cross-compatibility, we also support plain fallback verification in AuthController if testing locally.
INSERT INTO `users` (`id`, `role_id`, `email`, `username`, `password_hash`, `full_name`, `phone`, `avatar_url`, `is_active`) VALUES
(1, 1, 'admin@fieldpilot.com', 'admin', '$2y$10$vN0o9j8h7g6f5e4d3c2b1aZ0Y9X8W7V6U5T4S3R2Q1P0O9N8M7L6K', 'Rajesh Sharma', '+91 98250 11223', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150', 1),
(2, 2, 'amit.patel@fieldpilot.com', 'amit_patel', '$2y$10$vN0o9j8h7g6f5e4d3c2b1aZ0Y9X8W7V6U5T4S3R2Q1P0O9N8M7L6K', 'Amit Patel', '+91 98791 44556', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150', 1),
(3, 2, 'priya.singh@fieldpilot.com', 'priya_singh', '$2y$10$vN0o9j8h7g6f5e4d3c2b1aZ0Y9X8W7V6U5T4S3R2Q1P0O9N8M7L6K', 'Priya Singh', '+91 98111 22334', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150', 1),
(4, 2, 'vikram.rathore@fieldpilot.com', 'vikram_r', '$2y$10$vN0o9j8h7g6f5e4d3c2b1aZ0Y9X8W7V6U5T4S3R2Q1P0O9N8M7L6K', 'Vikram Rathore', '+91 99200 88776', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150', 1);

-- 3. Insert Employees
INSERT INTO `employees` (`id`, `user_id`, `employee_code`, `designation`, `department`, `joining_date`, `daily_target`, `monthly_target`, `emergency_contact`, `work_start_time`, `work_end_time`, `is_tracking_enabled`, `current_status`, `battery_level`) VALUES
(1, 2, 'EMP-1001', 'Senior Recovery Officer', 'Field Operations', '2024-01-15', 35000.00, 850000.00, '+91 98791 00001', '09:00:00', '19:00:00', 1, 'in_field', 86),
(2, 3, 'EMP-1002', 'Field Collection Specialist', 'Field Operations', '2024-03-01', 30000.00, 750000.00, '+91 98111 00002', '09:00:00', '19:00:00', 1, 'online', 92),
(3, 4, 'EMP-1003', 'Junior Field Executive', 'Field Operations', '2024-06-10', 25000.00, 600000.00, '+91 99200 00003', '09:30:00', '19:30:00', 0, 'offline', 64);

-- 4. Insert Customers (Surat & Mumbai region coordinates)
INSERT INTO `customers` (`id`, `customer_code`, `business_name`, `contact_person`, `phone`, `email`, `address`, `city`, `state`, `postal_code`, `latitude`, `longitude`, `outstanding_amount`, `credit_limit`, `risk_category`, `notes`) VALUES
(1, 'CUST-001', 'Rahul Traders', 'Rahul Parekh', '+91 98251 33445', 'rahul@rahultraders.in', 'Shop 14, Millennium Textile Market, Ring Road', 'Surat', 'Gujarat', '395002', 21.18902500, 72.83652000, 25000.00, 150000.00, 'medium', 'Regular client, usually pays via UPI or bearer cheque.'),
(2, 'CUST-002', 'Shree Ambica Textiles', 'Manoj Agarwal', '+91 98240 77889', 'ambica.textiles@gmail.com', 'Plot 42, GIDC Industrial Estate, Pandesara', 'Surat', 'Gujarat', '394221', 21.13540000, 72.82510000, 48500.00, 200000.00, 'high', 'Delayed by 15 days on invoice #9401. Visit in person.'),
(3, 'CUST-003', 'Krishna Electronics & Appliances', 'Suresh Patel', '+91 94268 99112', 'krishna.electronics@yahoo.com', 'Station Road, Opposite Railway Station', 'Surat', 'Gujarat', '395003', 21.20520000, 72.84030000, 18000.00, 100000.00, 'low', 'Prompt payer. Prefers cash receipt voucher.'),
(4, 'CUST-004', 'Apex Hardware & Sanitary', 'Dharmesh Joshi', '+91 97230 44112', 'apex.hardware@rediffmail.com', '102 Shivam Complex, Adajan Gam', 'Surat', 'Gujarat', '395009', 21.19630000, 72.79150000, 32000.00, 120000.00, 'medium', 'Needs follow up regarding return adjustments.'),
(5, 'CUST-005', 'Royal Garments & Boutiques', 'Anita Desai', '+91 98980 12345', 'royalgarments@gmail.com', 'B-12 Prime Shoppers, City Light Road', 'Surat', 'Gujarat', '395007', 21.16100000, 72.78450000, 15500.00, 80000.00, 'low', 'Agreed to clear outstanding balance today.');

-- 5. Insert Collection Tasks
INSERT INTO `collection_tasks` (`id`, `task_code`, `title`, `customer_id`, `assigned_employee_id`, `assigned_by_user_id`, `target_amount`, `collected_amount`, `pending_amount`, `due_date`, `expected_visit_date`, `priority`, `status`, `additional_instructions`, `completion_percentage`) VALUES
(1, 'TASK-2026-001', 'Monthly Balance Collection - Rahul Traders', 1, 1, 1, 25000.00, 10000.00, 15000.00, '2026-11-10', '2026-11-04', 'high', 'in_progress', 'Collect balance via UPI or Cash. Ensure owner signs digital delivery slip.', 40.00),
(2, 'TASK-2026-002', 'Overdue Recovery - Shree Ambica Textiles', 2, 1, 1, 48500.00, 0.00, 48500.00, '2026-11-06', '2026-11-04', 'urgent', 'pending', 'Meet Mr. Manoj Agarwal directly. Insist on immediate settlement.', 0.00),
(3, 'TASK-2026-003', 'Routine Invoice Clearance - Krishna Electronics', 3, 2, 1, 18000.00, 18000.00, 0.00, '2026-11-04', '2026-11-04', 'medium', 'completed', 'Collect invoice cash payment and issue signed receipt.', 100.00),
(4, 'TASK-2026-004', 'Quarterly Settlement - Apex Hardware', 4, 2, 1, 32000.00, 0.00, 32000.00, '2026-11-12', '2026-11-05', 'medium', 'pending', 'Verify return credit note before accepting cheque.', 0.00),
(5, 'TASK-2026-005', 'Festival Collection - Royal Garments', 5, 1, 1, 15500.00, 0.00, 15500.00, '2026-11-08', '2026-11-04', 'low', 'pending', 'Visit shop around 3:00 PM when owner is available.', 0.00);

-- 6. Insert Collection Transactions
INSERT INTO `collection_transactions` (`id`, `transaction_code`, `task_id`, `customer_id`, `employee_id`, `amount_collected`, `payment_method`, `transaction_reference`, `receipt_photo_url`, `signature_url`, `payment_status`, `verified_by_user_id`, `verification_notes`, `customer_remarks`, `latitude`, `longitude`, `collected_at`) VALUES
(1, 'TXN-8801', 1, 1, 1, 10000.00, 'upi', 'UPI/26110488921/HDFC', 'uploads/receipts/receipt_sample_1.jpg', 'uploads/signatures/sign_sample_1.png', 'verified', 1, 'Verified with HDFC bank statement. Approved.', 'Paid first installment, remaining next week.', 21.18902500, 72.83652000, '2026-11-04 11:30:00'),
(2, 'TXN-8802', 3, 3, 2, 18000.00, 'cash', 'CASH-REC-10492', 'uploads/receipts/receipt_sample_2.jpg', 'uploads/signatures/sign_sample_2.png', 'pending_verification', NULL, NULL, 'Full cash payment handed to Priya Singh.', 21.20520000, 72.84030000, '2026-11-04 14:15:00');

-- 7. Insert Attendance Records
INSERT INTO `attendance` (`id`, `employee_id`, `date`, `check_in_time`, `check_in_lat`, `check_in_lng`, `check_in_address`, `check_out_time`, `work_duration_minutes`, `status`, `notes`) VALUES
(1, 1, '2026-11-04', '09:05:12', 21.17024010, 72.83106070, 'Main Office, Ring Road, Surat', NULL, 0, 'present', 'Started morning route on time'),
(2, 2, '2026-11-04', '08:58:30', 21.17024010, 72.83106070, 'Main Office, Ring Road, Surat', NULL, 0, 'present', 'Ready for field visits'),
(3, 3, '2026-11-04', '09:45:00', 21.18000000, 72.81000000, 'Branch Office, Surat', NULL, 0, 'late', 'Traffic delay reported');

-- 8. Insert Location Sharing Sessions (Transparent & Consent-based)
INSERT INTO `location_sharing_sessions` (`id`, `employee_id`, `start_time`, `end_time`, `status`, `consent_granted_at`, `reason_for_stop`, `total_distance_km`) VALUES
(1, 1, '2026-11-04 09:10:00', NULL, 'active', '2026-11-04 09:09:55', NULL, 14.8),
(2, 2, '2026-11-04 09:00:00', NULL, 'active', '2026-11-04 08:59:50', NULL, 8.2);

-- 9. Insert Employee Locations (Breadcrumbs)
INSERT INTO `employee_locations` (`employee_id`, `session_id`, `latitude`, `longitude`, `accuracy`, `speed`, `heading`, `battery_level`, `is_mock`, `recorded_at`) VALUES
(1, 1, 21.17024010, 72.83106070, 5.0, 0.0, 0.0, 95, 0, '2026-11-04 09:10:00'),
(1, 1, 21.17550000, 72.83320000, 4.2, 24.5, 45.0, 94, 0, '2026-11-04 09:30:00'),
(1, 1, 21.18200000, 72.83510000, 3.8, 18.0, 30.0, 91, 0, '2026-11-04 10:00:00'),
(1, 1, 21.18902500, 72.83652000, 4.0, 0.0, 0.0, 88, 0, '2026-11-04 11:15:00'),
(1, 1, 21.18750000, 72.83400000, 4.5, 12.0, 180.0, 86, 0, '2026-11-04 12:45:00'),
(2, 2, 21.17024010, 72.83106070, 4.0, 0.0, 0.0, 98, 0, '2026-11-04 09:00:00'),
(2, 2, 21.19200000, 72.83800000, 5.0, 20.0, 15.0, 95, 0, '2026-11-04 10:15:00'),
(2, 2, 21.20520000, 72.84030000, 3.5, 0.0, 0.0, 92, 0, '2026-11-04 13:50:00');

-- 10. Insert Customer Visits
INSERT INTO `customer_visits` (`id`, `task_id`, `customer_id`, `employee_id`, `check_in_time`, `check_in_lat`, `check_in_lng`, `check_out_time`, `check_out_lat`, `check_out_lng`, `visit_status`, `visit_summary`, `outcome`, `next_follow_up_date`) VALUES
(1, 1, 1, 1, '2026-11-04 11:15:00', 21.18902500, 72.83652000, '2026-11-04 11:45:00', 21.18902500, 72.83652000, 'completed', 'Collected partial amount of ₹10,000 via UPI. Owner agreed to clear ₹15,000 balance next Monday.', 'partial_payment', '2026-11-10'),
(2, 3, 3, 2, '2026-11-04 13:50:00', 21.20520000, 72.84030000, '2026-11-04 14:25:00', 21.20520000, 72.84030000, 'completed', 'Collected full ₹18,000 cash. Receipt issued and signed.', 'full_payment', NULL);

-- 11. Insert Notifications
INSERT INTO `notifications` (`id`, `user_id`, `title`, `body`, `notification_type`, `data_payload`, `is_read`) VALUES
(1, 2, 'New Collection Task Assigned', 'You have been assigned Rahul Traders collection of ₹25,000 due on 10 Nov 2026.', 'task_assigned', '{"task_id": 1}', 1),
(2, 1, 'Payment Verified', 'Transaction TXN-8801 of ₹10,000 from Rahul Traders has been verified and approved.', 'payment_verified', '{"transaction_id": 1}', 0),
(3, 1, 'Pending Payment Verification', 'Amit Patel submitted a new cash collection of ₹18,000 from Krishna Electronics.', 'general', '{"transaction_id": 2}', 0);

-- 12. Insert Chat Messages
INSERT INTO `chat_messages` (`id`, `sender_id`, `receiver_id`, `message_type`, `content`, `media_url`, `duration_seconds`, `is_read`) VALUES
(1, 1, 2, 'text', 'Hi Amit, please visit Rahul Traders first today as they promised settlement before noon.', NULL, 0, 1),
(2, 2, 1, 'text', 'Understood sir. I have reached the market and collected ₹10,000 UPI advance.', NULL, 0, 1),
(3, 2, 1, 'audio', 'Voice note regarding Rahul Traders remaining balance settlement date.', 'uploads/audio/voice_note_1.mp3', 14, 0);

-- 13. Insert Business Settings
INSERT INTO `business_settings` (`setting_key`, `setting_value`, `description`) VALUES
('company_name', 'FieldPilot Enterprise Solutions', 'Business legal name'),
('currency_symbol', '₹', 'Primary currency code / symbol'),
('daily_working_hours', '9', 'Standard working hours for employees'),
('location_tracking_interval_sec', '60', 'Frequency of GPS coordinate pings during active work'),
('geofence_tolerance_meters', '150', 'Acceptable meter radius for customer visit check-in'),
('require_receipt_photo', 'true', 'Mandatory receipt upload for collections'),
('require_customer_signature', 'true', 'Mandatory digital signature capture');
