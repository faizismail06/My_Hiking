import 'package:flutter/material.dart';
import '../../../core/app_export.dart';

class StatsHeaderWidget extends StatelessWidget {
  final int totalCompletedHikes;
  final int uniqueMountains;
  final String userName;

  const StatsHeaderWidget({
    super.key,
    required this.totalCompletedHikes,
    required this.uniqueMountains,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.h),
      padding: EdgeInsets.all(18.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF065F46),
            Color(0xFF059669),
            Color(0xFF10B981),
          ],
        ),
        borderRadius: BorderRadius.circular(20.h),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withOpacity(0.3),
            blurRadius: 16.h,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Row(
            children: [
              Icon(
                Icons.terrain_rounded,
                color: Colors.white.withOpacity(0.9),
                size: 22.h,
              ),
              SizedBox(width: 8.h),
              Text(
                'Catatan Pendakian',
                style: TextStyle(
                  fontSize: 16.fSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Padding(
            padding: EdgeInsets.only(left: 30.h),
            child: Text(
              userName.isNotEmpty ? userName : 'Pendaki',
              style: TextStyle(
                fontSize: 13.fSize,
                color: Colors.white.withOpacity(0.75),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          // Stats row
          Row(
            children: [
              _buildStatCard(
                Icons.flag_rounded,
                totalCompletedHikes.toString(),
                'Total\nPendakian',
              ),
              SizedBox(width: 12.h),
              _buildStatCard(
                Icons.landscape_rounded,
                uniqueMountains.toString(),
                'Gunung\nDitaklukkan',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14.h),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36.h,
              height: 36.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10.h),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20.h,
              ),
            ),
            SizedBox(width: 10.h),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22.fSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10.fSize,
                      color: Colors.white.withOpacity(0.75),
                      height: 1.3,
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
}
