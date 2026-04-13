import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api/api_service.dart';
import '../../core/app_export.dart';
import '../../core/utils/web_file_downloader_stub.dart'
    if (dart.library.html) '../../core/utils/web_file_downloader_web.dart';
import '../offline_tracking_screen/offline_tracking_screen.dart';
import 'bloc/ticket_action_cubit.dart';
import 'bloc/ticket_action_state.dart';

class TicketActionScreen extends StatefulWidget {
  final int orderId;
  final String status;
  final String mountainName;
  final String hikingDate;

  const TicketActionScreen({
    super.key,
    required this.orderId,
    required this.status,
    required this.mountainName,
    required this.hikingDate,
  });

  @override
  State<TicketActionScreen> createState() => _TicketActionScreenState();
}

class _TicketActionScreenState extends State<TicketActionScreen> {
  final TicketActionCubit _cubit = TicketActionCubit();
  String? _selectedEmergencyType;
  final TextEditingController _descriptionController = TextEditingController();

  TicketActionState get _state => _cubit.state;

  final List<String> _emergencyTypes = [
    'Hipotermia',
    'Kaki Keselo',
    'Tersesat',
    'Kelelahan Ekstrem',
    'Dehidrasi',
    'Cedera',
    'Lainnya',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _cubit.close();
    super.dispose();
  }

  String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  Future<Directory> _resolveDownloadDirectory() async {
    if (kIsWeb) {
      throw Exception('Platform web menggunakan mekanisme download browser');
    }

    if (Platform.isAndroid) {
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
      }

      if (!status.isGranted) {
        throw Exception('Izin penyimpanan ditolak');
      }

      final downloadDir = Directory('/storage/emulated/0/Download');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      return downloadDir;
    }

