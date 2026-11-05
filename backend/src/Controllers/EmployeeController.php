<?php
declare(strict_types=1);

namespace FieldPilot\Controllers;

use FieldPilot\Services\AuditLogger;
use PDO;

class EmployeeController extends BaseController {
    public function index(array $params, ?array $user): void {
        $status = $this->getQuery('status');
        $search = $this->getQuery('search');

        $conditions = [];
        $bindings = [];

        if (!empty($status)) {
            $conditions[] = 'e.current_status = ?';
            $bindings[] = $status;
        }

        if (!empty($search)) {
            $conditions[] = '(u.full_name LIKE ? OR e.employee_code LIKE ? OR u.phone LIKE ? OR u.email LIKE ?)';
            $term = '%' . $search . '%';
            $bindings = array_merge($bindings, [$term, $term, $term, $term]);
        }

        $whereClause = !empty($conditions) ? 'WHERE ' . implode(' AND ', $conditions) : '';

        $sql = "
            SELECT 
                e.*,
                u.email, u.username, u.full_name, u.phone, u.avatar_url, u.is_active, u.last_login_at,
                COALESCE(col.total_collected_month, 0) as total_collected_month,
                COALESCE(tsk.active_tasks_count, 0) as active_tasks_count,
                l.latitude as last_lat, l.longitude as last_lng, l.recorded_at as last_location_time
            FROM employees e
            JOIN users u ON e.user_id = u.id
            LEFT JOIN (
                SELECT employee_id, SUM(amount_collected) as total_collected_month
                FROM collection_transactions
                WHERE payment_status != 'rejected' AND MONTH(collected_at) = MONTH(CURRENT_DATE()) AND YEAR(collected_at) = YEAR(CURRENT_DATE())
                GROUP BY employee_id
            ) col ON e.id = col.employee_id
            LEFT JOIN (
                SELECT assigned_employee_id, COUNT(*) as active_tasks_count
                FROM collection_tasks
                WHERE status IN ('pending', 'in_progress', 'overdue')
                GROUP BY assigned_employee_id
            ) tsk ON e.id = tsk.assigned_employee_id
            LEFT JOIN (
                SELECT el1.*
                FROM employee_locations el1
                INNER JOIN (
                    SELECT employee_id, MAX(id) as max_id
                    FROM employee_locations
                    GROUP BY employee_id
                ) el2 ON el1.id = el2.max_id
            ) l ON e.id = l.employee_id
            {$whereClause}
            ORDER BY u.full_name ASC
        ";

        $stmt = $this->db->prepare($sql);
        $stmt->execute($bindings);
        $employees = $stmt->fetchAll();

        $this->json(['employees' => $employees], 200, 'Employees loaded');
    }

    public function show(array $params, ?array $user): void {
        $id = (int)($params['id'] ?? 0);

        $stmt = $this->db->prepare("
            SELECT 
                e.*,
                u.email, u.username, u.full_name, u.phone, u.avatar_url, u.is_active, u.last_login_at
            FROM employees e
            JOIN users u ON e.user_id = u.id
            WHERE e.id = ?
        ");
        $stmt->execute([$id]);
        $employee = $stmt->fetch();

        if (!$employee) {
            $this->error('Employee not found', 404);
        }

        // Active Tasks
        $taskStmt = $this->db->prepare("
            SELECT t.*, c.business_name, c.contact_person, c.phone as customer_phone, c.city
            FROM collection_tasks t
            JOIN customers c ON t.customer_id = c.id
            WHERE t.assigned_employee_id = ?
            ORDER BY t.due_date ASC
            LIMIT 15
        ");
        $taskStmt->execute([$id]);
        $employee['tasks'] = $taskStmt->fetchAll();

        // Recent Transactions
        $txStmt = $this->db->prepare("
            SELECT t.*, c.business_name
            FROM collection_transactions t
            JOIN customers c ON t.customer_id = c.id
            WHERE t.employee_id = ?
            ORDER BY t.collected_at DESC
            LIMIT 10
        ");
        $txStmt->execute([$id]);
        $employee['transactions'] = $txStmt->fetchAll();

        $this->json(['employee' => $employee], 200, 'Employee profile loaded');
    }

    public function updateStatus(array $params, ?array $user): void {
        $employeeId = $user['employee_id'] ?? null;
        if (!$employeeId) {
            $this->error('Employee record not found.', 404);
        }

        $body = $this->getBody();
        $status = $body['status'] ?? null;
        $battery = isset($body['battery_level']) ? (int)$body['battery_level'] : null;

        $fields = [];
        $values = [];

        if ($status && in_array($status, ['offline', 'online', 'in_field', 'on_break'])) {
            $fields[] = 'current_status = ?';
            $values[] = $status;
        }

        if ($battery !== null) {
            $fields[] = 'battery_level = ?';
            $values[] = $battery;
        }

        if (!empty($fields)) {
            $values[] = $employeeId;
            $sql = "UPDATE employees SET " . implode(', ', $fields) . ", updated_at = NOW() WHERE id = ?";
            $this->db->prepare($sql)->execute($values);
        }

        $this->json(null, 200, 'Status updated');
    }
}
