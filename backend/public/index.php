<?php
declare(strict_types=1);

// Error reporting for development
ini_set('display_errors', '0');
error_reporting(E_ALL);

// Autoloader for FieldPilot namespace
spl_autoload_register(function ($class) {
    $prefix = 'FieldPilot\\';
    $baseDir = dirname(__DIR__) . '/src/';

    $len = strlen($prefix);
    if (strncmp($prefix, $class, $len) !== 0) {
        return;
    }

    $relativeClass = substr($class, $len);
    // Special handling for Config
    if (strpos($relativeClass, 'Config\\') === 0) {
        $file = dirname(__DIR__) . '/config/' . str_replace('\\', '/', substr($relativeClass, 7)) . '.php';
    } else {
        $file = $baseDir . str_replace('\\', '/', $relativeClass) . '.php';
    }

    if (file_exists($file)) {
        require $file;
    }
});

use FieldPilot\Router;
use FieldPilot\Middleware\CorsMiddleware;
use FieldPilot\Middleware\AuthMiddleware;
use FieldPilot\Controllers\AuthController;
use FieldPilot\Controllers\DashboardController;
use FieldPilot\Controllers\TaskController;
use FieldPilot\Controllers\TransactionController;
use FieldPilot\Controllers\AttendanceController;
use FieldPilot\Controllers\LocationController;
use FieldPilot\Controllers\CustomerController;
use FieldPilot\Controllers\EmployeeController;
use FieldPilot\Controllers\CommunicationController;
use FieldPilot\Controllers\ReportController;

// Handle CORS & Preflight requests
CorsMiddleware::handle();

$router = new Router();

// Auth Middleware Callables
$authAny = fn() => AuthMiddleware::authenticate();
$authAdmin = fn() => AuthMiddleware::authenticate('admin');
$authEmployee = fn() => AuthMiddleware::authenticate('employee');

// ----------------------------------------------------------------------------
// Health Check / System Status
// ----------------------------------------------------------------------------
$router->get('/api/health', function() {
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'app' => 'FieldPilot API',
        'status' => 'operational',
        'timestamp' => date('Y-m-d H:i:s'),
        'version' => '1.0.0'
    ]);
});

// ----------------------------------------------------------------------------
// Authentication Routes
// ----------------------------------------------------------------------------
$router->post('/api/auth/login', [AuthController::class, 'login']);
$router->get('/api/auth/me', [AuthController::class, 'me'], [$authAny]);
$router->post('/api/auth/update-profile', [AuthController::class, 'updateProfile'], [$authAny]);
$router->post('/api/auth/logout', [AuthController::class, 'logout'], [$authAny]);

// ----------------------------------------------------------------------------
// Dashboard Routes
// ----------------------------------------------------------------------------
$router->get('/api/dashboard/admin', [DashboardController::class, 'getAdminStats'], [$authAdmin]);
$router->get('/api/dashboard/employee', [DashboardController::class, 'getEmployeeStats'], [$authEmployee]);

// ----------------------------------------------------------------------------
// Task Management Routes
// ----------------------------------------------------------------------------
$router->get('/api/tasks', [TaskController::class, 'index'], [$authAny]);
$router->get('/api/tasks/{id}', [TaskController::class, 'show'], [$authAny]);
$router->post('/api/tasks', [TaskController::class, 'create'], [$authAdmin]);
$router->put('/api/tasks/{id}', [TaskController::class, 'update'], [$authAny]);
$router->delete('/api/tasks/{id}', [TaskController::class, 'delete'], [$authAdmin]);

// ----------------------------------------------------------------------------
// Collection & Transaction Routes
// ----------------------------------------------------------------------------
$router->get('/api/transactions', [TransactionController::class, 'index'], [$authAny]);
$router->post('/api/transactions', [TransactionController::class, 'recordPayment'], [$authAny]);
$router->post('/api/transactions/{id}/verify', [TransactionController::class, 'verifyPayment'], [$authAdmin]);

// ----------------------------------------------------------------------------
// Attendance Routes
// ----------------------------------------------------------------------------
$router->post('/api/attendance/check-in', [AttendanceController::class, 'checkIn'], [$authEmployee]);
$router->post('/api/attendance/check-out', [AttendanceController::class, 'checkOut'], [$authEmployee]);
$router->get('/api/attendance/history', [AttendanceController::class, 'getHistory'], [$authAny]);

// ----------------------------------------------------------------------------
// Live Location & Tracking Routes
// ----------------------------------------------------------------------------
$router->post('/api/location/session/start', [LocationController::class, 'startSession'], [$authEmployee]);
$router->post('/api/location/session/stop', [LocationController::class, 'stopSession'], [$authEmployee]);
$router->post('/api/location/ping', [LocationController::class, 'recordPing'], [$authEmployee]);
$router->get('/api/location/live-employees', [LocationController::class, 'getLiveEmployees'], [$authAdmin]);
$router->get('/api/location/history/{id}', [LocationController::class, 'getHistory'], [$authAny]);

// ----------------------------------------------------------------------------
// Customer Routes
// ----------------------------------------------------------------------------
$router->get('/api/customers', [CustomerController::class, 'index'], [$authAny]);
$router->get('/api/customers/{id}', [CustomerController::class, 'show'], [$authAny]);
$router->post('/api/customers', [CustomerController::class, 'create'], [$authAny]);
$router->post('/api/customers/visit', [CustomerController::class, 'recordVisit'], [$authEmployee]);

// ----------------------------------------------------------------------------
// Employee Management Routes
// ----------------------------------------------------------------------------
$router->get('/api/employees', [EmployeeController::class, 'index'], [$authAdmin]);
$router->get('/api/employees/{id}', [EmployeeController::class, 'show'], [$authAny]);
$router->post('/api/employees/status', [EmployeeController::class, 'updateStatus'], [$authEmployee]);

// ----------------------------------------------------------------------------
// Communication Routes (Chat, Audio Notes, Calling)
// ----------------------------------------------------------------------------
$router->get('/api/chat/{user_id}', [CommunicationController::class, 'getMessages'], [$authAny]);
$router->post('/api/chat/send', [CommunicationController::class, 'sendMessage'], [$authAny]);
$router->post('/api/calls/initiate', [CommunicationController::class, 'initiateCall'], [$authAny]);
$router->post('/api/calls/{id}/respond', [CommunicationController::class, 'respondCall'], [$authAny]);

// ----------------------------------------------------------------------------
// Reports & Audit Routes
// ----------------------------------------------------------------------------
$router->get('/api/reports/collections', [ReportController::class, 'getCollectionReport'], [$authAdmin]);
$router->get('/api/reports/audit-logs', [ReportController::class, 'getAuditLogs'], [$authAdmin]);

// Dispatch incoming request
$router->dispatch();
