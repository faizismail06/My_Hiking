import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';
import 'dart:ui' as ui; // Tambahan untuk efek blur glassmorphism
import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_search_view.dart';
import 'bloc/home_bloc.dart';
import 'models/home_initial_model.dart';
import 'models/homelist_item_model.dart';
import 'widgets/homelist_item_widget.dart';
import 'package:myhiking/api/api_service.dart';
import 'quick_access_handler_page.dart';

class HomeInitialPage extends StatefulWidget {
  const HomeInitialPage({super.key});

  @override
  HomeInitialPageState createState() => HomeInitialPageState();

  static Widget builder(BuildContext context) {
    return BlocProvider<HomeBloc>(
      create: (context) => HomeBloc(
        HomeState(
          homeInitialModelObj: HomeInitialModel(),
        ),
      )..add(HomeInitialEvent()),
      child: const HomeInitialPage(),
    );
  }
}

class HomeInitialPageState extends State<HomeInitialPage> {
  String userName = '';
  int userId = 0;
  bool isLoading = true;
  String? selectedProvince;
  final ScrollController _scrollController = ScrollController();
  static const String _siluetPath = 'assets/images/siluetgunung.jpeg';
  static const String _fallbackHeroPath = 'assets/images/img_home.png';
  String _heroBackgroundPath = _siluetPath;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _getUser();
    _prepareHeroBackground();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _openQuickAccess(QuickAccessAction action) async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => QuickAccessHandlerPage(
          action: action,
          initialUserId: userId,
        ),
      ),
    );
  }

  void _prepareHeroBackground() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final heroAsset = AssetImage(_heroBackgroundPath);
        await heroAsset.evict();
        if (!mounted) {
          return;
        }
        await precacheImage(heroAsset, context);
      } catch (_) {
        if (mounted && _heroBackgroundPath != _fallbackHeroPath) {
          setState(() {
            _heroBackgroundPath = _fallbackHeroPath;
          });
        }
      }
    });
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    try {
      _scrollController.removeListener(_onScroll);
      _scrollController.dispose();
    } catch (e) {}
    super.dispose();
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
    final maxScrollOffset = 120.0;
    final transparency = (_scrollOffset / maxScrollOffset).clamp(0.0, 1.0);

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Hero Header
        SliverAppBar(
          automaticallyImplyLeading: false,
          expandedHeight: 280.h,
          floating: false,
          pinned: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: _buildHeroHeader(context),
          ),
        ),

        // Sticky Unified Search & Filter Section (Modern)
        SliverPersistentHeader(
          pinned: true,
          delegate: _SearchBarDelegate(
            transparency: transparency,
            context: context,
            selectedProvince: selectedProvince,
            onProvinceChange: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  selectedProvince = newValue;
                });
                context.read<HomeBloc>().add(
                      HomeFilterProvinceEvent(
                        province:
                            newValue == 'Semua Provinsi' ? null : newValue,
                      ),
                    );
              }
            },
          ),
        ),

        // Feed Content
        SliverToBoxAdapter(
          child: _buildHomeFeed(context),
        ),
      ],
    );
  }

  /// Hero Header Widget - Modern Design
  Widget _buildHeroHeader(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(32.h),
        bottomRight: Radius.circular(32.h),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background siluet gunung
          Image.asset(
            _heroBackgroundPath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              if (_heroBackgroundPath != _fallbackHeroPath) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _heroBackgroundPath = _fallbackHeroPath;
                  });
                });
              }
              return Image.asset(
                _fallbackHeroPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: const Color(0xFF1B8A5A)),
              );
            },
          ),
          // Overlay Gradient Hijau Transparan
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1B8A5A).withOpacity(0.4),
                  const Color(0xFF105938).withOpacity(0.6),
                ],
              ),
            ),
          ),
          // Konten Header
          Container(
            width: double.maxFinite,
            padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h),

                // Greeting & Friend Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Halo, ${userName.isNotEmpty ? userName : "Pengguna"}",
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 22.fSize,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Mau muncak ke mana hari ini?',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14.fSize,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
// Friend Button
                    GestureDetector(
                      onTap: () {
                        if (userId != 0) {
                          Navigator.of(context, rootNavigator: true).pushNamed(
                            AppRoutes.friendScreen,
                            arguments: userId,
                          );
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(12.h),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.people_outline_rounded,
                          color: const Color(0xFF1B8A5A),
                          size: 26.h,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // Quick Actions Pane (Glassmorphism Container)
                ClipRRect(
                  borderRadius: BorderRadius.circular(24.h),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.h, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24.h),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildQuickAction(
                              Icons.local_activity_rounded,
                              "Tiket",
                              () => _openQuickAccess(QuickAccessAction.ticket)),
                          _buildQuickAction(Icons.map_rounded, "Maps",
                              () => _openQuickAccess(QuickAccessAction.maps)),
                          _buildQuickAction(
                            null,
                            "SOS",
                            () => _openQuickAccess(QuickAccessAction.sos),
                            isAlert: true,
                          ),
                          _buildQuickAction(Icons.cloud_rounded, "Cuaca", () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Fitur cuaca sedang disiapkan.',
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    IconData? icon,
    String label,
    VoidCallback onTap, {
    bool isAlert = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.h),
        hoverColor: Colors.white.withOpacity(0.1),
        splashColor: Colors.white.withOpacity(0.2),
        highlightColor: Colors.white.withOpacity(0.15),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isAlert ? 10.h : 8.h),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isAlert ? Colors.redAccent : Colors.transparent,
                  boxShadow: isAlert
                      ? [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.6),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: isAlert
                    ? Text(
                        "SOS",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.fSize,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : Icon(
                        icon,
                        size: 32.h,
                        color: Colors.white,
                      ),
              ),
              SizedBox(height: 8.h),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.fSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeFeed(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.h),
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          final homeInitialModelObj = state.homeInitialModelObj;
          final recommended = state.recommendedMountain;
          final mountains = homeInitialModelObj?.homelistItemList ?? [];
          final isLoading = state.isLoadingRecommended;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h), // Spacing after sticky header

              // Recommended Section
              if (isLoading) ...[
                _buildSectionHeader(
                    'Rekomendasi Untuk Anda', Icons.auto_awesome_rounded),
                _buildShimmerLoadingCard(),
                SizedBox(height: 16.h),
              ] else if (recommended != null) ...[
                _buildSectionHeader(
                    'Rekomendasi Untuk Anda', Icons.auto_awesome_rounded),
                HomelistItemWidget(
                  recommended,
                  isRecommended: true,
                ),
                SizedBox(height: 24.h),
              ],

              // Pilihan Lainnya Section Header
              Text(
                'Pilihan Lainnya',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18.fSize,
                  color: const Color(0xFF1B8A5A),
                ),
              ),
              SizedBox(height: 12.h),

              ListView.separated(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                separatorBuilder: (context, index) => SizedBox(height: 16.h),
                itemCount: mountains.length,
                itemBuilder: (context, index) {
                  HomelistItemModel model = mountains[index];
                  return HomelistItemWidget(model);
                },
              ),
              if (recommended == null && mountains.isEmpty && !isLoading)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.h),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.landscape_rounded,
                            size: 64.h, color: Colors.grey[300]),
                        SizedBox(height: 16.h),
                        Text(
                          'Belum ada data gunung tersedia.',
                          style: CustomTextStyles.bodyMediumGray500,
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 80.h), // Extra padding for bottom nav
            ],
          );
        },
      ),
    );
  }

  /// Modern Section Header
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, top: 8.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.h),
            decoration: BoxDecoration(
              color: const Color(0xFF1B8A5A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.h),
            ),
            child: Icon(icon, color: const Color(0xFF1B8A5A), size: 18.h),
          ),
          SizedBox(width: 10.h),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16.fSize,
              color: const Color(0xFF1B8A5A),
            ),
          ),
        ],
      ),
    );
  }

  /// Shimmer Loading Skeleton Card Modern
  Widget _buildShimmerLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.h),
        color: Colors.white,
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20.h,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.maxFinite,
              height: 180.h,
              color: Colors.grey[200],
              child: _buildShimmerEffect(),
            ),
            Padding(
              padding: EdgeInsets.all(16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 200.h,
                    height: 18.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4.h),
                    ),
                    child: _buildShimmerEffect(),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    width: 140.h,
                    height: 14.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4.h),
                    ),
                    child: _buildShimmerEffect(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.6),
                Colors.white.withOpacity(0.0),
              ],
              stops: [
                max(0, value - 0.3),
                value,
                min(1, value + 0.3),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Glassmorphism Sticky Header for Search & Filter
class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final double transparency;
  final BuildContext context;
  final String? selectedProvince;
  final Function(String?) onProvinceChange;

  const _SearchBarDelegate({
    required this.transparency,
    required this.context,
    required this.selectedProvince,
    required this.onProvinceChange,
  });

  // Diperbesar sedikit untuk mengakomodasi row search + filter
  @override
  double get minExtent => 85.h;

  @override
  double get maxExtent => 85.h;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Glassmorphism effect logic
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: transparency * 15,
          sigmaY: transparency * 15,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85 + (transparency * 0.1)),
            boxShadow: [
              if (transparency > 0)
                BoxShadow(
                  color: Colors.black.withOpacity(0.05 * transparency),
                  blurRadius: 10.h,
                  offset: Offset(0, 4.h),
                ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 14.h),
            child: Row(
              children: [
                // Search Bar
                Expanded(
                  flex: 5,
                  child:
                      BlocSelector<HomeBloc, HomeState, TextEditingController?>(
                    selector: (state) => state.searchController,
                    builder: (context, searchController) {
                      return CustomSearchView(
                        controller: searchController,
                        hintText: "Cari gunung...",
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.h,
                          vertical: 14.h,
                        ),
                        onChanged: (query) {
                          context.read<HomeBloc>().add(HomeSearchEvent(query));
                        },
                      );
                    },
                  ),
                ),
                SizedBox(width: 12.h),
                // Modern Filter Dropdown Mini
                Expanded(
                  flex: 4,
                  child: _buildCompactProvinceFilter(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactProvinceFilter() {
    final provinces = [
      'Semua Provinsi',
      'Jawa Tengah',
      'Jawa Timur',
      'Jawa Barat',
      'Sumatera Utara',
      'Sumatera Barat',
      'Sulawesi Utara',
      'Kalimantan Timur',
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.h),
      height: double.maxFinite,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.h),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4.h,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedProvince ?? 'Semua Provinsi',
          icon: Icon(Icons.filter_list_rounded,
              color: const Color(0xFF1B8A5A), size: 20.h),
          isExpanded: true,
          style: TextStyle(
            fontSize: 12.fSize,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          onChanged: onProvinceChange,
          items: provinces.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value == 'Semua Provinsi' ? 'Filter Area' : value,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_SearchBarDelegate oldDelegate) {
    return transparency != oldDelegate.transparency ||
        selectedProvince != oldDelegate.selectedProvince;
  }
}
