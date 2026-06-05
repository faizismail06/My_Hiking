import 'package:flutter/material.dart';

/// Debug-only page accessible via route '/test_onboarding_popup'.
/// Shows three buttons to instantly test each tier result popup
/// without needing to fill in the questionnaire or create a new account.
class OnboardingResultTestPage extends StatelessWidget {
  const OnboardingResultTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Onboarding Popup'),
        backgroundColor: const Color(0xFF1B734A),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bug_report, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Pilih tier untuk melihat popup hasil onboarding',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 32),
              _TierTestButton(
                label: 'Test Tier Pemula (Score 17)',
                color: const Color(0xFF1B734A),
                onTap: () => _showPopup(context, 'Pemula', '17', 'assets/images/logo_pemula.png'),
              ),
              const SizedBox(height: 14),
              _TierTestButton(
                label: 'Test Tier Menengah (Score 55)',
                color: const Color(0xFFD6A015),
                onTap: () => _showPopup(context, 'Menengah', '55', 'assets/images/logo_menengah.png'),
              ),
              const SizedBox(height: 14),
              _TierTestButton(
                label: 'Test Tier Mahir (Score 85)',
                color: const Color(0xFF8B4513),
                onTap: () => _showPopup(context, 'Mahir', '85', 'assets/images/logo_mahir.png'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPopup(
    BuildContext context,
    String weightedTier,
    String weightedScore,
    String badgeAsset,
  ) {
    final tierLower = weightedTier.toLowerCase();
    final Color tierColor;
    if (tierLower == 'mahir') {
      tierColor = const Color(0xFF8B4513);
    } else if (tierLower == 'menengah') {
      tierColor = const Color(0xFFD6A015);
    } else {
      tierColor = const Color(0xFF1B734A);
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // ── Card body ──
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 50),
              padding: const EdgeInsets.fromLTRB(24, 70, 24, 24),
              decoration: BoxDecoration(
                color: const Color(0xFFFCF9F0),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    'Selamat! Ini Awal\nBaru Kamu!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5D4037),
                      height: 1.3,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),

                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.55,
                      ),
                      children: [
                        const TextSpan(
                          text:
                              'Halo! Kuesioner kamu sudah tersimpan dengan baik. Berdasarkan jawabanmu, kami dengan bangga menempatkan kamu di Tier ',
                        ),
                        TextSpan(
                          text: weightedTier,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: tierColor,
                          ),
                        ),
                        const TextSpan(text: '.\nSkor fondasi kamu adalah '),
                        TextSpan(
                          text: weightedScore,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD6A015),
                          ),
                        ),
                        const TextSpan(
                          text:
                              ', yang merupakan titik awal yang luar biasa! Jangan khawatir, ini adalah langkah pertama yang sempurna untuk membangun kekuatan dan kebiasaan sehatmu.',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // CTA Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B734A),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(
                      'Ayo Mulai Perjalananmu!',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // Top center Tier Badge (No border)
            Positioned(
              top: 0,
              child: Image.asset(
                badgeAsset,
                width: 110,
                height: 110,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tierColor.withOpacity(0.15),
                    border: Border.all(
                      color: tierColor.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    color: tierColor,
                    size: 50,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierTestButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TierTestButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
