import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_icon_button.dart';
import '../rules_screen/rules_screen.dart';
import 'bloc/route_bloc.dart';
import 'models/route_model.dart';

class RouteScreen extends StatefulWidget {
  final int? jalurId;
  final int? idGunung;

  const RouteScreen({super.key, this.jalurId, this.idGunung});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  late String imageUrl; // Deklarasi imageUrl
  String userName = '';
  int userId = 0;
  bool isLoading = true;
  RouteModel? routeModel;

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  // Fungsi untuk membuka URL
  void _launchURL(RouteModel model) async {
    print('Attempting to launch URL:');
    print('mapBasecamp: ${model.mapBasecamp}');

    if (model.mapBasecamp.isNotEmpty) {
      try {
        // Untuk Windows, kita perlu memastikan URL dibuka di browser
        final Uri url = Uri.parse(model.mapBasecamp);
        print('Parsed URL: $url');

        if (!await launchUrl(
          url,
          mode: LaunchMode
              .platformDefault, // Gunakan platform default untuk Windows
        )) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tidak dapat membuka maps'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        print('Error launching URL: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal membuka maps: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      print('URL is empty');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('URL maps tidak tersedia'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          setState(() {
            userName = response['data']['name'];
            userId = response['data']['id'];
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
    return BlocProvider(
      create: (context) => RouteBloc(apiService: ApiService())
        ..add(RouteInitialEvent(
            jalurId: widget.jalurId!, idGunung: widget.idGunung!)),
      child: BlocBuilder<RouteBloc, RouteState>(
        builder: (context, state) {
          // print('jalur: $state.jalur');
          // print('gunung: $state.gunung');

          // Handle loading state
          if (state.isLoading) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              ),
            );
          }

          // Handle error state
          if (state.errorMessage != null) {
            return Scaffold(
              body: Center(
                child: Text(
                  'Error: ${state.errorMessage}',
                  style: CustomTextStyles.bodyMediumGray500,
                ),
              ),
            );
          }

          // Ensure data is not null
          if (state.jalur == null || state.gunung == null) {
            return Scaffold(
              body: Center(
                child: Text(
                  'Detail jalur tidak tersedia.',
                  style: CustomTextStyles.bodyMediumGray500,
                ),
              ),
            );
          }

          // Membuat instance ResDetailRouteCentres
          final resDetailRouteCentres = ResDetailRouteCentres(
            status: true,
            message: "Success",
            jalur: state.jalur!,
            gunung: state.gunung!,
          );

          // Membuat RouteModel menggunakan ResDetailRouteCentres
          final routeModel =
              RouteModel.fromResDetailRouteCentres(resDetailRouteCentres);

          // Main UI
          return SafeArea(
            child: Scaffold(
              backgroundColor: appTheme.gray50,
              body: Stack(
                children: [
                  // Header Section (Placed in the background)
                  _buildHeaderSection(context, routeModel),

                  // Content Section (with route details, actions, and buttons at the bottom)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.h,
                          vertical: 16.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onPrimary,
                          borderRadius: BorderRadiusStyle.customBorderTL30,
                          boxShadow: [
                            BoxShadow(
                              color: appTheme.black900.withOpacity(0.05),
                              spreadRadius: 1.h,
                              blurRadius: 4.h,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Route Details Section
                            _buildRouteDetailSection(context, routeModel),

                            SizedBox(height: 20.h),

                            // Route Actions Section
                            _buildRouteActions(context, routeModel),

                            SizedBox(height: 16.h),

                            // Buttons: Tata Tertib & Pesan Sekarang
                            _buildTataTertibButton(context),
                            SizedBox(height: 8.h),
                            _buildPesanSekarangButton(context),
                          ],
                        ),
                      ),
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

  /// **Header Section with Image**
  Widget _buildHeaderSection(BuildContext context, RouteModel routeModel) {
    final imageUrl = routeModel.gambar ??
        'assets/images/placeholder.png'; // Default placeholder image

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withOpacity(0.9),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16.h),
          bottomRight: Radius.circular(16.h),
        ),
      ),
      child: Stack(
        children: [
          // Image with proper height and fit
          ClipRRect(
            child: Image.network(
              imageUrl,
              height: 600.h, // Adjusted height as per the second image
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          // Back button positioned at the top-left
          Positioned(
            top: 16.h,
            left: 16.h,
            child: CustomIconButton(
              height: 40.h,
              width: 40.h,
              padding: EdgeInsets.all(8.h),
              onTap: () {
                Navigator.pop(context);
              },
              child: CustomImageView(
                imagePath: ImageConstant.imgIconArrowOnprimarycontainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // **Route Details Section**
  Widget _buildRouteDetailSection(BuildContext context, RouteModel routeModel) {
    return Container(
        padding: EdgeInsets.all(16.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.onPrimary,
          borderRadius: BorderRadiusStyle.roundedBorder10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CustomImageView(
                  imagePath: ImageConstant.imgLinkedin,
                  height: 24.h,
                  width: 24.h,
                  margin: EdgeInsets.only(right: 8.h),
                ),
                Text(
                  routeModel.name,
                  style: CustomTextStyles.titleLargePrimaryBlack.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              "${routeModel.location}",
              style: CustomTextStyles.bodyMediumGray500,
            ),
          ],
        ));
  }

  Widget _buildRouteActions(BuildContext context, RouteModel routeModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary, // Latar belakang tombol
              borderRadius:
                  BorderRadius.circular(8), // Penyesuaian bentuk tombol
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1), // Bayangan halus
                  offset: Offset(0, 4), // Posisi bayangan
                  blurRadius: 8, // Ukuran bayangan
                  spreadRadius: 1, // Penyebaran bayangan
                ),
              ],
            ),
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(8), // Penyesuaian bentuk tombol
                ),
              ),
              onPressed: () {
                // Action to view location
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on,
                      color: theme.colorScheme.primary, size: 35),
                  SizedBox(width: 8),
                  Text(
                      "Jarak\n${routeModel.distanceLabel} km", // Teks dengan dua baris
                      textAlign: TextAlign.center,
                      style: CustomTextStyles.labelMediumPrimary10.copyWith(
                          fontSize:
                              17) // Menggunakan CustomTextStyle untuk teks
                      ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 16.h),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white, // Latar belakang putih
              borderRadius:
                  BorderRadius.circular(8), // Penyesuaian bentuk tombol
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1), // Bayangan halus
                  offset: Offset(0, 4), // Posisi bayangan
                  blurRadius: 8, // Ukuran bayangan
                  spreadRadius: 1, // Penyebaran bayangan
                ),
              ],
            ),
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(8), // Penyesuaian bentuk tombol
                ),
              ),
              onPressed: () {
                _launchURL(routeModel);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map,
                      color: Theme.of(context).colorScheme.primary, size: 35),
                  SizedBox(width: 8),
                  Text(
                    "Open\nMaps",
                    style: TextStyle(
                        fontSize: 17,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // **Pesan Sekarang Button**
  Widget _buildPesanSekarangButton(BuildContext context) {
    return CustomElevatedButton(
      height: 56.h,
      text: "Pesan Sekarang",
      buttonStyle: CustomButtonStyles.outlineBlackTL14,
      buttonTextStyle: CustomTextStyles.titleLarge_1,
      onPressed: () async {
        final allowed = await _guardBeforeBooking(context);
        if (!allowed) return;

        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => BookingBloc(apiService: ApiService()),
              child: BookingScreen(
                jalurId: widget.jalurId, // Use widget to access jalurId
                idGunung: widget.idGunung, // Use widget to access idGunung
                // userId: userId,
              ),
            ),
          ),
        );
        print(
            "Navigating to BookingScreen with idGunung: ${widget.idGunung}, jalurId: ${widget.jalurId}, ${userId.toString()}");
      },
    );
  }

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
          const SnackBar(content: Text('Gagal mengambil data pengguna.')),
        );
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
      if (_isMissing(userData['phone'])) missingProfileFields.add('Nomor telepon');
      if (_isMissing(userData['emergency_phone'])) {
        missingProfileFields.add('Kontak darurat');
      }
      if (_isMissing(userData['date_of_birth'])) {
        missingProfileFields.add('Tanggal lahir');
      }

