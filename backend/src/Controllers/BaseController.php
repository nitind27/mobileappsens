<?php
declare(strict_types=1);

namespace FieldPilot\Controllers;

use FieldPilot\Config\Database;
use PDO;

abstract class BaseController {
    protected PDO $db;

    public function __construct() {
        $this->db = Database::getConnection();
    }

    protected function json(mixed $data, int $statusCode = 200, string $message = 'Success'): void {
        http_response_code($statusCode);
        header('Content-Type: application/json; charset=UTF-8');
        echo json_encode([
            'success' => $statusCode >= 200 && $statusCode < 300,
            'message' => $message,
            'data' => $data
        ]);
        exit;
    }

    protected function error(string $message, int $statusCode = 400, ?array $errors = null): void {
        http_response_code($statusCode);
        header('Content-Type: application/json; charset=UTF-8');
        echo json_encode([
            'success' => false,
            'message' => $message,
            'errors' => $errors
        ]);
        exit;
    }

    protected function getBody(): array {
        $contentType = $_SERVER['CONTENT_TYPE'] ?? '';
        if (str_contains($contentType, 'application/json')) {
            $input = file_get_contents('php://input');
            return json_decode($input, true) ?: [];
        }
        return $_POST;
    }

    protected function getQuery(string $key, mixed $default = null): mixed {
        return $_GET[$key] ?? $default;
    }

    protected function validate(array $data, array $rules): ?array {
        $errors = [];
        foreach ($rules as $field => $ruleString) {
            $ruleList = explode('|', $ruleString);
            $val = $data[$field] ?? null;

            foreach ($ruleList as $r) {
                if ($r === 'required' && ($val === null || $val === '')) {
                    $errors[$field] = "Field {$field} is required.";
                    break;
                }
                if ($r === 'numeric' && $val !== null && !is_numeric($val)) {
                    $errors[$field] = "Field {$field} must be numeric.";
                    break;
                }
                if ($r === 'email' && $val !== null && !filter_var($val, FILTER_VALIDATE_EMAIL)) {
                    $errors[$field] = "Field {$field} must be a valid email address.";
                    break;
                }
            }
        }
        return empty($errors) ? null : $errors;
    }
}
