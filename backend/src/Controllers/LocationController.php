<?php
declare(strict_types=1);

namespace FieldPilot\Controllers;

use FieldPilot\Services\AuditLogger;
use PDO;

class LocationController extends BaseController {
    /**
     * Start an authorized location sharing session (Consent explicitly granted)
     */
    public function startSession(array $params, ?array $user): void {
        $employeeId = $user['employee_id'] ?? null;
        if (!$employeeId) {
            $this->error('Employee record not found.', 404);
        }

        // Close any previously hanging active session
        $this->db->prepare("
            UPDATE location_sharing_sessions 
            SET status = 'completed', end_time = NOW() 
            WHERE employee_id = ? AND status = 'active'
        ")->execute([$employeeId]);

        // Create new session
        $stmt = $this->db->prepare("
            INSERT INTO location_sharing_sessions 
            (employee_id, start_time, status, consent_granted_at, total_distance_km, created_at)
            VALUES (?, NOW(), 'active', NOW(), 0.00, NOW())
        ");
        $stmt->execute([$employeeId]);
        $sessionId = (int)$this->db->lastInsertId();

        // Update employee status
        $this->db->prepare("
            UPDATE employees 
            SET is_tracking_enabled = 1, current_status = 'in_field', updated_at = NOW() 
            WHERE id = ?
        ")->execute([$employeeId]);

        AuditLogger::log((int)$user['id'], 'LOCATION_SHARING_STARTED', 'location_sharing_sessions', $sessionId);

        $this->json([
            'session_id' => $sessionId,
            'status' => 'active',
            'started_at' => date('Y-m-d H:i:s')
        ], 201, 'Location sharing session started with employee consent');
    }

    /**
     * Stop or pause location sharing session
     */
    public function stopSession(array $params, ?array $user): void {
        $employeeId = $user['employee_id'] ?? null;
        if (!$employeeId) {
            $this->error('Employee record not found.', 404);
        }

        $body = $this->getBody();
        $reason = $body['reason'] ?? 'User initiated stop';
        $status = $body['status'] ?? 'stopped'; // 'stopped' or 'paused'

        $stmt = $this->db->prepare("
            UPDATE location_sharing_sessions 
            SET status = ?, end_time = NOW(), reason_for_stop = ?
            WHERE employee_id = ? AND status IN ('active', 'paused')
        ");
        $stmt->execute([$status, $reason, $employeeId]);

        // Update employee status
        $this->db->prepare("
            UPDATE employees 
            SET is_tracking_enabled = 0, current_status = 'online', updated_at = NOW() 
            WHERE id = ?
        ")->execute([$employeeId]);

        AuditLogger::log((int)$user['id'], 'LOCATION_SHARING_' . strtoupper($status), 'location_sharing_sessions', null, null, ['reason' => $reason]);

        $this->json(null, 200, "Location sharing session {$status}");
    }

    /**
     * Record a live GPS location ping (only accepted if an active authorized session exists)
     */
    public function recordPing(array $params, ?array $user): void {
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

        // Verify active session exists
        $sessionStmt = $this->db->prepare("
            SELECT id FROM location_sharing_sessions 
            WHERE employee_id = ? AND status = 'active' 
            ORDER BY id DESC LIMIT 1
        ");
        $sessionStmt->execute([$employeeId]);
        $session = $sessionStmt->fetch();

        $sessionId = $session['id'] ?? null;

        // Auto-create session if not explicitly started yet
        if (!$sessionId) {
            $newSessionStmt = $this->db->prepare("
                INSERT INTO location_sharing_sessions 
                (employee_id, start_time, status, consent_granted_at, created_at)
                VALUES (?, NOW(), 'active', NOW(), NOW())
            ");
            $newSessionStmt->execute([$employeeId]);
            $sessionId = (int)$this->db->lastInsertId();
        }

        $lat = (float)$body['latitude'];
        $lng = (float)$body['longitude'];
        $accuracy = isset($body['accuracy']) ? (float)$body['accuracy'] : 5.0;
        $speed = isset($body['speed']) ? (float)$body['speed'] : 0.0;
        $heading = isset($body['heading']) ? (float)$body['heading'] : 0.0;
        $battery = isset($body['battery_level']) ? (int)$body['battery_level'] : null;
        $isMock = !empty($body['is_mock']) ? 1 : 0;

        $stmt = $this->db->prepare("
            INSERT INTO employee_locations 
            (employee_id, session_id, latitude, longitude, accuracy, speed, heading, battery_level, is_mock, recorded_at, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
        ");
        $stmt->execute([$employeeId, $sessionId, $lat, $lng, $accuracy, $speed, $heading, $battery, $isMock]);

        // Update employee battery & current status
        $this->db->prepare("
            UPDATE employees 
            SET battery_level = ?, current_status = 'in_field', is_tracking_enabled = 1, updated_at = NOW() 
            WHERE id = ?
        ")->execute([$battery, $employeeId]);

        $this->json([
            'recorded_at' => date('Y-m-d H:i:s'),
            'session_id' => $sessionId
        ], 200, 'Location ping saved');
    }

    /**
     * Admin view: get all active live locations
     */
    public function getLiveEmployees(array $params, ?array $user): void {
        $sql = "
            SELECT 
                e.id as employee_id, e.employee_code, e.current_status, e.is_tracking_enabled, e.battery_level,
                u.id as user_id, u.full_name, u.phone, u.avatar_url,
                l.latitude, l.longitude, l.accuracy, l.speed, l.heading, l.recorded_at,
                s.id as session_id, s.start_time as session_started_at, s.total_distance_km
            FROM employees e
            JOIN users u ON e.user_id = u.id
            LEFT JOIN location_sharing_sessions s ON e.id = s.employee_id AND s.status = 'active'
            LEFT JOIN (
                SELECT el1.*
                FROM employee_locations el1
                INNER JOIN (
                    SELECT employee_id, MAX(id) as max_id
                    FROM employee_locations
                    GROUP BY employee_id
                ) el2 ON el1.id = el2.max_id
            ) l ON e.id = l.employee_id
            ORDER BY e.current_status = 'in_field' DESC, e.current_status = 'online' DESC, u.full_name ASC
        ";

        $employees = $this->db->query($sql)->fetchAll();
        $this->json(['employees' => $employees], 200, 'Live employee coordinates fetched');
    }

    /**
     * Admin/Employee view: location history and route polyline for a given employee and date
     */
    public function getHistory(array $params, ?array $user): void {
        $employeeId = (int)($params['id'] ?? $user['employee_id'] ?? 0);
        $date = $this->getQuery('date', date('Y-m-d'));

        // If employee role, prevent spying on others
        if ($user['role_name'] === 'employee' && (int)$user['employee_id'] !== $employeeId) {
            $this->error('Unauthorized to view other employee location history.', 403);
        }

        $stmt = $this->db->prepare("
            SELECT id, session_id, latitude, longitude, accuracy, speed, heading, battery_level, recorded_at
            FROM employee_locations
            WHERE employee_id = ? AND DATE(recorded_at) = ?
            ORDER BY recorded_at ASC
        ");
        $stmt->execute([$employeeId, $date]);
        $points = $stmt->fetchAll();

        // Customer visits on that date
        $visitStmt = $this->db->prepare("
            SELECT v.*, c.business_name, c.contact_person, c.address, c.city, c.latitude as customer_lat, c.longitude as customer_lng
            FROM customer_visits v
            JOIN customers c ON v.customer_id = c.id
            WHERE v.employee_id = ? AND DATE(v.check_in_time) = ?
            ORDER BY v.check_in_time ASC
        ");
        $visitStmt->execute([$employeeId, $date]);
        $visits = $visitStmt->fetchAll();

        $this->json([
            'employee_id' => $employeeId,
            'date' => $date,
            'breadcrumbs' => $points,
            'visits' => $visits
        ], 200, 'Location history and route retrieved');
    }
}
