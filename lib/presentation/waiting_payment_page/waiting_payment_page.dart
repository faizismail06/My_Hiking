import 'dart:async';

import 'package:another_stepper/dto/stepper_data.dart';
import 'package:another_stepper/widgets/another_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:myhiking/presentation/payment_expired_page/payment_expired_page.dart';
import 'package:myhiking/presentation/payment_failed_page/payment_failed_page.dart';
import 'package:myhiking/presentation/payment_success_page/payment_success_page.dart';

import '../../api/api_service.dart';
import '../../core/app_export.dart';

class WaitingPaymentPage extends StatefulWidget {
  final String orderId;
  final int transactionId;
  final int? totalPayment;
  final String? paymentMethod;
  final String transactionCreatedAt;
  final String? paymentCode;
  final String? paymentCodeLabel;
  final String? paymentInstruction;
  final String? deeplinkUrl;
  final String? qrCodeUrl;
  final String? qrString;

  const WaitingPaymentPage({
    super.key,
    required this.orderId,
    required this.transactionId,
    required this.totalPayment,
    required this.paymentMethod,
    required this.transactionCreatedAt,
    this.paymentCode,
    this.paymentCodeLabel,
    this.paymentInstruction,
    this.deeplinkUrl,
    this.qrCodeUrl,
    this.qrString,
  });

  @override
  State<WaitingPaymentPage> createState() => _WaitingPaymentPageState();
}

class _WaitingPaymentPageState extends State<WaitingPaymentPage> {
  static const Duration _maxPaymentDuration = Duration(minutes: 15);
  static const Duration _pollingInterval = Duration(seconds: 7);

  Timer? _countdownTimer;
  Timer? _pollingTimer;

  late DateTime _createdAt;
  late DateTime _expiredAt;

  Duration _remainingTime = Duration.zero;
  bool _isRequestingStatus = false;
  bool _hasNavigated = false;
  bool _isCancellingOrder = false;

  int? _totalPayment;
  String _paymentMethod = '-';
  String _currentStatus = 'pending';
  String? _paymentCode;
  String? _paymentCodeLabel;
  String? _paymentInstruction;
  String? _deeplinkUrl;
  String? _qrString;

