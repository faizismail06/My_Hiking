import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui; // Tambahan untuk efek blur glassmorphism
import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_search_view.dart';
import 'bloc/home_bloc.dart';
import 'models/home_initial_model.dart';
import 'models/homelist_item_model.dart';
import 'models/recommendation_model.dart';
import 'widgets/homelist_item_widget.dart';
import 'package:myhiking/api/api_service.dart';
import 'quick_access_handler_page.dart';
import 'weather_screen.dart';
import '../trail_screen/trail_screen.dart';

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
  bool _isFriendHovered = false;
  bool _isFriendPressed = false;
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

    return RefreshIndicator(
      color: const Color(0xFF1B8A5A),
      onRefresh: _refreshHomeFeed,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
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
      ),
    );
  }

  Future<void> _refreshHomeFeed() async {
    final completer = Completer<void>();
    context.read<HomeBloc>().add(HomeRefreshEvent(completer: completer));
    await completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () => null,
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
                    // Friend Button with hover and press effects
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) {
                        if (!mounted) return;
                        setState(() => _isFriendHovered = true);
                      },
                      onExit: (_) {
                        if (!mounted) return;
                        setState(() {
                          _isFriendHovered = false;
                          _isFriendPressed = false;
                        });
                      },
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutCubic,
                        scale: _isFriendPressed
                            ? 0.94
                            : _isFriendHovered
                                ? 1.08
                                : 1.0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                    _isFriendHovered ? 0.22 : 0.14),
                                blurRadius: _isFriendHovered ? 18.h : 10.h,
                                offset: Offset(0, _isFriendHovered ? 7.h : 4.h),
                              ),
                              BoxShadow(
                                color: const Color(0xFF1B8A5A).withOpacity(
                                    _isFriendHovered ? 0.26 : 0.12),
                                blurRadius: _isFriendHovered ? 16.h : 8.h,
                                offset: Offset(0, _isFriendHovered ? 5.h : 2.h),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                if (userId != 0) {
                                  Navigator.of(context, rootNavigator: true)
                                      .pushNamed(
                                    AppRoutes.friendScreen,
                                    arguments: userId,
                                  );
                                }
                              },
                              onHover: (value) {
                                if (!mounted) return;
                                setState(() => _isFriendHovered = value);
                              },
                              onHighlightChanged: (value) {
                                if (!mounted) return;
                                setState(() => _isFriendPressed = value);
                              },
                              splashColor:
                                  const Color(0xFF1B8A5A).withOpacity(0.16),
                              highlightColor:
                                  const Color(0xFF1B8A5A).withOpacity(0.08),
                              child: Padding(
                                padding: EdgeInsets.all(12.h),
                                child: Icon(
                                  Icons.people_outline_rounded,
                                  color: const Color(0xFF1B8A5A),
                                  size: 26.h,
                                ),
                              ),
                            ),
                          ),
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
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                builder: (context) => const WeatherScreen(),
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
          final mountains = homeInitialModelObj?.homelistItemList ?? [];
          final recommendations = [...state.recommendations]
            ..sort((a, b) => b.score.compareTo(a.score));
          final topThree = recommendations.take(3).toList();

          final mountainPool = <HomelistItemModel>[
            if (state.baseRecommendedMountain != null)
              state.baseRecommendedMountain!,
            ...state.baseAllMountains,
          ];

          final recommendationError = state.recommendationError;
          final isLoading = state.isLoadingRecommended;
          final otherMountains = mountains;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h), // Spacing after sticky header

              // Recommended Section
              if (isLoading) ...[
                _buildSectionHeader(
                    'Rekomendasi Untuk Anda', Icons.auto_awesome_rounded),
                SizedBox(
                  height: 340.h,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 2,
                    separatorBuilder: (context, index) => SizedBox(width: 12.h),
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: 280.h,
                        child: _buildRecommendationLoading(),
                      );
                    },
                  ),
                ),
                SizedBox(height: 24.h),
              ] else ...[
                _buildSectionHeader(
                    'Rekomendasi Untuk Anda', Icons.auto_awesome_rounded),
                if (topThree.isNotEmpty)
                  SizedBox(
                    height: 340.h,
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: topThree.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(width: 12.h),
                      itemBuilder: (context, index) {
                        final recommendation = topThree[index];
                        final mountain = _findMountainByRecommendation(
                          recommendation,
                          mountainPool,
                        );

                        if (mountain == null) {
                          return SizedBox(
                            width: 280.h,
                            child: _buildRecommendationFallbackCard(
                                recommendation),
                          );
                        }

                        return SizedBox(
                          width: 280.h,
                          child: HomelistItemWidget(
                            mountain,
                            isRecommended: true,
                            topsisRecommendation: recommendation,
                            onTap: () => _openRecommendedRoute(
                              context,
                              recommendation,
                              mountain,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else if (recommendationError != null)
                  _buildRecommendationError(
                    recommendationError,
                    onRetry: () => context.read<HomeBloc>().add(
                          HomeRefreshEvent(),
                        ),
                  )
                else
                  _buildRecommendationEmpty(),
                SizedBox(height: 24.h),
              ],

              if (otherMountains.isNotEmpty) ...[
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
                  itemCount: otherMountains.length,
                  itemBuilder: (context, index) {
                    return HomelistItemWidget(otherMountains[index]);
                  },
                ),
              ],

              if (topThree.isEmpty && otherMountains.isEmpty && !isLoading)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.h),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.landscape_rounded,
                            size: 64.h, color: Colors.grey[300]),
                        SizedBox(height: 16.h),
                        Text(
                          'Belum ada rekomendasi tersedia.',
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

  HomelistItemModel? _findMountainByRecommendation(
    RecommendationModel recommendation,
    List<HomelistItemModel> mountains,
  ) {
    final target = _normalizeMountainName(recommendation.mountainName);

    for (final mountain in mountains) {
      final name = _normalizeMountainName(mountain.namaGunung ?? '');
      if (name == target || name.contains(target) || target.contains(name)) {
        return mountain;
      }
    }

    return null;
  }

  void _openRecommendedRoute(
    BuildContext context,
    RecommendationModel recommendation,
    HomelistItemModel mountain,
  ) {
    final idGunung = mountain.id;
    final jalurId = recommendation.routeId;

    if (idGunung == null || idGunung <= 0 || jalurId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data jalur rekomendasi belum valid.')),
      );
      return;
    }

    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => TrailScreen(
          jalurId: jalurId,
          idGunung: idGunung,
        ),
      ),
    );
  }

  String _normalizeMountainName(String value) {
    return value
        .toLowerCase()
        .replaceAll('gunung', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Widget _buildRecommendationLoading() {
    return Stack(
      children: [
        _buildShimmerLoadingCard(),
        Positioned.fill(
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.h),
              color: Colors.white.withOpacity(0.35),
            ),
            child: const CircularProgressIndicator(
              color: Color(0xFF1B8A5A),
              strokeWidth: 2.8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationError(
    String message, {
    required VoidCallback onRetry,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.h),
        color: Colors.white,
        border: Border.all(color: Colors.red.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red[400], size: 24.h),
          SizedBox(width: 10.h),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
                fontSize: 13.fSize,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Muat Ulang'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationEmpty() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.h),
        color: Colors.white,
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Text(
        'Belum ada rekomendasi jalur tersedia.',
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 13.fSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRecommendationFallbackCard(RecommendationModel item) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.h),
        color: Colors.white,
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16.h,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_rankMedal(item.rank)} #${item.rank} ${item.mountainName}',
              style: TextStyle(
                fontSize: 16.fSize,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1B8A5A),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Route: ${item.routeName}',
              style: TextStyle(
                fontSize: 13.fSize,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'Data detail gunung belum tersedia, silakan refresh.',
              style: TextStyle(
                fontSize: 12.fSize,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.h, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B8A5A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.h),
                  ),
                  child: Text(
                    'Score: ${item.score.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12.fSize,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B8A5A),
                    ),
                  ),
                ),
                SizedBox(width: 8.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.h, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: _riskColor(item.risk).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10.h),
                  ),
                  child: Text(
                    'Risk: ${item.risk}',
                    style: TextStyle(
                      fontSize: 12.fSize,
                      fontWeight: FontWeight.w700,
                      color: _riskColor(item.risk),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _rankMedal(int rank) {
    if (rank == 1) {
      return '🥇';
    }
    if (rank == 2) {
      return '🥈';
    }
    if (rank == 3) {
      return '🥉';
    }
    return '🏔';
  }

  Color _riskColor(String risk) {
    final value = risk.toUpperCase();
    if (value == 'SAFE' || value == 'LOW') {
      return const Color(0xFF1B8A5A);
    }
    if (value == 'MEDIUM') {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFFDC2626);
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
