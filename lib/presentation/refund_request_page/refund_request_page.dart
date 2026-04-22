import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api/api_service.dart';
import '../../core/app_export.dart';

class RefundRequestPage extends StatefulWidget {
  final int orderId;
  final String mountainName;
  final String hikingDate;

  const RefundRequestPage({
    super.key,
    required this.orderId,
    required this.mountainName,
    required this.hikingDate,
  });

  @override
  State<RefundRequestPage> createState() => _RefundRequestPageState();
}

class _RefundRequestPageState extends State<RefundRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  final NumberFormat _currency =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  bool _isPreviewLoading = true;
  bool _isSubmitting = false;
  String? _previewError;
  Map<String, dynamic>? _previewData;

  String _selectedMethod = 'Bank Transfer';
  String _selectedReasonChip = 'Change of plans';

  final List<String> _reasonOptions = [
    'Change of plans',
    'Illness',
    'Weather',
    'Other'
  ];

  bool get _isRefundDisabledByGuard {
    final message = (_previewError ?? '').toLowerCase();
    return message.contains('tidak diizinkan') &&
        message.contains('penjaga gunung');
  }

  @override
  void initState() {
    super.initState();
    _loadRefundPreview();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadRefundPreview() async {
    setState(() {
      _isPreviewLoading = true;
      _previewError = null;
    });

    final result = await ApiService().getRefundPreview(widget.orderId);

    if (!mounted) {
      return;
    }

    setState(() {
      _isPreviewLoading = false;
      if (result['success'] == true) {
        _previewData = (result['data'] as Map?)?.cast<String, dynamic>();
      } else {
        _previewError =
            result['message']?.toString() ?? 'Gagal mengambil preview refund.';
      }
    });
  }

  String? _requiredValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label wajib diisi';
    }
    return null;
  }

  Future<void> _submitDirectCancellation() async {
    setState(() {
      _isSubmitting = true;
    });

    final result = await ApiService().cancelOrder(widget.orderId);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan berhasil dibatalkan. Dana tidak dapat dikembalikan.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        AppRoutes.orderCancelledScreen,
        (route) => false,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ?? 'Gagal membatalkan pesanan.',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _submitRefundRequest() async {
    if (_isRefundDisabledByGuard) {
      await _submitDirectCancellation();
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    String finalReason = _selectedReasonChip;
    if (_reasonController.text.trim().isNotEmpty) {
      finalReason = '$_selectedReasonChip: ${_reasonController.text.trim()}';
    }

    final result = await ApiService().submitRefundRequest(
      orderId: widget.orderId,
      cancelReason: finalReason,
      refundMethod: _selectedMethod,
      bankName: _selectedMethod == 'Bank Transfer'
          ? _bankNameController.text.trim()
          : null,
      accountNumber: _selectedMethod == 'Bank Transfer'
          ? _accountNumberController.text.trim()
          : null,
      accountHolder: _accountHolderController.text.trim(),
      phoneNumber: _selectedMethod == 'Bank Transfer'
          ? null
          : _phoneNumberController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (result['success'] == true) {
      final message = result['message']?.toString() ??
          'Permintaan refund berhasil diajukan.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        AppRoutes.orderCancelledScreen,
        (route) => false,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(result['message']?.toString() ?? 'Gagal mengajukan refund'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildTopCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.mountainName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF1A2F45),
                  ),
                ),
              ),
              Icon(Icons.landscape, color: const Color(0xFF1A2F45), size: 32),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 18, color: Colors.black87),
              const SizedBox(width: 8),
              Text(
                widget.hikingDate,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined,
                  size: 18, color: Colors.black87),
              const SizedBox(width: 8),
              Text(
                'Order ID: #${widget.orderId}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    if (_isPreviewLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_previewError != null) {
      final isRefundDisabledByGuard = _isRefundDisabledByGuard;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRefundDisabledByGuard
              ? Colors.orange.shade50
              : Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRefundDisabledByGuard
                ? Colors.orange.shade200
                : Colors.red.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRefundDisabledByGuard
                  ? 'Peringatan! Jika tiket ini dibatalkan, biaya yang sudah dibayarkan tidak dapat dikembalikan.'
                  : _previewError!,
              style: TextStyle(
                color: isRefundDisabledByGuard
                    ? Colors.orange.shade900
                    : Colors.red.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isRefundDisabledByGuard) ...[
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _loadRefundPreview,
                child: const Text('Coba lagi'),
              ),
            ],
          ],
        ),
      );
    }

    final data = _previewData ?? <String, dynamic>{};
    final ticketPrice = (data['ticket_price'] as num?)?.toDouble() ?? 0;
    final penalty = (data['penalty_amount'] as num?)?.toDouble() ?? 0;
    final refund = (data['refund_amount'] as num?)?.toDouble() ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5F3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estimated Refund',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Color(0xFF1A2F45),
                ),
              ),
              Icon(Icons.info, color: Colors.black54, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          _buildAmountRow('Ticket Price', _currency.format(ticketPrice)),
          _buildAmountRow('Penalty', _currency.format(penalty)),
          const SizedBox(height: 8),
          _buildAmountRow(
            'Refund Amount',
            _currency.format(refund),
            isHighlight: true,
          ),
          if (refund <= 0) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                'Dana tidak dapat dikembalikan karena sudah Hari-H pendakian.',
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, String value,
      {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isHighlight ? 18 : 16,
              fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w500,
              color: isHighlight ? const Color(0xFF388E81) : Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlight ? 18 : 16,
              fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w500,
              color: isHighlight ? const Color(0xFF388E81) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicFields() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5F4),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RECEIVING DETAILS',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedMethod == 'Bank Transfer') ...[
            _buildFieldWithUnderline(
              controller: _bankNameController,
              label: 'Bank name',
              icon: Icons.account_balance,
              validator: (v) => _requiredValidator(v, 'Bank name'),
            ),
            const SizedBox(height: 16),
            _buildFieldWithUnderline(
              controller: _accountNumberController,
              label: 'Account number',
              icon: Icons.credit_card,
              keyboardType: TextInputType.number,
              validator: (v) => _requiredValidator(v, 'Account number'),
            ),
          ] else ...[
            _buildFieldWithUnderline(
              controller: _phoneNumberController,
              label: _selectedMethod == 'DANA' ? 'Nomor DANA' : 'Nomor GoPay',
              icon: Icons.phone_android,
              keyboardType: TextInputType.phone,
              validator: (v) => _requiredValidator(v, 'Nomor telepon'),
            ),
          ],
          const SizedBox(height: 16),
          _buildFieldWithUnderline(
            controller: _accountHolderController,
            label: 'Account holder',
            icon: Icons.person,
            validator: (v) => _requiredValidator(v, 'Account holder'),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldWithUnderline({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: null,
        hintText: label,
        hintStyle: const TextStyle(color: Colors.black54),
        prefixIcon: Icon(icon, color: Colors.blueGrey.shade400),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black26),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black26),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF388E81), width: 2),
        ),
        contentPadding: const EdgeInsets.only(top: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFCFC),
      appBar: AppBar(
        title: const Text(
          'Refund & Cancellation',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadRefundPreview,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            _buildTopCard(),
            const SizedBox(height: 24),
            _buildPreviewCard(),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cancellation reason',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _reasonOptions.map((reason) {
                      final isSelected = _selectedReasonChip == reason;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedReasonChip = reason;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2B475D)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2B475D)
                                  : Colors.black45,
                            ),
                          ),
                          child: Text(
                            reason,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _reasonController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          "Provide details for 'Other' or additional comments...",
                      hintStyle:
                          const TextStyle(color: Colors.black45, fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFFF2F5F4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF388E81)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (!_isRefundDisabledByGuard) ...[
                    // Refund Method Header Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black45),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: -24,
                            left: 4,
                            child: Container(
                              color: const Color(0xFFFBFCFC),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: const Text('Refund method',
                                  style: TextStyle(color: Colors.black87)),
                            ),
                          ),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedMethod,
                              isExpanded: true,
                              isDense: true,
                              icon: const Icon(Icons.arrow_drop_down,
                                  color: Colors.black87),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Bank Transfer',
                                  child: Row(
                                    children: [
                                      Icon(Icons.account_balance,
                                          color: Colors.black87),
                                      SizedBox(width: 10),
                                      Text('Bank Transfer',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'DANA',
                                  child: Row(
                                    children: [
                                      Icon(Icons.account_balance_wallet,
                                          color: Colors.black87),
                                      SizedBox(width: 10),
                                      Text('DANA',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'GoPay',
                                  child: Row(
                                    children: [
                                      Icon(Icons.account_balance_wallet,
                                          color: Colors.black87),
                                      SizedBox(width: 10),
                                      Text('GoPay',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedMethod = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildDynamicFields(),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Color(0xFFFBFCFC),
        ),
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF388E3C), // Hijau sesuai referensi
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: (_isSubmitting || _isPreviewLoading)
                ? null
                : _submitRefundRequest,
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isRefundDisabledByGuard
                        ? 'SUBMIT REQUEST'
                        : 'SUBMIT REFUND REQUEST',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
