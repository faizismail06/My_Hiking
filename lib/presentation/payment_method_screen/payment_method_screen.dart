import 'package:flutter/material.dart';
import 'package:another_stepper/dto/stepper_data.dart';
import 'package:another_stepper/widgets/another_stepper.dart';
import 'package:intl/intl.dart';
import 'package:myhiking/presentation/midtrans_payment_screen/midtrans_payment_screen.dart';
import 'package:myhiking/presentation/home_screen/home_screen.dart';
import '../../api/api_service.dart';
import '../../core/app_export.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/app_bar/appbar_subtitle.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../../widgets/custom_elevated_button.dart';

class PaymentMethodScreen extends StatefulWidget {
  final int orderId;
  const PaymentMethodScreen({super.key, required this.orderId});

  @override
  _PaymentMethodScreenState createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _isCancelling = false;
  Map<String, dynamic>? _orderData;
  List<dynamic> _paymentMethods = [];
  String? _selectedPaymentMethod;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Fetch order details and payment methods in parallel
      final results = await Future.wait([
        ApiService().fetchPesanan(widget.orderId),
        ApiService().getMidtransPaymentMethods(),
      ]);

      if (mounted) {
        setState(() {
          _orderData = results[0];
          if (results[1]['success'] == true) {
            _paymentMethods = results[1]['data'] ?? [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat data';
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(dynamic amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount ?? 0);
  }

  IconData _getPaymentIcon(String type) {
    switch (type) {
      case 'e_wallet':
        return Icons.account_balance_wallet;
      case 'bank_transfer':
        return Icons.account_balance;
      case 'cstore':
        return Icons.store;
      case 'credit_card':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: _buildBody(),
        bottomNavigationBar: _buildPaymentButton(context),
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
            onPressed: () => Navigator.of(context).pop(),
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

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            SizedBox(height: 16),
            Text('Memuat data...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(_errorMessage!, style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _fetchData();
              },
              child: Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepper(),
          SizedBox(height: 24.h),
          _buildOrderSummaryCard(),
          SizedBox(height: 16.h),
          _buildPaymentMethodSelectionCard(),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10.h),
      child: AnotherStepper(
        iconHeight: 26,
        iconWidth: 26,
        stepperDirection: Axis.horizontal,
        activeIndex: 1,
        barThickness: 4,
        inverted: true,
        stepperList: [
          StepperData(iconWidget: _buildStepperIcon("1", true)),
          StepperData(iconWidget: _buildStepperIcon("2", true)),
          StepperData(iconWidget: _buildStepperIcon("3", false)),
        ],
      ),
    );
  }

  Widget _buildStepperIcon(String label, bool isActive) {
    return Container(
      height: 26.h,
      width: 26.h,
      decoration: BoxDecoration(
        color: isActive ? theme.colorScheme.primary : appTheme.gray5001,
        borderRadius: BorderRadius.circular(14.h),
        border: isActive
            ? null
            : Border.all(color: appTheme.blueGray100, width: 2.h),
      ),
      child: Center(
        child: Text(
          label,
          style: isActive
              ? CustomTextStyles.titleMediumOnPrimary_2
              : TextStyle(color: appTheme.blueGray100),
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    final order = _orderData?['order'];
    final mountain = order?['mountain'];
    final trail = order?['trail'];
    final members = order?['members'] as List? ?? [];
    final totalMembers = members.length + 1;
    final pricePerPerson = order?['total_harga_tiket'] ?? 0;
    final totalPrice = totalMembers * pricePerPerson;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.landscape,
                    color: theme.colorScheme.primary, size: 24),
                SizedBox(width: 8),
                Text(
                  'Ringkasan Pesanan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            Divider(height: 24),
            _buildSummaryRow('Gunung', mountain?['nama'] ?? '-'),
            _buildSummaryRow('Jalur', trail?['nama'] ?? '-'),
            _buildSummaryRow('Tanggal Naik', order?['tanggal_naik'] ?? '-'),
            _buildSummaryRow('Tanggal Turun', order?['tanggal_turun'] ?? '-'),
            _buildSummaryRow('Jumlah Pendaki', '$totalMembers orang'),
            _buildSummaryRow('Harga/Orang', _formatCurrency(pricePerPerson)),
            Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Pembayaran',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  _formatCurrency(totalPrice),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelectionCard() {
    // Group payment methods by type
    Map<String, List<dynamic>> groupedMethods = {};
    for (var method in _paymentMethods) {
      String type = method['type'] ?? 'other';
      if (!groupedMethods.containsKey(type)) {
        groupedMethods[type] = [];
      }
      groupedMethods[type]!.add(method);
    }

    String _getTypeTitle(String type) {
      switch (type) {
        case 'e_wallet':
          return 'E-Wallet';
        case 'bank_transfer':
          return 'Virtual Account';
        case 'cstore':
          return 'Gerai Retail';
        case 'credit_card':
          return 'Kartu Kredit/Debit';
        default:
          return 'Lainnya';
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: theme.colorScheme.primary, size: 24),
                SizedBox(width: 8),
                Text(
                  'Pilih Metode Pembayaran',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            Divider(height: 24),
            ...groupedMethods.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Row(
                      children: [
                        Icon(_getPaymentIcon(entry.key),
                            size: 18, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Text(
                          _getTypeTitle(entry.key),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...entry.value
                      .map((method) => _buildPaymentMethodItem(method)),
                  SizedBox(height: 8.h),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodItem(Map<String, dynamic> method) {
    bool isSelected = _selectedPaymentMethod == method['id'];

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method['id'];
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.h),
        padding: EdgeInsets.all(12.h),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.05)
              : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method['name'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.black87,
                    ),
                  ),
                  if (method['description'] != null)
                    Text(
                      method['description'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle,
                  color: theme.colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton(BuildContext context) {
    bool canPay = _selectedPaymentMethod != null &&
        !_isProcessing &&
        !_isCancelling &&
        _orderData != null;

    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedPaymentMethod == null)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(
                'Pilih metode pembayaran terlebih dahulu',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: 12,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    canPay ? theme.colorScheme.primary : Colors.grey,
                disabledBackgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: canPay ? () => _processPayment(context) : null,
              icon: _isProcessing
                  ? Container(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.payment, color: Colors.white, size: 20),
              label: Text(
                _isProcessing ? "MEMPROSES..." : "BAYAR SEKARANG",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Manrope',
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                foregroundColor: Colors.red.shade600,
              ),
              onPressed: (_isProcessing || _isCancelling)
                  ? null
                  : () => _showCancelOrderConfirmation(context),
              icon: _isCancelling
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.red.shade400,
                        ),
                      ),
                    )
                  : Icon(Icons.delete_outline),
              label: Text(
                _isCancelling ? 'MEMBATALKAN...' : 'BATALKAN PESANAN',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment(BuildContext context) async {
    if (_selectedPaymentMethod == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Create Midtrans payment with selected payment method
      final paymentResult = await ApiService().createMidtransPayment(
        widget.orderId,
        paymentMethod: _selectedPaymentMethod,
        reuseIfPending: true,
      );

      if (!mounted) return;

      if (paymentResult['success'] == true &&
          paymentResult['redirect_url'] != null) {
        // Navigate to Midtrans payment screen
        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (context) => MidtransPaymentScreen(
              transactionId: paymentResult['transaction_id'] ?? 0,
              redirectUrl: paymentResult['redirect_url'],
              snapToken: paymentResult['snap_token'],
            ),
          ),
        );

        // Handle payment result
        if (result != null && mounted) {
          _handlePaymentResult(context, result, widget.orderId);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(paymentResult['message'] ?? 'Gagal membuat pembayaran'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error processing payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses pembayaran. Silakan coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showCancelOrderConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Batalkan Pesanan?'),
          content: Text(
            'Pesanan ini akan dihapus dari database. Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Kembali'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _cancelOrder(context);
              },
              child: Text('Ya, Batalkan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelOrder(BuildContext context) async {
    setState(() {
      _isCancelling = true;
    });

    try {
      final result = await ApiService().cancelOrder(widget.orderId);
      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(result['message']?.toString() ?? 'Pesanan dibatalkan.'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          AppRoutes.homeScreen,
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message']?.toString() ?? 'Gagal membatalkan pesanan.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat membatalkan pesanan.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  void _handlePaymentResult(
      BuildContext context, Map<String, dynamic> result, int orderId) {
    final status = result['status'] ?? 'pending';

    if (status == 'success') {
      // Payment success - navigate to home screen and show success message
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        AppRoutes.homeScreen,
        (route) => false,
      );

      // Show success snackbar after navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pembayaran berhasil! Transaksi Anda sudah lunas.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      });
    } else if (status == 'pending') {
      // Payment pending - navigate to home screen
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        AppRoutes.homeScreen,
        (route) => false,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silakan cek status pembayaran di menu Tiket saya'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      });
    } else if (status == 'cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pembayaran dibatalkan'),
          backgroundColor: Colors.grey,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Pembayaran gagal'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
