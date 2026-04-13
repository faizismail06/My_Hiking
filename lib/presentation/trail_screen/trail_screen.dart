import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui' as ui; // Tambahan untuk efek blur/glassmorphism
import 'package:myhiking/api/api_service.dart';
import 'package:myhiking/models/model.dart';
import 'package:myhiking/presentation/booking_screen/bloc/booking_bloc.dart';
import 'package:myhiking/presentation/booking_screen/booking_screen.dart';
import 'package:myhiking/presentation/data_profile_screen/bloc/data_profile_bloc.dart';
import 'package:myhiking/presentation/data_profile_screen/data_profile_screen.dart';
import 'package:myhiking/presentation/experience_onboarding_screen/experience_onboarding_screen.dart';
import 'package:myhiking/presentation/rules_screen/bloc/rules_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_export.dart';
import '../../widgets/weather_widget.dart' show WeatherBadge;
import '../trail_preview_screen/trail_preview_screen.dart';
import '../rules_screen/rules_screen.dart';
import 'bloc/trail_bloc.dart';
import 'models/trail_screen_model.dart';

class TrailScreen extends StatefulWidget {
  final int? jalurId;
  final int? idGunung;

  const TrailScreen({super.key, this.jalurId, this.idGunung});

  @override
  State<TrailScreen> createState() => _TrailScreenState();
}

