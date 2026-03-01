import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../../core/app_export.dart';

/// Model untuk pesan chat
class ChatMessage {
  final String message;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.message,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'message': message,
        'isUser': isUser,
      };
}

/// Chatbot Screen - UI modern untuk chatbot pendakian gunung
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  static Widget builder(BuildContext context) {
    return const ChatbotScreen();
  }

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _isServerConnected = false;

  @override
  void initState() {
    super.initState();
    _checkServerConnection();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Cek koneksi ke server chatbot
  Future<void> _checkServerConnection() async {
    final isHealthy = await _apiService.isChatbotServerHealthy();
    setState(() {
      _isServerConnected = isHealthy;
    });
  }

  /// Tambahkan pesan selamat datang
  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      message:
          'Halo! 👋 Saya Hiking Buddy, asisten virtual Anda untuk pendakian gunung.\n\n'
          'Saya bisa membantu Anda dengan:\n'
          '🏔️ Informasi gunung yang tersedia\n'
          '🚶 Jalur pendakian dan biayanya\n'
          '📋 Tata tertib pendakian\n'
          '💡 Tips dan saran pendakian\n\n'
          'Silakan tanya apa saja!',
      isUser: false,
    ));
  }

  /// Kirim pesan ke chatbot
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    // Tambahkan pesan user
    setState(() {
      _messages.add(ChatMessage(message: message, isUser: true));
      _messageController.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    // Siapkan history untuk konteks
    final history = _messages
        .take(_messages.length - 1) // Exclude pesan yang baru ditambahkan
        .map((m) => m.toJson())
        .toList();

    // Kirim ke API
    final response = await _apiService.sendChatMessage(
      message: message,
      history: history,
    );

    setState(() {
      _isLoading = false;
      if (response['success']) {
        _messages.add(ChatMessage(
          message: response['message'],
          isUser: false,
        ));
      } else {
        _messages.add(ChatMessage(
          message: response['message'] ??
              'Maaf, terjadi kesalahan. Silakan coba lagi.',
          isUser: false,
        ));
      }
    });

    _scrollToBottom();
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
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: EdgeInsets.only(
          top: 8.h,
          bottom: 8.h,
          left: message.isUser ? 50.h : 16.h,
          right: message.isUser ? 16.h : 50.h,
        ),
        child: Column(
          crossAxisAlignment:
              message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
              decoration: BoxDecoration(
                color: message.isUser
                    ? theme.colorScheme.primary
                    : appTheme.gray200,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.h),
                  topRight: Radius.circular(20.h),
                  bottomLeft:
                      message.isUser ? Radius.circular(20.h) : Radius.circular(4.h),
                  bottomRight:
                      message.isUser ? Radius.circular(4.h) : Radius.circular(20.h),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.message,
                style: TextStyle(
                  color: message.isUser ? Colors.white : appTheme.blueGray900,
                  fontSize: 14.fSize,
                  height: 1.5,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 4.h, left: 4.h, right: 4.h),
              child: Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  color: appTheme.gray500,
                  fontSize: 10.fSize,
                ),
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

  /// Widget untuk saran pertanyaan
  Widget _buildSuggestionChips() {
    final suggestions = [
      'Gunung apa saja yang tersedia?',
      'Jalur pendakian Lawu',
      'Berapa biaya pendakian?',
      'Tips pendakian pemula',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.h),
      child: Row(
        children: suggestions.map((suggestion) {
          return Padding(
            padding: EdgeInsets.only(right: 8.h),
            child: ActionChip(
              label: Text(
                suggestion,
                style: TextStyle(
                  fontSize: 12.fSize,
                  color: theme.colorScheme.primary,
                ),
              ),
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              side: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
              onPressed: () {
                _messageController.text = suggestion;
                _sendMessage();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.colorScheme.onPrimary,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.h),
              ),
              child: Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 24.h,
              ),
            ),
            SizedBox(width: 12.h),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hiking Buddy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.fSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      height: 8.h,
                      width: 8.h,
                      decoration: BoxDecoration(
                        color: _isServerConnected ? Colors.greenAccent : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4.h),
                    Text(
                      _isServerConnected ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.fSize,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
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
          // Header gradient
          Container(
            height: 20.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0),
                ],
              ),
            ),
          ),

          // Suggestion chips
          if (_messages.length <= 1)
            Container(
              padding: EdgeInsets.only(bottom: 16.h),
              child: _buildSuggestionChips(),
            ),

          // Chat messages
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
          ),

          // Server offline warning
          if (!_isServerConnected)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
              color: Colors.orange.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 20.h),
                  SizedBox(width: 8.h),
                  Expanded(
                    child: Text(
                      'Server chatbot sedang offline. Pastikan server Python berjalan.',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 12.fSize,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Input field
          Container(
            padding: EdgeInsets.all(16.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: appTheme.gray200,
                        borderRadius: BorderRadius.circular(24.h),
                      ),
                      child: TextField(
                        controller: _messageController,
                        enabled: _isServerConnected,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 4,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: _isServerConnected
                              ? 'Ketik pertanyaan Anda...'
                              : 'Server tidak terhubung',
                          hintStyle: TextStyle(
                            color: appTheme.gray500,
                            fontSize: 14.fSize,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20.h,
                            vertical: 12.h,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.h),
                  Container(
                    height: 48.h,
                    width: 48.h,
                    decoration: BoxDecoration(
                      color: _isServerConnected
                          ? theme.colorScheme.primary
                          : appTheme.gray400,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: _isLoading
                          ? SizedBox(
                              height: 20.h,
                              width: 20.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 22.h,
                            ),
                      onPressed: _isServerConnected && !_isLoading
                          ? _sendMessage
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
