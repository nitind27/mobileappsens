<?php
declare(strict_types=1);

namespace FieldPilot\Services;

use FieldPilot\Config\Database;
use PDO;

class AuditLogger {
    public static function log(?int $userId, string $action, string $entityType, ?int $entityId = null, ?array $oldValues = null, ?array $newValues = null): void {
        try {
            $db = Database::getConnection();
            $stmt = $db->prepare("
                INSERT INTO `audit_logs` 
                (`user_id`, `action`, `entity_type`, `entity_id`, `ip_address`, `user_agent`, `old_values`, `new_values`, `created_at`) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())
            ");

            $ip = $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';
            $ua = substr($_SERVER['HTTP_USER_AGENT'] ?? 'FieldPilot Client', 0, 255);
            $oldJson = $oldValues ? json_encode($oldValues) : null;
            $newJson = $newValues ? json_encode($newValues) : null;

            $stmt->execute([$userId, $action, $entityType, $entityId, $ip, $ua, $oldJson, $newJson]);
        } catch (\Throwable $e) {
            // Fail gracefully so logging errors don't interrupt primary transactions
            error_log('Audit log failure: ' . $e->getMessage());
        }
    }
}
