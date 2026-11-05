<?php
declare(strict_types=1);

namespace FieldPilot\Middleware;

class CorsMiddleware {
    public static function handle(): void {
        header("Access-Control-Allow-Origin: *");
        header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, PATCH, OPTIONS");
        header("Access-Control-Allow-Headers: Authorization, Content-Type, Accept, Origin, X-Requested-With, Cache-Control");
        header("Access-Control-Max-Age: 86400");
        header("Content-Type: application/json; charset=UTF-8");

        if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
            http_response_code(200);
            exit;
        }
    }
}