class _TrailScreenState extends State<TrailScreen> {
  late String imageUrl;
  String userName = '';
  int userId = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  void _launchURL(TrailScreenModel model) async {
    if (model.mapBasecamp.isNotEmpty) {
      try {
        final Uri url = Uri.parse(model.mapBasecamp);
        if (!await launchUrl(url, mode: LaunchMode.platformDefault)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Tidak dapat membuka maps'),
                  backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Gagal membuka maps: ${e.toString()}'),
                backgroundColor: Colors.red),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('URL maps tidak tersedia'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _getUser() async {
    final token = await ApiService().getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    try {
      final response = await ApiService().getUser(token);
      if (response['success']) {
        if (mounted) {
          setState(() {
            userName = response['data']['name'];
            userId = response['data']['id'];
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TrailBloc(apiService: ApiService())
        ..add(TrailInitialEvent(
            jalurId: widget.jalurId!, idGunung: widget.idGunung!)),
      child: BlocBuilder<TrailBloc, TrailState>(
        builder: (context, state) {
          if (state.isLoading) {
            return Scaffold(
              backgroundColor: const Color(0xFFF8F9FA),
              body: Center(
                  child: CircularProgressIndicator(
                      color: theme.colorScheme.primary)),
            );
          }

          if (state.errorMessage != null) {
            return Scaffold(
              body: Center(
                child: Text('Error: ${state.errorMessage}',
                    style: TextStyle(color: Colors.grey[600])),
              ),
            );
          }

          if (state.jalur == null || state.gunung == null) {
            return Scaffold(
              body: Center(
                child: Text('Detail jalur tidak tersedia.',
                    style: TextStyle(color: Colors.grey[600])),
              ),
            );
          }

          final resDetailRouteCentres = ResDetailRouteCentres(
            status: true,
            message: "Success",
            jalur: state.jalur!,
            gunung: state.gunung!,
            dss: state.dss,
          );

          final trailModel =
              TrailScreenModel.fromResDetailRouteCentres(resDetailRouteCentres);
          imageUrl = trailModel.gambar ?? 'assets/images/img_error.png';

          return SafeArea(
            top: false, // Edge-to-edge design
            child: Scaffold(
              backgroundColor: Colors.white,
              body: Stack(
                children: [
                  // 1. Fixed Hero Image Background
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 480.h,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey[300],
                            child: const Center(
                                child:
                                    Icon(Icons.image_not_supported, size: 40)),
                          ),
                        ),
                        // Soft Gradient Overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.4),
                                Colors.transparent,
                                Colors.black.withOpacity(0.2),
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Scrollable Content (Overlapping the image)
                  Positioned.fill(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          // Spacer to push content down, revealing the image
                          SizedBox(height: 340.h),

                          // Main Content Container with Rounded Tops
                          Container(
                            width: double.maxFinite,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA), // Soft background
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(32.h),
                                topRight: Radius.circular(32.h),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, -4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24.h, vertical: 28.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Drag indicator (aesthetic)
                                  Center(
                                    child: Container(
                                      width: 48.h,
                                      height: 5.h,
                                      margin: EdgeInsets.only(bottom: 24.h),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius:
                                            BorderRadius.circular(10.h),
                                      ),
                                    ),
                                  ),

                                  _buildTrailDetailSection(context, trailModel),
                                  SizedBox(height: 20.h),

                                  _buildTrailActions(context, trailModel),
                                  SizedBox(height: 24.h),

                                  _buildDssRecommendationCard(
                                      context, trailModel),
                                  SizedBox(height: 24.h),

                                  _buildPreviewJalurButton(context, trailModel),
                                  SizedBox(height: 12.h),

                                  _buildRulesButton(context),
                                  SizedBox(height: 32.h),

                                  _buildPesanSekarangButton(context),
                                  SizedBox(
                                      height: 40.h), // Extra padding at bottom
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Floating Glassmorphism Header (Back Button & Weather)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12.h,
                    left: 20.h,
                    right: 20.h,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Glass Back Button
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.h),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: EdgeInsets.all(10.h),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12.h),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.3)),
                                  ),
                                  child: Icon(Icons.arrow_back_ios_new_rounded,
                                      color: Colors.white, size: 20.h),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Weather Badge
                        if (state.jalur != null &&
                            state.jalur!.latitude != null &&
                            state.jalur!.longitude != null)
                          Flexible(
                            fit: FlexFit.loose,
                            child: WeatherBadge(
                              latitude: state.jalur!.latitude,
                              longitude: state.jalur!.longitude,
                              locationName: state.jalur!.nama,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// **Trail Details Section (Title & Location)**
  Widget _buildTrailDetailSection(
      BuildContext context, TrailScreenModel trailModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Jalur ${trailModel.name}",
          style: TextStyle(
            fontSize: 26.fSize,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            letterSpacing: 0.2,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_on_rounded,
                color: Colors.grey[500], size: 18.h),
            SizedBox(width: 6.h),
            Expanded(
              child: Text(
                trailModel.location.toString(),
                style: TextStyle(
                  fontSize: 14.fSize,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// **DSS Recommendation Card**
  Widget _buildDssRecommendationCard(
      BuildContext context, TrailScreenModel trailModel) {
    final dss = trailModel.dss;
    if (dss == null) return const SizedBox.shrink();

    Color badgeColor;
    String badgeText;
    IconData riskIcon;

    switch (dss.riskLevel) {
      case 'high_risk':
        badgeColor = const Color(0xFFE53935); // Modern Red
        badgeText = 'Risiko Tinggi';
        riskIcon = Icons.warning_rounded;
        break;
      case 'caution':
        badgeColor = const Color(0xFFF4511E); // Modern Orange/Amber
        badgeText = 'Perlu Pertimbangan';
        riskIcon = Icons.info_rounded;
        break;
      default:
        badgeColor = const Color(0xFF1B8A5A); // Primary Green
        badgeText = 'Aman';
        riskIcon = Icons.check_circle_rounded;
    }

    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(18.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.h),
        border: Border.all(color: badgeColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.h, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.h),
                    ),
                    child: Row(
                      children: [
                        Icon(riskIcon, color: badgeColor, size: 14.h),
                        SizedBox(width: 6.h),
                        Text(
                          badgeText,
                          style: TextStyle(
                            color: badgeColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.fSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10.h),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  'Skor: ${dss.finalScore.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.fSize,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (dss.weather != null)
            Container(
              padding: EdgeInsets.all(12.h),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(12.h),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_rounded,
                      color: Colors.blueGrey[400], size: 20.h),
                  SizedBox(width: 10.h),
                  Expanded(
                    child: Text(
                      '${dss.weather!.condition} • ${dss.weather!.temperature?.toStringAsFixed(0) ?? '-'}°C • Angin ${dss.weather!.windSpeed?.toStringAsFixed(1) ?? '-'} km/h',
                      style: TextStyle(
                        fontSize: 12.fSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (dss.weather != null) SizedBox(height: 12.h),
          Text(
            dss.message,
            style: TextStyle(
              fontSize: 13.fSize,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          if (dss.reasoning.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Divider(color: Colors.grey[200]),
            SizedBox(height: 8.h),
            ...dss.reasoning.map((item) => Padding(
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, size: 6.h, color: Colors.grey[400]),
                      SizedBox(width: 8.h),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 12.fSize,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  /// **Trail Actions (Distance & Map)**
  Widget _buildTrailActions(BuildContext context, TrailScreenModel trailModel) {
    return Row(
      children: [
        // Card Jarak
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.h),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(8.h),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.route_rounded,
                      color: Theme.of(context).colorScheme.primary, size: 20.h),
                ),
                SizedBox(width: 12.h),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Jarak Tempuh",
                        style: TextStyle(
                            fontSize: 11.fSize,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500)),
                    Text("${trailModel.distanceLabel} km",
                        style: TextStyle(
                            fontSize: 15.fSize,
                            color: Colors.black87,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12.h),
        // Card Open Maps
        Expanded(
          child: InkWell(
            onTap: () => _launchURL(trailModel),
            borderRadius: BorderRadius.circular(16.h),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.h),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(8.h),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.map_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20.h),
                  ),
                  SizedBox(width: 12.h),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Basecamp",
                            style: TextStyle(
                                fontSize: 11.fSize,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500)),
                        Text("Maps",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 15.fSize,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewJalurButton(
      BuildContext context, TrailScreenModel trailModel) {
    return SizedBox(
      width: double.maxFinite,
      height: 54.h,
      child: ElevatedButton.icon(
        icon: Icon(Icons.explore_rounded,
            size: 20.h, color: Theme.of(context).colorScheme.primary),
        label: Text(
          "Preview Jalur Lengkap",
          style: TextStyle(
              fontSize: 15.fSize,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.h)),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TrailPreviewScreen(
                trailName: trailModel.name,
                routePreview: trailModel.routePreview,
                basecampLatitude: trailModel.latitude,
                basecampLongitude: trailModel.longitude,
                posts: trailModel.posts,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRulesButton(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      height: 54.h,
      child: OutlinedButton.icon(
        icon: Icon(Icons.menu_book_rounded, size: 20.h, color: Colors.black87),
        label: Text(
          "Tata Tertib dan Peraturan",
          style: TextStyle(
              fontSize: 15.fSize,
              fontWeight: FontWeight.w700,
              color: Colors.black87),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.h)),
          backgroundColor: Colors.white,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => RulesBloc(apiService: ApiService()),
                child: RulesScreen(jalurId: widget.jalurId),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPesanSekarangButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.h),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      width: double.maxFinite,
      height: 58.h,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.h)),
        ),
        onPressed: () async {
          final allowed = await _guardBeforeBooking(context);
          if (!allowed) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => BookingBloc(apiService: ApiService()),
                child: BookingScreen(
                    jalurId: widget.jalurId, idGunung: widget.idGunung),
              ),
            ),
          );
        },
        child: Text(
          "Pesan Sekarang",
          style: TextStyle(
              fontSize: 16.fSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5),
        ),
      ),
    );
  }

  // --- Fungsi _guardBeforeBooking, _isMissing, dan _showWarningDialog biarkan utuh seperti aslinya ---
  Future<bool> _guardBeforeBooking(BuildContext context) async {
    try {
      final token = await ApiService().getToken();
      if (token == null || token.isEmpty) {
        await _showWarningDialog(
          title: 'Login Diperlukan',
          message: 'Silakan login terlebih dahulu untuk melanjutkan booking.',
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.orange,
          confirmText: 'Mengerti',
        );
        return false;
      }

      final userResponse = await ApiService().getUser(token);
      if (!(userResponse['success'] == true)) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengambil data pengguna.')));
        return false;
      }

      final userData = (userResponse['data'] as Map<String, dynamic>);
      final currentUserId = userData['id'] is int
          ? userData['id'] as int
          : int.tryParse(userData['id'].toString()) ?? 0;
      final userLevel = userData['level'] is int
          ? userData['level'] as int
          : int.tryParse((userData['level'] ?? '').toString()) ?? 0;
      final normalizedLevel = userLevel == 0 ? 1 : userLevel;

      final missingProfileFields = <String>[];
      if (_isMissing(userData['nik'])) missingProfileFields.add('NIK');
      if (_isMissing(userData['address'])) missingProfileFields.add('Alamat');
      if (_isMissing(userData['phone']))
        missingProfileFields.add('Nomor telepon');
      if (_isMissing(userData['emergency_phone']))
        missingProfileFields.add('Kontak darurat');
      if (_isMissing(userData['date_of_birth']))
        missingProfileFields.add('Tanggal lahir');

      if (normalizedLevel == 1 && missingProfileFields.isNotEmpty) {
        final openProfile = await _showWarningDialog(
          title: 'Data Profil Belum Lengkap',
          message: 'Sebelum booking, lengkapi data profil terlebih dahulu.',
          icon: Icons.report_problem_rounded,
          iconColor: Colors.orange,
          confirmText: 'Lengkapi Profil',
          cancelText: 'Nanti',
        );

        if (openProfile == true && context.mounted) {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => BlocProvider(
                      create: (context) =>
                          DataProfileBloc(apiService: ApiService()),
                      child: DataProfileScreen(userId: currentUserId))));
          if (!context.mounted) return false;
          return _guardBeforeBooking(context);
        }
        return false;
      }

      final onboarding =
          await ApiService().getOnboardingExperienceStatus(token);
      final data = (onboarding['data'] as Map<String, dynamic>?) ?? {};
      final isHiker = normalizedLevel == 1 || data['is_hiker'] == true;
      final identityComplete = data['identity_complete'] == true;
      final experienceCompleted = data['experience_completed'] == true;

      if (isHiker && !identityComplete) {
        final goToProfile = await _showWarningDialog(
          title: 'Data Profil Belum Lengkap',
          message: 'Sebelum booking, lengkapi data profil terlebih dahulu.',
          icon: Icons.report_problem_rounded,
          iconColor: Colors.orange,
          confirmText: 'Lengkapi Profil',
          cancelText: 'Nanti',
        );

        if (goToProfile == true && context.mounted) {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => BlocProvider(
                      create: (context) =>
                          DataProfileBloc(apiService: ApiService()),
                      child: DataProfileScreen(userId: currentUserId))));
          if (!context.mounted) return false;
          return _guardBeforeBooking(context);
        }
        return false;
      }

      if (isHiker && !experienceCompleted) {
        final openOnboarding = await _showWarningDialog(
          title: 'Isi Pengalaman Pendakian',
          message:
              'Sebelum booking, isi onboarding pengalaman pendakian terlebih dahulu.',
          icon: Icons.warning_rounded,
          iconColor: Colors.red,
          confirmText: 'Isi Sekarang',
          cancelText: 'Nanti',
        );

        if (openOnboarding == true && context.mounted) {
          final completed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                  builder: (context) => const ExperienceOnboardingScreen()));
          if (!context.mounted) return false;
          if (completed == true) return _guardBeforeBooking(context);
        }
        return false;
      }

      return true;
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memeriksa kesiapan booking.')));
      return false;
    }
  }

  bool _isMissing(dynamic value) {
    if (value == null) return true;
    final text = value.toString().trim().toLowerCase();
    return text.isEmpty || text == 'null' || text == '-';
  }

  Future<bool?> _showWarningDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required String confirmText,
    String? cancelText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: EdgeInsets.all(24.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.h),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 48.h),
              SizedBox(height: 16.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18.fSize,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87),
              ),
              SizedBox(height: 10.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14.fSize, color: Colors.grey[600], height: 1.4),
              ),
              SizedBox(height: 28.h),
              Row(
                children: [
                  if (cancelText != null) ...[
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.h)),
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(cancelText,
                            style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    SizedBox(width: 12.h),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.h)),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(confirmText,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
