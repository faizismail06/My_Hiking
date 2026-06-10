import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api/api_service.dart';

class RefundRequestResultPage extends StatefulWidget {
  final int orderId;
  final String mountainName;
  final String hikingDate;

  const RefundRequestResultPage({
    super.key,
    required this.orderId,
    required this.mountainName,
    required this.hikingDate,
  });

  @override
  State<RefundRequestResultPage> createState() =>
      _RefundRequestResultPageState();
}

class _RefundRequestResultPageState extends State<RefundRequestResultPage> {
  final NumberFormat _currency =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _loadResult();
  }

  Future<void> _loadResult() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response =
        await ApiService().getRefundRequestResultByOrder(widget.orderId);

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      if (response['success'] == true) {
        _result = (response['data'] as Map?)?.cast<String, dynamic>();
      } else {
        _errorMessage = response['message']?.toString() ??
            'Gagal mengambil hasil proses refund.';
      }
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'refunded':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    try {
      final parsed = DateTime.parse(value).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(parsed);
    } catch (_) {
      return value;
    }
  }

  Widget _buildStatusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        title: const Text(
          'Hasil Proses Refund',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadResult,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade200),
                      ),
                      onPressed: _loadResult,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              )
            else ...[
              _buildHeaderCard(),
              const SizedBox(height: 16),
              _buildProgressCard(),
              const SizedBox(height: 16),
              _buildPengembalianCard(),
              const SizedBox(height: 16),
              _buildAmountCard(),
              const SizedBox(height: 16),
              _buildProofCard(),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFC7E2D6), // Matching green bg card
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/images/gunungg.jpeg', // User requested gunungg.jpeg
                height: 100,
                width: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detail Pesanan',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        widget.mountainName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Order ID: #${widget.orderId}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Tanggal Naik: ${widget.hikingDate.split(', ').last}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.calendar_month,
                              size: 14, color: Colors.black87),
                        ],
                      ),
                    ],
                  ),
                ),
                // Padding di sebelah kanan agar tidak nabrak gunung
                const SizedBox(width: 150),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final data = _result ?? <String, dynamic>{};
    final status =
        (data['refund_status'] ?? 'pending').toString().toLowerCase();

    // Map status from backend to UI step index (0 = requested, 1 = admin review, 2 = processing, 3 = completed/refunded)
    // Note: backend status might be: pending, approved, rejected, refunded
    int currentStep = 0;
    if (status == 'pending') currentStep = 1;
    if (status == 'approved') currentStep = 2; // Or processing
    if (status == 'refunded') currentStep = 3;
    if (status == 'rejected') currentStep = 1; // Or custom error step

    // Fallback status chip mapping
    String chipLabel = 'PENDING';
    Color chipColor = Colors.orange.shade300;
    if (status == 'approved') {
      chipLabel = 'DIPROSES';
      chipColor = Colors.blue.shade300;
    } else if (status == 'refunded') {
      chipLabel = 'SELESAI';
      chipColor = Colors.green.shade300;
    } else if (status == 'rejected') {
      chipLabel = 'DITOLAK';
      chipColor = Colors.red.shade300;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: chipColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              chipLabel,
              style: TextStyle(
                color: chipColor.withValues(alpha: 1.0),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimelineStep(
                title: 'Permintaan\nDibuat',
                subtitle: _formatDateTime(data['requested_at']?.toString()),
                isActive: currentStep >= 0,
                isCompleted: currentStep > 0,
                isFirst: true,
              ),
              _buildTimelineLine(isCompleted: currentStep > 0),
              _buildTimelineStep(
                title: 'Review\nAdmin',
                subtitle: (status == 'rejected')
                    ? 'Ditolak'
                    : 'Menunggu\nkonfirmasi\nproses admin.',
                isActive: currentStep >= 1,
                isCompleted: currentStep > 1,
              ),
              _buildTimelineLine(isCompleted: currentStep > 1),
              _buildTimelineStep(
                title: 'Dana\nDiproses',
                subtitle: '',
                isActive: currentStep >= 2,
                isCompleted: currentStep > 2,
              ),
              _buildTimelineLine(isCompleted: currentStep > 2),
              _buildTimelineStep(
                title: 'Dana\nDiterima',
                subtitle: '',
                isActive: currentStep >= 3,
                isCompleted: currentStep >= 3,
                isLast: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isCompleted,
    bool isFirst = false,
    bool isLast = false,
  }) {
    Color dotColor = Colors.grey.shade300;
    if (isCompleted) {
      dotColor = const Color(0xFF388E3C);
    } else if (isActive) {
      dotColor = Colors.orange;
    }

    return Expanded(
      flex: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade600,
                height: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineLine({required bool isCompleted}) {
    return Expanded(
      flex: 1,
      child: Container(
        margin: const EdgeInsets.only(top: 11),
        height: 2,
        color: isCompleted ? const Color(0xFF388E3C) : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildPengembalianCard() {
    final data = _result ?? <String, dynamic>{};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Pengembalian',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 18, color: Colors.blueGrey.shade400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Alasan: ${data['cancel_reason'] ?? '-'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        size: 18, color: Colors.blueGrey.shade400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Metode: ${data['refund_method'] ?? '-'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.credit_card,
                        size: 18, color: Colors.blueGrey.shade400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('No. Rek/HP:',
                              style: TextStyle(fontSize: 12)),
                          Text(
                            '${data['account_number'] ?? '-'}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.person_outline,
                        size: 18, color: Colors.blueGrey.shade400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Nama Pemilik:',
                              style: TextStyle(fontSize: 12)),
                          Text(
                            '${data['account_holder'] ?? '-'}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    final data = _result ?? <String, dynamic>{};
    final refund = (data['refund_amount'] as num?)?.toDouble() ?? 0;
    final penalty = (data['penalty_amount'] as num?)?.toDouble() ?? 0;
    final adminPenalty = (data['admin_penalty_share'] as num?)?.toDouble() ?? 0;
    final rangerPenalty =
        (data['ranger_penalty_share'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                'Ringkasan Dana',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFC7E2D6)
                      .withValues(alpha: 0.5), // Match IDR pill color roughly
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.monetization_on,
                        size: 14, color: Color(0xFF388E3C)),
                    SizedBox(width: 4),
                    Text(
                      'IDR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _amountRow(
              'Refund Total', _currency.format(refund), const Color(0xFF388E3C),
              isBold: true),
          const Divider(height: 20),
          _amountRow(
              'Penalty Total', _currency.format(penalty), Colors.black87),
        ],
      ),
    );
  }

  Widget _amountRow(String label, String value, Color color,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black87,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: color,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildProofCard() {
    final data = _result ?? <String, dynamic>{};
    String? proofUrl = data['proof_url']?.toString();

    // Ganti host agar sesuai dengan konfigurasi server Flutter saat testing lokal
    if (proofUrl != null && proofUrl.contains('localhost')) {
      proofUrl =
          proofUrl.replaceAll('http://localhost', 'http://103.93.132.167:8000');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bukti Transfer',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (proofUrl == null || proofUrl.isEmpty)
            // Menggunakan Stack untuk mensimulasikan dashed border
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F5F4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _DashedBorderPainter(
                          color: Colors.grey.shade400,
                          strokeWidth: 2,
                          gap: 6,
                          radius: 8,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 30, horizontal: 16),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.camera_alt,
                              size: 48, color: Colors.blueGrey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'Bukti transfer belum tersedia.\nUnggah bukti jika tersedia.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                proofUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return const Text('Bukti transfer tidak dapat ditampilkan.');
                },
              ),
            ),
        ],
      ),
    );
  }
}

// Custom Painter untuk Dashed Border pada Bukti Transfer
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    var path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius)));

    Path dashPath = Path();
    double distance = 0.0;
    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += gap * 2;
      }
      distance = 0.0;
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
