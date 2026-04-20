import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/api_service.dart';
import '../../core/app_export.dart';
import '../tiket_saya_page/models/tiket_saya_model.dart';
import '../tiket_saya_page/widgets/hiking_record_card_widget.dart';
import '../tiket_saya_page/widgets/stats_header_widget.dart';
import '../tiket_saya_page/widgets/tier_progress_widget.dart';
import 'bloc/riwayat_transaksi_bloc.dart';

class RiwayatTransaksiPage extends StatefulWidget {
  const RiwayatTransaksiPage({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider<RiwayatTransaksiBloc>(
      create: (context) => RiwayatTransaksiBloc(const RiwayatTransaksiState())
        ..add(RiwayatTransaksiInitialEvent()),
      child: const RiwayatTransaksiPage(),
    );
  }

  @override
  State<RiwayatTransaksiPage> createState() => _RiwayatTransaksiPageState();
}

class _RiwayatTransaksiPageState extends State<RiwayatTransaksiPage> {
  String userId = '';
  String userName = '';
  String? userTier;
  String? userTierSource;
  String _selectedFilter = 'Semua';

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
          userTier = data['tier']?.toString();
          userTierSource = data['tier_source']?.toString();
        });
        if (mounted) {
          context
              .read<RiwayatTransaksiBloc>()
              .add(RiwayatTransaksiUserIdEvent(userId));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: const Color(0xFF1A1A2E)),
            onPressed: () => NavigatorService.pushNamedAndRemoveUntil(
              AppRoutes.homeScreen,
              arguments: {
                'initialInnerRoute': AppRoutes.profileScreen,
              },
            ),
          ),
          title: Text(
            'Riwayat Transaksi',
            style: TextStyle(
              fontSize: 18.fSize,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          centerTitle: false,
        ),
        body: BlocBuilder<RiwayatTransaksiBloc, RiwayatTransaksiState>(
          builder: (context, state) {
            if (state.isLoading) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.green.shade900),
                ),
              );
            }

            final completedHikes = state.completedHikesList;
            var historyOrders =
                List<TiketItemModel>.from(state.historyOrdersList);

            // Urutkan riwayat dari terbaru ke terlama berdasarkan updated_at di backend atau fallback
            historyOrders.sort((a, b) {
              final dateA =
                  DateTime.tryParse(a.updatedAt ?? a.tanggalNaik ?? '') ??
                      DateTime(0);
              final dateB =
                  DateTime.tryParse(b.updatedAt ?? b.tanggalNaik ?? '') ??
                      DateTime(0);
              // Fallback ke ID jika tanggal sama (atau null)
              if (dateA == dateB) {
                final idA = int.tryParse(a.id ?? '0') ?? 0;
                final idB = int.tryParse(b.id ?? '0') ?? 0;
                return idB.compareTo(idA);
              }
              return dateB.compareTo(dateA);
            });

            // Ekstrak status unik untuk filter
            final availableStatuses = historyOrders
                .map((e) => e.status ?? 'Unknown')
                .where((s) => s.isNotEmpty)
                .toSet()
                .toList()
              ..sort();

            final filterOptions = ['Semua', ...availableStatuses];

            if (!filterOptions.contains(_selectedFilter)) {
              _selectedFilter = 'Semua';
            }

            // Terapkan filter
            final filteredOrders = historyOrders.where((item) {
              if (_selectedFilter == 'Semua') return true;
              return (item.status ?? '') == _selectedFilter;
            }).toList();

            // Calculate unique mountains
            final uniqueMountains = completedHikes
                .map((h) => h.gunung?.toLowerCase() ?? '')
                .where((g) => g.isNotEmpty)
                .toSet()
                .length;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 18.h, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tier Progress
                  TierProgressWidget(
                    userTier: userTier,
                    tierSource: userTierSource,
                  ),
                  SizedBox(height: 14.h),
                  // Stats Header
                  StatsHeaderWidget(
                    totalCompletedHikes: completedHikes.length,
                    uniqueMountains: uniqueMountains,
                    userName: userName,
                  ),
                  SizedBox(height: 20.h),
                  // Section title
                  if (historyOrders.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(left: 4.h, bottom: 8.h),
                      child: Text(
                        'Riwayat Pendakian',
                        style: TextStyle(
                          fontSize: 16.fSize,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                    ),

                  // Filter Chips
                  if (historyOrders.isNotEmpty)
                    SizedBox(
                      height: 36.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: filterOptions.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(width: 8.h),
                        itemBuilder: (context, index) {
                          final option = filterOptions[index];
                          final isSelected = _selectedFilter == option;
                          return ChoiceChip(
                            label: Text(
                              option,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF1A1A2E),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 13.fSize,
                              ),
                            ),
                            selected: isSelected,
                            showCheckmark: false,
                            selectedColor: const Color(0xFF1B8A5A),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.h),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF1B8A5A)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = option;
                              });
                            },
                          );
                        },
                      ),
                    ),

                  if (historyOrders.isNotEmpty) SizedBox(height: 12.h),

                  if (filteredOrders.any((item) {
                    final s = (item.status ?? '').toLowerCase();
                    return s == 'cancel requested' || s == 'cancelled';
                  }))
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 12.h),
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.h, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10.h),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: const Color(0xFF1D4ED8), size: 16.h),
                          SizedBox(width: 8.h),
                          Expanded(
                            child: Text(
                              'Tap data dengan status Cancel Requested/Cancelled untuk melihat status proses refund.',
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
                  // Hiking records or empty state
                  if (filteredOrders.isEmpty)
                    _buildEmptyState()
                  else
                    ...List.generate(
                      filteredOrders.length,
                      (index) {
                        final item = filteredOrders[index];
                        final status = (item.status ?? '').trim().toLowerCase();
                        final canOpenRefundResult =
                            status == 'cancel requested' ||
                                status == 'cancelled';

                        return HikingRecordCardWidget(
                          model: item,
                          index: index,
                          onTap: canOpenRefundResult
                              ? () => _onTapHistoryOrder(item)
                              : null,
                        );
                      },
                    ),
                  SizedBox(height: 20.h),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.h,
              height: 80.h,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20.h),
              ),
              child: Icon(
                Icons.terrain_rounded,
                size: 40.h,
                color: const Color(0xFF9CA3AF),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Belum Ada Riwayat',
              style: TextStyle(
                fontSize: 16.fSize,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Riwayat pendakian yang sudah selesai\nakan muncul di sini',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.fSize,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onTapHistoryOrder(TiketItemModel model) async {
    final parsedId = int.tryParse(model.id ?? '') ?? 0;
    if (parsedId <= 0) {
      return;
    }

    final normalizedStatus = (model.status ?? '').trim().toLowerCase();
    if (normalizedStatus != 'cancel requested' &&
        normalizedStatus != 'cancelled') {
      return;
    }

    String formattedDate = '';
    try {
      final tanggal = DateTime.parse(model.tanggalNaik.toString());
      formattedDate = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(tanggal);
    } catch (_) {
      formattedDate = model.tanggalNaik ?? '-';
    }

    await Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.refundRequestResultPage,
      arguments: {
        'orderId': parsedId,
        'mountainName': model.gunung ?? 'Gunung',
        'hikingDate': formattedDate,
      },
    );
  }
}
