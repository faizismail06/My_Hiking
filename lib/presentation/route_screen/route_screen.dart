import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myhiking/api/api_service.dart';
import 'package:myhiking/models/model.dart';
import 'package:myhiking/presentation/booking_screen/bloc/booking_bloc.dart';
import 'package:myhiking/presentation/booking_screen/booking_screen.dart';
import 'package:myhiking/presentation/tata_tertib_screen/bloc/tata_tertib_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_export.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_icon_button.dart';
import '../tata_tertib_screen/tata_tertib_screen.dart';
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
                      "Jarak\n${routeModel.distance} km", // Teks dengan dua baris
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
      onPressed: () {
        Navigator.push(
          context,
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
                create: (context) => TataTertibBloc(
                  apiService:
                      ApiService(), // Pastikan ApiService terinisialisasi dengan benar
                ), // Memulai event Bloc
                child: TataTertibScreen(
                    jalurId: widget
                        .jalurId), // Memastikan jalurId dikirim ke TataTertibScreen
              ),
            ),
          );
        });
  }
}