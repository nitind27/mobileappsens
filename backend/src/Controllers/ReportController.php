<?php
declare(strict_types=1);

namespace FieldPilot\Controllers;

use PDO;

class ReportController extends BaseController {
    public function getCollectionReport(array $params, ?array $user): void {
        $startDate = $this->getQuery('start_date', date('Y-m-01'));
        $endDate = $this->getQuery('end_date', date('Y-m-d'));

        // Group by day
        $stmt = $this->db->prepare("
            SELECT 
                DATE(collected_at) as collection_date,
                COUNT(*) as transaction_count,
                SUM(CASE WHEN payment_method = 'cash' THEN amount_collected ELSE 0 END) as cash_total,
                SUM(CASE WHEN payment_method = 'upi' THEN amount_collected ELSE 0 END) as upi_total,
                SUM(CASE WHEN payment_method = 'cheque' THEN amount_collected ELSE 0 END) as cheque_total,
                SUM(CASE WHEN payment_method = 'bank_transfer' THEN amount_collected ELSE 0 END) as transfer_total,
                SUM(amount_collected) as daily_total
            FROM collection_transactions
            WHERE DATE(collected_at) BETWEEN ? AND ? AND payment_status != 'rejected'
            GROUP BY DATE(collected_at)
            ORDER BY collection_date ASC
        ");
        $stmt->execute([$startDate, $endDate]);
        $dailyTrends = $stmt->fetchAll();

        // Totals
        $totStmt = $this->db->prepare("
            SELECT 
                COALESCE(SUM(amount_collected), 0) as total_amount,
                COUNT(*) as total_transactions,
                COALESCE(AVG(amount_collected), 0) as average_ticket_size
            FROM collection_transactions
            WHERE DATE(collected_at) BETWEEN ? AND ? AND payment_status != 'rejected'
        ");
        $totStmt->execute([$startDate, $endDate]);
        $totals = $totStmt->fetch();

        $this->json([
            'start_date' => $startDate,
            'end_date' => $endDate,
            'totals' => $totals,
            'trends' => $dailyTrends
        ], 200, 'Collection report generated');
    }

    public function getAuditLogs(array $params, ?array $user): void {
        $limit = min(100, max(1, (int)$this->getQuery('limit', 50)));

        $stmt = $this->db->prepare("
            SELECT a.*, u.full_name as user_name, u.email as user_email
            FROM audit_logs a
            LEFT JOIN users u ON a.user_id = u.id
            ORDER BY a.created_at DESC
            LIMIT ?
        ");
        $stmt->bindValue(1, $limit, PDO::PARAM_INT);
        $stmt->execute();
        $logs = $stmt->fetchAll();

        $this->json(['audit_logs' => $logs], 200, 'Audit logs retrieved');
    }
}
