import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/api_service.dart';
import '../../core/app_export.dart';
import '../waiting_payment_page/waiting_payment_page.dart';
import '../detail_mountain_screen/detail_mountain_screen.dart';
import '../detail_mountain_screen/bloc/detail_mountain_bloc.dart';
import '../trail_screen/trail_screen.dart';
import '../trail_screen/bloc/trail_bloc.dart';
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
  bool _showScrollToBottomBtn = false;
  bool _canPop = false;

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
    _scrollController.addListener(_scrollListener);
  }

  String get _chatSessionKey => '${widget.role}:${widget.userId ?? 0}';

  bool get _preferFreshChatOnNextOpen =>
      _freshChatOnNextOpen[_chatSessionKey] == true;

  void _setPreferFreshChatOnNextOpen(bool value) {
    _freshChatOnNextOpen[_chatSessionKey] = value;
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final showButton = maxScroll - currentScroll > 200;
    if (showButton != _showScrollToBottomBtn) {
      setState(() {
        _showScrollToBottomBtn = showButton;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_scrollListener);
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
            mountains: msg['mountains'] != null
                ? List<Map<String, dynamic>>.from(
                    (msg['mountains'] as List).map((e) => Map<String, dynamic>.from(e as Map)))
                : null,
            source: msg['source']?.toString(),
            intent: msg['intent']?.toString(),
            responseType: msg['type']?.toString(),
            data: msg['data'] != null
                ? Map<String, dynamic>.from(msg['data'] as Map)
                : null,
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

    final List<String> paragraphs = welcomeMsg
        .split('\n\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    for (var paragraph in paragraphs) {
      _cubit.addMessage(ChatMessage(
        message: paragraph,
        isUser: false,
      ));
    }
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
      final responseSource = response['source']?.toString();
      final responseType = response['type']?.toString();
      final responseIntent = response['intent']?.toString();
      final responseData = response['data'];

      final hasPayment = _toInt(response['order_id']) != null ||
          _toInt(response['transaction_id']) != null ||
          response['payment_url'] != null;

      // Cek apakah ini response dari static FAQ dengan data kaya (mountain_cards, route_cards, buttons)
      final bool isRichStaticResponse = responseSource == 'static_faq' &&
          responseType != null &&
          responseType != 'text' &&
          responseData != null;

      if (isRichStaticResponse) {
        // Untuk Static FAQ: satu bubble teks + data (cards/buttons) di bawahnya
        // Ambil mountains dari data jika type mountain_cards
        List<Map<String, dynamic>>? mountainsList;
        if (responseType == 'mountain_cards' && responseData is Map) {
          final rawMountains = responseData['mountains'];
          if (rawMountains is List) {
            mountainsList = List<Map<String, dynamic>>.from(
                rawMountains.map((e) => Map<String, dynamic>.from(e as Map)));
          }
        }

        _cubit.addMessage(ChatMessage(
          message: rawMessage,
          isUser: false,
          source: responseSource,
          intent: responseIntent,
          responseType: responseType,
          data: responseData is Map ? Map<String, dynamic>.from(responseData) : null,
          mountains: mountainsList,
        ));
      } else {
        // Untuk Gemini API / static text: split paragraf seperti sebelumnya
        final processedMessage = hasPayment ? _normalizeChatbotPaymentText(rawMessage) : rawMessage;

        final List<String> paragraphs = processedMessage
            .split('\n\n')
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();

        if (paragraphs.isEmpty) {
          paragraphs.add(processedMessage);
        }

        final rawMountains = response['mountains'];
        final List<Map<String, dynamic>>? mountainsList = rawMountains is List
            ? List<Map<String, dynamic>>.from(
                rawMountains.map((e) => Map<String, dynamic>.from(e as Map)))
            : null;

        for (int i = 0; i < paragraphs.length; i++) {
          final isLast = i == paragraphs.length - 1;
          _cubit.addMessage(ChatMessage(
            message: paragraphs[i],
            isUser: false,
            downloadUrl: isLast ? response['download_url'] : null,
            paymentUrl: isLast ? response['payment_url'] : null,
            orderId: isLast ? (response['order_id'] is int
                ? response['order_id']
                : int.tryParse(response['order_id']?.toString() ?? '')) : null,
            transactionId: isLast ? (response['transaction_id'] is int
                ? response['transaction_id']
                : int.tryParse(response['transaction_id']?.toString() ?? '')) : null,
            paymentMethod: isLast ? _sanitizePaymentMethod(response['payment_method']?.toString()) : null,
            totalPayment: isLast ? _toInt(response['total_payment']) : null,
            transactionCreatedAt: isLast ? response['transaction_created_at']?.toString() : null,
            paymentCode: isLast ? response['payment_code']?.toString() : null,
            paymentCodeLabel: isLast ? response['payment_code_label']?.toString() : null,
            paymentInstruction: isLast ? response['payment_instruction']?.toString() : null,
            deeplinkUrl: isLast ? response['deeplink_url']?.toString() : null,
            qrCodeUrl: isLast ? response['qr_code_url']?.toString() : null,
            qrString: isLast ? response['qr_string']?.toString() : null,
            mountains: isLast ? mountainsList : null,
            source: isLast ? responseSource : null,
            intent: isLast ? responseIntent : null,
            responseType: isLast ? responseType : null,
            data: isLast && responseData is Map ? Map<String, dynamic>.from(responseData) : null,
          ));
        }
      }
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
      final fullUrl = 'http://127.0.0.1:5000/$downloadUrl';
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

  Widget _buildMountainCards(List<Map<String, dynamic>> mountains) {
    return MountainCardsCarousel(
      mountains: mountains,
      baseUrl: baseUrl,
      onQuickReply: _handleQuickReplyButton,
    );
  }

  Widget _buildRouteCards(Map<String, dynamic> data) {
    return RouteCardsCarousel(
      data: data,
      baseUrl: baseUrl,
      onQuickReply: _handleQuickReplyButton,
    );
  }

  Widget _routeStatChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.h, vertical: 3.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F4),
        borderRadius: BorderRadius.circular(8.h),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.h, color: const Color(0xFF1B8A5A)),
          SizedBox(width: 3.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.fSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1B8A5A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonChips(Map<String, dynamic> data) {
    final buttons = data['buttons'];
    if (buttons == null || buttons is! List || buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: MediaQuery.of(context).size.width * 0.82,
      margin: EdgeInsets.only(top: 10.h, bottom: 4.h),
      child: Wrap(
        spacing: 8.h,
        runSpacing: 8.h,
        children: buttons.map<Widget>((btn) {
          final b = btn as Map<String, dynamic>;
          return OutlinedButton.icon(
            onPressed: () =>
                _handleQuickReplyButton(b['payload']?.toString() ?? ''),
            icon: Icon(Icons.arrow_forward_ios_rounded,
                size: 12.h, color: const Color(0xFF1B8A5A)),
            label: Text(
              b['label']?.toString() ?? '',
              style: TextStyle(
                fontSize: 12.fSize,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B8A5A),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1B8A5A), width: 1.2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.h)),
              padding:
                  EdgeInsets.symmetric(horizontal: 14.h, vertical: 8.h),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _handleQuickReplyButton(String payload) {
    if (payload.isEmpty) return;
    _messageController.text = payload;
    _sendMessage();
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
                    width: (message.mountains != null && message.mountains!.isNotEmpty) ||
                            (!message.isUser && message.responseType == 'route_cards' && message.data != null) ||
                            (!message.isUser && message.responseType == 'buttons' && message.data != null)
                        ? double.infinity
                        : null,
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
                  if (message.mountains != null && message.mountains!.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    _buildMountainCards(message.mountains!),
                  ],
                  // Route cards from Static FAQ
                  if (!message.isUser &&
                      message.responseType == 'route_cards' &&
                      message.data != null) ...[
                    SizedBox(height: 8.h),
                    _buildRouteCards(message.data!),
                  ],
                  // Button chips from Static FAQ
                  if (!message.isUser &&
                      message.responseType == 'buttons' &&
                      message.data != null) ...[
                    SizedBox(height: 6.h),
                    _buildButtonChips(message.data!),
                  ],
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
          return PopScope(
            canPop: _canPop,
            onPopInvoked: (didPop) async {
              if (didPop) return;
              await _autoSaveHistory();
              if (context.mounted) {
                setState(() {
                  _canPop = true;
                });
                Navigator.of(context).pop();
              }
            },
            child: Scaffold(
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
                  final navigator = Navigator.of(context);
                  if (navigator.canPop()) {
                    navigator.pop();
                  } else {
                    await _autoSaveHistory();
                    if (!mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                        context, AppRoutes.homeScreen, (route) => false);
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
                    child: Stack(
                      children: [
                        ListView.builder(
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
                        if (_showScrollToBottomBtn)
                          Positioned(
                            bottom: 12.h,
                            right: 16.h,
                            child: GestureDetector(
                              onTap: _scrollToBottom,
                              child: Container(
                                width: 36.h,
                                height: 36.h,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Color(0xFF1B8A5A),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                      ],
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
          ),
        );
      },
    ),
  );
}
}

class MountainCardsCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> mountains;
  final String baseUrl;
  final Function(String) onQuickReply;

  const MountainCardsCarousel({
    super.key,
    required this.mountains,
    required this.baseUrl,
    required this.onQuickReply,
  });

  @override
  State<MountainCardsCarousel> createState() => _MountainCardsCarouselState();
}

class _MountainCardsCarouselState extends State<MountainCardsCarousel> {
  int _currentPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mountains = widget.mountains;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 280.h,
          width: double.infinity,
          child: PageView.builder(
            controller: _pageController,
            pageSnapping: true,
            physics: const PageScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: mountains.length,
            itemBuilder: (context, index) {
              final m = mountains[index];
              final String nama = m['nama'] ?? 'Gunung';
              final String ketinggian = '${m['ketinggian'] ?? 0} mdpl';
              final String provinsi = m['provinsi'] ?? 'Indonesia';
              final int? id = m['id'];
              final String gambarGunung = m['gambar_gunung'] ?? '';
              final String deskripsi = m['deskripsi'] ?? '';

              final String fullImageUrl = gambarGunung.isNotEmpty
                  ? '${widget.baseUrl}/images/$gambarGunung'
                  : '';

              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.h),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: appTheme.gray200.withOpacity(0.8)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.h),
                  child: InkWell(
                    onTap: () {
                      if (id != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider(
                              create: (context) => DetailMountainBloc(
                                  apiService: ApiService())
                                ..add(DetailMountainInitialEvent(id)),
                              child: DetailMountainScreen(idGunung: id),
                            ),
                          ),
                        );
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 120.h,
                          width: double.infinity,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: fullImageUrl.isNotEmpty
                                    ? Image.network(
                                        fullImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(
                                          color: Colors.grey[100],
                                          child: Icon(Icons.terrain,
                                              color: Colors.grey[400], size: 32.h),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.grey[100],
                                        child: Icon(Icons.terrain,
                                            color: Colors.grey[400], size: 32.h),
                                      ),
                              ),
                              Positioned(
                                top: 8.h,
                                right: 8.h,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10.h, vertical: 4.h),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF1B8A5A),
                                      borderRadius: BorderRadius.circular(12.h)),
                                  child: Text(
                                    ketinggian,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.fSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 8.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nama,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.fSize,
                                  color: appTheme.blueGray900,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded,
                                      size: 12.h, color: const Color(0xFF1B8A5A)),
                                  SizedBox(width: 4.h),
                                  Expanded(
                                    child: Text(
                                      provinsi,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11.fSize,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (deskripsi.isNotEmpty) ...[
                                SizedBox(height: 4.h),
                                Text(
                                  deskripsi,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 11.fSize,
                                    height: 1.4,
                                  ),
                                ),
                              ] else
                                SizedBox(height: 30.h),
                              SizedBox(height: 8.h),
                              Container(
                                width: double.infinity,
                                height: 34.h,
                                child: ElevatedButton(
                                  onPressed: () => widget.onQuickReply('pesan tiket $nama'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B8A5A),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.h)),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Pesan Tiket',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.fSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (mountains.length > 1) ...[
          SizedBox(height: 6.h),
          Center(
            child: _buildPageIndicator(mountains.length, _currentPage),
          ),
        ],
      ],
    );
  }

  Widget _buildPageIndicator(int itemCount, int currentPage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(itemCount, (dotIndex) {
            final distance = (dotIndex - currentPage).abs();
            double width = 0;
            double height = 0;
            double margin = 0;
            Color color = Colors.grey[300]!;

            if (distance == 0) {
              width = 16.h;
              height = 6.h;
              margin = 4.h;
              color = const Color(0xFF1B8A5A);
            } else if (distance == 1) {
              width = 6.h;
              height = 6.h;
              margin = 4.h;
              color = Colors.grey[400]!;
            } else if (distance == 2) {
              width = 4.h;
              height = 4.h;
              margin = 4.h;
              color = Colors.grey[300]!;
            } else {
              width = 0;
              height = 0;
              margin = 0;
            }

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.symmetric(horizontal: margin),
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3.h),
              ),
            );
          }),
        ),
        if (itemCount > 5) ...[
          SizedBox(width: 8.h),
          Text(
            '(${currentPage + 1} dari $itemCount)',
            style: TextStyle(
              fontSize: 10.fSize,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class RouteCardsCarousel extends StatefulWidget {
  final Map<String, dynamic> data;
  final String baseUrl;
  final Function(String) onQuickReply;

  const RouteCardsCarousel({
    super.key,
    required this.data,
    required this.baseUrl,
    required this.onQuickReply,
  });

  @override
  State<RouteCardsCarousel> createState() => _RouteCardsCarouselState();
}

class _RouteCardsCarouselState extends State<RouteCardsCarousel> {
  int _currentPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routes = widget.data['routes'];
    if (routes == null || routes is! List || routes.isEmpty) {
      return const SizedBox.shrink();
    }

    // Check if any route card has visible buttons (i.e. not containing "detail" in label)
    bool hasBookingButtons = false;
    for (var route in routes) {
      if (route is Map) {
        final buttons = route['buttons'];
        if (buttons is List && buttons.isNotEmpty) {
          final visibleButtons = buttons.where(
            (btn) => btn is Map && btn['label']?.toString().toLowerCase().contains('detail') != true,
          ).toList();
          if (visibleButtons.isNotEmpty) {
            hasBookingButtons = true;
            break;
          }
        }
      }
    }

    final double carouselHeight = hasBookingButtons ? 290.h : 240.h;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: carouselHeight,
          width: double.infinity,
          child: PageView.builder(
            controller: _pageController,
            pageSnapping: true,
            physics: const PageScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              final r = route as Map<String, dynamic>;
              final String namaJalur = r['nama_jalur'] ?? 'Jalur';
              final double jarak = (r['jarak'] is num) ? (r['jarak'] as num).toDouble() : 0;
              final int biaya = (r['biaya'] is num) ? (r['biaya'] as num).toInt() : 0;
              final String estimasi = r['estimasi_waktu'] ?? '-';
              final String kesulitan = r['tingkat_kesulitan'] ?? '-';
              final String basecamp = r['basecamp'] ?? '';
              final String deskripsi = r['deskripsi'] ?? '';
              final String gambarJalur = r['gambar_jalur'] ?? '';
              final List buttons = r['buttons'] ?? [];

              final String fullImageUrl = gambarJalur.isNotEmpty &&
                      !gambarJalur.startsWith('assets/')
                  ? '${widget.baseUrl}/images/$gambarJalur'
                  : '';

              final biayaStr = NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(biaya);

              String difficultyLabel = kesulitan;
              Color difficultyColor = const Color(0xFF1B8A5A);
              if (kesulitan == 'mudah') {
                difficultyLabel = 'Mudah';
                difficultyColor = const Color(0xFF4CAF50);
              } else if (kesulitan == 'sedang') {
                difficultyLabel = 'Sedang';
                difficultyColor = const Color(0xFFFFA726);
              } else if (kesulitan == 'sulit') {
                difficultyLabel = 'Sulit';
                difficultyColor = const Color(0xFFEF5350);
              } else if (kesulitan == 'sangat_sulit') {
                difficultyLabel = 'Sangat Sulit';
                difficultyColor = const Color(0xFFB71C1C);
              }

              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.h),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: appTheme.gray200.withOpacity(0.8)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.h),
                  child: InkWell(
                    onTap: () {
                      final int? id = r['id'] is num ? (r['id'] as num).toInt() : null;
                      final int? idGunung = r['id_gunung'] is num ? (r['id_gunung'] as num).toInt() : null;
                      if (id != null && idGunung != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider(
                              create: (context) => TrailBloc(apiService: ApiService()),
                              child: TrailScreen(
                                jalurId: id,
                                idGunung: idGunung,
                              ),
                            ),
                          ),
                        );
                      } else {
                        final detailBtn = buttons.firstWhere(
                          (btn) => btn['label']?.toString().toLowerCase().contains('detail') == true,
                          orElse: () => null,
                        );
                        if (detailBtn != null) {
                          widget.onQuickReply(detailBtn['payload']?.toString() ?? '');
                        }
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 120.h,
                          width: double.infinity,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: fullImageUrl.isNotEmpty
                                    ? Image.network(
                                        fullImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey[100],
                                          child: Icon(Icons.terrain,
                                              color: Colors.grey[400], size: 32.h),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.grey[100],
                                        child: Icon(Icons.terrain,
                                            color: Colors.grey[400], size: 32.h),
                                      ),
                              ),
                              Positioned(
                                top: 8.h,
                                right: 8.h,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10.h, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: difficultyColor,
                                    borderRadius: BorderRadius.circular(12.h),
                                  ),
                                  child: Text(
                                    difficultyLabel,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.fSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 8.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                namaJalur,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.fSize,
                                  color: appTheme.blueGray900,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  _routeStatChip(Icons.straighten, '${jarak.toStringAsFixed(1)} km'),
                                  SizedBox(width: 8.h),
                                  _routeStatChip(Icons.timer_outlined, estimasi),
                                  SizedBox(width: 8.h),
                                  _routeStatChip(Icons.attach_money, biayaStr),
                                ],
                              ),
                              if (basecamp.isNotEmpty) ...[
                                SizedBox(height: 4.h),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_rounded,
                                        size: 12.h, color: const Color(0xFF1B8A5A)),
                                    SizedBox(width: 4.h),
                                    Expanded(
                                      child: Text(
                                        basecamp,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 11.fSize,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (deskripsi.isNotEmpty) ...[
                                SizedBox(height: 4.h),
                                Text(
                                  deskripsi,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 11.fSize,
                                    height: 1.4,
                                  ),
                                ),
                              ] else
                                SizedBox(height: 14.h),
                              Builder(builder: (context) {
                                final visibleButtons = buttons.where(
                                  (btn) => btn['label']?.toString().toLowerCase().contains('detail') != true,
                                ).toList();
                                if (visibleButtons.isNotEmpty) {
                                  return Column(
                                    children: [
                                      SizedBox(height: 6.h),
                                      Column(
                                        children: visibleButtons.map<Widget>((btn) {
                                          final b = btn as Map<String, dynamic>;
                                          return Container(
                                            width: double.infinity,
                                            height: 34.h,
                                            margin: EdgeInsets.only(bottom: 4.h),
                                            child: ElevatedButton(
                                              onPressed: () => widget.onQuickReply(
                                                  b['payload']?.toString() ?? ''),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF1B8A5A),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(10.h)),
                                                elevation: 0,
                                              ),
                                              child: Text(
                                                b['label']?.toString() ?? '',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12.fSize,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  );
                                }
                                return const SizedBox.shrink();
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (routes.length > 1) ...[
          SizedBox(height: 6.h),
          Center(
            child: _buildPageIndicator(routes.length, _currentPage),
          ),
        ],
      ],
    );
  }

  Widget _routeStatChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8.h),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.h, color: const Color(0xFF1B8A5A)),
          SizedBox(width: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.fSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1B8A5A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int itemCount, int currentPage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(itemCount, (dotIndex) {
            final distance = (dotIndex - currentPage).abs();
            double width = 0;
            double height = 0;
            double margin = 0;
            Color color = Colors.grey[300]!;

            if (distance == 0) {
              width = 16.h;
              height = 6.h;
              margin = 4.h;
              color = const Color(0xFF1B8A5A);
            } else if (distance == 1) {
              width = 6.h;
              height = 6.h;
              margin = 4.h;
              color = Colors.grey[400]!;
            } else if (distance == 2) {
              width = 4.h;
              height = 4.h;
              margin = 4.h;
              color = Colors.grey[300]!;
            } else {
              width = 0;
              height = 0;
              margin = 0;
            }

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.symmetric(horizontal: margin),
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3.h),
              ),
            );
          }),
        ),
        if (itemCount > 5) ...[
          SizedBox(width: 8.h),
          Text(
            '(${currentPage + 1} dari $itemCount)',
            style: TextStyle(
              fontSize: 10.fSize,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

