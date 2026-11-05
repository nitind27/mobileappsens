<?php
declare(strict_types=1);

namespace FieldPilot\Controllers;

use FieldPilot\Services\AuditLogger;
use PDO;

class TaskController extends BaseController {
    public function index(array $params, ?array $user): void {
        $employeeId = $this->getQuery('employee_id');
        $status = $this->getQuery('status');
        $priority = $this->getQuery('priority');
        $search = $this->getQuery('search');

        // If user is employee, automatically lock to their employee_id
        if ($user['role_name'] === 'employee') {
            $employeeId = $user['employee_id'];
        }

        $conditions = [];
        $bindings = [];

        if (!empty($employeeId)) {
            $conditions[] = 't.assigned_employee_id = ?';
            $bindings[] = (int)$employeeId;
        }

        if (!empty($status)) {
            $conditions[] = 't.status = ?';
            $bindings[] = $status;
        }

        if (!empty($priority)) {
            $conditions[] = 't.priority = ?';
            $bindings[] = $priority;
        }

        if (!empty($search)) {
            $conditions[] = '(t.title LIKE ? OR t.task_code LIKE ? OR c.business_name LIKE ? OR c.contact_person LIKE ?)';
            $term = '%' . $search . '%';
            $bindings = array_merge($bindings, [$term, $term, $term, $term]);
        }

        $whereClause = !empty($conditions) ? 'WHERE ' . implode(' AND ', $conditions) : '';

        $sql = "
            SELECT 
                t.*,
                c.customer_code, c.business_name, c.contact_person, c.phone as customer_phone,
                c.address as customer_address, c.city as customer_city, 
                c.latitude as customer_lat, c.longitude as customer_lng,
                c.outstanding_amount as customer_outstanding,
                u.full_name as assigned_employee_name,
                creator.full_name as created_by_name
            FROM collection_tasks t
            JOIN customers c ON t.customer_id = c.id
            JOIN employees e ON t.assigned_employee_id = e.id
            JOIN users u ON e.user_id = u.id
            JOIN users creator ON t.assigned_by_user_id = creator.id
            {$whereClause}
            ORDER BY FIELD(t.priority, 'urgent', 'high', 'medium', 'low'), t.due_date ASC
        ";

        $stmt = $this->db->prepare($sql);
        $stmt->execute($bindings);
        $tasks = $stmt->fetchAll();

        $this->json(['tasks' => $tasks], 200, 'Tasks retrieved successfully');
    }

