import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api/api_service.dart';
import '../../core/app_export.dart';
import '../midtrans_payment_screen/midtrans_payment_screen.dart';
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

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatbotCubit _cubit = ChatbotCubit();
  final ApiService _apiService = ApiService();

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
    _cubit.setUserId(widget.userId);
    _checkServerConnection();
    _loadUserIdIfNeeded();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _autoSaveHistory();
    _messageController.dispose();
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  /// Load user ID jika belum ada
  Future<void> _loadUserIdIfNeeded() async {
    if (_userId != null) {
      _loadFriends();
      _loadChatHistories();
      return;
    }
    try {
      final token = await _apiService.getToken();
      if (token != null) {
        final response = await _apiService.getUserProfile(token);
        if (response['success']) {
          _cubit.setUserId(response['data']['id']);
          await _loadFriends();
          _loadChatHistories();
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
  Future<void> _loadChatHistories() async {
    if (_userId == null) return;
    try {
      final result = await _apiService.getChatHistories(
        userId: _userId!,
        role: widget.role,
      );
      if (result['success'] == true && result['data'] != null) {
        _cubit
            .setChatHistories(List<Map<String, dynamic>>.from(result['data']));
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
          ));
        }
        _cubit.setCurrentHistoryId(historyId);
        _cubit.replaceMessages(rebuiltMessages);
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
    Navigator.pop(context); // Close drawer
  }

  /// Cek koneksi ke server chatbot
  Future<void> _checkServerConnection() async {
    final isHealthy = await _apiService.isChatbotServerHealthy();
    _cubit.setServerConnected(isHealthy);
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
      _cubit.addMessage(ChatMessage(
        message: response['message'],
        isUser: false,
        downloadUrl: response['download_url'],
        paymentUrl: response['payment_url'],
        orderId: response['order_id'] is int
            ? response['order_id']
            : int.tryParse(response['order_id']?.toString() ?? ''),
        transactionId: response['transaction_id'] is int
            ? response['transaction_id']
            : int.tryParse(response['transaction_id']?.toString() ?? ''),
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
    }
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
              final input = idController.text.trim();
              final id = int.tryParse(input);

              if (id == null || id <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ID harus berupa angka valid'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (id == _userId) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ID diri sendiri tidak bisa ditambahkan'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              if (tempSelectedIds.contains(id)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ID sudah ada di daftar anggota'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              final lookup = await _apiService.getUserById(id);
              if (lookup['success'] != true || lookup['data'] == null) {
                ScaffoldMessenger.of(context).showSnackBar(
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
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Konfirmasi Anggota'),
                  content: Text(
                    'ID: $id\nNama: $name\nStatus: ${isFriend ? 'Teman' : 'Bukan teman'}\n\nTambahkan sebagai anggota pendaki?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Tambah'),
                    ),
                  ],
                ),
              );

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

  /// Buka pembayaran Midtrans
  Future<void> _openPayment(ChatMessage message) async {
    if (message.paymentUrl != null && message.paymentUrl!.isNotEmpty) {
      // Navigasi ke MidtransPaymentScreen dengan redirect URL
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => MidtransPaymentScreen(
            transactionId: message.transactionId ?? 0,
            redirectUrl: message.paymentUrl,
            orderId: message.orderId,
          ),
        ),
      );

      if (result != null && mounted) {
        final backendSnapshot = await _fetchBackendPaymentSnapshot(
          message: message,
          paymentResult: result,
        );

        final status = result['status']?.toString() ?? 'pending';
        final backendStatus = backendSnapshot['status']?.toString();
        final statusMsg = _buildPaymentStatusMessage(
          gatewayStatus: status,
          backendStatus: backendStatus,
          orderStatus: backendSnapshot['order_status']?.toString(),
          isPaymentExpired: backendSnapshot['is_payment_expired'] == true,
          gatewayMessage: result['message']?.toString(),
        );

        // Mark as paid if backend confirms Complete or gateway says success
        final normalizedBackend = (backendStatus ?? '').trim().toLowerCase();
        final normalizedGateway = status.trim().toLowerCase();
        if (normalizedBackend == 'complete' || normalizedGateway == 'success') {
          _cubit.markMessagePaid(message);
        }

        _cubit.addMessage(ChatMessage(
          message: statusMsg,
          isUser: false,
        ));
        _scrollToBottom();
      }
    }
  }

  String _buildPaymentStatusMessage({
    required String gatewayStatus,
    String? backendStatus,
    String? orderStatus,
    bool isPaymentExpired = false,
    String? gatewayMessage,
  }) {
    final backend = (backendStatus ?? '').trim().toLowerCase();
    final gateway = gatewayStatus.trim().toLowerCase();
    final order = (orderStatus ?? '').trim().toLowerCase();

    if (backend == 'complete') {
      return 'Pembayaran sudah selesai dan terverifikasi. Tiket Anda siap digunakan.';
    }

    if (isPaymentExpired || order == 'expired') {
      return 'Pembayaran sudah kedaluwarsa. Silakan buat pesanan baru jika ingin melanjutkan pendakian.';
    }

    if (backend == 'incomplete' || backend == 'unverified') {
      return 'Pembayaran belum lunas. Silakan lanjutkan pembayaran di menu Tiket saya atau tombol Bayar Sekarang.';
    }

    if (gateway == 'success') {
      return 'Pembayaran berhasil diproses. Sistem sedang sinkronisasi, status akan segera diperbarui.';
    }

    if (gateway == 'pending') {
      return 'Pembayaran belum lunas. Silakan cek kembali status di menu Tiket saya.';
    }

    if (gateway == 'failed' || backend == 'failed') {
      return 'Pembayaran gagal. Anda bisa coba lagi melalui menu Tiket saya.';
    }

    if (gatewayMessage != null && gatewayMessage.trim().isNotEmpty) {
      return gatewayMessage.trim();
    }

    return 'Status pembayaran belum final. Silakan cek menu Transaksi untuk status terbaru.';
  }

  Future<Map<String, dynamic>?> _pollLatestPaymentStatus(
      String checkRef) async {
    final normalizedRef = checkRef.trim();
    if (normalizedRef.isEmpty || normalizedRef == '0') {
      return null;
    }

    const maxAttempt = 4;

    for (var i = 0; i < maxAttempt; i++) {
      final latest = await _apiService.checkMidtransStatus(normalizedRef);
      if (latest['success'] == true && latest['data'] != null) {
        final dynamic payload = latest['data'];
        final dynamic data = payload is Map<String, dynamic>
            ? (payload['data'] ?? payload)
            : payload;

        final status = (data is Map ? data['status'] : null)?.toString();
        final normalized = status?.trim().toLowerCase();

        if (normalized == 'complete' ||
            normalized == 'incomplete' ||
            normalized == 'failed') {
          return {
            'status': status,
            'order_status': data is Map ? data['order_status'] : null,
            'is_payment_expired':
                data is Map && data['is_payment_expired'] == true,
          };
        }

        if (i == maxAttempt - 1) {
          return {
            'status': status,
            'order_status': data is Map ? data['order_status'] : null,
            'is_payment_expired':
                data is Map && data['is_payment_expired'] == true,
          };
        }
      }

      await Future.delayed(const Duration(seconds: 2));
    }

    return null;
  }

  Future<Map<String, dynamic>> _fetchBackendPaymentSnapshot({
    required ChatMessage message,
    required Map<String, dynamic> paymentResult,
  }) async {
    final refs = <String>{
      if (message.transactionId != null && message.transactionId! > 0)
        message.transactionId!.toString(),
      if (message.orderId != null && message.orderId! > 0)
        message.orderId!.toString(),
      if (paymentResult['transaction_id'] != null)
        paymentResult['transaction_id'].toString(),
      if (paymentResult['order_id'] != null)
        paymentResult['order_id'].toString(),
    };

    for (final ref in refs) {
      final snapshot = await _pollLatestPaymentStatus(ref);
      if (snapshot != null &&
          (snapshot['status']?.toString().isNotEmpty ?? false)) {
        return snapshot;
      }
    }

    final fallbackOrderId = message.orderId ??
        int.tryParse(paymentResult['order_id']?.toString() ?? '');
    if (fallbackOrderId != null && fallbackOrderId > 0) {
      try {
        final orderRes = await _apiService.fetchPesanan(fallbackOrderId);
        final order = orderRes['order'];
        final tx = order is Map<String, dynamic> ? order['transaction'] : null;
        return {
          'status': tx is Map ? tx['status_pesanan'] : null,
          'order_status':
              order is Map<String, dynamic> ? order['status'] : null,
          'is_payment_expired':
              (order is Map<String, dynamic> ? order['status'] : null) ==
                  'Expired',
        };
      } catch (_) {
        // Ignore fallback errors, will return empty snapshot.
      }
    }

    return const {};
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
                  if (message.paymentUrl != null &&
                      message.paymentUrl!.isNotEmpty &&
                      !message.isUser)
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: ElevatedButton.icon(
                        onPressed:
                            message.isPaid ? null : () => _openPayment(message),
                        icon: Icon(
                            message.isPaid ? Icons.check_circle : Icons.payment,
                            size: 18.h,
                            color: Colors.white),
                        label: Text(
                            message.isPaid ? 'Sudah Dibayar' : 'Bayar Sekarang',
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
                    icon: Icon(Icons.add, color: Colors.white, size: 18.h),
                    label: Text(
                      'Chat Baru',
                      style: TextStyle(color: Colors.white, fontSize: 13.fSize),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white70),
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
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
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
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
                  color: Colors.transparent,
                  child: SafeArea(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.h),
                        border: Border.all(color: appTheme.gray200, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              SizedBox(width: 16.h),
                              Expanded(
                                child: TextField(
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
                                        fontSize: 14.fSize),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 16.h),
                                  ),
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                              if (_isLoading)
                                Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 16.h),
                                  child: SizedBox(
                                    height: 20.h,
                                    width: 20.h,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _rolePrimaryColor),
                                  ),
                                ),
                              if (!_isLoading)
                                IconButton(
                                  icon: Icon(Icons.send_rounded,
                                      color: _rolePrimaryColor),
                                  onPressed:
                                      _isServerConnected ? _sendMessage : null,
                                ),
                            ],
                          ),
                          Container(height: 1, color: appTheme.gray200),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.h, vertical: 4.h),
                            child: Row(
                              children: [
                                ActionChip(
                                  label: Text('Member',
                                      style: TextStyle(
                                          color: _rolePrimaryColor,
                                          fontSize: 12.fSize)),
                                  avatar: Icon(Icons.group_add,
                                      color: _rolePrimaryColor, size: 16.h),
                                  backgroundColor:
                                      _rolePrimaryColor.withOpacity(0.1),
                                  side: BorderSide.none,
                                  onPressed: _isServerConnected
                                      ? _openMemberPickerModal
                                      : null,
                                ),
                                const Spacer(),
                                IconButton(
                                    icon: Icon(Icons.camera_alt_outlined,
                                        color: appTheme.gray500, size: 20.h),
                                    onPressed: () {}),
                                IconButton(
                                    icon: Icon(Icons.attach_file,
                                        color: appTheme.gray500, size: 20.h),
                                    onPressed: () {}),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Text('Harap periksa kembali respons dari AI.',
                      style: TextStyle(
                          fontSize: 11.fSize, color: appTheme.gray500)),
                ),
                if (_selectedMemberIds.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                    color: Colors.white,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _selectedMemberIds.map((id) {
                        final name = _selectedMemberNames[id] ?? 'ID $id';
                        return Chip(
                          label: Text('$name (#$id)'),
                          onDeleted: () {
                            _cubit.removeSelectedMember(id);
                          },
                        );
                      }).toList(),
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
