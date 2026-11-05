<?php
declare(strict_types=1);

namespace FieldPilot\Controllers;

use FieldPilot\Services\FileUploadService;
use FieldPilot\Services\AuditLogger;
use PDO;
use Exception;

class TransactionController extends BaseController {
    public function index(array $params, ?array $user): void {
        $status = $this->getQuery('status');
        $employeeId = $this->getQuery('employee_id');
        $taskId = $this->getQuery('task_id');

        if ($user['role_name'] === 'employee') {
            $employeeId = $user['employee_id'];
        }

        $conditions = [];
        $bindings = [];

        if (!empty($status)) {
            $conditions[] = 't.payment_status = ?';
            $bindings[] = $status;
        }

        if (!empty($employeeId)) {
            $conditions[] = 't.employee_id = ?';
            $bindings[] = (int)$employeeId;
        }

        if (!empty($taskId)) {
            $conditions[] = 't.task_id = ?';
            $bindings[] = (int)$taskId;
        }

        $whereClause = !empty($conditions) ? 'WHERE ' . implode(' AND ', $conditions) : '';

        $sql = "
            SELECT 
                t.*,
                tsk.title as task_title, tsk.task_code,
                c.business_name as customer_name, c.phone as customer_phone, c.city as customer_city,
                u.full_name as employee_name,
                v.full_name as verified_by_name
            FROM collection_transactions t
            JOIN collection_tasks tsk ON t.task_id = tsk.id
            JOIN customers c ON t.customer_id = c.id
            JOIN employees e ON t.employee_id = e.id
            JOIN users u ON e.user_id = u.id
            LEFT JOIN users v ON t.verified_by_user_id = v.id
            {$whereClause}
            ORDER BY t.collected_at DESC
        ";

        $stmt = $this->db->prepare($sql);
        $stmt->execute($bindings);
        $transactions = $stmt->fetchAll();

        $this->json(['transactions' => $transactions], 200, 'Transactions loaded');
    }

