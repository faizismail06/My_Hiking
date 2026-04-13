import 'package:flutter/material.dart';
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
      create: (context) =>
          RiwayatTransaksiBloc(const RiwayatTransaksiState())
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
            onPressed: () => Navigator.pop(context),
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
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.green.shade900),
                ),
              );
            }

            final completedHikes = state.completedHikesList;

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
                  if (completedHikes.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(left: 4.h, bottom: 12.h),
                      child: Text(
                        'Pendakian Selesai',
                        style: TextStyle(
                          fontSize: 16.fSize,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                  // Hiking records or empty state
                  if (completedHikes.isEmpty)
                    _buildEmptyState()
                  else
                    ...List.generate(
                      completedHikes.length,
                      (index) => HikingRecordCardWidget(
                        model: completedHikes[index],
                        index: index,
                      ),
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
}
