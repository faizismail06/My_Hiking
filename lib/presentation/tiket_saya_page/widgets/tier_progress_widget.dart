import 'package:flutter/material.dart';
import '../../../core/app_export.dart';

class TierProgressWidget extends StatelessWidget {
  final String? userTier;
  final String? tierSource;

  const TierProgressWidget({
    super.key,
    this.userTier,
    this.tierSource,
  });

  @override
  Widget build(BuildContext context) {
    final tier = _parseTier(userTier);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.h),
      padding: EdgeInsets.all(18.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.h),
        border: Border.all(
          color: const Color(0xFFE5E7EB).withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16.h,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 38.h,
                height: 38.h,
                decoration: BoxDecoration(
                  color: tier.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10.h),
                ),
                child: Icon(
                  tier.icon,
                  color: tier.color,
                  size: 22.h,
                ),
              ),
              SizedBox(width: 12.h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level Pendaki',
                      style: TextStyle(
                        fontSize: 12.fSize,
                        color: const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      tier.label,
                      style: TextStyle(
                        fontSize: 16.fSize,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              ),
              if (tierSource != null && tierSource!.isNotEmpty)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.h, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12.h),
                  ),
                  child: Text(
                    _formatSource(tierSource),
                    style: TextStyle(
                      fontSize: 10.fSize,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 20.h),
          // Progress bar
          _buildProgressBar(tier.step),
          SizedBox(height: 10.h),
          // Labels
          Row(
            children: [
              _buildStepLabel('Pemula', 0, tier.step),
              _buildStepLabel('Menengah', 1, tier.step),
              _buildStepLabel('Mahir', 2, tier.step),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int currentStep) {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index <= currentStep;
        final isFirst = index == 0;
        final isLast = index == 2;

        return Expanded(
          child: Row(
            children: [
              if (!isFirst)
                Expanded(
                  child: Container(
                    height: 3.h,
                    color: isActive
                        ? _stepColor(currentStep)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
              Container(
                width: 28.h,
                height: 28.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? _stepColor(currentStep)
                      : const Color(0xFFE5E7EB),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: _stepColor(currentStep).withOpacity(0.4),
                            blurRadius: 8.h,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: isActive
                      ? Icon(
                          index < currentStep
                              ? Icons.check_rounded
                              : _stepIcon(index),
                          color: Colors.white,
                          size: 16.h,
                        )
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12.fSize,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 3.h,
                    color: index < currentStep
                        ? _stepColor(currentStep)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepLabel(String label, int step, int currentStep) {
    final isActive = step <= currentStep;
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11.fSize,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
          color: isActive ? const Color(0xFF1A1A2E) : const Color(0xFF9CA3AF),
        ),
      ),
    );
  }

  Color _stepColor(int step) {
    switch (step) {
      case 0:
        return const Color(0xFF8BC34A);
      case 1:
        return const Color(0xFFFFB300);
      case 2:
        return const Color(0xFFE57373);
      default:
        return const Color(0xFF8BC34A);
    }
  }

  IconData _stepIcon(int step) {
    switch (step) {
      case 0:
        return Icons.eco_outlined;
      case 1:
        return Icons.hiking_rounded;
      case 2:
        return Icons.workspace_premium_outlined;
      default:
        return Icons.eco_outlined;
    }
  }

  _TierInfo _parseTier(String? rawTier) {
    final normalized = (rawTier ?? '').trim().toLowerCase();

    if (normalized.isEmpty || normalized == 'null') {
      return const _TierInfo(
        label: 'Belum Ditentukan',
        color: Color(0xFFFFD54F),
        icon: Icons.help_outline_rounded,
        step: -1,
      );
    }

    if (normalized == 'pemula' ||
        normalized == 'beginner' ||
        normalized == 'tier_1') {
      return const _TierInfo(
        label: 'Tier 1 - Pemula',
        color: Color(0xFF8BC34A),
        icon: Icons.eco_outlined,
        step: 0,
      );
    }

    if (normalized == 'menengah' ||
        normalized == 'intermediate' ||
        normalized == 'tier_2') {
      return const _TierInfo(
        label: 'Tier 2 - Menengah',
        color: Color(0xFFFFB300),
        icon: Icons.hiking_rounded,
        step: 1,
      );
    }

    if (normalized == 'mahir' ||
        normalized == 'advanced' ||
        normalized == 'tier_3') {
      return const _TierInfo(
        label: 'Tier 3 - Mahir',
        color: Color(0xFFE57373),
        icon: Icons.workspace_premium_outlined,
        step: 2,
      );
    }

    return _TierInfo(
      label: rawTier ?? '-',
      color: const Color(0xFF81C784),
      icon: Icons.flag_outlined,
      step: 0,
    );
  }

  String _formatSource(String? source) {
    if (source == null || source.trim().isEmpty) return '';
    final formatted = source.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
    return formatted;
  }
}

class _TierInfo {
  final String label;
  final Color color;
  final IconData icon;
  final int step;

  const _TierInfo({
    required this.label,
    required this.color,
    required this.icon,
    required this.step,
  });
}
