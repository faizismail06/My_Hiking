import 'package:flutter/material.dart';
import 'package:myhiking/api/api_service.dart';

class ExperienceOnboardingScreen extends StatefulWidget {
  const ExperienceOnboardingScreen({super.key});

  @override
  State<ExperienceOnboardingScreen> createState() =>
      _ExperienceOnboardingScreenState();
}

class _ExperienceOnboardingScreenState extends State<ExperienceOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahPendakianController = TextEditingController();
  final _jumlahSummitController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _jumlahPendakianController.dispose();
    _jumlahSummitController.dispose();
    super.dispose();
  }

  int? _parseInt(String value) {
    return int.tryParse(value.trim());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final jumlahPendakian = _parseInt(_jumlahPendakianController.text) ?? 0;
    final jumlahSummit = _parseInt(_jumlahSummitController.text) ?? 0;

    if (jumlahSummit > jumlahPendakian) {
      _showSnack('Jumlah summit tidak boleh lebih besar dari jumlah pendakian.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await ApiService().submitOnboardingExperience(
        jumlahPendakian: jumlahPendakian,
        jumlahSummit: jumlahSummit,
      );

      if (!mounted) return;

      final data = (response['data'] as Map<String, dynamic>?) ?? {};
      final tier = data['tier']?.toString() ?? '-';

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.verified_rounded, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Expanded(child: Text('Onboarding Berhasil')),
            ],
          ),
          content: Text(
            'Data pengalaman tersimpan.\nTier Anda: $tier',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiActionException catch (e) {
      if (!mounted) return;
      _showSnack(e.message);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Terjadi kesalahan saat menyimpan onboarding experience.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding Experience'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Isi data pengalaman pendakian untuk menentukan tier awal Anda.',
                        style: TextStyle(color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _jumlahPendakianController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah pendakian sebelumnya',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Jumlah pendakian wajib diisi.';
                  }
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null || parsed < 0) {
                    return 'Isi angka valid (>= 0).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _jumlahSummitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah summit',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Jumlah summit wajib diisi.';
                  }
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null || parsed < 0) {
                    return 'Isi angka valid (>= 0).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B734A), // Warna hijau tombol Anda
                    foregroundColor: Colors.white,            // <--- INI KUNCINYA agar teks & ikon jadi PUTIH
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), // Biar melengkung sesuai gambar
                    ),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white, // Loader juga harus putih
                          ),
                        )
                      : const Icon(Icons.flag_rounded, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'Menyimpan...' : 'Simpan Onboarding',
                    style: const TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
