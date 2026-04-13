import 'package:flutter/material.dart';
import 'package:myhiking/api/api_service.dart';
import 'package:myhiking/presentation/data_profile_screen/bloc/data_profile_bloc.dart';
import 'package:myhiking/presentation/data_profile_screen/data_profile_screen.dart';
import 'package:myhiking/presentation/landing_screen/landing_screen.dart';
import 'package:myhiking/presentation/profile_screen/bloc/profile_bloc.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_icon_button.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider<ProfileBloc>(
      create: (context) => ProfileBloc(const ProfileState()),
      child: const ProfileScreen(),
    );
  }

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = '';
  int userId = 0;
  String? userTier;
  String? userTierSource;
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    // Inisialisasi data awal
    context.read<ProfileBloc>().add(ProfileInitialEvent());
    _getUser();
  }

  Future<void> _getUser() async {
    final token = await ApiService().getToken();

    // Cek apakah token null atau kosong
    if (token == null || token.isEmpty) {
      // Jika token tidak tersedia, tampilkan pesan atau ambil tindakan lain
      // print("Token is null or empty");
      if (mounted) {
        setState(() {
          isLoading =
              false; // Menyelesaikan status loading jika token tidak ada
        });
      }
      return; // Keluar dari fungsi jika token tidak ada
    }

    // print("Token: $token"); // Debugging, pastikan token ada

    try {
      final response = await ApiService().getUser(token);
      if (response['success']) {
        if (mounted) {
          final data = response['data'] as Map<String, dynamic>;
          setState(() {
            userName = (data['name'] ?? '').toString();
            userId = data['id'] is int
                ? data['id'] as int
                : int.tryParse((data['id'] ?? '').toString()) ?? 0;
            userTier = data['tier']?.toString();
            userTierSource = data['tier_source']?.toString();
            isLoading = false;
          });
        }
      } else {
        // Menangani error jika API gagal
        // print("Error: ${response['message']}");
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      // Tangani error jaringan atau kesalahan lainnya
      // print("Error fetching user: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        return SafeArea(
            child: Scaffold(
          backgroundColor: appTheme.gray50,
          body: SingleChildScrollView(
            child: Container(
              width: double.maxFinite,
              padding: EdgeInsets.symmetric(horizontal: 0, vertical: 24.h),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  _buildProfileHeader(context),
                  SizedBox(height: 32.h),
                  _buildProfileSettings(context),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ));
      },
    );
  }

  /// Section Widget: Profile Header
  Widget _buildProfileHeader(BuildContext context) {
    final tierPresentation = _tierPresentation(userTier);

    return SizedBox(
      height: 164.h,
      width: double.maxFinite,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 224.h,
            margin: EdgeInsets.only(bottom: 26.h),
            padding: EdgeInsets.only(left: 58.h, top: 10.h, bottom: 10.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 0.h),
                  child: Text(
                    "ID : ${userId.toString()}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CustomTextStyles.titleMediumOnPrimary_1,
                  ),
                ),
                SizedBox(height: 5.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 9.h, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(999.h),
                    border: Border.all(
                      color: tierPresentation.color.withOpacity(0.85),
                      width: 1.h,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tierPresentation.icon,
                          color: tierPresentation.color,
                          size: 13.h,
                        ),
                        SizedBox(width: 6.h),
                        Text(
                          tierPresentation.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CustomTextStyles.bodySmallGray50003.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            fontSize: 11.fSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          CustomImageView(
            imagePath: ImageConstant.imgAmping91,
            height: 164.h,
            width: 228.h,
            alignment: Alignment.centerLeft,
          ),
        ],
      ),
    );
  }

  _TierPresentation _tierPresentation(String? rawTier) {
    final normalized = (rawTier ?? '').trim().toLowerCase();

    if (normalized.isEmpty || normalized == 'null') {
      return const _TierPresentation(
        label: 'Tier: Belum Ditentukan',
        color: Color(0xFFFFD54F),
        icon: Icons.help_outline_rounded,
      );
    }

    if (normalized == 'pemula' ||
        normalized == 'beginner' ||
        normalized == 'tier_1') {
      return const _TierPresentation(
        label: 'Tier 1 - Pemula',
        color: Color(0xFF8BC34A),
        icon: Icons.eco_outlined,
      );
    }

    if (normalized == 'menengah' ||
        normalized == 'intermediate' ||
        normalized == 'tier_2') {
      return const _TierPresentation(
        label: 'Tier 2 - Menengah',
        color: Color(0xFFFFB300),
        icon: Icons.hiking_rounded,
      );
    }

    if (normalized == 'mahir' ||
        normalized == 'advanced' ||
        normalized == 'tier_3') {
      return const _TierPresentation(
        label: 'Tier 3 - Mahir',
        color: Color(0xFFE57373),
        icon: Icons.workspace_premium_outlined,
      );
    }

    return _TierPresentation(
      label: 'Tier: ${rawTier ?? '-'}',
      color: const Color(0xFF81C784),
      icon: Icons.flag_outlined,
    );
  }

  String _formatTierSource(String? source) {
    if (source == null || source.trim().isEmpty) return '-';
    return source.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Section Widget: Profile Settings
  Widget _buildProfileSettings(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(horizontal: 16.h),
      child: Column(
        children: [
          // Data Profile Option
          GestureDetector(
            onTap: () => onTapProfileone(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 16.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(16.h),
                border: Border.all(
                  color: theme.colorScheme.onPrimary,
                  width: 1.h,
                ),
                boxShadow: [
                  BoxShadow(
                    color: appTheme.blueGray40019.withOpacity(0.08),
                    spreadRadius: 2.h,
                    blurRadius: 8.h,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 28.h,
                        width: 28.h,
                        decoration: BoxDecoration(
                          color: appTheme.blueGray50,
                          borderRadius: BorderRadius.circular(8.h),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomImageView(
                              imagePath: ImageConstant.imgOutlineUsers,
                              height: 22.h,
                              width: double.maxFinite,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16.h),
                      Text(
                        "lbl_data_profile".tr,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  CustomImageView(
                    imagePath: ImageConstant.imgArrowRight,
                    height: 24.h,
                    width: 24.h,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 14.h),

          // Transaction Option
          GestureDetector(
            onTap: () => onTapTransaction(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 16.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(16.h),
                border: Border.all(
                  color: theme.colorScheme.onPrimary,
                  width: 1.h,
                ),
                boxShadow: [
                  BoxShadow(
                    color: appTheme.blueGray40019.withOpacity(0.08),
                    spreadRadius: 2.h,
                    blurRadius: 8.h,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              width: double.maxFinite,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CustomIconButton(
                        height: 28.h,
                        width: 28.h,
                        padding: EdgeInsets.all(4.h),
                        decoration: BoxDecoration(
                          color: appTheme.blueGray50,
                          borderRadius: BorderRadius.circular(8.h),
                        ),
                        child: CustomImageView(
                          imagePath: ImageConstant.imgClock,
                        ),
                      ),
                      SizedBox(width: 16.h),
                      Text(
                        "lbl_cek_transaksi".tr,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  CustomImageView(
                    imagePath: ImageConstant.imgArrowRight,
                    height: 24.h,
                    width: 24.h,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 14.h),

          // Logout Option
          GestureDetector(
            onTap: () => onLogout(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 16.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(16.h),
                border: Border.all(
                  color: theme.colorScheme.onPrimary,
                  width: 1.h,
                ),
                boxShadow: [
                  BoxShadow(
                    color: appTheme.blueGray40019.withOpacity(0.08),
                    spreadRadius: 2.h,
                    blurRadius: 8.h,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              width: double.maxFinite,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CustomIconButton(
                        height: 28.h,
                        width: 28.h,
                        padding: EdgeInsets.all(4.h),
                        decoration: BoxDecoration(
                          color: appTheme.blueGray50,
                          borderRadius: BorderRadius.circular(8.h),
                        ),
                        child: Icon(
                          Icons.logout,
                          color: theme.colorScheme.primary,
                          size: 18,
                        ),
                      ),
                      SizedBox(width: 16.h),
                      Text(
                        "Log Out".tr,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  CustomImageView(
                    imagePath: ImageConstant.imgArrowRight,
                    height: 24.h,
                    width: 24.h,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void onTapProfileone(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => DataProfileBloc(apiService: ApiService()),
          child: DataProfileScreen(
            userId: userId, // Use widget to access jalurId
          ),
        ),
      ),
    );
  }

  void onTapTransaction(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.transactionPage);
  }

  void onLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Keluar dari akun Anda?",
            style: TextStyle(fontSize: 16, color: theme.colorScheme.primary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup pop-up tanpa keluar
              },
              child: Text("Batalkan"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Menutup pop-up
                Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.loginScreen,
                    (route) =>
                        false); // Menuju ke halaman login dan menghapus stack
              },
              child: Text(
                "Keluar",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TierPresentation {
  final String label;
  final Color color;
  final IconData icon;

  const _TierPresentation({
    required this.label,
    required this.color,
    required this.icon,
  });
}