    public function show(array $params, ?array $user): void {
        $id = (int)($params['id'] ?? 0);

        $stmt = $this->db->prepare("
            SELECT 
                t.*,
                c.customer_code, c.business_name, c.contact_person, c.phone as customer_phone,
                c.email as customer_email, c.address as customer_address, c.city as customer_city,
                c.latitude as customer_lat, c.longitude as customer_lng, c.outstanding_amount as customer_outstanding,
                u.full_name as assigned_employee_name, u.phone as assigned_employee_phone,
                creator.full_name as created_by_name
            FROM collection_tasks t
            JOIN customers c ON t.customer_id = c.id
            JOIN employees e ON t.assigned_employee_id = e.id
            JOIN users u ON e.user_id = u.id
            JOIN users creator ON t.assigned_by_user_id = creator.id
            WHERE t.id = ?
        ");
        $stmt->execute([$id]);
        $task = $stmt->fetch();

        if (!$task) {
            $this->error('Task not found.', 404);
        }

        // Fetch associated transactions
        $txStmt = $this->db->prepare("
            SELECT t.*, u.full_name as verified_by_name
            FROM collection_transactions t
            LEFT JOIN users u ON t.verified_by_user_id = u.id
            WHERE t.task_id = ?
            ORDER BY t.collected_at DESC
        ");
        $txStmt->execute([$id]);
        $task['transactions'] = $txStmt->fetchAll();

        // Fetch visits
        $visitStmt = $this->db->prepare("
            SELECT * FROM customer_visits WHERE task_id = ? ORDER BY check_in_time DESC
        ");
        $visitStmt->execute([$id]);
        $task['visits'] = $visitStmt->fetchAll();

        $this->json(['task' => $task], 200, 'Task details loaded');
    }

    public function create(array $params, ?array $user): void {
        $body = $this->getBody();
        $errors = $this->validate($body, [
            'title' => 'required',
            'customer_id' => 'required|numeric',
            'assigned_employee_id' => 'required|numeric',
            'target_amount' => 'required|numeric',
            'due_date' => 'required',
            'expected_visit_date' => 'required'
        ]);

        if ($errors) {
            $this->error('Validation error', 422, $errors);
        }

        $taskCode = 'TASK-' . date('Ymd') . '-' . strtoupper(substr(uniqid(), -4));
        $targetAmount = (float)$body['target_amount'];
        $priority = $body['priority'] ?? 'medium';
        $instructions = $body['additional_instructions'] ?? '';

        $stmt = $this->db->prepare("
            INSERT INTO collection_tasks 
            (task_code, title, customer_id, assigned_employee_id, assigned_by_user_id, 
             target_amount, collected_amount, pending_amount, due_date, expected_visit_date, 
             priority, status, additional_instructions, completion_percentage, created_at)
            VALUES (?, ?, ?, ?, ?, ?, 0.00, ?, ?, ?, ?, 'pending', ?, 0.00, NOW())
        ");

        $stmt->execute([
            $taskCode,
            trim($body['title']),
            (int)$body['customer_id'],
            (int)$body['assigned_employee_id'],
            (int)$user['id'],
            $targetAmount,
            $targetAmount, // initial pending amount = target amount
            $body['due_date'],
            $body['expected_visit_date'],
            $priority,
            $instructions
        ]);

        $taskId = (int)$this->db->lastInsertId();

        // Send In-app Notification to assigned employee
        $empUserStmt = $this->db->prepare("SELECT user_id FROM employees WHERE id = ?");
        $empUserStmt->execute([(int)$body['assigned_employee_id']]);
        $empUserId = $empUserStmt->fetchColumn();

        if ($empUserId) {
            $notifStmt = $this->db->prepare("
                INSERT INTO notifications (user_id, title, body, notification_type, data_payload, is_read, created_at)
                VALUES (?, ?, ?, 'task_assigned', ?, 0, NOW())
            ");
            $notifStmt->execute([
                $empUserId,
                'New Field Collection Task Assigned',
                "Task {$taskCode}: {$body['title']} for ₹" . number_format($targetAmount, 2),
                json_encode(['task_id' => $taskId])
            ]);
        }

        AuditLogger::log((int)$user['id'], 'TASK_CREATED', 'collection_tasks', $taskId, null, $body);

        $this->json(['task_id' => $taskId, 'task_code' => $taskCode], 201, 'Task created successfully');
    }

    public function update(array $params, ?array $user): void {
        $id = (int)($params['id'] ?? 0);
        $body = $this->getBody();

        $stmt = $this->db->prepare("SELECT * FROM collection_tasks WHERE id = ?");
        $stmt->execute([$id]);
        $existing = $stmt->fetch();

        if (!$existing) {
            $this->error('Task not found', 404);
        }

        $fields = [];
        $values = [];

        if (isset($body['title'])) {
            $fields[] = 'title = ?';
            $values[] = trim($body['title']);
        }
        if (isset($body['priority'])) {
            $fields[] = 'priority = ?';
            $values[] = $body['priority'];
        }
        if (isset($body['status'])) {
            $fields[] = 'status = ?';
            $values[] = $body['status'];
            if ($body['status'] === 'completed') {
                $fields[] = 'completed_at = NOW()';
            }
        }
        if (isset($body['due_date'])) {
            $fields[] = 'due_date = ?';
            $values[] = $body['due_date'];
        }
        if (isset($body['expected_visit_date'])) {
            $fields[] = 'expected_visit_date = ?';
            $values[] = $body['expected_visit_date'];
        }
        if (isset($body['assigned_employee_id'])) {
            $fields[] = 'assigned_employee_id = ?';
            $values[] = (int)$body['assigned_employee_id'];
        }
        if (isset($body['additional_instructions'])) {
            $fields[] = 'additional_instructions = ?';
            $values[] = $body['additional_instructions'];
        }

        if (empty($fields)) {
            $this->error('No changes provided', 400);
        }

        $values[] = $id;
        $sql = "UPDATE collection_tasks SET " . implode(', ', $fields) . ", updated_at = NOW() WHERE id = ?";
        $this->db->prepare($sql)->execute($values);

        AuditLogger::log((int)$user['id'], 'TASK_UPDATED', 'collection_tasks', $id, $existing, $body);

        $this->json(null, 200, 'Task updated successfully');
    }

    public function delete(array $params, ?array $user): void {
        $id = (int)($params['id'] ?? 0);
        $stmt = $this->db->prepare("DELETE FROM collection_tasks WHERE id = ?");
        $stmt->execute([$id]);

        AuditLogger::log((int)$user['id'], 'TASK_DELETED', 'collection_tasks', $id);
        $this->json(null, 200, 'Task deleted successfully');
    }
}
