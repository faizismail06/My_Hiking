import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'bloc/midtrans_payment_cubit.dart';
import 'bloc/midtrans_payment_state.dart';
import '../../api/api_service.dart';
import '../../core/app_export.dart';
import '../../widgets/app_bar/appbar_subtitle.dart';
import '../../widgets/app_bar/custom_app_bar.dart';

class MidtransPaymentScreen extends StatefulWidget {
  final int transactionId;
  final String? snapToken;
  final String? redirectUrl;

  const MidtransPaymentScreen({
    super.key,
    required this.transactionId,
    this.snapToken,
    this.redirectUrl,
  });

  @override
  State<MidtransPaymentScreen> createState() => _MidtransPaymentScreenState();
}

class _MidtransPaymentScreenState extends State<MidtransPaymentScreen> {
  WebViewController? _controller;
  final MidtransPaymentCubit _cubit = MidtransPaymentCubit();
  final bool _isWebPlatform = kIsWeb;

  MidtransPaymentState get _state => _cubit.state;

  @override
  void initState() {
    super.initState();
    _initPayment();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _initPayment() async {
    try {
      if (widget.redirectUrl != null && widget.redirectUrl!.isNotEmpty) {
        // Already have redirect URL from previous screen
        _cubit.setPaymentUrl(widget.redirectUrl);
        _cubit.setLoading(false);

        // For web platform, open in browser
        if (_isWebPlatform) {
          await _openPaymentInBrowser();
        } else {
          _initWebView();
        }
      } else {
        // Need to create payment first
        final result =
            await ApiService().createMidtransPayment(widget.transactionId);

        if (result['success'] == true && result['redirect_url'] != null) {
          _cubit.setPaymentUrl(result['redirect_url']);
          _cubit.setLoading(false);

          // For web platform, open in browser
          if (_isWebPlatform) {
            await _openPaymentInBrowser();
          } else {
            _initWebView();
          }
        } else {
          _cubit.setError(result['message'] ?? 'Gagal membuat pembayaran');
        }
      }
    } catch (e) {
      _cubit.setError('Terjadi kesalahan: $e');
    }
  }

  Future<void> _openPaymentInBrowser() async {
    if (_state.paymentUrl == null) return;

    try {
      final uri = Uri.parse(_state.paymentUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _cubit.setPaymentOpenedInBrowser(true);
      } else {
        _cubit.setError('Tidak dapat membuka halaman pembayaran');
      }
    } catch (e) {
      _cubit.setError('Gagal membuka browser: $e');
    }
  }

  void _initWebView() {
    if (_state.paymentUrl == null) return;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            _cubit.setLoading(true);
          },
          onPageFinished: (String url) {
            _cubit.setLoading(false);
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView Error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            // Handle callback URLs from Midtrans
            final url = request.url.toLowerCase();

            // Check for finish/callback URLs
            if (url.contains('/finish') ||
                url.contains('status_code=') ||
                url.contains('transaction_status=')) {
              _handlePaymentCallback(request.url);
              return NavigationDecision.prevent;
            }

            // Allow Midtrans Snap URLs
            if (url.contains('midtrans.com') ||
                url.contains('sandbox.midtrans') ||
                url.contains('snap.midtrans')) {
              return NavigationDecision.navigate;
            }

            // Allow bank/payment provider URLs
            if (url.contains('permatabank') ||
                url.contains('bca') ||
                url.contains('bni') ||
                url.contains('mandiri') ||
                url.contains('bri') ||
                url.contains('cimb') ||
                url.contains('gopay') ||
                url.contains('dana') ||
                url.contains('ovo') ||
                url.contains('shopeepay') ||
                url.contains('linkaja') ||
                url.contains('indomaret') ||
                url.contains('alfamart')) {
              return NavigationDecision.navigate;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
        ..loadRequest(Uri.parse(_state.paymentUrl!));
  }

  Future<void> _handlePaymentCallback(String url) async {
    // Parse URL parameters
    final uri = Uri.parse(url);
    final params = uri.queryParameters;

    final transactionStatus = params['transaction_status'] ?? '';
    final orderId = params['order_id'] ?? '';
    final statusCode = params['status_code'] ?? '';

    print('Payment Callback - Status: $transactionStatus, Order: $orderId');

    // Determine result based on status
    String status = 'pending';
    String message = 'Pembayaran sedang diproses';

    if (transactionStatus == 'capture' ||
        transactionStatus == 'settlement' ||
        statusCode == '200') {
      status = 'success';
      message = 'Pembayaran berhasil!';

      // Sync status with backend silently (don't show loading for success)
      // This ensures DB is updated even if webhook doesn't reach localhost
      _syncPaymentStatus(orderId); // Don't await - just fire and forget
    } else if (transactionStatus == 'deny' ||
        transactionStatus == 'cancel' ||
        transactionStatus == 'expire' ||
        statusCode == '202') {
      status = 'failed';
      message = 'Pembayaran gagal atau dibatalkan';
    } else if (transactionStatus == 'pending' || statusCode == '201') {
      // For pending, sync and check actual status
      try {
        await _syncPaymentStatus(orderId);
        final result = await ApiService().checkMidtransStatus(
            orderId.isNotEmpty ? orderId : widget.transactionId.toString());

        if (result['success'] == true && result['data'] != null) {
          final data = result['data']['data'] ?? result['data'];
          final dbStatus = (data['status'] ?? '').toString().toLowerCase();

          if (dbStatus == 'complete') {
            status = 'success';
            message = 'Pembayaran berhasil!';
          }
        }
      } catch (e) {
        print('Error checking status: $e');
        status = 'pending';
        message = 'Silakan cek status di halaman Tiket saya';
      }
    }

    // Show result and navigate back
    if (mounted) {
      _showPaymentResult(status, message);
    }
  }

  /// Sync payment status with backend (important for localhost where webhook can't reach)
  Future<void> _syncPaymentStatus(String orderId) async {
    try {
      if (orderId.isEmpty) {
        orderId = widget.transactionId.toString();
      }
      print('Syncing payment status for order: $orderId');
      final result = await ApiService().checkMidtransStatus(orderId);
      print('Sync result: $result');
    } catch (e) {
      print('Error syncing payment status: $e');
    }
  }

  void _showPaymentResult(String status, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                status == 'success'
                    ? Icons.check_circle
                    : status == 'failed'
                        ? Icons.cancel
                        : Icons.hourglass_empty,
                color: status == 'success'
                    ? Colors.green
                    : status == 'failed'
                        ? Colors.red
                        : Colors.orange,
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                status == 'success'
                    ? 'Pembayaran Berhasil'
                    : status == 'failed'
                        ? 'Pembayaran Gagal'
                        : 'Menunggu Pembayaran',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  // Return to previous screen with result
                  Navigator.of(this.context).pop({
                    'status': status,
                    'message': message,
                    'transaction_id': widget.transactionId,
                  });
                },
                child: Text(
                  'OK',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<MidtransPaymentCubit, MidtransPaymentState>(
        builder: (context, state) {
          return SafeArea(
            child: Scaffold(
              appBar: _buildAppBar(context),
              body: _buildBody(state),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomAppBar(
      height: 40.h,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _showExitConfirmation(),
            padding: EdgeInsets.only(right: 16.h),
          ),
          Expanded(
            child: Center(
              child: AppbarSubtitleOne(text: "Pembayaran"),
            ),
          ),
          const SizedBox(width: 50),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Batalkan Pembayaran?'),
          content: Text(
            'Apakah Anda yakin ingin membatalkan pembayaran? '
            'Transaksi akan tetap tersimpan dan dapat dilanjutkan nanti.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Tidak'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(this.context).pop({
                  'status': 'cancelled',
                  'message': 'Pembayaran dibatalkan',
                  'transaction_id': widget.transactionId,
                });
              },
              child: Text(
                'Ya, Batalkan',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(MidtransPaymentState state) {
    if (state.hasError) {
      return _buildErrorState();
    }

    if (state.isLoading && state.paymentUrl == null) {
      return _buildLoadingState();
    }

    // For web platform, show instruction to complete payment in browser
    if (_isWebPlatform) {
      return _buildWebPlatformBody();
    }

    return Stack(
      children: [
        if (state.paymentUrl != null && _controller != null)
          WebViewWidget(controller: _controller!),
        if (state.isLoading)
          Container(
            color: Colors.white.withOpacity(0.8),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Memuat halaman pembayaran...',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWebPlatformBody() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _state.paymentOpenedInBrowser
                  ? Icons.open_in_browser
                  : Icons.payment,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            SizedBox(height: 24),
            Text(
              _state.paymentOpenedInBrowser
                  ? 'Pembayaran Dibuka di Browser'
                  : 'Siap untuk Pembayaran',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              _state.paymentOpenedInBrowser
                  ? 'Halaman pembayaran telah dibuka di tab/window baru. '
                      'Silakan selesaikan pembayaran di sana.'
                  : 'Klik tombol di bawah untuk membuka halaman pembayaran.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            if (!_state.paymentOpenedInBrowser)
              ElevatedButton.icon(
                icon: Icon(Icons.open_in_browser, color: Colors.white),
                label: Text(
                  'Buka Halaman Pembayaran',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _openPaymentInBrowser,
              ),
            if (_state.paymentOpenedInBrowser) ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    SizedBox(height: 8),
                    Text(
                      'Setelah pembayaran selesai, klik tombol di bawah '
                      'untuk kembali dan mengecek status pembayaran.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    icon: Icon(Icons.refresh),
                    label: Text('Buka Lagi'),
                    onPressed: _openPaymentInBrowser,
                  ),
                  SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: Icon(Icons.check, color: Colors.white),
                    label: Text(
                      'Selesai',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () async {
                      String status = 'pending';
                      String message =
                          'Silakan cek status di halaman tiket saya';

                      if (widget.transactionId > 0) {
                        final result = await ApiService().checkMidtransStatus(
                            widget.transactionId.toString());

                        if (result['success'] == true &&
                            result['data'] != null) {
                          final data = result['data']['data'] ?? result['data'];
                          final dbStatus =
                              (data['status'] ?? '').toString().toLowerCase();
                          if (dbStatus == 'complete') {
                            status = 'success';
                            message = 'Pembayaran berhasil!';
                          }
                        }
                      }

                      Navigator.of(context).pop({
                        'status': status,
                        'message': message,
                        'transaction_id': widget.transactionId,
                      });
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: 24),
          Text(
            'Menyiapkan pembayaran...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Mohon tunggu sebentar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 24),
            Text(
              'Gagal Memuat Pembayaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              _state.errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Kembali'),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                  ),
                  onPressed: () {
                    _cubit.clearError();
                    _cubit.setLoading(true);
                    _initPayment();
                  },
                  child: Text(
                    'Coba Lagi',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
