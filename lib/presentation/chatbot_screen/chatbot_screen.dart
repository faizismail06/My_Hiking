import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/api_service.dart';
import '../../core/app_export.dart';
import '../waiting_payment_page/waiting_payment_page.dart';
import 'bloc/chatbot_cubit.dart';
import 'bloc/chatbot_state.dart';
import 'models/chat_message.dart';

/// Chatbot Screen - UI modern untuk chatbot pendakian gunung
/// Mendukung 3 role: pendaki, admin, penjaga
/// Fitur: booking via chat, payment Midtrans, riwayat chat, ekspor Excel
class ChatbotScreen extends StatefulWidget {
  final String role;
  final int? userId;

  const ChatbotScreen({
    super.key,
    this.role = 'pendaki',
    this.userId,
  });

  static Widget builder(BuildContext context) {
    return const ChatbotScreen(
      role: 'pendaki',
    );
  }

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatbotCubit _cubit = ChatbotCubit();
  final ApiService _apiService = ApiService();
  static const Duration _paymentStatusSyncInterval = Duration(seconds: 12);

  Timer? _paymentStatusSyncTimer;
  bool _isSyncingPaymentStatus = false;
  final Set<int> _busyPaymentOrderIds = <int>{};
  bool _hasAttemptedInitialHistoryLoad = false;

  static final Map<String, bool> _freshChatOnNextOpen = <String, bool>{};

