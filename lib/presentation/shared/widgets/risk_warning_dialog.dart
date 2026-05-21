import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../home_screen/models/recommendation_model.dart';

/// A humanized warning dialog shown when a user tries to open a route whose
/// risk_level is 'caution' or 'high_risk'.
///
/// The dialog is purely informational — it never blocks navigation.
/// Buttons:
///   - Batal          → closes dialog, does NOT navigate
///   - Lihat Risiko Detail (high_risk only) → navigates & signals "detail" intent
///   - Lanjut / Lanjut Anyway → navigates anyway
class RiskWarningDialog extends StatelessWidget {
  final RecommendationModel recommendation;

  /// Human-readable user tier string (e.g. "pemula", "menengah", "mahir").
  final String userTier;

  const RiskWarningDialog({
    super.key,
    required this.recommendation,
    required this.userTier,
  });

  // ── Public factory ──────────────────────────────────────────────────────

  /// Show the dialog and return a [_RiskDialogResult]:
  ///   - null          → user tapped Batal / dismissed
  ///   - 'continue'    → user tapped Lanjut
  ///   - 'detail'      → user tapped Lihat Risiko Detail
  static Future<String?> show(
    BuildContext context, {
    required RecommendationModel recommendation,
    required String userTier,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => RiskWarningDialog(
        recommendation: recommendation,
        userTier: userTier,
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isHighRisk = recommendation.rawRisk == 'high_risk';
    final isCaution = recommendation.rawRisk == 'caution';

    final config = _buildConfig(isHighRisk: isHighRisk, isCaution: isCaution);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.h),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _DialogContent(
        config: config,
        recommendation: recommendation,
        isHighRisk: isHighRisk,
      ),
    );
  }

  // ── Config builder ──────────────────────────────────────────────────────

  _RiskConfig _buildConfig({
    required bool isHighRisk,
    required bool isCaution,
  }) {
    final tier = userTier.toLowerCase().trim();
    final mountainName = recommendation.mountainName;
    final routeName = recommendation.routeName;

    if (isHighRisk) {
      // Pemula vs. default message for high_risk
      final bool isPemula =
          tier == 'pemula' || tier == 'tier_1' || tier == 'beginner';

      return _RiskConfig(
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFD32F2F),
        iconBgColor: const Color(0xFFFFEBEE),
        badgeLabel: 'Risiko Tinggi',
        badgeColor: const Color(0xFFD32F2F),
        title: isPemula
            ? 'Gunung ini cukup menantang untukmu'
            : 'Perhatian: Risiko Tinggi',
        body: isPemula
            ? 'Jalur $routeName di $mountainName tergolong menantang '
                'untuk pendaki pemula. Pertimbangkan persiapan lebih matang, '
                'atau pilih rute yang lebih sesuai dengan pengalamanmu.\n\n'
                'Apakah kamu yakin ingin melanjutkan?'
            : 'Jalur $routeName di $mountainName dinilai berisiko tinggi '
                'berdasarkan profil kamu dan kondisi saat ini.\n\n'
                'Pastikan kamu telah mempersiapkan diri dengan baik. '
                'Apakah kamu ingin tetap melanjutkan?',
        showDetailButton: true,
        continueLabel: 'Lanjut Anyway',
      );
    }

    if (isCaution) {
      final bool isMenengah =
          tier == 'menengah' || tier == 'tier_2' || tier == 'intermediate';

      return _RiskConfig(
        icon: Icons.info_outline_rounded,
        iconColor: const Color(0xFFF57C00),
        iconBgColor: const Color(0xFFFFF3E0),
        badgeLabel: 'Perlu Perhatian',
        badgeColor: const Color(0xFFF57C00),
        title: 'Rute cukup challenging',
        body: isMenengah
            ? 'Jalur $routeName di $mountainName tergolong cukup '
                'menantang, tapi kamu sudah punya pengalaman mendaki. '
                'Silakan lanjutkan jika kamu merasa siap.'
            : 'Jalur $routeName di $mountainName membutuhkan perhatian '
                'ekstra. Pastikan kondisi fisik dan perlengkapanmu memadai.',
        showDetailButton: false,
        continueLabel: 'Lanjut',
      );
    }

    // Fallback (shouldn't normally be reached if dialog is only shown for caution/high_risk)
    return _RiskConfig(
      icon: Icons.shield_outlined,
      iconColor: const Color(0xFF1B8A5A),
      iconBgColor: const Color(0xFFE8F5E9),
      badgeLabel: 'Info',
      badgeColor: const Color(0xFF1B8A5A),
      title: 'Informasi Jalur',
      body: 'Perhatikan kondisi cuaca dan fisik sebelum mendaki.',
      showDetailButton: false,
      continueLabel: 'Lanjut',
    );
  }
}

// ── Internal data class ────────────────────────────────────────────────────────

class _RiskConfig {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String badgeLabel;
  final Color badgeColor;
  final String title;
  final String body;
  final bool showDetailButton;
  final String continueLabel;

  const _RiskConfig({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.badgeLabel,
    required this.badgeColor,
    required this.title,
    required this.body,
    required this.showDetailButton,
    required this.continueLabel,
  });
}

// ── Dialog content widget ──────────────────────────────────────────────────────

class _DialogContent extends StatelessWidget {
  final _RiskConfig config;
  final RecommendationModel recommendation;
  final bool isHighRisk;

  const _DialogContent({
    required this.config,
    required this.recommendation,
    required this.isHighRisk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.h),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.h),
                decoration: BoxDecoration(
                  color: config.iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(config.icon, color: config.iconColor, size: 26.h),
              ),
              SizedBox(width: 12.h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.h, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: config.badgeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6.h),
                      ),
                      child: Text(
                        config.badgeLabel,
                        style: TextStyle(
                          color: config.badgeColor,
                          fontSize: 10.fSize,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    // Title
                    Text(
                      config.title,
                      style: TextStyle(
                        fontSize: 15.fSize,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // ── Route info chip ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10.h),
            ),
            child: Row(
              children: [
                Icon(Icons.route_rounded, size: 14.h, color: Colors.grey[600]),
                SizedBox(width: 6.h),
                Expanded(
                  child: Text(
                    '${recommendation.routeName} — ${recommendation.mountainName}',
                    style: TextStyle(
                      fontSize: 12.fSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // ── Body message ────────────────────────────────────────────────
          Text(
            config.body,
            style: TextStyle(
              fontSize: 13.fSize,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),

          SizedBox(height: 24.h),

          // ── Action buttons ──────────────────────────────────────────────
          Row(
            children: [
              // Cancel button
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.h)),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      fontSize: 13.fSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),

              // Detail button (high_risk only)
              if (config.showDetailButton) ...[
                SizedBox(width: 8.h),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop('detail'),
                    style: OutlinedButton.styleFrom(
                      side:
                          BorderSide(color: config.iconColor.withOpacity(0.6)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.h)),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text(
                      'Lihat Risiko',
                      style: TextStyle(
                        fontSize: 12.fSize,
                        fontWeight: FontWeight.w700,
                        color: config.iconColor,
                      ),
                    ),
                  ),
                ),
              ],

              SizedBox(width: 8.h),

              // Continue button
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop('continue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: config.iconColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.h)),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Text(
                    config.continueLabel,
                    style: TextStyle(
                      fontSize: 13.fSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
