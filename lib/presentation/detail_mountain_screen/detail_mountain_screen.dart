import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui' as ui; // Tambahan untuk efek blur/glassmorphism
import 'package:myhiking/api/api_service.dart';
import 'package:myhiking/models/model.dart';
import 'package:myhiking/presentation/trail_screen/trail_screen.dart';
import '../../core/app_export.dart';
import '../../widgets/app_bar/appbar_leading_iconbutton.dart';
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
  late String imageUrl;
  String userName = '';
  int userId = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    context
        .read<DetailMountainBloc>()
        .add(DetailMountainInitialEvent(widget.idGunung));
    _getUser();
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
    return BlocBuilder<DetailMountainBloc, DetailMountainState>(
      builder: (context, state) {
        if (state.isLoading) {
          return Scaffold(
            backgroundColor: appTheme.gray50,
            body: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }

        if (state.error != null) {
          return Scaffold(
            body: Center(
              child: Text(
                'Error: ${state.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final detailMountain = state.gunung != null
            ? DetailMountainModel.fromGunung(state.gunung!)
            : null;

        imageUrl = detailMountain?.gambar ?? 'assets/images/img_error.png';

        final routes = state.jalurList;

        return SafeArea(
          top: false, // Membiarkan gambar menabrak status bar agar lebih wide
          child: Scaffold(
            backgroundColor: const Color(0xFFF8F9FA), // Warna background super soft
            body: SizedBox(
              width: double.maxFinite,
              child: Column(
                children: [
                  _buildHeroHeader(context, detailMountain, state.gunung),
                  // Kita tarik content sedikit ke atas agar memberikan efek overlapping
                  Transform.translate(
                    offset: Offset(0, -30.h),
                    child: _buildElevationAndLocation(context, detailMountain),
                  ),
                  Expanded(
                    child: Transform.translate(
                      offset: Offset(0, -10.h),
                      child: routes != null
                          ? _buildRouteList(context, routes)
                          : const Center(child: Text('Tidak ada jalur tersedia')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Membangun Header Hero Image (Wide & Elegant)
  Widget _buildHeroHeader(
      BuildContext context, DetailMountainModel? detailMountain, Gunung? gunung) {
    return SizedBox(
      height: 380.h,
      width: double.maxFinite,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image (Edge to Edge)
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[300],
              child: const Center(child: Icon(Icons.image_not_supported, size: 50)),
            ),
          ),
          
          // Gradient Overlay (Halus dari bawah ke atas)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4), // Gelap di atas untuk tombol back
                  Colors.transparent,
                  Colors.black.withOpacity(0.0),
                  Colors.black.withOpacity(0.8), // Gelap di bawah untuk teks
                ],
                stops: const [0.0, 0.2, 0.5, 1.0],
              ),
            ),
          ),

          // Top Bar (Back Button & Weather)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16.h,
            left: 20.h,
            right: 20.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Glassmorphism Back Button
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.h),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.h),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: AppbarLeadingIconbutton(
                        imagePath: ImageConstant.imgIconArrow,
                        onTap: () => onTapIconarrowone(context),
                      ),
                    ),
                  ),
                ),
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

          // Mountain Title (Di atas gambar langsung)
          Positioned(
            bottom: 50.h, // Memberi ruang untuk floating card
            left: 24.h,
            right: 24.h,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detailMountain?.name ?? "Memuat...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28.fSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: Colors.white70, size: 18.h),
                    SizedBox(width: 4.h),
                    Text(
                      detailMountain?.province ?? "Lokasi Tidak Diketahui",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14.fSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Info Section (Elevation & Province) - Bergaya Floating Card
  Widget _buildElevationAndLocation(
      BuildContext context, DetailMountainModel? detailMountain) {
    if (detailMountain == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.h),
      child: Container(
        padding: EdgeInsets.all(16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.h),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ketinggian Section
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.h),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.h),
                    ),
                    child: Icon(
                      Icons.terrain_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24.h,
                    ),
                  ),
                  SizedBox(width: 12.h),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ketinggian",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12.fSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "${detailMountain.height} MDPL",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 15.fSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Divider
            Container(
              height: 40.h,
              width: 1.h,
              color: Colors.grey[200],
            ),
            SizedBox(width: 16.h),
            // Region Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Wilayah",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12.fSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    detailMountain.province ?? "-",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 13.fSize,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Daftar Jalur Pendakian yang dimodernisasi
  Widget _buildRouteList(BuildContext context, List<Jalur> routes) {
    if (routes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_walk_rounded, size: 48.h, color: Colors.grey[400]),
            SizedBox(height: 12.h),
            Text(
              'Belum ada data jalur pendakian.',
              style: TextStyle(fontSize: 14.fSize, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 26.h, vertical: 8.h),
          child: Text(
            "Pilih Jalur Pendakian",
            style: TextStyle(
              fontSize: 18.fSize,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(top: 8.h, bottom: 24.h, left: 24.h, right: 24.h),
            physics: const BouncingScrollPhysics(),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];

              if (route.id == null || route.nama.isEmpty) {
                return const SizedBox.shrink();
              }

              return GestureDetector(
                onTap: () {
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
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 14.h),
                  padding: EdgeInsets.all(16.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.h),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Map Icon Container
                      Container(
                        padding: EdgeInsets.all(12.h),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.map_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20.h,
                        ),
                      ),
                      SizedBox(width: 16.h),
                      // Route Name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Via ${route.nama}",
                              style: TextStyle(
                                fontSize: 15.fSize,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              "Lihat detail & estimasi",
                              style: TextStyle(
                                fontSize: 12.fSize,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Modern Forward Arrow
                      Container(
                        padding: EdgeInsets.all(6.h),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8.h),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 16.h,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  onTapIconarrowone(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.homeScreen,
    );
  }
}