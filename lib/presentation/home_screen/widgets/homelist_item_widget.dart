import 'package:flutter/material.dart';
import 'dart:ui' as ui; // Tambahan untuk efek blur glassmorphism
import 'package:myhiking/api/api_service.dart';
import 'package:myhiking/presentation/detail_mountain_screen/bloc/detail_mountain_bloc.dart';
import 'package:myhiking/presentation/detail_mountain_screen/detail_mountain_screen.dart';
import '../../../core/app_export.dart';
import '../models/homelist_item_model.dart';
import '../models/recommendation_model.dart';

class HomelistItemWidget extends StatefulWidget {
  const HomelistItemWidget(
    this.homelistItemModelObj, {
    super.key,
    this.isRecommended = false,
    this.topsisRecommendation,
    this.onTap,
  });

  final HomelistItemModel homelistItemModelObj;
  final bool isRecommended;
  final RecommendationModel? topsisRecommendation;
  final VoidCallback? onTap;

  @override
  State<HomelistItemWidget> createState() => _HomelistItemWidgetState();
}

class _HomelistItemWidgetState extends State<HomelistItemWidget> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.homelistItemModelObj.gambar ?? '';
    final rec = widget.topsisRecommendation;

    // Determine risk for border accent when risk != safe
    final riskBorderColor = _riskBorderColor(rec?.rawRisk ?? '');

    final cardScale = _isPressed
        ? 0.985
        : _isHovered
            ? 1.01
            : 1.0;

    final offsetY = _isPressed
        ? 1.5
        : _isHovered
            ? -4.0
            : 0.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!mounted) return;
        setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (!mounted) return;
        setState(() {
          _isHovered = false;
          _isPressed = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translate(0.0, offsetY)
          ..scale(cardScale),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.h),
          color: Colors.white,
          border: Border.all(
            color: _isHovered
                ? (riskBorderColor ?? const Color(0xFF1B8A5A)).withOpacity(0.35)
                : riskBorderColor?.withOpacity(0.20) ??
                    Colors.grey.withOpacity(0.1),
            width: riskBorderColor != null ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isHovered ? 0.12 : 0.09),
              blurRadius: _isHovered ? 34.h : 28.h,
              spreadRadius: 0.5,
              offset: Offset(0, _isHovered ? 14.h : 10.h),
            ),
            BoxShadow(
              color:
                  const Color(0xFF1B8A5A).withOpacity(_isHovered ? 0.14 : 0.08),
              blurRadius: _isHovered ? 24.h : 18.h,
              spreadRadius: -2,
              offset: Offset(0, _isHovered ? 10.h : 6.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.h),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (widget.onTap != null) {
                  widget.onTap!.call();
                  return;
                }
                onTapImgGunung(context, widget.homelistItemModelObj);
              },
              onHover: (value) {
                if (!mounted) return;
                setState(() => _isHovered = value);
              },
              onHighlightChanged: (value) {
                if (!mounted) return;
                setState(() => _isPressed = value);
              },
              splashColor: const Color(0xFF1B8A5A).withOpacity(0.12),
              highlightColor: const Color(0xFF1B8A5A).withOpacity(0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  Stack(
                    children: [
                      Container(
                        width: double.maxFinite,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                        ),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[100],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_not_supported_rounded,
                                        color: Colors.grey[400], size: 32.h),
                                    SizedBox(height: 8.h),
                                    Text('Gambar tidak tersedia',
                                        style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 12.fSize)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      // Recommended Badge (Glassmorphism)
                      if (widget.isRecommended)
                        Positioned(
                          top: 16.h,
                          right: 16.h,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.h),
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.h,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF1B8A5A).withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(12.h),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      color: Colors.amberAccent,
                                      size: 16.h,
                                    ),
                                    SizedBox(width: 6.h),
                                    Text(
                                      rec != null
                                          ? 'TOP #${rec.rank}'
                                          : 'Saran',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.fSize,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Risk badge (shown for caution / high_risk)
                      if (widget.isRecommended && rec != null && rec.warning)
                        Positioned(
                          top: 16.h,
                          left: 16.h,
                          child: _buildRiskBadge(rec.rawRisk),
                        ),
                    ],
                  ),
                  // Content Section
                  Padding(
                    padding: EdgeInsets.all(16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.homelistItemModelObj.namaGunung ??
                              'Nama Tidak Tersedia',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 16.fSize,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 16.h,
                              color: const Color(0xFF1B8A5A).withOpacity(0.7),
                            ),
                            SizedBox(width: 6.h),
                            Expanded(
                              child: Text(
                                widget.homelistItemModelObj.province?.name ??
                                    'Provinsi Tidak Tersedia',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13.fSize,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (widget.isRecommended && rec != null) ...[
                          SizedBox(height: 12.h),
                          Text(
                            'Route: ${rec.routeName}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13.fSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          // Risk indicator row (safe = green, caution = amber, high_risk = red)
                          SizedBox(height: 8.h),
                          _buildRiskIndicatorRow(rec.rawRisk),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Risk badge overlay (top-left of image) ──────────────────────────────

  Widget _buildRiskBadge(String rawRisk) {
    final isHighRisk = rawRisk == 'high_risk';
    final color =
        isHighRisk ? const Color(0xFFD32F2F) : const Color(0xFFF57C00);
    final icon =
        isHighRisk ? Icons.warning_rounded : Icons.info_outline_rounded;
    final label = isHighRisk ? 'Risiko Tinggi' : 'Perlu Perhatian';

    return ClipRRect(
      borderRadius: BorderRadius.circular(10.h),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.85),
            borderRadius: BorderRadius.circular(10.h),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 12.h),
              SizedBox(width: 4.h),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.fSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Risk indicator row (inside card content) ────────────────────────────

  Widget _buildRiskIndicatorRow(String rawRisk) {
    final data = _riskIndicatorData(rawRisk);
    if (data == null) return const SizedBox.shrink();

    return Row(
      children: [
        Container(
          width: 8.h,
          height: 8.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: data.color,
          ),
        ),
        SizedBox(width: 6.h),
        Text(
          data.label,
          style: TextStyle(
            fontSize: 11.fSize,
            fontWeight: FontWeight.w600,
            color: data.color,
          ),
        ),
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Color? _riskBorderColor(String rawRisk) {
    if (rawRisk == 'high_risk') return const Color(0xFFD32F2F);
    if (rawRisk == 'caution') return const Color(0xFFF57C00);
    return null; // safe → no accent border
  }

  _RiskIndicatorData? _riskIndicatorData(String rawRisk) {
    if (rawRisk == 'high_risk') {
      return _RiskIndicatorData(
        color: const Color(0xFFD32F2F),
        label: 'Risiko Tinggi',
      );
    }
    if (rawRisk == 'caution') {
      return _RiskIndicatorData(
        color: const Color(0xFFF57C00),
        label: 'Perlu Perhatian',
      );
    }
    if (rawRisk == 'safe') {
      return _RiskIndicatorData(
        color: const Color(0xFF1B8A5A),
        label: 'Aman',
      );
    }
    return null;
  }
}

class _RiskIndicatorData {
  final Color color;
  final String label;
  const _RiskIndicatorData({required this.color, required this.label});
}

Future<void> onTapImgGunung(
    BuildContext context, HomelistItemModel homelistItemModelObj) async {
  final idGunung = homelistItemModelObj.id;

  if (idGunung != null) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => DetailMountainBloc(apiService: ApiService())
            ..add(DetailMountainInitialEvent(idGunung)),
          child: DetailMountainScreen(idGunung: idGunung),
        ),
      ),
    );
  } else {
    print('Mountain ID tidak ditemukan');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data gunung tidak valid')),
    );
  }
}
