<?php
declare(strict_types=1);

namespace FieldPilot\Middleware;

use FieldPilot\Config\Database;
use FieldPilot\Services\JWTService;
use PDO;

class AuthMiddleware {
    public static function authenticate(?string $requiredRole = null): array {
        $headers = getallheaders();
        $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';

        if (!$authHeader || !preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
            http_response_code(401);
            echo json_encode([
                'success' => false,
                'message' => 'Unauthorized: Missing or malformed Bearer token.'
            ]);
            exit;
        }

        $token = $matches[1];
        $payload = JWTService::validateToken($token);

        if (!$payload || !isset($payload['user_id'])) {
            http_response_code(401);
            echo json_encode([
                'success' => false,
                'message' => 'Unauthorized: Invalid or expired token.'
            ]);
            exit;
        }

        $db = Database::getConnection();
        $stmt = $db->prepare("
            SELECT u.id, u.role_id, u.email, u.username, u.full_name, u.phone, u.avatar_url, u.is_active,
                   r.name as role_name,
                   e.id as employee_id, e.employee_code, e.current_status, e.is_tracking_enabled
            FROM users u
            JOIN roles r ON u.role_id = r.id
            LEFT JOIN employees e ON u.id = e.user_id
            WHERE u.id = ? AND u.is_active = 1
        ");
        $stmt->execute([$payload['user_id']]);
        $user = $stmt->fetch();

        if (!$user) {
            http_response_code(401);
            echo json_encode([
                'success' => false,
                'message' => 'User account is inactive or not found.'
            ]);
            exit;
        }

        // Role check if specified
        if ($requiredRole !== null && $user['role_name'] !== $requiredRole && $user['role_name'] !== 'admin') {
            http_response_code(403);
            echo json_encode([
                'success' => false,
                'message' => 'Forbidden: You do not have permission to access this resource.'
            ]);
            exit;
        }

        return $user;
    }
}
