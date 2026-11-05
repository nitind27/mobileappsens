<?php
declare(strict_types=1);

namespace FieldPilot\Controllers;

use FieldPilot\Services\AuditLogger;
use PDO;

class AttendanceController extends BaseController {
    public function checkIn(array $params, ?array $user): void {
        $employeeId = $user['employee_id'] ?? null;
        if (!$employeeId) {
            $this->error('Employee record not found.', 404);
        }

        $body = $this->getBody();
        $errors = $this->validate($body, [
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric'
        ]);

        if ($errors) {
            $this->error('Validation error', 422, $errors);
        }

        $today = date('Y-m-d');
        $currentTime = date('H:i:s');
        $lat = (float)$body['latitude'];
        $lng = (float)$body['longitude'];
        $address = $body['address'] ?? 'Field Location';
        $notes = $body['notes'] ?? null;

        // Check if already checked in today
        $existing = $this->db->prepare("SELECT * FROM attendance WHERE employee_id = ? AND date = ?");
        $existing->execute([$employeeId, $today]);
        $record = $existing->fetch();

        if ($record) {
            $this->error('Already checked in for today at ' . $record['check_in_time'], 400);
        }

        // Determine if late (e.g. check-in after 09:30:00)
        $empStmt = $this->db->prepare("SELECT work_start_time FROM employees WHERE id = ?");
        $empStmt->execute([$employeeId]);
        $expectedStart = $empStmt->fetchColumn() ?: '09:00:00';

        $status = 'present';
        if (strtotime($currentTime) > (strtotime($expectedStart) + 1800)) { // 30 min grace
            $status = 'late';
        }

        $stmt = $this->db->prepare("
            INSERT INTO attendance 
            (employee_id, date, check_in_time, check_in_lat, check_in_lng, check_in_address, status, notes, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())
        ");
        $stmt->execute([$employeeId, $today, $currentTime, $lat, $lng, $address, $status, $notes]);
        $attendanceId = (int)$this->db->lastInsertId();

        // Update employee status to online
        $this->db->prepare("UPDATE employees SET current_status = 'online', updated_at = NOW() WHERE id = ?")->execute([$employeeId]);

        AuditLogger::log((int)$user['id'], 'ATTENDANCE_CHECKIN', 'attendance', $attendanceId);

        $this->json([
            'attendance_id' => $attendanceId,
            'check_in_time' => $currentTime,
            'status' => $status
        ], 201, 'Checked in successfully');
    }

    public function checkOut(array $params, ?array $user): void {
        $employeeId = $user['employee_id'] ?? null;
        if (!$employeeId) {
            $this->error('Employee record not found.', 404);
        }

        $body = $this->getBody();
        $lat = isset($body['latitude']) ? (float)$body['latitude'] : null;
        $lng = isset($body['longitude']) ? (float)$body['longitude'] : null;
        $address = $body['address'] ?? 'Field Location';
        $today = date('Y-m-d');
        $currentTime = date('H:i:s');

        $stmt = $this->db->prepare("SELECT * FROM attendance WHERE employee_id = ? AND date = ?");
        $stmt->execute([$employeeId, $today]);
        $attendance = $stmt->fetch();

        if (!$attendance) {
            $this->error('No check-in record found for today.', 400);
        }

        if ($attendance['check_out_time'] !== null) {
            $this->error('Already checked out for today at ' . $attendance['check_out_time'], 400);
        }

        // Calculate work duration in minutes
        $checkInSec = strtotime($attendance['check_in_time']);
        $checkOutSec = strtotime($currentTime);
        $durationMinutes = max(0, (int)(($checkOutSec - $checkInSec) / 60));

        $update = $this->db->prepare("
            UPDATE attendance 
            SET check_out_time = ?, check_out_lat = ?, check_out_lng = ?, check_out_address = ?, 
                work_duration_minutes = ?, updated_at = NOW()
            WHERE id = ?
        ");
        $update->execute([$currentTime, $lat, $lng, $address, $durationMinutes, $attendance['id']]);

        // Stop active location sharing session
        $this->db->prepare("
            UPDATE location_sharing_sessions 
            SET status = 'completed', end_time = NOW(), reason_for_stop = 'Employee checked out'
            WHERE employee_id = ? AND status = 'active'
        ")->execute([$employeeId]);

        // Set status to offline
        $this->db->prepare("
            UPDATE employees 
            SET current_status = 'offline', is_tracking_enabled = 0, updated_at = NOW() 
            WHERE id = ?
        ")->execute([$employeeId]);

        AuditLogger::log((int)$user['id'], 'ATTENDANCE_CHECKOUT', 'attendance', (int)$attendance['id']);

        $this->json([
            'check_out_time' => $currentTime,
            'duration_minutes' => $durationMinutes
        ], 200, 'Checked out successfully');
    }

    public function getHistory(array $params, ?array $user): void {
        $employeeId = $this->getQuery('employee_id');
        $month = $this->getQuery('month', date('Y-m'));

        if ($user['role_name'] === 'employee') {
            $employeeId = $user['employee_id'];
        }

        $conditions = ["DATE_FORMAT(a.date, '%Y-%m') = ?"];
        $bindings = [$month];

        if (!empty($employeeId)) {
            $conditions[] = 'a.employee_id = ?';
            $bindings[] = (int)$employeeId;
        }

        $whereClause = 'WHERE ' . implode(' AND ', $conditions);

        $sql = "
            SELECT 
                a.*,
                e.employee_code,
                u.full_name as employee_name
            FROM attendance a
            JOIN employees e ON a.employee_id = e.id
            JOIN users u ON e.user_id = u.id
            {$whereClause}
            ORDER BY a.date DESC, a.check_in_time DESC
        ";

        $stmt = $this->db->prepare($sql);
        $stmt->execute($bindings);
        $records = $stmt->fetchAll();

        $this->json(['attendance' => $records], 200, 'Attendance history loaded');
    }
}