  @override
  void initState() {
    super.initState();
    _totalPayment = widget.totalPayment;
    _paymentMethod = (widget.paymentMethod ?? '').trim().isNotEmpty
        ? widget.paymentMethod!.trim()
        : '-';
    _paymentCode = _sanitizeNullable(widget.paymentCode);
    _paymentCodeLabel = _sanitizeNullable(widget.paymentCodeLabel);
    _paymentInstruction = _sanitizeNullable(widget.paymentInstruction);
    _deeplinkUrl = _sanitizeNullable(widget.deeplinkUrl);
    _qrString = _sanitizeNullable(widget.qrString);

    _createdAt = _parseTransactionCreatedAt(widget.transactionCreatedAt);
    _expiredAt = _createdAt.add(_maxPaymentDuration);

    _updateRemainingTime();
    _startCountdown();
    _startStatusPolling();
    _pollPaymentStatus();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  DateTime _parseTransactionCreatedAt(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return DateTime.now();
    }

    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingTime();
    });
  }

  void _startStatusPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      _pollPaymentStatus();
    });
  }

  void _updateRemainingTime() {
    if (_hasNavigated || !mounted) {
      return;
    }

    final remaining = _expiredAt.difference(DateTime.now());

    if (remaining <= Duration.zero) {
      setState(() {
        _remainingTime = Duration.zero;
      });
      _handlePaymentExpired('Payment time has expired');
      return;
    }

    setState(() {
      _remainingTime = remaining;
    });
  }

  Future<void> _pollPaymentStatus() async {
    if (_hasNavigated || _isRequestingStatus) {
      return;
    }

    _isRequestingStatus = true;

    try {
      final response = await ApiService().getPaymentStatus(widget.orderId);
      if (response['success'] != true) {
        return;
      }

      final payload = response['data'];
      if (payload is! Map<String, dynamic>) {
        return;
      }

      final status = (payload['status'] ?? 'pending').toString().toLowerCase();
      final totalPayment = _toInt(payload['total_payment']);
      final method = payload['payment_method']?.toString();
      final transactionCreatedAt =
          payload['transaction_created_at']?.toString();
      final qrisStringCandidate =
          _sanitizeNullable(payload['qr_string']?.toString());

      if (mounted) {
        setState(() {
          _currentStatus = status;
          if (totalPayment != null && totalPayment > 0) {
            _totalPayment = totalPayment;
          }
          if (method != null && method.trim().isNotEmpty) {
            _paymentMethod = method.trim();
          }

          _paymentCode = _sanitizeNullable(payload['payment_code']?.toString());
          _paymentCodeLabel =
              _sanitizeNullable(payload['payment_code_label']?.toString());
          _paymentInstruction =
              _sanitizeNullable(payload['payment_instruction']?.toString());
          _deeplinkUrl = _sanitizeNullable(payload['deeplink_url']?.toString());

          if (qrisStringCandidate != null) {
            _qrString = qrisStringCandidate;
          }

          if (transactionCreatedAt != null &&
              transactionCreatedAt.trim().isNotEmpty) {
            _createdAt =
                _parseTransactionCreatedAt(transactionCreatedAt.trim());
            _expiredAt = _createdAt.add(_maxPaymentDuration);
          }
        });
      }

      switch (status) {
        case 'paid':
          _navigateToSuccess();
          break;
        case 'expired':
          _handlePaymentExpired('Payment time has expired');
          break;
        case 'failed':
          _navigateToFailed();
          break;
        default:
          break;
      }
    } catch (_) {
      // Keep page alive and continue polling on next interval.
    } finally {
      _isRequestingStatus = false;
    }
  }

  int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse((value ?? '').toString());
  }

  String? _sanitizeNullable(String? value) {
    final cleaned = (value ?? '').trim();
    return cleaned.isEmpty || cleaned == 'null' ? null : cleaned;
  }

  Future<void> _openDeeplink() async {
    if (_deeplinkUrl == null) {
      return;
    }

    final uri = Uri.tryParse(_deeplinkUrl!);
    if (uri == null) {
      return;
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka tautan pembayaran.'),
        ),
      );
    }
  }

  Future<void> _copyPaymentCode() async {
    if (_paymentCode == null || _paymentCode!.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: _paymentCode!));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nomor pembayaran berhasil disalin.'),
      ),
    );
  }

  bool get _isQrisPayment {
    final method = _paymentMethod.toLowerCase();
    return method.contains('qris');
  }

  String? get _resolvedQrisUrl {
    if (!_isQrisPayment) {
      return null;
    }

    // Use backend proxy for QRIS image to avoid Midtrans auth/CORS issues.
    return '$baseUrl/payment/qris-image/${widget.orderId}';
  }

  Future<void> _downloadQris() async {
    final qrisUrl = _resolvedQrisUrl;
    if (qrisUrl == null) {
      return;
    }

    try {
      final uri = Uri.tryParse(qrisUrl);
      if (uri == null) {
        throw Exception('QRIS URL tidak valid');
      }

      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        throw Exception('Gagal membuka tautan QRIS');
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Tautan QRIS dibuka. Silakan simpan gambar dari browser.'),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengunduh QRIS. Silakan coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleDownloadQr() async {
    if (_resolvedQrisUrl != null) {
      await _downloadQris();
      return;
    }

    if (_qrString != null) {
      await Clipboard.setData(ClipboardData(text: _qrString!));
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'QR tersedia sebagai string dan sudah disalin ke clipboard.',
          ),
        ),
      );
      return;
    }

    if (_deeplinkUrl != null) {
      await _openDeeplink();
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kode QR belum tersedia untuk diunduh.'),
      ),
    );
  }

  Future<void> _cancelOrder() async {
    if (_isCancellingOrder || _hasNavigated) {
      return;
    }

    final parsedOrderId = int.tryParse(widget.orderId);
    if (parsedOrderId == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order ID tidak valid. Gagal membatalkan pesanan.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCancellingOrder = true;
    });

    try {
      final result = await ApiService().cancelOrder(parsedOrderId);
      if (!mounted) {
        return;
      }

      if (result['success'] == true) {
        _hasNavigated = true;
        _countdownTimer?.cancel();
        _pollingTimer?.cancel();

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
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan saat membatalkan pesanan.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCancellingOrder = false;
        });
      }
    }
  }

  void _navigateToSuccess() {
    if (_hasNavigated || !mounted) {
      return;
    }

    _hasNavigated = true;
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSuccessPage(
          orderId: widget.orderId,
          totalPayment: _totalPayment,
          paymentMethod: _paymentMethod,
        ),
      ),
    );
  }

  void _navigateToFailed() {
    if (_hasNavigated || !mounted) {
      return;
    }

    _hasNavigated = true;
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentFailedPage(
          orderId: widget.orderId,
        ),
      ),
    );
  }

  void _handlePaymentExpired(String message) {
    if (_hasNavigated || !mounted) {
      return;
    }

    _hasNavigated = true;
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentExpiredPage(
          orderId: widget.orderId,
          message: message,
        ),
      ),
    );
  }

  String _formatCurrency(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return formatter.format(amount);
  }

  String _formatCountdown(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray5001,
        body: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 20.h),
            child: Column(
              children: [
                _buildHeader(context),
                SizedBox(height: 18.h),
                _buildProgressSection(context),
                SizedBox(height: 8.h),
                _buildWaitingCard(context),
                SizedBox(height: 12.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.transparent,
      width: double.maxFinite,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context, rootNavigator: true)
                    .pushNamedAndRemoveUntil(
                  AppRoutes.homeScreen,
                  (route) => false,
                );
              },
              child: const Icon(
                Icons.arrow_back,
                size: 24,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 24.0),
                child: Text(
                  'Payment Verification',
                  style: CustomTextStyles.titleMediumGray900,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.only(left: 10.h, right: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.maxFinite,
            child: AnotherStepper(
              iconHeight: 24,
              iconWidth: 26,
              stepperDirection: Axis.horizontal,
              activeIndex: 1,
              barThickness: 4,
              inverted: true,
              stepperList: [
                StepperData(
                  iconWidget: _buildStepperIcon('1', true),
                ),
                StepperData(
                  iconWidget: _buildStepperIcon('2', true),
                ),
                StepperData(
                  iconWidget: _buildStepperIcon('3', false),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          _buildTimerCard(context),
        ],
      ),
    );
  }

  Widget _buildTimerCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
      decoration: BoxDecoration(
        color: appTheme.teal900.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.h),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.access_time, color: appTheme.teal900, size: 28.h),
          SizedBox(width: 12.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selesaikan Pembayaran dalam waktu',
                  style: TextStyle(
                    fontSize: 12.h,
                    color: appTheme.teal900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _formatCountdown(_remainingTime),
                  style: TextStyle(
                    fontSize: 16.h,
                    color: appTheme.teal900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperIcon(String label, bool active) {
    return Container(
      height: active ? 24.h : 22.h,
      width: 26.h,
      decoration: BoxDecoration(
        color: active ? theme.colorScheme.primary : appTheme.gray5001,
        borderRadius: BorderRadius.circular(12.h),
        border: active
            ? null
            : Border.all(
                color: appTheme.blueGray100,
                width: 2.h,
              ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : appTheme.blueGray100,
            fontWeight: FontWeight.bold,
            fontSize: 12.h,
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingCard(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 24.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.onPrimary,
            borderRadius: BorderRadiusStyle.roundedBorder14,
            border: Border.all(color: appTheme.teal900, width: 2.h),
            boxShadow: [
              BoxShadow(
                color: appTheme.black900.withValues(alpha: 0.04),
                spreadRadius: 2.h,
                blurRadius: 2.h,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _isQrisPayment
              ? _buildQrisContent(context)
              : _buildVaContent(context),
        ),
        SizedBox(height: 24.h),
        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            onPressed: _isCancellingOrder ? null : _cancelOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: appTheme.teal900,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.h),
              ),
            ),
            child: _isCancellingOrder
                ? SizedBox(
                    width: 22.h,
                    height: 22.h,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'BATALKAN PESANAN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.h,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        if (_isCancellingOrder) ...[
          SizedBox(height: 8.h),
          Text(
            'Membatalkan pesanan...',
            style: TextStyle(
              color: appTheme.gray50003,
              fontSize: 11.h,
            ),
          ),
        ],
        SizedBox(height: 12.h),
        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true)
                  .pushNamedAndRemoveUntil(
                AppRoutes.homeScreen,
                (route) => false,
              );
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: appTheme.teal900, width: 1.5.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.h),
              ),
            ),
            child: Text(
              'KEMBALI KE HOME',
              style: TextStyle(
                color: appTheme.teal900,
                fontSize: 14.h,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'Status: ${_currentStatus.toUpperCase()}',
          style: TextStyle(
            color: appTheme.gray50003,
            fontSize: 10.h,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQrisContent(BuildContext context) {
    final totalText =
        _totalPayment != null ? _formatCurrency(_totalPayment!) : '-';
    final hasDownloadSource =
        _resolvedQrisUrl != null || _qrString != null || _deeplinkUrl != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomImageView(
          imagePath: ImageConstant.imgPngwingCom1,
          height: 48.h,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 20.h),
        Text(
          'Scan QR untuk Membayar',
          style: CustomTextStyles.titleMediumGray900,
        ),
        SizedBox(height: 16.h),
        if (_qrString != null)
          Container(
            width: 220.h,
            height: 220.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.h),
            ),
            child: Center(
              child: QrImageView(
                data: _qrString!,
                version: QrVersions.auto,
                size: 200.h,
                backgroundColor: Colors.white,
              ),
            ),
          )
        else if (_resolvedQrisUrl != null)
          GestureDetector(
            onTap: _downloadQris,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.h),
              child: Image.network(
                _resolvedQrisUrl!,
                width: 220.h,
                height: 220.h,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 220.h,
                    height: 220.h,
                    color: appTheme.gray100,
                    child: const Center(
                      child: Text('QR Code tidak dapat dimuat'),
                    ),
                  );
                },
              ),
            ),
          )
        else
          Container(
            width: 220.h,
            height: 220.h,
            color: appTheme.gray100,
            child: const Center(
              child: Text('QR Code tidak tersedia'),
            ),
          ),
        SizedBox(height: 12.h),
        SizedBox(
          width: double.infinity,
          height: 44.h,
          child: OutlinedButton.icon(
            onPressed: hasDownloadSource ? _handleDownloadQr : null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: appTheme.teal900, width: 1.2.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.h),
              ),
            ),
            icon: Icon(Icons.download_rounded, color: appTheme.teal900),
            label: Text(
              'UNDUH KODE QR',
              style: TextStyle(
                color: appTheme.teal900,
                fontSize: 12.h,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (_deeplinkUrl != null &&
            _qrString == null &&
            _resolvedQrisUrl == null) ...[
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: _openDeeplink,
            child: Text(
              'Buka Aplikasi Pembayaran',
              style: TextStyle(
                fontSize: 14.h,
                color: Colors.blue.shade800,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
        SizedBox(height: 24.h),
        Text(
          'ID PESANAN',
          style: TextStyle(
            fontSize: 12.h,
            color: appTheme.gray50003,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          widget.orderId,
          style: TextStyle(
            fontSize: 14.h,
            color: appTheme.gray900,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          totalText,
          style: TextStyle(
            fontSize: 28.h,
            color: appTheme.teal900,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (_deeplinkUrl != null && !_isQrisPayment) ...[
          SizedBox(height: 16.h),
          GestureDetector(
            onTap: _openDeeplink,
            child: Text(
              'Buka Aplikasi Pembayaran',
              style: TextStyle(
                fontSize: 14.h,
                color: Colors.blue.shade800,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVaContent(BuildContext context) {
    final totalText =
        _totalPayment != null ? _formatCurrency(_totalPayment!) : '-';
    final instructionText = _paymentInstruction ??
        'Gunakan nomor VA ini untuk\nmenyelesaikan pembayaran.';

    final bankName =
        _paymentCodeLabel ?? _paymentMethod.replaceAll('_', ' ').toUpperCase();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomImageView(
          imagePath: ImageConstant.imgPaymentByTapping,
          height: 200.h,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 6.h),
        Text(
          'ID PESANAN',
          style: TextStyle(
            fontSize: 12.h,
            color: appTheme.gray50003,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          widget.orderId,
          style: TextStyle(
            fontSize: 14.h,
            color: appTheme.gray900,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          totalText,
          style: TextStyle(
            fontSize: 28.h,
            color: appTheme.teal900,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomImageView(
              imagePath: ImageConstant.imgLogoBankBri,
              height: 24.h,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 8.h),
            Flexible(
              child: Text(
                bankName,
                style: TextStyle(
                  fontSize: 14.h,
                  color: appTheme.gray50003,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        GestureDetector(
          onTap: _copyPaymentCode,
          child: Text(
            _paymentCode ?? 'NOMOR-VA',
            style: TextStyle(
              fontSize: 18.h,
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          instructionText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.h,
            color: appTheme.teal900,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
