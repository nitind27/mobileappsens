<?php
declare(strict_types=1);

namespace FieldPilot\Controllers;

use FieldPilot\Services\AuditLogger;
use PDO;

class CustomerController extends BaseController {
    public function index(array $params, ?array $user): void {
        $search = $this->getQuery('search');
        $city = $this->getQuery('city');

        $conditions = [];
        $bindings = [];

        if (!empty($search)) {
            $conditions[] = '(c.business_name LIKE ? OR c.contact_person LIKE ? OR c.phone LIKE ? OR c.customer_code LIKE ?)';
            $term = '%' . $search . '%';
            $bindings = array_merge($bindings, [$term, $term, $term, $term]);
        }

        if (!empty($city)) {
            $conditions[] = 'c.city = ?';
            $bindings[] = $city;
        }

        $whereClause = !empty($conditions) ? 'WHERE ' . implode(' AND ', $conditions) : '';

        $sql = "
            SELECT 
                c.*,
                COUNT(DISTINCT t.id) as active_tasks_count,
                COALESCE(SUM(t.pending_amount), 0) as total_pending_tasks_amount
            FROM customers c
            LEFT JOIN collection_tasks t ON c.id = t.customer_id AND t.status IN ('pending', 'in_progress', 'overdue')
            {$whereClause}
            GROUP BY c.id
            ORDER BY c.outstanding_amount DESC, c.business_name ASC
        ";

        $stmt = $this->db->prepare($sql);
        $stmt->execute($bindings);
        $customers = $stmt->fetchAll();

        $this->json(['customers' => $customers], 200, 'Customers loaded');
    }

    public function show(array $params, ?array $user): void {
        $id = (int)($params['id'] ?? 0);

        $stmt = $this->db->prepare("SELECT * FROM customers WHERE id = ?");
        $stmt->execute([$id]);
        $customer = $stmt->fetch();

        if (!$customer) {
            $this->error('Customer not found', 404);
        }

        // Collection history
        $txStmt = $this->db->prepare("
            SELECT t.*, u.full_name as employee_name 
            FROM collection_transactions t
            JOIN employees e ON t.employee_id = e.id
            JOIN users u ON e.user_id = u.id
            WHERE t.customer_id = ?
            ORDER BY t.collected_at DESC
        ");
        $txStmt->execute([$id]);
        $customer['transactions'] = $txStmt->fetchAll();

        // Tasks
        $taskStmt = $this->db->prepare("
            SELECT t.*, u.full_name as employee_name
            FROM collection_tasks t
            JOIN employees e ON t.assigned_employee_id = e.id
            JOIN users u ON e.user_id = u.id
            WHERE t.customer_id = ?
            ORDER BY t.created_at DESC
        ");
        $taskStmt->execute([$id]);
        $customer['tasks'] = $taskStmt->fetchAll();

        // Visits
        $visitStmt = $this->db->prepare("
            SELECT v.*, u.full_name as employee_name 
            FROM customer_visits v
            JOIN employees e ON v.employee_id = e.id
            JOIN users u ON e.user_id = u.id
            WHERE v.customer_id = ?
            ORDER BY v.check_in_time DESC
        ");
        $visitStmt->execute([$id]);
        $customer['visits'] = $visitStmt->fetchAll();

        $this->json(['customer' => $customer], 200, 'Customer details loaded');
    }

    public function create(array $params, ?array $user): void {
        $body = $this->getBody();
        $errors = $this->validate($body, [
            'business_name' => 'required',
            'contact_person' => 'required',
            'phone' => 'required',
            'address' => 'required',
            'city' => 'required',
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric'
        ]);

        if ($errors) {
            $this->error('Validation error', 422, $errors);
        }

        $code = 'CUST-' . strtoupper(substr(uniqid(), -5));
        $outstanding = isset($body['outstanding_amount']) ? (float)$body['outstanding_amount'] : 0.0;
        $creditLimit = isset($body['credit_limit']) ? (float)$body['credit_limit'] : 100000.0;
        $risk = $body['risk_category'] ?? 'medium';

        $stmt = $this->db->prepare("
            INSERT INTO customers 
            (customer_code, business_name, contact_person, phone, email, address, city, state, postal_code, latitude, longitude, outstanding_amount, credit_limit, risk_category, notes, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
        ");
        $stmt->execute([
            $code,
            trim($body['business_name']),
            trim($body['contact_person']),
            trim($body['phone']),
            $body['email'] ?? null,
            trim($body['address']),
            trim($body['city']),
            $body['state'] ?? 'Gujarat',
            $body['postal_code'] ?? null,
            (float)$body['latitude'],
            (float)$body['longitude'],
            $outstanding,
            $creditLimit,
            $risk,
            $body['notes'] ?? null
        ]);

        $customerId = (int)$this->db->lastInsertId();
        AuditLogger::log((int)$user['id'], 'CUSTOMER_CREATED', 'customers', $customerId, null, $body);

        $this->json(['customer_id' => $customerId, 'customer_code' => $code], 201, 'Customer created successfully');
    }

    public function recordVisit(array $params, ?array $user): void {
        $body = $this->getBody();
        $errors = $this->validate($body, [
            'task_id' => 'required|numeric',
            'customer_id' => 'required|numeric',
            'check_in_lat' => 'required|numeric',
            'check_in_lng' => 'required|numeric'
        ]);

        if ($errors) {
            $this->error('Validation error', 422, $errors);
        }

        $employeeId = $user['employee_id'] ?? (int)($body['employee_id'] ?? 0);
        $taskId = (int)$body['task_id'];
        $customerId = (int)$body['customer_id'];
        $lat = (float)$body['check_in_lat'];
        $lng = (float)$body['check_in_lng'];
        $summary = $body['visit_summary'] ?? '';
        $outcome = $body['outcome'] ?? 'follow_up_needed';
        $nextFollowUp = $body['next_follow_up_date'] ?? null;

        $stmt = $this->db->prepare("
            INSERT INTO customer_visits 
            (task_id, customer_id, employee_id, check_in_time, check_in_lat, check_in_lng, check_out_time, check_out_lat, check_out_lng, visit_status, visit_summary, outcome, next_follow_up_date, created_at)
            VALUES (?, ?, ?, NOW(), ?, ?, NOW(), ?, ?, 'completed', ?, ?, ?, NOW())
        ");
        $stmt->execute([$taskId, $customerId, $employeeId, $lat, $lng, $lat, $lng, $summary, $outcome, $nextFollowUp]);

        $visitId = (int)$this->db->lastInsertId();
        AuditLogger::log((int)$user['id'], 'CUSTOMER_VISIT_RECORDED', 'customer_visits', $visitId);

        $this->json(['visit_id' => $visitId], 201, 'Visit recorded successfully');
    }
}
