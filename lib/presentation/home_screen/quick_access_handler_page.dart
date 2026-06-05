import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../api/api_service.dart';
import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../offline_tracking_screen/offline_tracking_screen.dart';
import 'quick_sos_screen.dart';

enum QuickAccessAction {
  ticket,
  maps,
  sos,
}

class QuickAccessHandlerPage extends StatefulWidget {
  final QuickAccessAction action;
  final int initialUserId;

  const QuickAccessHandlerPage({
    super.key,
    required this.action,
    this.initialUserId = 0,
  });

  @override
  State<QuickAccessHandlerPage> createState() => _QuickAccessHandlerPageState();
}

class _QuickAccessHandlerPageState extends State<QuickAccessHandlerPage> {
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    _userId = widget.initialUserId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processQuickAccess();
    });
  }

  Future<bool> _ensureUserReady() async {
    if (_userId > 0) {
      return true;
    }

    final token = await ApiService().getToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    final response = await ApiService().getUser(token);
    if (response['success'] == true) {
      _userId = (response['data']?['id'] ?? 0) is int
          ? response['data']['id']
          : int.tryParse((response['data']?['id'] ?? '').toString()) ?? 0;
      return _userId > 0;
    }

    return false;
  }

  Future<List<_QuickOrderCandidate>> _fetchOrderCandidates() async {
    final token = await ApiService().getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sesi login tidak ditemukan.');
    }

    final responses = await Future.wait([
      http.get(Uri.parse('$baseUrl/orders?user_id=$_userId&per_page=50')),
      http.get(Uri.parse('$baseUrl/transactions?user_id=$_userId&per_page=50')),
    ]);

    final ordersResponse = responses[0];
    final transactionsResponse = responses[1];

    if (ordersResponse.statusCode != 200) {
      throw Exception('Gagal memuat data tiket.');
    }

    if (transactionsResponse.statusCode != 200) {
      throw Exception('Gagal memuat data transaksi.');
    }

    final ordersPayload = jsonDecode(ordersResponse.body);
    final transactionsPayload = jsonDecode(transactionsResponse.body);

    final orders = (ordersPayload['data'] as List?) ?? const [];
    final transactions = (transactionsPayload['data'] as List?) ?? const [];

    final transactionStatusByOrderId = <int, String>{};
    for (final raw in transactions) {
      if (raw is! Map) {
        continue;
      }

      final item = Map<String, dynamic>.from(raw);
      final orderId = int.tryParse((item['id_pesanan'] ?? '').toString()) ?? 0;
      if (orderId <= 0) {
        continue;
      }

      final status = (item['status'] ?? '').toString().trim().toLowerCase();
      transactionStatusByOrderId[orderId] = status;
    }

    final candidates = <_QuickOrderCandidate>[];
    for (final raw in orders) {
      if (raw is! Map) {
        continue;
      }

      final item = Map<String, dynamic>.from(raw);
      final orderId = int.tryParse((item['id'] ?? '').toString()) ?? 0;
      if (orderId <= 0) {
        continue;
      }

      final hikingDate =
          DateTime.tryParse((item['tanggal_naik'] ?? '').toString());
      if (hikingDate == null) {
        continue;
      }

      final transactionStatus = transactionStatusByOrderId[orderId] ?? '';
      final isPaid = transactionStatus == 'complete';

      candidates.add(
        _QuickOrderCandidate(
          orderId: orderId,
          mountainName: (item['gunung'] ?? 'Gunung').toString(),
          hikingDate: hikingDate,
          status: (item['status'] ?? '').toString().trim(),
          isPaid: isPaid,
        ),
      );
    }

    return candidates;
  }

  _QuickOrderCandidate? _pickNearestPaidTicket(
      List<_QuickOrderCandidate> items) {
    final paid = items.where((item) => item.isPaid).toList();
    if (paid.isEmpty) {
      return null;
    }

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    paid.sort((a, b) {
      final aDate =
          DateTime(a.hikingDate.year, a.hikingDate.month, a.hikingDate.day);
      final bDate =
          DateTime(b.hikingDate.year, b.hikingDate.month, b.hikingDate.day);

      final aIsUpcoming = !aDate.isBefore(startOfToday);
      final bIsUpcoming = !bDate.isBefore(startOfToday);

      if (aIsUpcoming != bIsUpcoming) {
        return aIsUpcoming ? -1 : 1;
      }

      if (aIsUpcoming) {
        return aDate.compareTo(bDate);
      }

      return bDate.compareTo(aDate);
    });

    return paid.first;
  }

  _QuickOrderCandidate? _pickCurrentHikingTicket(
      List<_QuickOrderCandidate> items) {
    final hiking = items
        .where((item) => item.status.toLowerCase() == 'sedang mendaki')
        .toList();

    if (hiking.isEmpty) {
      return null;
    }

    final now = DateTime.now();
    hiking.sort((a, b) {
      final aDistance = a.hikingDate.difference(now).abs();
      final bDistance = b.hikingDate.difference(now).abs();
      return aDistance.compareTo(bDistance);
    });

    return hiking.first;
  }

  void _showErrorAndBack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    Navigator.of(context).pop();
  }

  Future<void> _processQuickAccess() async {
    final userReady = await _ensureUserReady();
    if (!userReady) {
      _showErrorAndBack('Silakan login untuk menggunakan Quick Access.');
      return;
    }

    try {
      final candidates = await _fetchOrderCandidates();

      switch (widget.action) {
        case QuickAccessAction.ticket:
          final nearestPaid = _pickNearestPaidTicket(candidates);
          if (nearestPaid == null) {
            _showErrorAndBack('Belum ada tiket yang sudah dibayar.');
            return;
          }

          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.ticketScreen,
            arguments: nearestPaid.orderId,
          );
          return;

        case QuickAccessAction.maps:
          final hiking = _pickCurrentHikingTicket(candidates);
          final nearestPaid = _pickNearestPaidTicket(candidates);
          final selected = hiking ?? nearestPaid;

          if (selected == null) {
            _showErrorAndBack(
                'Belum ada tiket aktif untuk membuka maps offline.');
            return;
          }

          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => OfflineTrackingScreen(
                orderId: selected.orderId,
                mountainName: selected.mountainName,
              ),
            ),
          );
          return;

        case QuickAccessAction.sos:
          final hiking = _pickCurrentHikingTicket(candidates);
          if (hiking == null) {
            _showErrorAndBack('Tidak ada tiket yang sedang berstatus mendaki.');
            return;
          }

          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => QuickSosScreen(
                orderId: hiking.orderId,
                mountainName: hiking.mountainName,
                hikingDate: hiking.hikingDate,
              ),
            ),
          );
          return;
      }
    } catch (e) {
      _showErrorAndBack('Gagal memproses Quick Access: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.action) {
      QuickAccessAction.ticket => 'Membuka Tiket',
      QuickAccessAction.maps => 'Membuka Maps Offline',
      QuickAccessAction.sos => 'Membuka SOS',
    };

    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray50,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
              SizedBox(height: 14.h),
              Text(
                '$title...',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickOrderCandidate {
  final int orderId;
  final String mountainName;
  final DateTime hikingDate;
  final String status;
  final bool isPaid;

  const _QuickOrderCandidate({
    required this.orderId,
    required this.mountainName,
    required this.hikingDate,
    required this.status,
    required this.isPaid,
  });
}
