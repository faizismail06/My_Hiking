import 'package:flutter/material.dart';
import 'dart:ui' as ui; // Tambahan untuk efek blur glassmorphism
import 'package:myhiking/api/api_service.dart';
import 'package:myhiking/presentation/detail_mountain_screen/bloc/detail_mountain_bloc.dart';
import 'package:myhiking/presentation/detail_mountain_screen/detail_mountain_screen.dart';
import '../../../core/app_export.dart';
import '../models/homelist_item_model.dart';
import '../models/recommendation_model.dart';

// ignore_for_file: must_be_immutable
class HomelistItemWidget extends StatelessWidget {
  HomelistItemWidget(
    this.homelistItemModelObj, {
    super.key,
    this.isRecommended = false,
    this.topsisRecommendation,
    this.onTap,
  });

  HomelistItemModel homelistItemModelObj;
  final bool isRecommended;
  final RecommendationModel? topsisRecommendation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    String imageUrl = (homelistItemModelObj.gambar ?? '');

    final recommendation = homelistItemModelObj.dss;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.h),
        color: Colors.white,
        border: Border.all(
            color: Colors.grey.withOpacity(0.1), width: 1), // Micro-border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 28.h,
            spreadRadius: 0.5,
            offset: Offset(0, 10.h),
          ),
          BoxShadow(
            color: const Color(0xFF1B8A5A).withOpacity(0.08),
            blurRadius: 18.h,
            spreadRadius: -2,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.h),
        child: InkWell(
          onTap: () {
            if (onTap != null) {
              onTap!.call();
              return;
            }
            onTapImgGunung(context, homelistItemModelObj);
          },
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
                  if (isRecommended)
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
                              color: const Color(0xFF1B8A5A).withOpacity(0.85),
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
                                  topsisRecommendation != null
                                      ? 'TOPSIS #${topsisRecommendation!.rank}'
                                      : 'Rekomendasi DSS',
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
                ],
              ),
              // Content Section
              Padding(
                padding: EdgeInsets.all(16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      homelistItemModelObj.namaGunung ?? 'Nama Tidak Tersedia',
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
                            homelistItemModelObj.province?.name ??
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
                    if (isRecommended && recommendation != null) ...[
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.h,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B8A5A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.h),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.analytics_rounded,
                                    size: 14.h, color: const Color(0xFF1B8A5A)),
                                SizedBox(width: 4.h),
                                Text(
                                  'Risk: ${recommendation.riskLevel.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 12.fSize,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1B8A5A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (isRecommended && topsisRecommendation != null) ...[
                      SizedBox(height: 12.h),
                      Text(
                        'Route: ${topsisRecommendation!.routeName}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13.fSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.h,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B8A5A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.h),
                            ),
                            child: Text(
                              'Score: ${topsisRecommendation!.score.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12.fSize,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1B8A5A),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.h,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: _riskColor(topsisRecommendation!.risk)
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8.h),
                            ),
                            child: Text(
                              'Risk: ${topsisRecommendation!.risk}',
                              style: TextStyle(
                                fontSize: 12.fSize,
                                fontWeight: FontWeight.w700,
                                color: _riskColor(topsisRecommendation!.risk),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
