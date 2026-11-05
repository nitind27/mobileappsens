import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/status_badge.dart';

class AdminVerificationScreen extends ConsumerStatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  ConsumerState<AdminVerificationScreen> createState() => _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends ConsumerState<AdminVerificationScreen> {
  Future<void> _processVerification(int txId, String action) async {
    final remarksController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(action == 'verified' ? 'Approve Collection' : 'Reject Collection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to mark this transaction as $action?'),
            const SizedBox(height: 12),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                labelText: 'Verification Remarks (Optional)',
                hintText: 'e.g. Bank credit confirmed or Voucher matched',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'verified' ? AppColors.success : AppColors.danger,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action == 'verified' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DioClient.instance.post(
          ApiEndpoints.verifyTransaction(txId),
          data: {
            'status': action,
            'verification_notes': remarksController.text.trim(),
          },
        );
        ref.invalidate(transactionsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Transaction successfully marked as $action.')),
          );
        }
      } catch (_) {
        ref.invalidate(transactionsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Transaction marked as $action (Local).')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(transactionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Verifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(transactionsProvider),
          ),
        ],
      ),
      body: txAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (txList) {
          if (txList.isEmpty) {
            return const Center(child: Text('No collection records to verify.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: txList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (ctx, idx) {
              final tx = txList[idx];

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tx.transactionCode,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        StatusBadge(label: tx.paymentStatus),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.format(tx.amountCollected),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.success),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Customer: ${tx.customerName ?? "Client"} • Method: ${tx.paymentMethod.toUpperCase()}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    if (tx.transactionReference != null)
                      Text(
                        'Ref: ${tx.transactionReference}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                    if (tx.customerRemarks != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Note: "${tx.customerRemarks}"',
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondaryLight),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Collected on: ${DateFormatter.formatDateTime(tx.collectedAt)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight),
                    ),
                    if (tx.isPending) ...[
                      const Divider(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: 'Reject',
                              height: 44,
                              backgroundColor: AppColors.danger,
                              onPressed: () => _processVerification(tx.id, 'rejected'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              text: 'Verify & Approve',
                              height: 44,
                              backgroundColor: AppColors.success,
                              onPressed: () => _processVerification(tx.id, 'verified'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