    return getApplicationDocumentsDirectory();
  }

  String _buildGpxContent({
    required String mountainName,
    required String trailName,
    required List<Map<String, dynamic>> points,
    required List<Map<String, dynamic>> posts,
  }) {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final buffer = StringBuffer();

    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
        '<gpx version="1.1" creator="MyHiking" xmlns="http://www.topografix.com/GPX/1/1">');
    buffer.writeln('  <metadata>');
    buffer.writeln(
        '    <name>${_escapeXml('$mountainName - $trailName')}</name>');
    buffer.writeln('    <time>$nowIso</time>');
    buffer.writeln('  </metadata>');

    for (final post in posts) {
      final lat =
          double.tryParse((post['lat'] ?? post['latitude'] ?? '').toString());
      final lng = double.tryParse(
          (post['lng'] ?? post['lon'] ?? post['longitude'] ?? '').toString());
      if (lat == null || lng == null) {
        continue;
      }

      final name = _escapeXml((post['name'] ?? 'Pos').toString());
      final description = post['description']?.toString();
      buffer.writeln('  <wpt lat="$lat" lon="$lng">');
      buffer.writeln('    <name>$name</name>');
      if (description != null && description.isNotEmpty) {
        buffer.writeln('    <desc>${_escapeXml(description)}</desc>');
      }
      buffer.writeln('  </wpt>');
    }

    buffer.writeln('  <trk>');
    buffer.writeln(
        '    <name>${_escapeXml('$mountainName - $trailName')}</name>');
    buffer.writeln('    <trkseg>');

    for (final point in points) {
      final lat =
          double.tryParse((point['lat'] ?? point['latitude'] ?? '').toString());
      final lng = double.tryParse(
          (point['lng'] ?? point['lon'] ?? point['longitude'] ?? '')
              .toString());
      if (lat == null || lng == null) {
        continue;
      }

      final ele = point['ele'];
      final time = point['time']?.toString();

      buffer.writeln('      <trkpt lat="$lat" lon="$lng">');
      if (ele != null) {
        buffer.writeln('        <ele>${_escapeXml(ele.toString())}</ele>');
      }
      if (time != null && time.isNotEmpty) {
        buffer.writeln('        <time>${_escapeXml(time)}</time>');
      }
      buffer.writeln('      </trkpt>');
    }

    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');
    buffer.writeln('</gpx>');

    return buffer.toString();
  }

  Future<void> _downloadOrderedRoute() async {
    if (_state.isRouteDownloadLoading) {
      return;
    }

    _cubit.setRouteDownloadLoading(true);

    try {
      final orderResponse = await ApiService().fetchPesanan(widget.orderId);
      final order = orderResponse['order'] as Map<String, dynamic>?;

      final mountainId = int.tryParse((order?['id_gunung'] ?? '').toString());
      final trailId = int.tryParse((order?['id_jalur'] ?? '').toString());

      if (mountainId == null || trailId == null) {
        throw Exception('Data gunung/jalur pada pesanan tidak ditemukan');
      }

      final previewResponse = await ApiService().fetchTrailPreview(
        mountainId: mountainId,
        trailId: trailId,
      );

      final routePreview =
          previewResponse['route_preview'] as Map<String, dynamic>?;
      final pointsRaw = (routePreview?['points'] as List?) ?? const [];
      if (pointsRaw.isEmpty) {
        throw Exception('Preview jalur belum tersedia untuk rute ini');
      }

      final points = pointsRaw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      final posts = ((previewResponse['posts'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      final trailName = (order?['trail']?['nama'] ?? 'jalur').toString();
      final mountainName =
          (order?['mountain']?['nama'] ?? widget.mountainName).toString();

      final gpxContent = _buildGpxContent(
        mountainName: mountainName,
        trailName: trailName,
        points: points,
        posts: posts,
      );
      final safeMountain =
          mountainName.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
      final safeTrail = trailName.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
      final fileName =
          'jalur_${safeMountain}_${safeTrail}_${widget.orderId}.gpx';

      if (kIsWeb) {
        await downloadTextFileOnWeb(
          fileName: fileName,
          content: gpxContent,
          mimeType: 'application/gpx+xml',
        );

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jalur berhasil diunduh melalui browser'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      final directory = await _resolveDownloadDirectory();
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(gpxContent, flush: true);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Jalur berhasil diunduh ke: ${file.path}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal download jalur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) _cubit.setRouteDownloadLoading(false);
    }
  }

  bool _canCancelOrder() {
    final status = widget.status.toLowerCase();
    return status == 'booking' || status == 'bayar';
  }

  void _showCancelOrderDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Batalkan Pesanan?'),
        content: const Text(
          'Pesanan yang dibatalkan tidak dapat dikembalikan. Lanjutkan pembatalan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelOrder();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Ya, Batalkan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder() async {
    if (_state.isCancelOrderLoading) {
      return;
    }

    _cubit.setCancelOrderLoading(true);

    try {
      final result = await ApiService().cancelOrder(widget.orderId);
      if (!mounted) {
        return;
      }

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message']?.toString() ?? 'Pesanan berhasil dibatalkan.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message']?.toString() ?? 'Gagal membatalkan pesanan.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat membatalkan pesanan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        _cubit.setCancelOrderLoading(false);
      }
    }
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Layanan lokasi tidak aktif. Mohon aktifkan GPS.'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    // Check and request permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin lokasi ditolak'),
            backgroundColor: Colors.red,
          ),
        );
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Izin lokasi ditolak permanen. Mohon izinkan di pengaturan.'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    // Get current position
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mendapatkan lokasi: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  void _showPanicDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.red, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'PANIC / DARURAT',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih jenis keadaan darurat:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: Text('Pilih jenis darurat'),
                          value: _selectedEmergencyType,
                          items: _emergencyTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              _selectedEmergencyType = value;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Keterangan tambahan (opsional):',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Jelaskan kondisi Anda...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.orange.shade700),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Lokasi Anda akan dikirim ke tim SAR untuk bantuan darurat.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _selectedEmergencyType = null;
                    _descriptionController.clear();
                  },
                  child: Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: _selectedEmergencyType == null
                      ? null
                      : () {
                          Navigator.pop(context);
                          _sendPanicRequest();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Kirim SOS',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _sendPanicRequest() async {
    _cubit.setPanicLoading(true);

    try {
      // Get current location
      final position = await _getCurrentLocation();
      if (position == null) {
        _cubit.setPanicLoading(false);
        return;
      }

      // Get user ID
      final token = await ApiService().getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi telah berakhir. Silakan login kembali.'),
            backgroundColor: Colors.red,
          ),
        );
        _cubit.setPanicLoading(false);
        return;
      }

      final userResponse = await ApiService().getUserProfile(token);
      if (!userResponse['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mendapatkan data pengguna'),
            backgroundColor: Colors.red,
          ),
        );
        _cubit.setPanicLoading(false);
        return;
      }

      final userId = userResponse['data']['id'];

      // Send panic request
      final response = await ApiService().sendPanicRequest(
        userId: userId,
        orderId: widget.orderId,
        latitude: position.latitude,
        longitude: position.longitude,
        emergencyType: _selectedEmergencyType!,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
      );

      if (response['success']) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                response['message'] ?? 'Gagal mengirim permintaan darurat'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _cubit.setPanicLoading(false);
      _selectedEmergencyType = null;
      _descriptionController.clear();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 80,
            ),
            SizedBox(height: 16),
            Text(
              'Permintaan Darurat Terkirim!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Tim SAR telah menerima permintaan Anda dan akan segera merespons. Tetap tenang dan tunggu bantuan.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'OK',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<TicketActionCubit, TicketActionState>(
        builder: (context, state) {
          return SafeArea(
            child: Scaffold(
              backgroundColor: appTheme.gray50,
              appBar: AppBar(
                backgroundColor: theme.colorScheme.primary,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Detail Tiket',
                  style: TextStyle(color: Colors.white),
                ),
                centerTitle: true,
              ),
              body: ListView(
                padding: EdgeInsets.all(20.h),
                children: [
                  // Order Info Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.terrain,
                                color: theme.colorScheme.primary,
                                size: 32,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.mountainName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    widget.hikingDate,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Divider(),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              'Order ID: ',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            Text(
                              '#${widget.orderId}',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Status: ',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(widget.status)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.status,
                                style: TextStyle(
                                  color: _getStatusColor(widget.status),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  // View Ticket Button
                  _buildActionButton(
                    icon: Icons.qr_code_2,
                    title: 'Lihat Tiket',
                    subtitle: 'Tampilkan QR Code untuk check-in',
                    color: theme.colorScheme.primary,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.ticketScreen,
                        arguments: widget.orderId,
                      );
                    },
                  ),

                  SizedBox(height: 16),

                  _buildActionButton(
                    icon: Icons.route,
                    title: 'Download Jalur (GPX)',
                    subtitle:
                        'Simpan jalur pendakian yang dipesan untuk offline',
                    color: Colors.teal,
                    isLoading: state.isRouteDownloadLoading,
                    onTap: _downloadOrderedRoute,
                  ),

                  if (_canCancelOrder()) ...[
                    SizedBox(height: 16),
                    _buildActionButton(
                      icon: Icons.cancel_outlined,
                      title: 'Batalkan Pesanan',
                      subtitle: 'Batalkan pesanan ini sebelum jadwal pendakian',
                      color: Colors.red,
                      isLoading: state.isCancelOrderLoading,
                      onTap: _showCancelOrderDialog,
                    ),
                  ],

                  SizedBox(height: 16),

                  _buildActionButton(
                    icon: Icons.explore,
                    title: 'Tracking Offline + Kompas',
                    subtitle: 'Upload GPX, tracking GPS, dan kompas real-time',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OfflineTrackingScreen(
                            orderId: widget.orderId,
                            mountainName: widget.mountainName,
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 16),

                  // Panic Button - Only show when status is "Sedang Mendaki"
                  if (widget.status == 'Sedang Mendaki') ...[
                    _buildActionButton(
                      icon: Icons.sos,
                      title: 'PANIC / SOS',
                      subtitle: 'Kirim permintaan bantuan darurat',
                      color: Colors.red,
                      isLoading: state.isPanicLoading,
                      onTap: _showPanicDialog,
                    ),
                    SizedBox(height: 20),
                    // Warning info
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red.shade700,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Gunakan tombol PANIC hanya dalam keadaan darurat. Tim SAR akan segera dikirim ke lokasi Anda.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 20),

                  // Google Form Button (for checkout/feedback)
                  if (widget.status == 'Sedang Mendaki')
                    Center(
                      child: TextButton.icon(
                        onPressed: () async {
                          const url = 'https://forms.gle/24H6HALhYRYEXVLS8';
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: Icon(Icons.assignment_outlined),
                        label: Text('Isi Form Feedback'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      )
                    : Icon(
                        icon,
                        color: color,
                        size: 28,
                      ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Booking':
        return Colors.blue;
      case 'Sedang Mendaki':
        return Colors.orange;
      case 'Selesai':
        return Colors.green;
      case 'Dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