    public function recordPayment(array $params, ?array $user): void {
        $body = $this->getBody();
        $errors = $this->validate($body, [
            'task_id' => 'required|numeric',
            'amount_collected' => 'required|numeric',
            'payment_method' => 'required'
        ]);

        if ($errors) {
            $this->error('Validation error', 422, $errors);
        }

        $taskId = (int)$body['task_id'];
        $amount = (float)$body['amount_collected'];
        $paymentMethod = $body['payment_method'];
        $txRef = $body['transaction_reference'] ?? null;
        $remarks = $body['customer_remarks'] ?? null;
        $latitude = isset($body['latitude']) ? (float)$body['latitude'] : null;
        $longitude = isset($body['longitude']) ? (float)$body['longitude'] : null;

        // Fetch task & customer
        $taskStmt = $this->db->prepare("SELECT * FROM collection_tasks WHERE id = ?");
        $taskStmt->execute([$taskId]);
        $task = $taskStmt->fetch();

        if (!$task) {
            $this->error('Collection task not found', 404);
        }

        $employeeId = $user['employee_id'] ?? (int)($body['employee_id'] ?? $task['assigned_employee_id']);
        $customerId = (int)$task['customer_id'];

        // Handle uploaded receipt file or base64
        $receiptUrl = null;
        if (isset($_FILES['receipt']) && $_FILES['receipt']['error'] === UPLOAD_ERR_OK) {
            try {
                $uploadResult = FileUploadService::handleUpload($_FILES['receipt'], 'receipts');
                $receiptUrl = $uploadResult['relative_path'];
            } catch (Exception $e) {
                $this->error('Receipt upload failed: ' . $e->getMessage(), 400);
            }
        } elseif (!empty($body['receipt_base64'])) {
            try {
                $uploadResult = FileUploadService::handleBase64Upload($body['receipt_base64'], 'receipts', 'jpg');
                $receiptUrl = $uploadResult['relative_path'];
            } catch (Exception $e) {
                $this->error('Receipt processing failed: ' . $e->getMessage(), 400);
            }
        } elseif (!empty($body['receipt_photo_url'])) {
            $receiptUrl = $body['receipt_photo_url'];
        }

        // Handle customer digital signature
        $signatureUrl = null;
        if (isset($_FILES['signature']) && $_FILES['signature']['error'] === UPLOAD_ERR_OK) {
            try {
                $signResult = FileUploadService::handleUpload($_FILES['signature'], 'signatures');
                $signatureUrl = $signResult['relative_path'];
            } catch (Exception $e) {
                $this->error('Signature upload failed: ' . $e->getMessage(), 400);
            }
        } elseif (!empty($body['signature_base64'])) {
            try {
                $signResult = FileUploadService::handleBase64Upload($body['signature_base64'], 'signatures', 'png');
                $signatureUrl = $signResult['relative_path'];
            } catch (Exception $e) {
                $this->error('Signature processing failed: ' . $e->getMessage(), 400);
            }
        } elseif (!empty($body['signature_url'])) {
            $signatureUrl = $body['signature_url'];
        }

        $txCode = 'TXN-' . date('ymd') . '-' . strtoupper(substr(uniqid(), -4));

        $this->db->beginTransaction();

        try {
            // Insert transaction
            $txInsert = $this->db->prepare("
                INSERT INTO collection_transactions 
                (transaction_code, task_id, customer_id, employee_id, amount_collected, 
                 payment_method, transaction_reference, receipt_photo_url, signature_url, 
                 payment_status, customer_remarks, latitude, longitude, collected_at, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending_verification', ?, ?, ?, NOW(), NOW())
            ");
            $txInsert->execute([
                $txCode,
                $taskId,
                $customerId,
                $employeeId,
                $amount,
                $paymentMethod,
                $txRef,
                $receiptUrl,
                $signatureUrl,
                $remarks,
                $latitude,
                $longitude
            ]);

            $txId = (int)$this->db->lastInsertId();

            // Calculate updated collection values for task
            $newCollected = (float)$task['collected_amount'] + $amount;
            $newPending = max(0.0, (float)$task['target_amount'] - $newCollected);
            $completionPercent = (float)$task['target_amount'] > 0 
                ? min(100.0, round(($newCollected / (float)$task['target_amount']) * 100, 2))
                : 100.0;
            $newStatus = $newPending <= 0 ? 'completed' : 'in_progress';
            $completedAtSql = $newStatus === 'completed' ? ', completed_at = NOW()' : '';

            $taskUpdate = $this->db->prepare("
                UPDATE collection_tasks 
                SET collected_amount = ?, pending_amount = ?, completion_percentage = ?, status = ? {$completedAtSql}, updated_at = NOW()
                WHERE id = ?
            ");
            $taskUpdate->execute([$newCollected, $newPending, $completionPercent, $newStatus, $taskId]);

            // Update customer outstanding amount
            $custUpdate = $this->db->prepare("
                UPDATE customers 
                SET outstanding_amount = GREATEST(0, outstanding_amount - ?), updated_at = NOW() 
                WHERE id = ?
            ");
            $custUpdate->execute([$amount, $customerId]);

            // Create notification for admin
            $adminNotif = $this->db->prepare("
                INSERT INTO notifications (user_id, title, body, notification_type, data_payload, is_read, created_at)
                SELECT id, 'New Collection Submitted', ?, 'general', ?, 0, NOW()
                FROM users WHERE role_id = 1
            ");
            $notifBody = "{$user['full_name']} collected ₹" . number_format($amount, 2) . " ({$paymentMethod}) for task {$task['task_code']}.";
            $adminNotif->execute([$notifBody, json_encode(['transaction_id' => $txId, 'task_id' => $taskId])]);

            $this->db->commit();

            AuditLogger::log((int)$user['id'], 'RECORD_PAYMENT', 'collection_transactions', $txId, null, [
                'amount' => $amount,
                'method' => $paymentMethod,
                'task_id' => $taskId
            ]);

            $this->json([
                'transaction_id' => $txId,
                'transaction_code' => $txCode,
                'task_updated' => [
                    'collected_amount' => $newCollected,
                    'pending_amount' => $newPending,
                    'completion_percentage' => $completionPercent,
                    'status' => $newStatus
                ]
            ], 201, 'Payment recorded and pending verification');

        } catch (Exception $e) {
            $this->db->rollBack();
            $this->error('Failed to record payment: ' . $e->getMessage(), 500);
        }
    }

    public function verifyPayment(array $params, ?array $user): void {
        $id = (int)($params['id'] ?? 0);
        $body = $this->getBody();

        $action = $body['status'] ?? 'verified'; // 'verified' or 'rejected'
        if (!in_array($action, ['verified', 'rejected'])) {
            $this->error("Invalid status. Expected 'verified' or 'rejected'.", 422);
        }

        $notes = $body['verification_notes'] ?? '';

        $stmt = $this->db->prepare("
            SELECT t.*, e.user_id as employee_user_id, tsk.task_code 
            FROM collection_transactions t
            JOIN employees e ON t.employee_id = e.id
            JOIN collection_tasks tsk ON t.task_id = tsk.id
            WHERE t.id = ?
        ");
        $stmt->execute([$id]);
        $tx = $stmt->fetch();

        if (!$tx) {
            $this->error('Transaction not found', 404);
        }

        $update = $this->db->prepare("
            UPDATE collection_transactions 
            SET payment_status = ?, verified_by_user_id = ?, verification_notes = ?, updated_at = NOW()
            WHERE id = ?
        ");
        $update->execute([$action, $user['id'], $notes, $id]);

        // Notify employee
        $notifTitle = $action === 'verified' ? 'Payment Verified & Approved' : 'Payment Verification Rejected';
        $notifBody = "Your collection of ₹" . number_format((float)$tx['amount_collected'], 2) . " for {$tx['task_code']} was marked {$action}." . ($notes ? " Note: {$notes}" : "");

        $notifStmt = $this->db->prepare("
            INSERT INTO notifications (user_id, title, body, notification_type, data_payload, is_read, created_at)
            VALUES (?, ?, ?, 'payment_verified', ?, 0, NOW())
        ");
        $notifStmt->execute([
            $tx['employee_user_id'],
            $notifTitle,
            $notifBody,
            json_encode(['transaction_id' => $id, 'status' => $action])
        ]);

        AuditLogger::log((int)$user['id'], 'VERIFY_PAYMENT', 'collection_transactions', $id, ['old_status' => $tx['payment_status']], ['new_status' => $action, 'notes' => $notes]);

        $this->json(null, 200, "Transaction marked as {$action}");
    }
}
