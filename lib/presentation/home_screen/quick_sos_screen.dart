import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../api/api_service.dart';

class QuickSosScreen extends StatefulWidget {
  final int orderId;
  final String mountainName;
  final DateTime hikingDate;

  const QuickSosScreen({
    super.key,
    required this.orderId,
    required this.mountainName,
    required this.hikingDate,
  });

  @override
  State<QuickSosScreen> createState() => _QuickSosScreenState();
}

class _QuickSosScreenState extends State<QuickSosScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> _emergencyTypes = const [
    'Hipotermia',
    'Kaki Keselo',
    'Tersesat',
    'Kelelahan Ekstrem',
    'Dehidrasi',
    'Cedera',
    'Lainnya',
  ];

  String? _selectedEmergencyType;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<Position?> _getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Layanan lokasi tidak aktif. Mohon aktifkan GPS.'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin lokasi ditolak.'),
            backgroundColor: Colors.red,
          ),
        );
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Izin lokasi ditolak permanen. Aktifkan dari pengaturan perangkat.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mendapatkan lokasi: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  Future<int?> _getCurrentUserId() async {
    final token = await _apiService.getToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    final userResponse = await _apiService.getUserProfile(token);
    if (userResponse['success'] != true) {
      return null;
    }

    return int.tryParse((userResponse['data']?['id'] ?? '').toString());
  }

  Future<void> _submitSos() async {
    if (_selectedEmergencyType == null || _selectedEmergencyType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih alasan darurat terlebih dahulu.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final position = await _getCurrentLocation();
      if (position == null) {
        return;
      }

      final userId = await _getCurrentUserId();
      if (userId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi login tidak valid. Silakan login ulang.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final response = await _apiService.sendPanicRequest(
        userId: userId,
        orderId: widget.orderId,
        latitude: position.latitude,
        longitude: position.longitude,
        emergencyType: _selectedEmergencyType!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (!mounted) return;

      if (response['success'] == true) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text('Permintaan Darurat Terkirim'),
              content: const Text(
                'Tim SAR telah menerima permintaan Anda. Tetap tenang dan tunggu bantuan.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(this.context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (response['message'] ?? 'Gagal mengirim permintaan darurat')
                  .toString(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'EEEE, dd MMMM yyyy',
      'id_ID',
    ).format(widget.hikingDate);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SOS Darurat'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.info_outline, color: Color(0xFFB91C1C)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tiket status mendaki aktif terdeteksi otomatis.',
                            style: TextStyle(
                              color: Color(0xFFB91C1C),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Order ID: ${widget.orderId}'),
                    Text('Gunung: ${widget.mountainName}'),
                    Text('Tanggal naik: $formattedDate'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Alasan Darurat',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedEmergencyType,
                decoration: InputDecoration(
                  hintText: 'Pilih alasan darurat',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _emergencyTypes
                    .map(
                      (type) => DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEmergencyType = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Keterangan Tambahan (Opsional)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Jelaskan kondisi saat ini...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Text(
                  'Lokasi GPS Anda akan dikirim ke tim SAR saat tombol SOS ditekan.',
                  style: TextStyle(color: Color(0xFF92400E)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitSos,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.sos),
                  label: Text(_isSubmitting ? 'Mengirim...' : 'Kirim SOS'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
