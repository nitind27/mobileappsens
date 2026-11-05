<?php
declare(strict_types=1);

namespace FieldPilot\Controllers;

use PDO;

class DashboardController extends BaseController {
    public function getAdminStats(array $params, ?array $user): void {
        $today = date('Y-m-d');
        $startOfMonth = date('Y-m-01');

        // Total and active employees
        $empCounts = $this->db->query("
            SELECT 
                COUNT(*) as total_employees,
                SUM(CASE WHEN current_status IN ('online', 'in_field') THEN 1 ELSE 0 END) as active_employees,
                SUM(CASE WHEN current_status = 'in_field' THEN 1 ELSE 0 END) as on_field_employees
            FROM employees
        ")->fetch();

        // Collections: Today, Monthly, Total
        $todayCollection = $this->db->query("
            SELECT COALESCE(SUM(amount_collected), 0) as total_today
            FROM collection_transactions
            WHERE DATE(collected_at) = '{$today}' AND payment_status != 'rejected'
        ")->fetch()['total_today'];

        $monthlyCollection = $this->db->query("
            SELECT COALESCE(SUM(amount_collected), 0) as total_month
            FROM collection_transactions
            WHERE DATE(collected_at) >= '{$startOfMonth}' AND payment_status != 'rejected'
        ")->fetch()['total_month'];

        // Targets and Pending Collection
        $taskSummary = $this->db->query("
            SELECT 
                COALESCE(SUM(target_amount), 0) as total_target,
                COALESCE(SUM(collected_amount), 0) as total_collected,
                COALESCE(SUM(pending_amount), 0) as total_pending,
                COUNT(*) as total_tasks,
                SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_tasks,
                SUM(CASE WHEN status = 'in_progress' THEN 1 ELSE 0 END) as in_progress_tasks,
                SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending_tasks,
                SUM(CASE WHEN status = 'overdue' THEN 1 ELSE 0 END) as overdue_tasks
            FROM collection_tasks
        ")->fetch();

        $totalTarget = (float)$taskSummary['total_target'];
        $totalCollected = (float)$taskSummary['total_collected'];
        $achievementPercent = $totalTarget > 0 ? round(($totalCollected / $totalTarget) * 100, 1) : 0;

        // Payment Methods Breakdown
        $paymentMethods = $this->db->query("
            SELECT payment_method, COALESCE(SUM(amount_collected), 0) as total_amount, COUNT(*) as tx_count
            FROM collection_transactions
            WHERE payment_status != 'rejected'
            GROUP BY payment_method
        ")->fetchAll();

        // Employee Rankings
        $rankings = $this->db->query("
            SELECT 
                e.id, e.employee_code, e.current_status, e.daily_target,
                u.full_name, u.avatar_url,
                COALESCE(SUM(t.amount_collected), 0) as total_collected,
                COUNT(t.id) as transactions_count
            FROM employees e
            JOIN users u ON e.user_id = u.id
            LEFT JOIN collection_transactions t ON e.id = t.employee_id AND t.payment_status != 'rejected'
            GROUP BY e.id, u.id
            ORDER BY total_collected DESC
            LIMIT 5
        ")->fetchAll();

        // Recent 5 Transactions
        $recentTransactions = $this->db->query("
            SELECT 
                t.id, t.transaction_code, t.amount_collected, t.payment_method, 
                t.payment_status, t.collected_at,
                c.business_name as customer_name,
                u.full_name as employee_name
            FROM collection_transactions t
            JOIN customers c ON t.customer_id = c.id
            JOIN employees e ON t.employee_id = e.id
            JOIN users u ON e.user_id = u.id
            ORDER BY t.collected_at DESC
            LIMIT 5
        ")->fetchAll();

        // Active Employee Locations on Field
        $activeEmployees = $this->db->query("
            SELECT 
                e.id as employee_id, e.employee_code, e.current_status, e.is_tracking_enabled, e.battery_level,
                u.full_name, u.phone, u.avatar_url,
                l.latitude, l.longitude, l.speed, l.accuracy, l.recorded_at
            FROM employees e
            JOIN users u ON e.user_id = u.id
            LEFT JOIN (
                SELECT el1.*
                FROM employee_locations el1
                INNER JOIN (
                    SELECT employee_id, MAX(id) as max_id
                    FROM employee_locations
                    GROUP BY employee_id
                ) el2 ON el1.id = el2.max_id
            ) l ON e.id = l.employee_id
            WHERE e.current_status IN ('online', 'in_field')
        ")->fetchAll();

        $this->json([
            'summary' => [
                'total_employees' => (int)$empCounts['total_employees'],
                'active_employees' => (int)$empCounts['active_employees'],
                'on_field_employees' => (int)$empCounts['on_field_employees'],
                'today_collection' => (float)$todayCollection,
                'monthly_collection' => (float)$monthlyCollection,
                'total_pending' => (float)$taskSummary['total_pending'],
                'total_target' => $totalTarget,
                'total_collected' => $totalCollected,
                'achievement_percent' => $achievementPercent,
                'tasks_count' => [
                    'total' => (int)$taskSummary['total_tasks'],
                    'completed' => (int)$taskSummary['completed_tasks'],
                    'in_progress' => (int)$taskSummary['in_progress_tasks'],
                    'pending' => (int)$taskSummary['pending_tasks'],
                    'overdue' => (int)$taskSummary['overdue_tasks']
                ]
            ],
            'payment_methods' => $paymentMethods,
            'rankings' => $rankings,
            'recent_transactions' => $recentTransactions,
            'active_field_map' => $activeEmployees
        ], 200, 'Admin dashboard data loaded');
    }

    public function getEmployeeStats(array $params, ?array $user): void {
        $employeeId = $user['employee_id'] ?? null;
        if (!$employeeId) {
            $this->error('Employee record not found for this user.', 404);
        }

        $today = date('Y-m-d');

        // Employee daily target
        $emp = $this->db->query("SELECT * FROM employees WHERE id = {$employeeId}")->fetch();
        $dailyTarget = (float)($emp['daily_target'] ?? 25000);

        // Today's collection
        $todayCollection = $this->db->query("
            SELECT COALESCE(SUM(amount_collected), 0) as total_today
            FROM collection_transactions
            WHERE employee_id = {$employeeId} AND DATE(collected_at) = '{$today}' AND payment_status != 'rejected'
        ")->fetch()['total_today'];

        $pendingAmount = max(0, $dailyTarget - (float)$todayCollection);
        $completionRate = $dailyTarget > 0 ? round(((float)$todayCollection / $dailyTarget) * 100, 1) : 0;

        // Today's attendance
        $attendance = $this->db->query("
            SELECT * FROM attendance
            WHERE employee_id = {$employeeId} AND date = '{$today}'
            LIMIT 1
        ")->fetch();

        // Assigned Tasks counts
        $taskCounts = $this->db->query("
            SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed,
                SUM(CASE WHEN status = 'in_progress' THEN 1 ELSE 0 END) as in_progress,
                SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending,
                SUM(CASE WHEN status = 'overdue' THEN 1 ELSE 0 END) as overdue
            FROM collection_tasks
            WHERE assigned_employee_id = {$employeeId}
        ")->fetch();

        // Today's Visit Schedule
        $todayVisits = $this->db->query("
            SELECT 
                t.id as task_id, t.task_code, t.title, t.target_amount, t.collected_amount, 
                t.pending_amount, t.priority, t.status, t.due_date,
                c.id as customer_id, c.business_name, c.contact_person, c.phone, 
                c.address, c.city, c.latitude, c.longitude
            FROM collection_tasks t
            JOIN customers c ON t.customer_id = c.id
            WHERE t.assigned_employee_id = {$employeeId} 
              AND (t.expected_visit_date = '{$today}' OR t.status IN ('pending', 'in_progress'))
            ORDER BY FIELD(t.priority, 'urgent', 'high', 'medium', 'low'), t.due_date ASC
            LIMIT 10
        ")->fetchAll();

        // Location sharing session status
        $sharingSession = $this->db->query("
            SELECT * FROM location_sharing_sessions
            WHERE employee_id = {$employeeId} AND status = 'active'
            ORDER BY id DESC LIMIT 1
        ")->fetch();

        $this->json([
            'metrics' => [
                'daily_target' => $dailyTarget,
                'today_collected' => (float)$todayCollection,
                'today_pending' => $pendingAmount,
                'completion_rate' => $completionRate,
                'current_status' => $emp['current_status'],
                'is_tracking_enabled' => (bool)$emp['is_tracking_enabled'],
                'battery_level' => $emp['battery_level']
            ],
            'attendance' => $attendance ?: null,
            'location_session' => $sharingSession ?: null,
            'task_counts' => [
                'total' => (int)$taskCounts['total'],
                'completed' => (int)$taskCounts['completed'],
                'in_progress' => (int)$taskCounts['in_progress'],
                'pending' => (int)$taskCounts['pending'],
                'overdue' => (int)$taskCounts['overdue']
            ],
            'today_visits' => $todayVisits
        ], 200, 'Employee dashboard data loaded');
    }
}
