import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myhiking/api/api_service.dart';
import 'package:myhiking/models/model.dart';
import 'package:myhiking/presentation/trail_screen/trail_screen.dart';
import '../../core/app_export.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/app_bar/appbar_leading_iconbutton.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/weather_widget.dart' show WeatherBadge;
import '../trail_screen/bloc/trail_bloc.dart';
import 'bloc/detail_mountain_bloc.dart';
import 'models/detail_mountain_model.dart';

class DetailMountainScreen extends StatefulWidget {
  final int idGunung;

  const DetailMountainScreen({super.key, required this.idGunung});

  @override
  State<DetailMountainScreen> createState() => _DetailMountainScreenState();
}

class _DetailMountainScreenState extends State<DetailMountainScreen> {
  late String imageUrl; // Deklarasi imageUrl
  String userName = '';
  int userId = 0;
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    // Memicu event untuk mengambil data saat screen diinisialisasi
    context
        .read<DetailMountainBloc>()
        .add(DetailMountainInitialEvent(widget.idGunung));
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
    return BlocBuilder<DetailMountainBloc, DetailMountainState>(
      builder: (context, state) {
        // Jika data sedang dimuat
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Jika ada error
        if (state.error != null) {
          return Center(child: Text('Error: ${state.error}'));
        }

        // Pastikan data gunung ada
        final detailMountain = state.gunung != null
            ? DetailMountainModel.fromGunung(state.gunung!)
            : null;

        // Ambil URL gambar dari detailMountain
        imageUrl = detailMountain?.gambar ??
            'assets/images/img_error.png'; // Gunakan gambar default jika null

        final routes = state.jalurList;

        return SafeArea(
          child: Scaffold(
            backgroundColor: appTheme.gray50,
            body: SizedBox(
              width: double.maxFinite,
              child: Column(
                children: [
                  _buildHeader(context, detailMountain, state.gunung),
                  SizedBox(height: 16.h),
                  if (detailMountain != null)
                    _buildElevationColumn(context, detailMountain),
                  SizedBox(height: 16.h),
                  Expanded(
                    child: routes != null
                        ? _buildRouteList(context, routes)
                        : const Center(child: Text('No routes available')),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, DetailMountainModel? detailMountain,
      Gunung? gunung) {
    return SizedBox(
      height: 396.h,
      width: double.maxFinite,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          _buildBackgroundStack(context, gunung),
          Text(
            detailMountain?.name ?? "Loading...",
            style: CustomTextStyles.headlineSmall_1,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRouteList(BuildContext context, List<Jalur> routes) {
    if (routes.isEmpty) {
      // Tampilkan pesan jika daftar rute kosong
      return const Center(
        child: Text(
          'Tidak ada jalur tersedia',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.h),
      child: SingleChildScrollView(
        // Membuat list jalur dapat digulir
        child: Column(
          children: routes.map((route) {
            // Validasi properti route
            if (route.id == null || route.nama.isEmpty) {
              return const SizedBox.shrink(); // Abaikan jika data tidak valid
            }

            return GestureDetector(
              onTap: () {
                // Navigasi ke TrailScreen jika ID valid
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider(
                      create: (context) => TrailBloc(apiService: ApiService()),
                      child: TrailScreen(
                        jalurId: route.id,
                        idGunung: widget.idGunung,
                      ),
                    ),
                  ),
                );
                print(
                    "Navigating to TrailScreen with idGunung: ${widget.idGunung}, jalurId: ${route.id}, ${userId.toString()}");
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 16.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onPrimary,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  borderRadius: BorderRadius.circular(8.h),
                ),
                child: Row(
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 12.h),
                      child: CustomImageView(
                        imagePath:
                            ImageConstant.imgLinkedin, // Gunakan gambar default
                        height: 20.h,
                        width: 18.h,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        route.nama, // Nama jalur
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            );
          }).toList(), // Konversi list jalur ke widget
        ),
      ),
    );
  }

  Widget _buildElevationColumn(
      BuildContext context, DetailMountainModel detailMountain) {
    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.symmetric(horizontal: 24.h),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "lbl_ketinggian".tr,
                    style: CustomTextStyles.bodySmallBlack900,
                  ),
                  Text(
                    "${detailMountain.height} m",
                    style: CustomTextStyles.titleMediumSemiBold,
                  ),
                ],
              ),
              SizedBox(width: 12.h),
              Expanded(
                child: CustomElevatedButton(
                  height: 42.h,
                  text: detailMountain.province,
                  leftIcon: Container(
                    margin: EdgeInsets.only(right: 12.h),
                    child: CustomImageView(
                      imagePath: ImageConstant.imgLinkedin,
                      height: 20.h,
                      width: 18.h,
                      fit: BoxFit.contain,
                    ),
                  ),
                  buttonStyle: CustomButtonStyles.fillPrimaryTL8,
                  buttonTextStyle: CustomTextStyles.titleMediumSemiBold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundStack(BuildContext context, Gunung? gunung) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: 372.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Gunakan imageUrl untuk gambar latar belakang
            CustomImageView(
              imagePath: imageUrl, // Pastikan imageUrl valid
              height: 371.h, // Sesuaikan dengan tinggi yang lebih besar
              width: double.maxFinite,
              fit: BoxFit.cover, // Memastikan gambar memenuhi ar
            ),
            Container(
              width: double.maxFinite,
              margin: EdgeInsets.only(top: 8.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Custom header with back button and weather badge
                  Container(
                    height: 56.h,
                    padding: EdgeInsets.symmetric(horizontal: 24.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Back button
                        AppbarLeadingIconbutton(
                          imagePath: ImageConstant.imgIconArrow,
                          onTap: () => onTapIconarrowone(context),
                        ),
                        // Weather badge on the right
                        if (gunung != null &&
                            gunung.latitude != null &&
                            gunung.longitude != null)
                          WeatherBadge(
                            latitude: gunung.latitude,
                            longitude: gunung.longitude,
                            locationName: gunung.nama,
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: double.maxFinite,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.h,
                      vertical: 40.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: const Alignment(0.43, 0.79),
                        end: const Alignment(0.43, 0.05),
                        colors: [
                          appTheme.gray50,
                          appTheme.gray50.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 22.h),
                        SizedBox(
                          width: double.maxFinite,
                          child: Column(
                            children: [
                              // SizedBox(height: 30.h),
                              // Gambar gunung di tengah yang lebih besar dan berbentuk bulat
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 24.h),
                                width: 120.h, // Ukuran gambar lebih besar
                                height: 120.h, // Ukuran gambar lebih besar
                                decoration: BoxDecoration(
                                  shape: BoxShape
                                      .circle, // Membuatnya berbentuk bulat
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 12.h,
                                      spreadRadius: 2.h,
                                    ),
                                  ],
                                  image: DecorationImage(
                                    image: NetworkImage(
                                        imageUrl), // Gambar yang digunakan
                                    fit: BoxFit
                                        .cover, // Gambar mengisi area bulat
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  onTapIconarrowone(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.homeScreen,
    );
  }
}
