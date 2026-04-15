import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:myhiking/presentation/waiting_payment_page/waiting_payment_page.dart';
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
  final int? orderId;
  final int? totalPayment;
  final String? paymentMethod;
  final String? transactionCreatedAt;

  const MidtransPaymentScreen({
    super.key,
    required this.transactionId,
    this.snapToken,
    this.redirectUrl,
    this.orderId,
    this.totalPayment,
    this.paymentMethod,
    this.transactionCreatedAt,
  });

  @override
  State<MidtransPaymentScreen> createState() => _MidtransPaymentScreenState();
}

class _MidtransPaymentScreenState extends State<MidtransPaymentScreen> {
  WebViewController? _controller;
  final MidtransPaymentCubit _cubit = MidtransPaymentCubit();
  final bool _isWebPlatform = kIsWeb;
  bool _isNavigatingToWaiting = false;

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
            final url = request.url.toLowerCase();

            if (_isFinishCallbackUrl(url)) {
              _handleFinishRedirect(request.url);
              return NavigationDecision.prevent;
            }

            if (url.contains('midtrans.com') ||
                url.contains('sandbox.midtrans') ||
                url.contains('snap.midtrans')) {
              return NavigationDecision.navigate;
            }

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

  bool _isFinishCallbackUrl(String url) {
    return url.contains('/api/midtrans/finish') ||
        (url.contains('/finish') && url.contains('order_id=')) ||
        (url.contains('order_id=') &&
            (url.contains('status_code=') ||
                url.contains('transaction_status=')));
  }

  Future<void> _handleFinishRedirect(String callbackUrl) async {
    if (_isNavigatingToWaiting) {
      return;
    }

    _isNavigatingToWaiting = true;

    final callbackUri = Uri.tryParse(callbackUrl);
    final callbackOrderRef = callbackUri?.queryParameters['order_id'];

    String resolvedOrderId =
        (widget.orderId?.toString() ?? callbackOrderRef ?? '').trim();
    int resolvedTransactionId = widget.transactionId;
    int? resolvedTotalPayment = widget.totalPayment;
    String resolvedPaymentMethod = (widget.paymentMethod ?? '').trim();
    String resolvedCreatedAt = (widget.transactionCreatedAt ?? '').trim();

    final fallbackRef = callbackOrderRef ??
        widget.orderId?.toString() ??
        widget.transactionId.toString();
    final snapshot = await ApiService().getPaymentStatus(fallbackRef);

    if (snapshot['success'] == true && snapshot['data'] is Map<String, dynamic>) {
      final data = snapshot['data'] as Map<String, dynamic>;

      final incomingOrderId = data['order_id']?.toString();
      if (incomingOrderId != null && incomingOrderId.trim().isNotEmpty) {
        resolvedOrderId = incomingOrderId.trim();
      }

      final incomingTransactionId = _asInt(data['transaction_id']);
      if (incomingTransactionId != null && incomingTransactionId > 0) {
        resolvedTransactionId = incomingTransactionId;
      }

      final incomingTotalPayment = _asInt(data['total_payment']);
      if (incomingTotalPayment != null && incomingTotalPayment > 0) {
        resolvedTotalPayment = incomingTotalPayment;
      }

      final incomingMethod = data['payment_method']?.toString();
      if (incomingMethod != null && incomingMethod.trim().isNotEmpty) {
        resolvedPaymentMethod = incomingMethod.trim();
      }

      final incomingCreatedAt = data['transaction_created_at']?.toString();
      if (incomingCreatedAt != null && incomingCreatedAt.trim().isNotEmpty) {
        resolvedCreatedAt = incomingCreatedAt.trim();
      }
    }

    if (resolvedOrderId.isEmpty) {
      resolvedOrderId = fallbackRef;
    }

    if (resolvedCreatedAt.isEmpty) {
      resolvedCreatedAt = DateTime.now().toIso8601String();
    }

    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WaitingPaymentPage(
          orderId: resolvedOrderId,
          transactionId: resolvedTransactionId,
          totalPayment: resolvedTotalPayment,
          paymentMethod: resolvedPaymentMethod,
          transactionCreatedAt: resolvedCreatedAt,
        ),
      ),
    );
  }

  int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse((value ?? '').toString());
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
                      'Setelah memilih metode pembayaran di Midtrans, '
                      'Anda akan diarahkan otomatis ke halaman menunggu pembayaran.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
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
