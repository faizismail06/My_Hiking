import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myhiking/presentation/midtrans_payment_screen/midtrans_payment_screen.dart';
import 'package:myhiking/presentation/payment_method_screen/payment_method_screen.dart';
import '../../api/api_service.dart';
import '../../core/app_export.dart';
import 'bloc/tiket_saya_bloc.dart';
import 'models/tiket_saya_model.dart';
import 'widgets/active_ticket_item_widget.dart';

class TiketSayaPage extends StatefulWidget {
  const TiketSayaPage({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider<TiketSayaBloc>(
      create: (context) => TiketSayaBloc(const TiketSayaState(
        tiketSayaModelObj: TiketSayaModel(),
      ))
        ..add(TiketSayaInitialEvent()),
      child: const TiketSayaPage(),
    );
  }

  @override
  State<TiketSayaPage> createState() => _TiketSayaPageState();
}

class _TiketSayaPageState extends State<TiketSayaPage> {
  String userId = '';
  String userName = '';

  @override
  void initState() {
    super.initState();
    _getUserProfile();
  }

  Future<void> _getUserProfile() async {
    final token = await ApiService().getToken();
    if (token != null) {
      final response = await ApiService().getUserProfile(token);
      if (response['success']) {
        final data = response['data'] as Map<String, dynamic>;
        setState(() {
          userId = data['id'].toString();
          userName = (data['name'] ?? '').toString();
        });
        if (mounted) {
          context.read<TiketSayaBloc>().add(TiketSayaUserIdEvent(userId));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray50,
        body: Container(
          width: double.maxFinite,
          decoration: BoxDecoration(
            color: appTheme.gray50,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(height: 20.h),
              _buildHeaderSection(context),
              Expanded(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 22.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Tiket Saya",
                            style: CustomTextStyles.titleMediumBlack900,
                          ),
                          SizedBox(height: 10.h),
                          _buildTicketList(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Header section with image and user greeting
  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.only(left: 10.h),
      child: Row(
        children: [
          CustomImageView(
            imagePath: ImageConstant.imgriwayat,
            height: 136.h,
            width: 186.h,
          ),
          SizedBox(width: 8.h),
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                width: double.maxFinite,
                margin: EdgeInsets.only(bottom: 28.h),
                padding: EdgeInsets.only(
                  left: 30.h,
                  top: 8.h,
                  bottom: 8.h,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 4.h),
                    Text(
                      "lbl_hello".tr,
                      style: CustomTextStyles.titleMediumOnPrimary_2,
                    ),
                    Text(
                      userName,
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  /// Active tickets list (only non-Selesai orders)
  Widget _buildTicketList(BuildContext context) {
    return Expanded(
      child: BlocBuilder<TiketSayaBloc, TiketSayaState>(
        builder: (context, state) {
          if (state.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.green.shade900),
              ),
            );
          }

          final activeTickets =
              state.tiketSayaModelObj?.activeTicketsList ?? [];

          if (activeTickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    size: 48.h,
                    color: const Color(0xFF9CA3AF),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Belum ada tiket aktif',
                    style: TextStyle(
                      fontSize: 14.fSize,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            separatorBuilder: (context, index) => SizedBox(height: 14.h),
            itemCount: activeTickets.length,
            itemBuilder: (context, index) {
              final model = activeTickets[index];
              return ActiveTicketItemWidget(
                model: model,
                onTap: () => _handleTicketTap(model, state),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleTicketTap(
      TiketItemModel model, TiketSayaState state) async {
    int parsedId = int.tryParse(model.id ?? '') ?? 0;
    if (parsedId <= 0) return;

    final status = (model.status ?? '').trim();

    // Check for unpaid
    final tx = state.transactionMap?[parsedId];
    final isUnpaid = status.toLowerCase() == 'bayar' ||
        (tx != null && tx.status?.toLowerCase() == 'incomplete');

    if (isUnpaid) {
      final hasSelectedPaymentMethod =
          tx != null && (tx.paymentType?.trim().isNotEmpty ?? false);

      if (hasSelectedPaymentMethod) {
        final resumed = await _resumePendingPayment(parsedId, tx!);
        if (resumed) {
          if (mounted && userId.isNotEmpty) {
            context.read<TiketSayaBloc>().add(TiketSayaUserIdEvent(userId));
          }
          return;
        }
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentMethodScreen(orderId: parsedId),
        ),
      );

      if (mounted && userId.isNotEmpty) {
        context.read<TiketSayaBloc>().add(TiketSayaUserIdEvent(userId));
      }
      return;
    }

    // Navigate to ticket action screen
    String formattedDate = '';
    try {
      DateTime tanggal = DateTime.parse(model.tanggalNaik.toString());
      formattedDate = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(tanggal);
    } catch (e) {
      formattedDate = model.tanggalNaik ?? '';
    }

    final result = await Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.ticketActionScreen,
      arguments: {
        'orderId': parsedId,
        'status': status.isEmpty ? 'Booking' : status,
        'mountainName': model.gunung ?? 'Gunung',
        'hikingDate': formattedDate,
      },
    );

    if (result == true && mounted && userId.isNotEmpty) {
      context.read<TiketSayaBloc>().add(TiketSayaUserIdEvent(userId));
    }
  }

  Future<bool> _resumePendingPayment(int orderId, TransaksiItemModel tx) async {
    try {
      final paymentResult = await ApiService().createMidtransPayment(
        orderId,
        reuseIfPending: true,
      );

      if (!mounted) {
        return false;
      }

      if (paymentResult['success'] == true &&
          paymentResult['redirect_url'] != null) {
        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (context) => MidtransPaymentScreen(
              transactionId: paymentResult['transaction_id'] ?? tx.id ?? 0,
              redirectUrl: paymentResult['redirect_url'],
              snapToken: paymentResult['snap_token'],
            ),
          ),
        );

        if (result != null && mounted) {
          final message = result['message']?.toString();
          if (message != null && message.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: (result['status'] == 'success')
                    ? Colors.green
                    : Colors.orange,
              ),
            );
          }
        }

        return true;
      }

      final message = paymentResult['message']?.toString() ?? '';
      if (message.toLowerCase().contains('melewati batas waktu')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }
}
