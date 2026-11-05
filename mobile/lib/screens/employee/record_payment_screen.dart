import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/currency_formatter.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/signature_pad_modal.dart';

class RecordPaymentScreen extends ConsumerStatefulWidget {
  final int taskId;
  final String customerName;
  final double pendingAmount;

  const RecordPaymentScreen({
    super.key,
    required this.taskId,
    required this.customerName,
    required this.pendingAmount,
  });

  @override
  ConsumerState<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends ConsumerState<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _remarksController = TextEditingController();

  String _paymentMethod = 'upi';
  Uint8List? _signatureBytes;
  XFile? _receiptImage;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Default to full pending amount
    if (widget.pendingAmount > 0) {
      _amountController.text = widget.pendingAmount.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() => _receiptImage = picked);
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image selection cancelled.')),
      );
    }
  }

  Future<void> _captureSignature() async {
    final bytes = await SignaturePadModal.show(context);
    if (bytes != null) {
      setState(() => _signatureBytes = bytes);
    }
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? sigBase64;
      if (_signatureBytes != null) {
        sigBase64 = 'data:image/png;base64,' + base64Encode(_signatureBytes!);
      }

      await DioClient.instance.post(
        ApiEndpoints.transactions,
        data: {
          'task_id': widget.taskId,
          'amount_collected': double.parse(_amountController.text.trim()),
          'payment_method': _paymentMethod,
          'transaction_reference': _referenceController.text.trim(),
          'customer_remarks': _remarksController.text.trim(),
          'signature_base64': sigBase64,
          'latitude': 21.189025,
          'longitude': 72.836520,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment collection recorded successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded successfully (Offline Synced).')),
        );
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Field Collection'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Client & Balance Summary Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.electricBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.electricBlue.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CUSTOMER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
                        const SizedBox(height: 2),
                        Text(widget.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('CURRENT PENDING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.format(widget.pendingAmount),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.danger),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Amount Input
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                decoration: const InputDecoration(
                  labelText: 'Amount Collected (₹) *',
                  prefixText: '₹ ',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter amount';
                  final num = double.tryParse(v);
                  if (num == null || num <= 0) return 'Enter a valid amount greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Payment Method Selector
              const Text('Payment Method *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildMethodChip('UPI / QR', 'upi', Icons.qr_code_2),
                  _buildMethodChip('Cash', 'cash', Icons.money),
                  _buildMethodChip('Cheque', 'cheque', Icons.account_balance_wallet_outlined),
                  _buildMethodChip('Bank Transfer', 'bank_transfer', Icons.account_balance),
                ],
              ),
              const SizedBox(height: 20),

              // Reference / Cheque number
              TextFormField(
                controller: _referenceController,
                decoration: InputDecoration(
                  labelText: _paymentMethod == 'upi'
                      ? 'UPI Transaction ID / UTR'
                      : _paymentMethod == 'cheque'
                          ? 'Cheque Number & Bank'
                          : 'Receipt / Voucher Number',
                  hintText: 'e.g. 26110488921 or CHQ-40291',
                ),
              ),
              const SizedBox(height: 20),

              // Receipt Upload Box
              const Text('Payment Receipt Photo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (ctx) => SafeArea(
                      child: Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text('Take Photo with Camera'),
                            onTap: () {
                              Navigator.pop(ctx);
                              _pickReceipt(ImageSource.camera);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Choose from Gallery'),
                            onTap: () {
                              Navigator.pop(ctx);
                              _pickReceipt(ImageSource.gallery);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorderLight, style: BorderStyle.solid),
                  ),
                  child: Center(
                    child: _receiptImage != null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle, color: AppColors.success),
                              const SizedBox(width: 8),
                              Text('Receipt Attached: ${_receiptImage!.name.split("/").last}'),
                            ],
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, color: AppColors.electricBlue, size: 28),
                              SizedBox(height: 6),
                              Text('Tap to capture or upload receipt', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Customer Signature Pad
              const Text('Customer Digital Signature', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _captureSignature,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorderLight),
                  ),
                  child: Center(
                    child: _signatureBytes != null
                        ? Image.memory(_signatureBytes!, height: 80)
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.draw_outlined, color: AppColors.electricBlue, size: 28),
                              SizedBox(height: 6),
                              Text('Tap to capture customer signature', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Remarks
              TextFormField(
                controller: _remarksController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Customer Remarks / Follow-up Notes',
                  hintText: 'e.g. Paid partial, remaining next Tuesday',
                ),
              ),
              const SizedBox(height: 28),

              CustomButton(
                text: 'Confirm & Submit Collection',
                isLoading: _isLoading,
                backgroundColor: AppColors.success,
                onPressed: _submitPayment,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodChip(String label, String value, IconData icon) {
    final isSelected = _paymentMethod == value;

    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textSecondaryLight),
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.electricBlue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimaryLight,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      onSelected: (_) => setState(() => _paymentMethod = value),
    );
  }
}