      if (normalizedLevel == 1 && missingProfileFields.isNotEmpty) {
        final openProfile = await _showWarningDialog(
          title: 'Data Profil Belum Lengkap',
          message:
              'Sebelum booking, lengkapi data profil terlebih dahulu',
          icon: Icons.report_problem_rounded,
          iconColor: Colors.orange,
          confirmText: 'Lengkapi Profil',
          cancelText: 'Nanti',
        );

        if (openProfile == true && context.mounted) {
          await Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => DataProfileBloc(apiService: ApiService()),
                child: DataProfileScreen(
                  userId: currentUserId,
                  redirectToHomeOnSave: false,
                ),
              ),
            ),
          );

          if (!context.mounted) return false;
          return _guardBeforeBooking(context);
        }
        return false;
      }

      final onboarding = await ApiService().getOnboardingExperienceStatus(token);
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
          await Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => DataProfileBloc(apiService: ApiService()),
                child: DataProfileScreen(
                  userId: currentUserId,
                  redirectToHomeOnSave: false,
                ),
              ),
            ),
          );

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
          final completed = await Navigator.of(context, rootNavigator: true)
              .push<bool>(
            MaterialPageRoute(
              builder: (context) => const ExperienceOnboardingScreen(),
            ),
          );

          if (!context.mounted) return false;
          if (completed == true) {
            return _guardBeforeBooking(context);
          }
        }
        return false;
      }

      return true;
    } on ApiActionException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      return false;
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memeriksa kesiapan booking.')),
      );
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
          padding: EdgeInsets.symmetric(
            horizontal: 20.h,
            vertical: 20.h,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.onPrimary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 6.h),
              Icon(icon, color: iconColor, size: 40.h),
              SizedBox(height: 20.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: CustomTextStyles.titleSmallBlack900.copyWith(
                  height: 1.40,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: CustomTextStyles.bodySmallBlack900.copyWith(
                  height: 1.40,
                ),
              ),
              SizedBox(height: 32.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (cancelText != null)
                    CustomElevatedButton(
                      height: 35.h,
                      width: 100.h,
                      text: cancelText,
                      buttonStyle: CustomButtonStyles.fillRed,
                      buttonTextStyle: CustomTextStyles.labelMediumOnPrimary,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  CustomElevatedButton(
                    height: 35.h,
                    width: cancelText != null ? 100.h : 140.h,
                    text: confirmText,
                    buttonStyle: CustomButtonStyles.fillPrimaryTL12,
                    buttonTextStyle: CustomTextStyles.labelMediumOnPrimary,
                    onPressed: () => Navigator.of(context).pop(true),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // **Tata Tertib Button**
  Widget _buildTataTertibButton(BuildContext context) {
    return CustomElevatedButton(
        height: 56.h,
        text: "Tata Tertib dan Peraturan",
        margin: EdgeInsets.only(right: 2.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.onPrimary,
          borderRadius: BorderRadiusStyle.roundedBorder14,
          boxShadow: [
            BoxShadow(
              color: appTheme.black900.withOpacity(0.08),
              spreadRadius: 1.h,
              blurRadius: 2.h,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        leftIcon: Container(
          margin: EdgeInsets.only(right: 16.h),
          child: CustomImageView(
            imagePath: ImageConstant.imgVideocamera,
            height: 24.h,
            width: 24.h,
            fit: BoxFit.contain,
          ),
        ),
        buttonStyle: CustomButtonStyles.outlineBlack,
        buttonTextStyle: CustomTextStyles.labelLargePrimarySemiBold,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => RulesBloc(
                  apiService:
                      ApiService(), // Pastikan ApiService terinisialisasi dengan benar
                ), // Memulai event Bloc
                child: RulesScreen(
                    jalurId: widget
                        .jalurId), // Memastikan jalurId dikirim ke RulesScreen
              ),
            ),
          );
        });
  }
}
