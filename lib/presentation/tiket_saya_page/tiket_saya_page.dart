import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myhiking/presentation/payment_method_screen/payment_method_screen.dart';
import 'package:myhiking/presentation/waiting_payment_page/waiting_payment_page.dart';
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
  static const Duration _paymentWindow = Duration(minutes: 15);
  static const Duration _pendingStatusPollingInterval = Duration(seconds: 12);

  String userId = '';
  String userName = '';
  final Set<int> _trackedPendingOrderIds = <int>{};
  final Map<int, _PendingPaymentMeta> _pendingPaymentMetaMap =
      <int, _PendingPaymentMeta>{};
  final Set<int> _expiredOrderIdsSyncing = <int>{};

  void _triggerExpiredTicketSync(int? orderId) {
    if (orderId == null || _expiredOrderIdsSyncing.contains(orderId)) {
      return;
    }

    _expiredOrderIdsSyncing.add(orderId);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ApiService().getPaymentStatus(orderId.toString());
      } catch (_) {}
      if (mounted && userId.isNotEmpty) {
        context.read<TiketSayaBloc>().add(TiketSayaUserIdEvent(userId));
      }
    });
  }

  Timer? _countdownTicker;
  Timer? _pendingStatusPollingTimer;

  @override
  void initState() {
    super.initState();
    _getUserProfile();
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    _pendingStatusPollingTimer?.cancel();
    super.dispose();
  }

  void _ensureCountdownTicker() {
    if (_countdownTicker?.isActive ?? false) {
      return;
    }

    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _stopCountdownTicker() {
    _countdownTicker?.cancel();
    _countdownTicker = null;
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
                          SizedBox(height: 8.h),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.h, vertical: 10.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10.h),
                              border:
                                  Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline,
                                    color: const Color(0xFF1D4ED8), size: 16.h),
                                SizedBox(width: 8.h),
                                Expanded(
                                  child: Text(
                                    'Tiket dengan status Cancel Requested/Cancelled dipindahkan ke Riwayat Transaksi. Lihat status refund di sana.',
                                    style: TextStyle(
                                      fontSize: 11.fSize,
                                      color: const Color(0xFF1E3A8A),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
            _syncPendingTracking(const <int>{});
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

          final pendingTickets = <_PendingTicketViewData>[];
          final overdueTickets = <_OverdueTicketViewData>[];
          final paidTickets = <TiketItemModel>[];

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          for (final ticket in activeTickets) {
            final orderId = int.tryParse(ticket.id ?? '');
            final tx = _findTransactionForOrder(state, orderId);
            final remainingTime = _resolveRemainingTime(
              ticket,
              tx,
              orderId: orderId,
            );

            if (_isPendingPaymentTicket(ticket, tx, orderId: orderId)) {
              if (remainingTime != null && remainingTime <= Duration.zero) {
                _triggerExpiredTicketSync(orderId);
                continue;
              }

              pendingTickets.add(
                _PendingTicketViewData(
                  model: ticket,
                  orderId: orderId,
                  transaction: tx,
                  remainingTime: remainingTime,
                ),
              );
            } else {
              // Check overdue: status 'Sedang Mendaki' + tanggal_turun sudah lewat
              final status = (ticket.status ?? '').trim();
              if (status == 'Sedang Mendaki' && ticket.tanggalTurun != null) {
                try {
                  final tanggalTurun = DateTime.parse(ticket.tanggalTurun!);
                  final turunDate = DateTime(tanggalTurun.year, tanggalTurun.month, tanggalTurun.day);
                  if (turunDate.isBefore(today)) {
                    final overdueDays = today.difference(turunDate).inDays;
                    overdueTickets.add(
                      _OverdueTicketViewData(
                        model: ticket,
                        overdueDays: overdueDays,
                      ),
                    );
                    continue;
                  }
                } catch (_) {}
              }
              paidTickets.add(ticket);
            }
          }

          _syncPendingTracking(
            pendingTickets.map((item) => item.orderId).whereType<int>().toSet(),
          );

          return ListView(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            children: [
              // === Seksi: Selesaikan Pembayaran (hidden jika kosong) ===
              if (pendingTickets.isNotEmpty) ...[
                _buildSectionTitle(
                  icon: Icons.access_time_filled,
                  iconColor: const Color(0xFFF97316),
                  title: 'Selesaikan Pembayaran',
                ),
                SizedBox(height: 12.h),
                ...pendingTickets.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == pendingTickets.length - 1 ? 0 : 12.h,
                    ),
                    child: ActiveTicketItemWidget(
                      model: data.model,
                      isPendingPaymentCard: true,
                      pendingRemainingTime: data.remainingTime,
                      isCountdownSyncing: data.remainingTime == null,
                      onTap: () => _handlePayNow(data),
                      onPayNowTap: () => _handlePayNow(data),
                    ),
                  );
                }),
                SizedBox(height: 24.h),
              ],

              // === Seksi: Pendakian Overdue (hidden jika kosong) ===
              if (overdueTickets.isNotEmpty) ...[
                _buildSectionTitle(
                  icon: Icons.warning_amber_rounded,
                  iconColor: const Color(0xFFDC2626),
                  title: 'Pendakian Overdue',
                ),
                SizedBox(height: 12.h),
                ...overdueTickets.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == overdueTickets.length - 1 ? 0 : 12.h,
                    ),
                    child: ActiveTicketItemWidget(
                      model: data.model,
                      isOverdueCard: true,
                      overdueDays: data.overdueDays,
                      onTap: () => _handleTicketTap(data.model, state),
                    ),
                  );
                }),
                SizedBox(height: 24.h),
              ],

              // === Seksi: Tiket Terpesan ===
              _buildSectionTitle(
                icon: Icons.check_circle,
                iconColor: const Color(0xFF16A34A),
                title: 'Tiket Terpesan',
              ),
              SizedBox(height: 12.h),
              if (paidTickets.isEmpty)
                _buildEmptySection(
                  icon: Icons.confirmation_number_outlined,
                  message: 'Belum ada tiket yang sudah lunas',
                )
              else
                ...paidTickets.asMap().entries.map((entry) {
                  final index = entry.key;
                  final model = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == paidTickets.length - 1 ? 0 : 12.h,
                    ),
                    child: ActiveTicketItemWidget(
                      model: model,
                      onTap: () => _handleTicketTap(model, state),
                    ),
                  );
                }),
              SizedBox(height: 8.h),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required Color iconColor,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22.h),
        SizedBox(width: 8.h),
        Text(
          title,
          style: TextStyle(
            fontSize: 18.fSize,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySection({
    required IconData icon,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.h),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9CA3AF), size: 18.h),
          SizedBox(width: 8.h),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.fSize,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TransaksiItemModel? _findTransactionForOrder(
    TiketSayaState state,
    int? orderId,
  ) {
    if (orderId == null) {
      return null;
    }

    final txMap = state.transactionMap;
    if (txMap == null) {
      return null;
    }

    return txMap[orderId];
  }

  bool _isPendingPaymentTicket(
    TiketItemModel model,
    TransaksiItemModel? tx, {
    int? orderId,
  }) {
    final status = (model.status ?? '').trim().toLowerCase();
    final txStatus = (tx?.status ?? '').trim().toLowerCase();
    final basePending = status == 'bayar' || txStatus == 'incomplete';

    if (!basePending) {
      return false;
    }

    if (orderId == null) {
      return true;
    }

    final meta = _pendingPaymentMetaMap[orderId];
    if (meta == null) {
      return true;
    }

    return meta.status == 'pending';
  }

  Duration? _resolveRemainingTime(
    TiketItemModel model,
    TransaksiItemModel? tx, {
    int? orderId,
  }) {
    if (orderId != null) {
      final meta = _pendingPaymentMetaMap[orderId];
      if (meta != null) {
        final remaining = meta.expiresAt.difference(DateTime.now());
        return remaining.isNegative ? Duration.zero : remaining;
      }
    }

    final createdAt = _resolveFallbackCreatedAt(model, tx);
    if (createdAt == null) {
      return null;
    }

    final expiresAt = createdAt.add(_paymentWindow);
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  DateTime? _resolveFallbackCreatedAt(
    TiketItemModel model,
    TransaksiItemModel? tx,
  ) {
    final candidates = [
      tx?.waktuPembayaran,
      model.updatedAt,
    ];

    for (final raw in candidates) {
      final value = (raw ?? '').trim();
      if (value.isEmpty) {
        continue;
      }

      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed.isUtc ? parsed.toLocal() : parsed;
      }
    }

    return null;
  }

  void _syncPendingTracking(Set<int> orderIds) {
    final isSameSet = _trackedPendingOrderIds.length == orderIds.length &&
        _trackedPendingOrderIds.containsAll(orderIds);

    if (isSameSet) {
      return;
    }

    _trackedPendingOrderIds
      ..clear()
      ..addAll(orderIds);

    _pendingPaymentMetaMap.removeWhere((key, _) => !orderIds.contains(key));

    _pendingStatusPollingTimer?.cancel();
    if (orderIds.isEmpty) {
      _stopCountdownTicker();
      return;
    }

    _ensureCountdownTicker();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshPendingPaymentStatuses(orderIds.toList());
    });

    _pendingStatusPollingTimer =
        Timer.periodic(_pendingStatusPollingInterval, (_) {
      _refreshPendingPaymentStatuses(_trackedPendingOrderIds.toList());
    });
  }

  Future<void> _refreshPendingPaymentStatuses(List<int> orderIds) async {
    if (!mounted || orderIds.isEmpty) {
      return;
    }

    bool hasChanges = false;
    bool shouldReloadTicketData = false;

    final results = await Future.wait(
      orderIds.map((orderId) async {
        try {
          final response =
              await ApiService().getPaymentStatus(orderId.toString());
          if (response['success'] != true) {
            return _PendingStatusFetchResult(orderId: orderId);
          }

          final payload = response['data'];
          if (payload is! Map<String, dynamic>) {
            return _PendingStatusFetchResult(orderId: orderId);
          }

          return _PendingStatusFetchResult(
            orderId: orderId,
            payload: payload,
          );
        } catch (_) {
          return _PendingStatusFetchResult(orderId: orderId);
        }
      }),
    );

    for (final result in results) {
      final payload = result.payload;
      if (payload == null) {
        continue;
      }

      final orderId = result.orderId;
      try {
        final status =
            (payload['status'] ?? 'pending').toString().trim().toLowerCase();
        final createdAt = _parseDateTime(payload['transaction_created_at']);
        if (createdAt == null) {
          continue;
        }

        final expiresAt = _parseDateTime(payload['payment_expires_at']) ??
            createdAt.add(_paymentWindow);

        final previous = _pendingPaymentMetaMap[orderId];
        final next = _PendingPaymentMeta(
          status: status,
          createdAt: createdAt,
          expiresAt: expiresAt,
        );

        if (previous != next) {
          _pendingPaymentMetaMap[orderId] = next;
          hasChanges = true;
        }

        if (status != 'pending') {
          shouldReloadTicketData = true;
        }
      } catch (_) {
        // Ignore malformed payload for this ticket and continue others.
      }
    }

    if (hasChanges && mounted) {
      setState(() {});
    }

    if (shouldReloadTicketData && mounted && userId.isNotEmpty) {
      context.read<TiketSayaBloc>().add(TiketSayaUserIdEvent(userId));
    }
  }

  DateTime? _parseDateTime(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return null;
    }

    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  Future<void> _handleTicketTap(
      TiketItemModel model, TiketSayaState state) async {
    int parsedId = int.tryParse(model.id ?? '') ?? 0;
    if (parsedId <= 0) return;

    final status = (model.status ?? '').trim();
    final normalizedStatus = status.toLowerCase();

    if (normalizedStatus == 'cancel requested' ||
        normalizedStatus == 'cancelled') {
      String formattedDate = '';
      try {
        DateTime tanggal = DateTime.parse(model.tanggalNaik.toString());
        formattedDate =
            DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(tanggal);
      } catch (e) {
        formattedDate = model.tanggalNaik ?? '';
      }

      await Navigator.of(context, rootNavigator: true).pushNamed(
        AppRoutes.refundRequestResultPage,
        arguments: {
          'orderId': parsedId,
          'mountainName': model.gunung ?? 'Gunung',
          'hikingDate': formattedDate,
        },
      );
      return;
    }

    // Check for unpaid
    final tx = state.transactionMap?[parsedId];
    final isUnpaid = status.toLowerCase() == 'bayar' ||
        (tx != null && tx.status?.toLowerCase() == 'incomplete');

    if (isUnpaid) {
      await _handlePayNow(
        _PendingTicketViewData(
          model: model,
          orderId: parsedId,
          transaction: tx,
          remainingTime: _resolveRemainingTime(model, tx, orderId: parsedId),
        ),
      );
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

  Future<void> _handlePayNow(_PendingTicketViewData pendingTicket) async {
    final parsedId = pendingTicket.orderId;
    if (parsedId == null || parsedId <= 0) {
      return;
    }

    final remaining = pendingTicket.remainingTime;
    if (remaining != null && remaining <= Duration.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran sudah melewati batas waktu.'),
          backgroundColor: Colors.red,
        ),
      );

      if (mounted && userId.isNotEmpty) {
        context.read<TiketSayaBloc>().add(TiketSayaUserIdEvent(userId));
      }
      return;
    }

    final resumed =
        await _openWaitingPayment(parsedId, pendingTicket.transaction);
    if (resumed) {
      if (mounted && userId.isNotEmpty) {
        context.read<TiketSayaBloc>().add(TiketSayaUserIdEvent(userId));
      }
      return;
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
  }

  Future<bool> _openWaitingPayment(int orderId, TransaksiItemModel? tx) async {
    try {
      final paymentResult = await ApiService().createMidtransPayment(
        orderId,
        reuseIfPending: true,
      );

      if (!mounted) {
        return false;
      }

      if (paymentResult['success'] == true &&
          (paymentResult['redirect_url'] != null ||
              paymentResult['payment_code'] != null ||
              paymentResult['deeplink_url'] != null ||
              paymentResult['qr_code_url'] != null ||
              paymentResult['qr_string'] != null)) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WaitingPaymentPage(
              orderId:
                  (_parseInt(paymentResult['order_id']) ?? orderId).toString(),
              transactionId: paymentResult['transaction_id'] ?? tx?.id ?? 0,
              totalPayment: _parseInt(paymentResult['total_payment']),
              paymentMethod: paymentResult['payment_method'] ?? tx?.paymentType,
              transactionCreatedAt: paymentResult['transaction_created_at'] ??
                  tx?.waktuPembayaran ??
                  DateTime.now().toIso8601String(),
              paymentCode: paymentResult['payment_code']?.toString(),
              paymentCodeLabel: paymentResult['payment_code_label']?.toString(),
              paymentInstruction:
                  paymentResult['payment_instruction']?.toString(),
              deeplinkUrl: paymentResult['deeplink_url']?.toString(),
              qrCodeUrl: paymentResult['qr_code_url']?.toString(),
              qrString: paymentResult['qr_string']?.toString(),
            ),
          ),
        );
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

  int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse((value ?? '').toString());
  }
}

class _PendingPaymentMeta {
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;

  const _PendingPaymentMeta({
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is _PendingPaymentMeta &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.expiresAt == expiresAt;
  }

  @override
  int get hashCode => Object.hash(status, createdAt, expiresAt);
}

class _PendingTicketViewData {
  final TiketItemModel model;
  final int? orderId;
  final TransaksiItemModel? transaction;
  final Duration? remainingTime;

  const _PendingTicketViewData({
    required this.model,
    required this.orderId,
    required this.transaction,
    required this.remainingTime,
  });
}

class _PendingStatusFetchResult {
  final int orderId;
  final Map<String, dynamic>? payload;

  const _PendingStatusFetchResult({
    required this.orderId,
    this.payload,
  });
}

class _OverdueTicketViewData {
  final TiketItemModel model;
  final int overdueDays;

  const _OverdueTicketViewData({
    required this.model,
    required this.overdueDays,
  });
}