  ChatbotState get _state => _cubit.state;
  List<ChatMessage> get _messages => _state.messages;
  bool get _isLoading => _state.isLoading;
  bool get _isServerConnected => _state.isServerConnected;
  int? get _userId => _state.userId;
  int? get _currentHistoryId => _state.currentHistoryId;
  List<Map<String, dynamic>> get _chatHistories => _state.chatHistories;
  List<Map<String, dynamic>> get _friends => _state.friends;
  Set<int> get _selectedMemberIds => _state.selectedMemberIds;
  Map<int, String> get _selectedMemberNames => _state.selectedMemberNames;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit.setRole(widget.role);
    _cubit.setUserId(widget.userId);
    _checkServerConnection();
    _loadUserIdIfNeeded();
    _addWelcomeMessage();
    _startPaymentStatusSync();
  }

  String get _chatSessionKey => '${widget.role}:${widget.userId ?? 0}';

  bool get _preferFreshChatOnNextOpen =>
      _freshChatOnNextOpen[_chatSessionKey] == true;

  void _setPreferFreshChatOnNextOpen(bool value) {
    _freshChatOnNextOpen[_chatSessionKey] = value;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _paymentStatusSyncTimer?.cancel();
    _autoSaveHistory();
    _messageController.dispose();
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncPendingPaymentStatuses();
    }
  }

  /// Load user ID jika belum ada
  Future<void> _loadUserIdIfNeeded() async {
    if (_userId != null) {
      _loadFriends();
      _loadChatHistories(autoOpenLatestIfNeeded: true);
      return;
    }
    try {
      final token = await _apiService.getToken();
      if (token != null) {
        final response = await _apiService.getUserProfile(token);
        if (response['success']) {
          _cubit.setUserId(response['data']['id']);
          await _loadFriends();
          _loadChatHistories(autoOpenLatestIfNeeded: true);
        }
      }
    } catch (e) {
      print('Error loading user ID: $e');
    }
  }

  Future<void> _loadFriends() async {
    if (_userId == null) return;
    try {
      final result = await _apiService.getFriends(_userId!);
      if (result['success'] == true && result['data'] is List) {
        _cubit.setFriends(List<Map<String, dynamic>>.from(result['data']));
      }
    } catch (e) {
      print('Error loading friends: $e');
    }
  }

  /// Load daftar riwayat chat dari server
  Future<void> _loadChatHistories({
    bool autoOpenLatestIfNeeded = false,
  }) async {
    if (_userId == null) return;
    try {
      final result = await _apiService.getChatHistories(
        userId: _userId!,
        role: widget.role,
      );
      if (result['success'] == true && result['data'] != null) {
        final histories = List<Map<String, dynamic>>.from(result['data']);
        _cubit.setChatHistories(histories);

        if (autoOpenLatestIfNeeded && !_hasAttemptedInitialHistoryLoad) {
          _hasAttemptedInitialHistoryLoad = true;

          if (_preferFreshChatOnNextOpen) {
            return;
          }

          if (histories.isNotEmpty) {
            await _loadChatHistory(histories.first['id']);
          }
        }
      }
    } catch (e) {
      print('Error loading chat histories: $e');
    }
  }

  /// Load riwayat chat tertentu
  Future<void> _loadChatHistory(int historyId) async {
    try {
      final result = await _apiService.getChatHistory(historyId);
      if (result['success'] == true && result['data'] != null) {
        final messages = result['data']['messages'] as List;
        final rebuiltMessages = <ChatMessage>[];
        for (var msg in messages) {
          rebuiltMessages.add(ChatMessage(
            message: msg['message'] ?? '',
            isUser: msg['isUser'] ?? false,
            orderId: _toInt(msg['order_id']),
            transactionId: _toInt(msg['transaction_id']),
            isPaid: msg['is_paid'] == true,
          ));
        }
        _cubit.setCurrentHistoryId(historyId);
        _cubit.replaceMessages(rebuiltMessages);
        _setPreferFreshChatOnNextOpen(false);
        _syncPendingPaymentStatuses();
        _scrollToBottom();
      }
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  /// Auto-save riwayat chat
  Future<void> _autoSaveHistory() async {
    if (_userId == null || _messages.length <= 1) return;

    // Filter hanya pesan user (bukan welcome message)
    final userMessages = _messages.where((m) => m.isUser).toList();
    if (userMessages.isEmpty) return;

    try {
      final messagesJson = _messages.map((m) => m.toJson()).toList();
      final result = await _apiService.saveChatHistory(
        userId: _userId!,
        role: widget.role,
        messages: messagesJson,
        historyId: _currentHistoryId,
      );

      if (result['success'] == true && result['history_id'] != null) {
        final historyId = result['history_id'];
        if (historyId is int && _currentHistoryId != historyId) {
          _cubit.setCurrentHistoryId(historyId);
        }
      }
    } catch (e) {
      print('Error auto-saving history: $e');
    }
  }

  /// Hapus riwayat chat
  Future<void> _deleteHistory(int historyId) async {
    try {
      await _apiService.deleteChatHistory(historyId, userId: _userId);
      _loadChatHistories();
      if (_currentHistoryId == historyId) {
        _cubit.setCurrentHistoryId(null);
        _cubit.clearMessages();
        _addWelcomeMessage();
      }
    } catch (e) {
      print('Error deleting history: $e');
    }
  }

  /// Mulai chat baru
  void _startNewChat() {
    _autoSaveHistory();
    _cubit.setCurrentHistoryId(null);
    _cubit.clearMessages();
    _addWelcomeMessage();
    _setPreferFreshChatOnNextOpen(true);
    Navigator.pop(context); // Close drawer
  }

  /// Cek koneksi ke server chatbot
  Future<void> _checkServerConnection() async {
    final isHealthy = await _apiService.isChatbotServerHealthy();
    _cubit.setServerConnected(isHealthy);
  }

  void _startPaymentStatusSync() {
    _paymentStatusSyncTimer?.cancel();
    _paymentStatusSyncTimer = Timer.periodic(_paymentStatusSyncInterval, (_) {
      _syncPendingPaymentStatuses();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPendingPaymentStatuses();
    });
  }

  Future<void> _syncPendingPaymentStatuses() async {
    if (!mounted || _isSyncingPaymentStatus) {
      return;
    }

    final pendingOrderIds = _messages
        .where((m) => !m.isUser && !m.isPaid && m.orderId != null)
        .map((m) => m.orderId!)
        .toSet()
        .toList();

    if (pendingOrderIds.isEmpty) {
      return;
    }

    _isSyncingPaymentStatus = true;
    try {
      final statuses = await Future.wait(
        pendingOrderIds.map(
          (orderId) => _cubit.fetchPaymentStatus(orderId.toString()),
        ),
      );

      for (var i = 0; i < pendingOrderIds.length; i++) {
        final orderId = pendingOrderIds[i];
        final response = statuses[i];
        if (response['success'] != true ||
            response['data'] is! Map<String, dynamic>) {
          continue;
        }

        final payload = response['data'] as Map<String, dynamic>;
        final status =
            (payload['status'] ?? 'pending').toString().trim().toLowerCase();

        _cubit.updatePaymentInfoForOrder(
          orderId: orderId,
          transactionId: _toInt(payload['transaction_id']),
          paymentMethod: _sanitizePaymentMethod(
            payload['payment_method']?.toString(),
          ),
          totalPayment: _toInt(payload['total_payment']),
          transactionCreatedAt: payload['transaction_created_at']?.toString(),
          paymentCode: payload['payment_code']?.toString(),
          paymentCodeLabel: payload['payment_code_label']?.toString(),
          paymentInstruction: payload['payment_instruction']?.toString(),
          deeplinkUrl: payload['deeplink_url']?.toString(),
          qrCodeUrl: payload['qr_code_url']?.toString(),
          qrString: payload['qr_string']?.toString(),
        );

        if (status == 'paid' || status == 'complete' || status == 'success') {
          final changed = _cubit.markOrderPaid(orderId: orderId);
          if (changed) {
            _appendPaymentVerifiedMessage(orderId: orderId);
            await _autoSaveHistory();
            await _loadChatHistories();
          }
        }
      }
    } catch (_) {
      // Ignore polling failures and retry on next tick.
    } finally {
      _isSyncingPaymentStatus = false;
    }
  }

  bool _hasPaymentVerifiedMessage(int orderId) {
    final marker = 'order #$orderId sudah terverifikasi';
    return _messages.any(
      (m) => !m.isUser && m.message.toLowerCase().contains(marker),
    );
  }

  void _appendPaymentVerifiedMessage({required int orderId}) {
    if (_hasPaymentVerifiedMessage(orderId)) {
      return;
    }

    _cubit.addMessage(
      ChatMessage(
        message:
            'Pembayaran untuk order #$orderId sudah terverifikasi. Tiket Anda siap digunakan.',
        isUser: false,
      ),
    );
    _scrollToBottom();
  }

  String _normalizeChatbotPaymentText(String input) {
    var text = input;
    text = text.replaceAll(
      RegExp(
        r"Silakan klik tombol 'Bayar Sekarang' untuk melanjutkan pembayaran\\.",
        caseSensitive: false,
      ),
      'Silakan pilih metode pembayaran, lalu lanjutkan melalui Waiting Payment.',
    );
    text = text.replaceAll(
      RegExp(r'Bayar Sekarang', caseSensitive: false),
      'Pilih Metode Pembayaran',
    );
    return text;
  }

  int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse((value ?? '').toString());
  }

  String _formatCurrency(int? value) {
    if (value == null) {
      return '-';
    }

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  bool _isPaymentMethodSelected(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) {
      return false;
    }

    final normalized = raw.toLowerCase();
    return normalized != 'belum dipilih' &&
        normalized != 'not selected' &&
        normalized != '-' &&
        normalized != 'null';
  }

  String? _sanitizePaymentMethod(String? value) {
    final raw = (value ?? '').trim();
    return _isPaymentMethodSelected(raw) ? raw : null;
  }

  /// Info role untuk judul
  String get _roleTitle {
    switch (widget.role) {
      case 'admin':
        return 'Admin Assistant';
      case 'penjaga':
        return 'Trail Guard Assistant';
      default:
        return 'Hiking Buddy';
    }
  }

  /// Warna tema berdasarkan role
  Color get _rolePrimaryColor {
    switch (widget.role) {
      case 'admin':
        return const Color(0xFF1565C0);
      case 'penjaga':
        return const Color(0xFFE65100);
      default:
        return theme.colorScheme.primary;
    }
  }

  /// Icon berdasarkan role
  IconData get _roleIcon {
    switch (widget.role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'penjaga':
        return Icons.shield;
      default:
        return Icons.smart_toy_outlined;
    }
  }

  /// Tambahkan pesan selamat datang berdasarkan role
  void _addWelcomeMessage() {
    String welcomeMsg;

    switch (widget.role) {
      case 'admin':
        welcomeMsg =
            'Halo Admin! Saya Admin Assistant untuk aplikasi My Hiking.\n\n'
            'Saya bisa membantu Anda dengan:\n'
            '- Melihat semua data (gunung, jalur, pesanan, transaksi, user)\n'
            '- CRUD data gunung dan jalur pendakian\n'
            '- Rekap laporan dalam format Excel\n'
            '- Analisis data dan ringkasan\n\n'
            'Ketik perintah atau pertanyaan Anda!';
        break;
      case 'penjaga':
        welcomeMsg = 'Halo Penjaga Jalur! Saya Trail Guard Assistant.\n\n'
            'Saya bisa membantu Anda dengan:\n'
            '- SAR Dashboard (permintaan darurat aktif)\n'
            '- Data pendaki aktif di gunung\n'
            '- Rekap data dalam format Excel\n'
            '- Informasi gunung dan jalur\n\n'
            'Ketik pertanyaan atau minta laporan!';
        break;
      default:
        welcomeMsg =
            'Halo! Saya Hiking Buddy, asisten virtual Anda untuk pendakian gunung.\n\n'
            'Saya bisa membantu Anda dengan:\n'
            '- Informasi gunung yang tersedia\n'
            '- Jalur pendakian dan biayanya\n'
            '- Tata tertib pendakian\n'
            '- Tips dan saran pendakian\n'
            '- Pemesanan tiket pendakian + pembayaran\n\n'
            'Silakan tanya apa saja!';
    }

    _cubit.addMessage(ChatMessage(
      message: welcomeMsg,
      isUser: false,
    ));
  }

  /// Kirim pesan ke chatbot
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    if (_userId == null) {
      await _loadUserIdIfNeeded();
      if (_userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('User login tidak terdeteksi. Silakan login ulang.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    _cubit.addMessage(ChatMessage(message: message, isUser: true));
    _setPreferFreshChatOnNextOpen(false);
    _messageController.clear();
    _cubit.setLoading(true);

    _scrollToBottom();

    // Simpan secepatnya agar pesan pertama seperti "halo" langsung tercatat.
    await _autoSaveHistory();
    await _loadChatHistories();

    // Siapkan history untuk konteks
    final history =
        _messages.take(_messages.length - 1).map((m) => m.toJson()).toList();

    // Kirim ke API
    final response = await _apiService.sendChatMessage(
      message: message,
      history: history,
      role: widget.role,
      userId: _userId,
      selectedMemberIds:
          _selectedMemberIds.isEmpty ? null : _selectedMemberIds.toList(),
      selectedMemberNames: _selectedMemberNames.values.toList(),
    );

    _cubit.setLoading(false);
    if (response['success']) {
      final rawMessage = response['message']?.toString() ?? '';
      final hasPayment = _toInt(response['order_id']) != null ||
          _toInt(response['transaction_id']) != null ||
          response['payment_url'] != null;

      _cubit.addMessage(ChatMessage(
        message:
            hasPayment ? _normalizeChatbotPaymentText(rawMessage) : rawMessage,
        isUser: false,
        downloadUrl: response['download_url'],
        paymentUrl: response['payment_url'],
        orderId: response['order_id'] is int
            ? response['order_id']
            : int.tryParse(response['order_id']?.toString() ?? ''),
        transactionId: response['transaction_id'] is int
            ? response['transaction_id']
            : int.tryParse(response['transaction_id']?.toString() ?? ''),
        paymentMethod:
            _sanitizePaymentMethod(response['payment_method']?.toString()),
        totalPayment: _toInt(response['total_payment']),
        transactionCreatedAt: response['transaction_created_at']?.toString(),
        paymentCode: response['payment_code']?.toString(),
        paymentCodeLabel: response['payment_code_label']?.toString(),
        paymentInstruction: response['payment_instruction']?.toString(),
        deeplinkUrl: response['deeplink_url']?.toString(),
        qrCodeUrl: response['qr_code_url']?.toString(),
        qrString: response['qr_string']?.toString(),
      ));
    } else {
      _cubit.addMessage(ChatMessage(
        message: response['message'] ??
            'Maaf, terjadi kesalahan. Silakan coba lagi.',
        isUser: false,
      ));
    }

    _scrollToBottom();

    // Simpan otomatis setiap percakapan agar langsung muncul di riwayat.
    await _autoSaveHistory();
    await _loadChatHistories();

    // Setelah booking jadi, reset pilihan anggota agar tidak kebawa ke booking berikutnya.
    if (response['order_id'] != null) {
      _cubit.clearSelectedMembers();
      _setPreferFreshChatOnNextOpen(false);
    }

    _syncPendingPaymentStatuses();
  }

  Future<void> _openMemberPickerModal() async {
    if (_userId == null) {
      await _loadUserIdIfNeeded();
      if (_userId == null) return;
    }

    await _loadFriends();

    final searchController = TextEditingController();
    final idController = TextEditingController();
    final tempSelectedIds = Set<int>.from(_selectedMemberIds);
    final tempSelectedNames = Map<int, String>.from(_selectedMemberNames);
    final friendIds = _friends
        .map((f) => int.tryParse(f['id'].toString()) ?? 0)
        .where((id) => id > 0)
        .toSet();

    List<Map<String, dynamic>> filteredFriends =
        List<Map<String, dynamic>>.from(_friends);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void applyFriendFilter(String keyword) {
              final key = keyword.trim().toLowerCase();
              setModalState(() {
                if (key.isEmpty) {
                  filteredFriends = List<Map<String, dynamic>>.from(_friends);
                } else {
                  filteredFriends = _friends.where((f) {
                    final idTxt = f['id'].toString().toLowerCase();
                    final nameTxt = (f['name'] ?? '').toString().toLowerCase();
                    return idTxt.contains(key) || nameTxt.contains(key);
                  }).toList();
                }
              });
            }

            Future<void> addManualId() async {
              final messenger = ScaffoldMessenger.of(this.context);
              final input = idController.text.trim();
              final id = int.tryParse(input);

              if (id == null || id <= 0) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('ID harus berupa angka valid'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (id == _userId) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('ID diri sendiri tidak bisa ditambahkan'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              if (tempSelectedIds.contains(id)) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('ID sudah ada di daftar anggota'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              final lookup = await _apiService.getUserById(id);
              if (!mounted) {
                return;
              }

              if (lookup['success'] != true || lookup['data'] == null) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('ID user tidak ditemukan'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final user = lookup['data'] as Map<String, dynamic>;
              final name = (user['name'] ?? 'Tanpa Nama').toString();
              final isFriend = friendIds.contains(id);

              final confirmed = await showDialog<bool>(
                context: this.context,
                builder: (ctx) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  backgroundColor: const Color(0xFFF4F7F4),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Konfirmasi Anggota',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.teal.shade50,
                              child: Icon(Icons.person,
                                  size: 40, color: theme.colorScheme.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: $id',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    'Status: ${isFriend ? 'Teman' : 'Belum dalam kontak Anda'}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Tambahkan $name sebagai\nanggota tim pendaki Anda?',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: Colors.grey.shade400),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  foregroundColor: Colors.black87,
                                ),
                                child: const Text(
                                  'Batal',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 6,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pop(ctx, true),
                                icon: const Icon(Icons.person_add_alt_1,
                                    size: 20),
                                label: const Text(
                                  'Tambah Anggota',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 16),
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );

              if (!mounted) {
                return;
              }

              if (confirmed == true) {
                setModalState(() {
                  tempSelectedIds.add(id);
                  tempSelectedNames[id] = name;
                  idController.clear();
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pilih Anggota Pendaki',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Cari dari daftar teman (nama / ID)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: applyFriendFilter,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 170,
                    child: filteredFriends.isEmpty
                        ? const Center(
                            child: Text('Belum ada teman yang cocok'))
                        : ListView.builder(
                            itemCount: filteredFriends.length,
                            itemBuilder: (context, index) {
                              final f = filteredFriends[index];
                              final id = int.tryParse(f['id'].toString()) ?? 0;
                              final name = (f['name'] ?? '').toString();
                              final checked = tempSelectedIds.contains(id);
                              return CheckboxListTile(
                                value: checked,
                                title: Text(name),
                                subtitle: Text('ID: $id (Teman)'),
                                onChanged: id <= 0
                                    ? null
                                    : (val) {
                                        setModalState(() {
                                          if (val == true) {
                                            tempSelectedIds.add(id);
                                            tempSelectedNames[id] = name;
                                          } else {
                                            tempSelectedIds.remove(id);
                                            tempSelectedNames.remove(id);
                                          }
                                        });
                                      },
                              );
                            },
                          ),
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: idController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Input ID user (boleh non-teman)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: addManualId,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _rolePrimaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: const Text(
                          'Tambah ID',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (tempSelectedIds.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: tempSelectedIds.map((id) {
                        final name = tempSelectedNames[id] ?? 'ID $id';
                        final isFriend = friendIds.contains(id);
                        return Chip(
                          label: Text(
                              '${isFriend ? 'Teman' : 'User'}: $name (#$id)'),
                          onDeleted: () {
                            setModalState(() {
                              tempSelectedIds.remove(id);
                              tempSelectedNames.remove(id);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _cubit.setSelectedMembers(
                          ids: tempSelectedIds,
                          names: tempSelectedNames,
                        );
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('Gunakan Pilihan Ini',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _rolePrimaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Download file Excel
  Future<void> _downloadFile(String downloadUrl) async {
    try {
      final fullUrl = 'http://127.0.0.1:5000$downloadUrl';
      final uri = Uri.parse(fullUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download URL: $fullUrl'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('Error downloading file: $e');
    }
  }

  Future<void> _handlePaymentAction(ChatMessage message) async {
    final orderId = message.orderId;
    if (orderId == null || orderId <= 0) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Order tidak ditemukan. Silakan lakukan pemesanan lagi.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_busyPaymentOrderIds.contains(orderId)) {
      return;
    }

    if (!_isPaymentMethodSelected(message.paymentMethod) ||
        message.transactionId == null ||
        message.transactionCreatedAt == null) {
      await _selectPaymentMethodAndPrepareWaiting(message);
      return;
    }

    await _openWaitingPaymentPage(message);
  }

  Future<void> _selectPaymentMethodAndPrepareWaiting(
      ChatMessage message) async {
    final orderId = message.orderId;
    if (orderId == null || orderId <= 0) {
      return;
    }

    final methods = await _cubit.fetchPaymentMethods();
    if (!mounted) {
      return;
    }

    if (methods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Metode pembayaran belum tersedia saat ini.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final pickedMethod = await _showPaymentMethodPicker(
        methods: methods, initialOrderId: orderId);
    if (pickedMethod == null) {
      return;
    }

    setState(() {
      _busyPaymentOrderIds.add(orderId);
    });

    try {
      final paymentResult = await _cubit.createPaymentForOrder(
        orderId: orderId,
        paymentMethod: pickedMethod['id'].toString(),
      );

      if (!mounted) {
        return;
      }

      if (paymentResult['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              paymentResult['message']?.toString() ??
                  'Gagal menyiapkan pembayaran.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final resolvedOrderId = _toInt(paymentResult['order_id']) ?? orderId;
      final resolvedMessage = message.copyWith(
        orderId: resolvedOrderId,
        transactionId:
            _toInt(paymentResult['transaction_id']) ?? message.transactionId,
        paymentMethod: _sanitizePaymentMethod(
              paymentResult['payment_method']?.toString(),
            ) ??
            _sanitizePaymentMethod(pickedMethod['name']?.toString()),
        totalPayment: _toInt(paymentResult['total_payment']),
        transactionCreatedAt:
            paymentResult['transaction_created_at']?.toString() ??
                DateTime.now().toIso8601String(),
        paymentCode: paymentResult['payment_code']?.toString(),
        paymentCodeLabel: paymentResult['payment_code_label']?.toString(),
        paymentInstruction: paymentResult['payment_instruction']?.toString(),
        deeplinkUrl: paymentResult['deeplink_url']?.toString(),
        qrCodeUrl: paymentResult['qr_code_url']?.toString(),
        qrString: paymentResult['qr_string']?.toString(),
      );

      _cubit.replaceMessage(message, resolvedMessage);

      await _autoSaveHistory();
      await _loadChatHistories();

      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() {
          _busyPaymentOrderIds.remove(orderId);
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _showPaymentMethodPicker({
    required List<Map<String, dynamic>> methods,
    required int initialOrderId,
  }) async {
    Map<String, dynamic>? selected;

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(bottomSheetContext).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pilih Metode Pembayaran',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Order #$initialOrderId',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: methods.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final method = methods[index];
                        final id = method['id']?.toString() ?? '';
                        final isSelected = selected?['id']?.toString() == id;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(method['name']?.toString() ?? id),
                          subtitle: method['description'] == null
                              ? null
                              : Text(method['description'].toString()),
                          trailing: isSelected
                              ? Icon(Icons.check_circle,
                                  color: _rolePrimaryColor)
                              : const Icon(Icons.circle_outlined),
                          onTap: () {
                            setModalState(() {
                              selected = method;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: selected == null
                          ? null
                          : () => Navigator.pop(bottomSheetContext, selected),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _rolePrimaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      icon: const Icon(Icons.payment),
                      label: const Text('Gunakan Metode Ini'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openWaitingPaymentPage(ChatMessage message) async {
    final orderId = message.orderId;
    if (orderId == null || orderId <= 0) {
      return;
    }

    if (message.transactionId == null ||
        message.transactionCreatedAt == null ||
        message.transactionCreatedAt!.trim().isEmpty) {
      await _selectPaymentMethodAndPrepareWaiting(message);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WaitingPaymentPage(
          orderId: orderId.toString(),
          transactionId: message.transactionId!,
          totalPayment: message.totalPayment,
          paymentMethod: message.paymentMethod,
          transactionCreatedAt: message.transactionCreatedAt!,
          paymentCode: message.paymentCode,
          paymentCodeLabel: message.paymentCodeLabel,
          paymentInstruction: message.paymentInstruction,
          deeplinkUrl: message.deeplinkUrl,
          qrCodeUrl: message.qrCodeUrl,
          qrString: message.qrString,
        ),
      ),
    );

    await _refreshPaymentStatusAfterWaiting(
      orderId: orderId,
      transactionId: message.transactionId,
      showMessage: true,
    );
  }

  Future<void> _refreshPaymentStatusAfterWaiting({
    required int orderId,
    int? transactionId,
    bool showMessage = false,
  }) async {
    final response = await _cubit.fetchPaymentStatus(orderId.toString());
    if (response['success'] != true ||
        response['data'] is! Map<String, dynamic>) {
      return;
    }

    final payload = response['data'] as Map<String, dynamic>;
    final status =
        (payload['status'] ?? 'pending').toString().trim().toLowerCase();

    _cubit.updatePaymentInfoForOrder(
      orderId: orderId,
      transactionId: _toInt(payload['transaction_id']) ?? transactionId,
      paymentMethod:
          _sanitizePaymentMethod(payload['payment_method']?.toString()),
      totalPayment: _toInt(payload['total_payment']),
      transactionCreatedAt: payload['transaction_created_at']?.toString(),
      paymentCode: payload['payment_code']?.toString(),
      paymentCodeLabel: payload['payment_code_label']?.toString(),
      paymentInstruction: payload['payment_instruction']?.toString(),
      deeplinkUrl: payload['deeplink_url']?.toString(),
      qrCodeUrl: payload['qr_code_url']?.toString(),
      qrString: payload['qr_string']?.toString(),
    );

    final paid =
        status == 'paid' || status == 'complete' || status == 'success';
    if (paid) {
      final changed =
          _cubit.markOrderPaid(orderId: orderId, transactionId: transactionId);
      if (showMessage && changed) {
        _appendPaymentVerifiedMessage(orderId: orderId);
      }

      await _autoSaveHistory();
      await _loadChatHistories();
    }
  }

  /// Scroll ke bawah
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Widget untuk bubble chat
  Widget _buildMessageBubble(ChatMessage message) {
    if (_messages.length == 1 &&
        message == _messages.first &&
        !message.isUser) {
      return const SizedBox.shrink();
    }

    final hasPaymentOrder =
        !message.isUser && message.orderId != null && message.orderId! > 0;
    final isLatestPaymentMessage = hasPaymentOrder
        ? _messages.lastIndexWhere(
              (m) => !m.isUser && m.orderId == message.orderId,
            ) ==
            _messages.indexOf(message)
        : false;
    final hasPreparedPayment =
        _isPaymentMethodSelected(message.paymentMethod) &&
            (message.transactionCreatedAt ?? '').trim().isNotEmpty;
    final isBusy =
        hasPaymentOrder && _busyPaymentOrderIds.contains(message.orderId);

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        margin: EdgeInsets.only(top: 8.h, bottom: 8.h, left: 16.h, right: 16.h),
        child: Row(
          mainAxisAlignment:
              message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser)
              Container(
                width: 32.h,
                height: 32.h,
                margin: EdgeInsets.only(right: 8.h),
                child: RepaintBoundary(
                  child: Lottie.asset(
                    'assets/lottie/Siri.json',
                    fit: BoxFit.contain,
                    repeat: true,
                    animate: _messages.last == message,
                  ),
                ),
              ),
            Flexible(
              child: Column(
                crossAxisAlignment: message.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: message.isUser ? appTheme.gray200 : Colors.white,
                      borderRadius: BorderRadius.circular(20.h),
                      boxShadow: message.isUser
                          ? []
                          : [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4)),
                            ],
                    ),
                    child: Text(
                      message.message,
                      style: TextStyle(
                          color: appTheme.blueGray900,
                          fontSize: 14.fSize,
                          height: 1.5),
                    ),
                  ),
                  if (hasPaymentOrder &&
                      isLatestPaymentMessage &&
                      hasPreparedPayment &&
                      !message.isPaid)
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 8.h),
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.h, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.h),
                        border: Border.all(color: appTheme.gray200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detail Pembayaran',
                            style: TextStyle(
                              fontSize: 12.fSize,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          if (_isPaymentMethodSelected(message.paymentMethod))
                            Text('Metode: ${message.paymentMethod}'),
                          if (message.totalPayment != null)
                            Text(
                                'Total: ${_formatCurrency(message.totalPayment)}'),
                          if ((message.paymentCode ?? '').trim().isNotEmpty)
                            Text(
                              '${(message.paymentCodeLabel ?? 'Kode Bayar').trim()}: ${message.paymentCode}',
                            ),
                        ],
                      ),
                    ),
                  if (hasPaymentOrder && isLatestPaymentMessage)
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: ElevatedButton.icon(
                        onPressed: (message.isPaid || isBusy)
                            ? null
                            : () => _handlePaymentAction(message),
                        icon: Icon(
                            message.isPaid
                                ? Icons.check_circle
                                : hasPreparedPayment
                                    ? Icons.hourglass_top
                                    : Icons.payment,
                            size: 18.h,
                            color: Colors.white),
                        label: Text(
                            message.isPaid
                                ? 'Sudah Dibayar'
                                : isBusy
                                    ? 'Menyiapkan Pembayaran...'
                                    : hasPreparedPayment
                                        ? 'Buka Waiting Payment'
                                        : 'Pilih Metode Pembayaran',
                            style: TextStyle(
                                fontSize: 13.fSize, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: message.isPaid
                              ? Colors.grey.shade400
                              : const Color(0xFF00C853),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.h)),
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.h, vertical: 10.h),
                        ),
                      ),
                    ),
                  if (message.downloadUrl != null && !message.isUser)
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadFile(message.downloadUrl!),
                        icon: Icon(Icons.download,
                            size: 18.h, color: Colors.white),
                        label: Text('Download Excel',
                            style: TextStyle(
                                fontSize: 12.fSize, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _rolePrimaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.h)),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.h, vertical: 8.h),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.only(top: 4.h, left: 4.h, right: 4.h),
                    child: Text(_formatTime(message.timestamp),
                        style: TextStyle(
                            color: appTheme.gray500, fontSize: 10.fSize)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format waktu
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Widget typing indicator
  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(left: 16.h, top: 8.h, bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
        decoration: BoxDecoration(
          color: appTheme.gray200,
          borderRadius: BorderRadius.circular(20.h),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            SizedBox(width: 4.h),
            _buildDot(1),
            SizedBox(width: 4.h),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  /// Dot animasi untuk typing indicator
  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          height: 8.h,
          width: 8.h,
          decoration: BoxDecoration(
            color: appTheme.gray500.withOpacity(0.3 + (value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  /// Widget untuk saran pertanyaan berdasarkan role

  Widget _buildSuggestionGrid() {
    List<String> suggestions;

    switch (widget.role) {
      case 'admin':
        suggestions = [
          'Tampilkan semua pesanan hari ini',
          'Buatkan rekap laporan pendapatan Excel',
          'Berapa total transaksi bulan ini?',
          'Daftar semua gunung',
        ];
        break;
      case 'penjaga':
        suggestions = [
          'Apakah ada permintaan SAR aktif?',
          'Siapa saja pendaki yang sedang di gunung?',
          'Buatkan rekap SAR Dashboard Excel',
          'Rekap pesanan dalam Excel',
        ];
        break;
      default:
        suggestions = [
          'Gunung apa saja yang tersedia?',
          'Saya ingin memesan tiket',
          'Berapa biaya pendakian?',
          'Tips pendakian pemula',
        ];
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.h),
      child: Column(
        children: [
          Wrap(
            spacing: 12.h,
            runSpacing: 12.h,
            alignment: WrapAlignment.center,
            children: suggestions.take(2).map((suggestion) {
              return InkWell(
                onTap: () {
                  _messageController.text = suggestion;
                  _sendMessage();
                },
                borderRadius: BorderRadius.circular(16.h),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  padding: EdgeInsets.all(16.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.h),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      fontSize: 13.fSize,
                      color: appTheme.black900,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 16.h),
          TextButton.icon(
            onPressed: () {},
            icon: Icon(Icons.refresh, size: 18.h, color: appTheme.gray500),
            label: Text(
              'Refresh saran otomatis',
              style: TextStyle(color: appTheme.gray500, fontSize: 13.fSize),
            ),
          ),
        ],
      ),
    );
  }

  /// Build drawer untuk riwayat chat
  Widget _buildHistoryDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16.h, 48.h, 16.h, 16.h),
            decoration: BoxDecoration(
              color: _rolePrimaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: Colors.white, size: 24.h),
                    SizedBox(width: 8.h),
                    Text(
                      'Riwayat Chat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.fSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _startNewChat,
                    icon: Icon(Icons.add,
                        color: const Color(0xFF2E7D32), size: 18.h),
                    label: Text(
                      'Chat Baru',
                      style: TextStyle(
                          color: const Color(0xFF2E7D32), fontSize: 13.fSize),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.h),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _chatHistories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48.h, color: appTheme.gray400),
                        SizedBox(height: 16.h),
                        Text(
                          'Belum ada riwayat chat',
                          style: TextStyle(
                            color: appTheme.gray500,
                            fontSize: 14.fSize,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    itemCount: _chatHistories.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final history = _chatHistories[index];
                      final isActive = _currentHistoryId == history['id'];
                      return ListTile(
                        selected: isActive,
                        selectedTileColor: _rolePrimaryColor.withOpacity(0.08),
                        leading: Icon(
                          Icons.chat_bubble,
                          color:
                              isActive ? _rolePrimaryColor : appTheme.gray400,
                          size: 20.h,
                        ),
                        title: Text(
                          history['title'] ?? 'Chat',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.fSize,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        subtitle: Text(
                          history['updated_at'] ?? '',
                          style: TextStyle(
                            fontSize: 11.fSize,
                            color: appTheme.gray500,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline,
                              size: 18.h, color: Colors.red[300]),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Hapus Riwayat'),
                                content: const Text(
                                    'Yakin ingin menghapus riwayat chat ini?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.grey[700],
                                    ),
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _deleteHistory(history['id']);
                                    },
                                    child: const Text('Hapus',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        onTap: () {
                          _autoSaveHistory();
                          _loadChatHistory(history['id']);
                          Navigator.pop(context); // Close drawer
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 40.h),
          SizedBox(
            width: 150.h,
            height: 150.h,
            child: Lottie.asset(
              'assets/lottie/Siri.json',
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Halo, Ada yang bisa dibantu?',
            style: TextStyle(
              fontSize: 22.fSize,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.h),
            child: Text(
              'Pilih prompt di bawah ini atau ketik sendiri pertanyaan Anda.',
              style: TextStyle(
                fontSize: 14.fSize,
                color: Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 32.h),
          _buildSuggestionGrid(),
        ],
      ),
    );
  }

  void _showAllSelectedMembers() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: EdgeInsets.all(20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Anggota Terpilih',
                      style: TextStyle(
                          fontSize: 18.fSize, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                BlocBuilder<ChatbotCubit, ChatbotState>(
                  bloc: _cubit,
                  builder: (context, state) {
                    if (state.selectedMemberIds.isEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (Navigator.canPop(ctx)) {
                          Navigator.pop(ctx);
                        }
                      });
                      return const SizedBox.shrink();
                    }
                    return Wrap(
                      spacing: 8.h,
                      runSpacing: 8.h,
                      children: state.selectedMemberIds.map((id) {
                        final name = state.selectedMemberNames[id] ?? 'ID $id';
                        return Chip(
                          label: Text('$name (#$id)'),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            _cubit.removeSelectedMember(id);
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<ChatbotCubit, ChatbotState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: const Color(0xFFF1F8F1),
            drawer: _buildHistoryDrawer(),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              iconTheme: const IconThemeData(color: Colors.black87),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () async {
                  await _autoSaveHistory();
                  if (!mounted) return;
                  final navigator = Navigator.of(this.context);
                  if (navigator.canPop()) {
                    navigator.pop();
                  } else {
                    Navigator.pushNamedAndRemoveUntil(
                        this.context, AppRoutes.homeScreen, (route) => false);
                  }
                },
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_roleIcon, color: _rolePrimaryColor, size: 24.h),
                  SizedBox(width: 8.h),
                  Text(
                    _roleTitle,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 18.fSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              actions: [
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.black87),
                    tooltip: 'Riwayat Chat',
                    onPressed: () {
                      _loadChatHistories();
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.black87),
                  onPressed: () {
                    _checkServerConnection();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_isServerConnected
                            ? 'Server terhubung'
                            : 'Server tidak terhubung'),
                        backgroundColor:
                            _isServerConnected ? Colors.green : Colors.red,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                if (_messages.length > 1)
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.only(bottom: 16.h),
                      itemCount: _messages.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length && _isLoading) {
                          return _buildTypingIndicator();
                        }
                        return _buildMessageBubble(_messages[index]);
                      },
                    ),
                  )
                else
                  Expanded(
                    child: _buildEmptyState(),
                  ),

                // Input field
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Text('Harap periksa kembali respons dari AI.',
                      style: TextStyle(
                          fontSize: 11.fSize, color: appTheme.gray500)),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(16.h, 0, 16.h, 16.h),
                  child: SafeArea(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7F4),
                        borderRadius: BorderRadius.circular(30.h),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 4.h, vertical: 4.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(Icons.person_add_outlined,
                                  color: appTheme.gray500),
                              onPressed: _isServerConnected
                                  ? _openMemberPickerModal
                                  : null,
                            ),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_selectedMemberIds.isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(
                                          top: 8.h, bottom: 4.h),
                                      child: Builder(builder: (context) {
                                        final firstId =
                                            _selectedMemberIds.first;
                                        final firstName =
                                            _selectedMemberNames[firstId] ??
                                                'ID $firstId';
                                        final moreCount =
                                            _selectedMemberIds.length - 1;

                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 10.h,
                                                    vertical: 6.h),
                                                decoration: BoxDecoration(
                                                  color: appTheme.gray200,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          16.h),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        '$firstName (#$firstId)',
                                                        style: TextStyle(
                                                            fontSize: 12.fSize,
                                                            color:
                                                                Colors.black87,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    SizedBox(width: 8.h),
                                                    GestureDetector(
                                                      onTap: () => _cubit
                                                          .removeSelectedMember(
                                                              firstId),
                                                      child: Icon(Icons.close,
                                                          size: 14.h,
                                                          color:
                                                              Colors.black54),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (moreCount > 0) ...[
                                              SizedBox(width: 6.h),
                                              GestureDetector(
                                                onTap: _showAllSelectedMembers,
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 8.h,
                                                      vertical: 6.h),
                                                  decoration: BoxDecoration(
                                                    color: _rolePrimaryColor
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16.h),
                                                    border: Border.all(
                                                        color: _rolePrimaryColor
                                                            .withOpacity(0.5)),
                                                  ),
                                                  child: Text(
                                                    '+$moreCount',
                                                    style: TextStyle(
                                                        fontSize: 12.fSize,
                                                        color:
                                                            _rolePrimaryColor,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                              ),
                                            ]
                                          ],
                                        );
                                      }),
                                    ),
                                  TextField(
                                    controller: _messageController,
                                    enabled: _isServerConnected,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    maxLines: 4,
                                    minLines: 1,
                                    style: TextStyle(fontSize: 14.fSize),
                                    decoration: InputDecoration(
                                      hintText: _isServerConnected
                                          ? 'Ketik pertanyaan Anda...'
                                          : 'Server offline',
                                      hintStyle: TextStyle(
                                          color: appTheme.gray500,
                                          fontSize: 13.fSize),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.only(
                                          top: _selectedMemberIds.isNotEmpty
                                              ? 4.h
                                              : 12.h,
                                          bottom: 12.h),
                                    ),
                                    onSubmitted: (_) => _sendMessage(),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isLoading)
                                  Padding(
                                    padding: EdgeInsets.all(8.h),
                                    child: SizedBox(
                                      height: 24.h,
                                      width: 24.h,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _rolePrimaryColor),
                                    ),
                                  )
                                else
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.all(8.h),
                                    icon: Icon(Icons.send,
                                        color: _rolePrimaryColor),
                                    onPressed: _isServerConnected
                                        ? _sendMessage
                                        : null,
                                  ),
                                SizedBox(width: 4.h),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
