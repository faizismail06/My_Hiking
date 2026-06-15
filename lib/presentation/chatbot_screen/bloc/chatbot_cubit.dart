import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../api/api_service.dart';
import '../models/chat_message.dart';
import 'chatbot_state.dart';

class ChatbotCubit extends Cubit<ChatbotState> {
  final ApiService _apiService = ApiService();
  String _role = 'pendaki';

  ChatbotCubit() : super(const ChatbotState());

  void setRole(String role) {
    _role = role;
  }

  void setUserId(int? value) {
    emit(state.copyWith(userId: value));
  }

  void setLoading(bool value) {
    emit(state.copyWith(isLoading: value));
  }

  void setServerConnected(bool value) {
    emit(state.copyWith(isServerConnected: value));
  }

  void setChatHistories(List<Map<String, dynamic>> value) {
    emit(state.copyWith(chatHistories: List<Map<String, dynamic>>.from(value)));
  }

  void setFriends(List<Map<String, dynamic>> value) {
    emit(state.copyWith(friends: List<Map<String, dynamic>>.from(value)));
  }

  void setCurrentHistoryId(int? value) {
    if (value == null) {
      emit(state.copyWith(clearCurrentHistoryId: true));
      return;
    }
    emit(state.copyWith(currentHistoryId: value));
  }

  void replaceMessages(List<ChatMessage> value) {
    emit(state.copyWith(messages: List<ChatMessage>.from(value)));
  }

  void addMessage(ChatMessage message) {
    final next = List<ChatMessage>.from(state.messages)..add(message);
    emit(state.copyWith(messages: next));
  }

  void clearMessages() {
    emit(state.copyWith(messages: const []));
  }

  void setSelectedMembers({
    required Set<int> ids,
    required Map<int, String> names,
  }) {
    emit(state.copyWith(
      selectedMemberIds: Set<int>.from(ids),
      selectedMemberNames: Map<int, String>.from(names),
    ));
  }

  void clearSelectedMembers() {
    emit(state.copyWith(
      selectedMemberIds: <int>{},
      selectedMemberNames: <int, String>{},
    ));
  }

  void markMessagePaid(ChatMessage message) {
    message.isPaid = true;
    emit(state.copyWith(messages: List<ChatMessage>.from(state.messages)));
  }

  void replaceMessage(ChatMessage oldMessage, ChatMessage newMessage) {
    final index = state.messages.indexWhere((m) => identical(m, oldMessage));
    if (index < 0) {
      return;
    }

    final next = List<ChatMessage>.from(state.messages);
    next[index] = newMessage;
    emit(state.copyWith(messages: next));
  }

  void updatePaymentInfoForOrder({
    required int orderId,
    int? transactionId,
    String? paymentMethod,
    int? totalPayment,
    String? transactionCreatedAt,
    String? paymentCode,
    String? paymentCodeLabel,
    String? paymentInstruction,
    String? deeplinkUrl,
    String? qrCodeUrl,
    String? qrString,
  }) {
    final normalizedPaymentMethod = _normalizePaymentMethod(paymentMethod);

    bool changed = false;
    final next = state.messages.map((message) {
      if (message.isUser) {
        return message;
      }

      final matchesOrder =
          message.orderId != null && message.orderId == orderId;
      final matchesTx = transactionId != null &&
          transactionId > 0 &&
          message.transactionId != null &&
          message.transactionId == transactionId;

      if (!matchesOrder && !matchesTx) {
        return message;
      }

      changed = true;
      return message.copyWith(
        orderId: orderId,
        transactionId: transactionId ?? message.transactionId,
        paymentMethod: normalizedPaymentMethod,
        totalPayment: totalPayment,
        transactionCreatedAt: transactionCreatedAt,
        paymentCode: paymentCode,
        paymentCodeLabel: paymentCodeLabel,
        paymentInstruction: paymentInstruction,
        deeplinkUrl: deeplinkUrl,
        qrCodeUrl: qrCodeUrl,
        qrString: qrString,
      );
    }).toList();

    if (changed) {
      emit(state.copyWith(messages: next));
    }
  }

  String? _normalizePaymentMethod(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) {
      return null;
    }

    final normalized = raw.toLowerCase();
    if (normalized == 'belum dipilih' ||
        normalized == 'not selected' ||
        normalized == '-' ||
        normalized == 'null') {
      return null;
    }

    return raw;
  }

  bool markOrderPaid({int? orderId, int? transactionId}) {
    bool changed = false;
    final next = state.messages.map((message) {
      if (message.isUser || message.isPaid) {
        return message;
      }

      final matchesOrder = orderId != null &&
          message.orderId != null &&
          message.orderId == orderId;
      final matchesTx = transactionId != null &&
          transactionId > 0 &&
          message.transactionId != null &&
          message.transactionId == transactionId;

      if (!matchesOrder && !matchesTx) {
        return message;
      }

      changed = true;
      return message.copyWith(isPaid: true);
    }).toList();

    if (changed) {
      emit(state.copyWith(messages: next));
    }

    return changed;
  }

  void removeSelectedMember(int id) {
    final nextIds = Set<int>.from(state.selectedMemberIds)..remove(id);
    final nextNames = Map<int, String>.from(state.selectedMemberNames)
      ..remove(id);
    emit(state.copyWith(
      selectedMemberIds: nextIds,
      selectedMemberNames: nextNames,
    ));
  }

  // --- BUSINESS LOGIC MOVED FROM UI ---

  Future<void> checkServerConnection() async {
    final isHealthy = await _apiService.isChatbotServerHealthy();
    setServerConnected(isHealthy);
  }

  Future<void> loadUserIdIfNeeded() async {
    if (state.userId != null) {
      loadFriends();
      loadChatHistories();
      return;
    }
    try {
      final token = await _apiService.getToken();
      if (token != null) {
        final response = await _apiService.getUserProfile(token);
        if (response['success']) {
          setUserId(response['data']['id']);
          await loadFriends();
          loadChatHistories();
        }
      }
    } catch (e) {
      print('Error loading user ID: $e');
    }
  }

  Future<void> loadFriends() async {
    if (state.userId == null) return;
    try {
      final result = await _apiService.getFriends(state.userId!);
      if (result['success'] == true && result['data'] is List) {
        setFriends(List<Map<String, dynamic>>.from(result['data']));
      }
    } catch (e) {
      print('Error loading friends: $e');
    }
  }

  Future<void> loadChatHistories() async {
    if (state.userId == null) return;
    try {
      final result = await _apiService.getChatHistories(
        userId: state.userId!,
        role: _role,
      );
      if (result['success'] == true && result['data'] != null) {
        setChatHistories(List<Map<String, dynamic>>.from(result['data']));
      }
    } catch (e) {
      print('Error loading chat histories: $e');
    }
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

  Future<void> loadChatHistory(int historyId) async {
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
        setCurrentHistoryId(historyId);
        replaceMessages(rebuiltMessages);
      }
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  Future<void> autoSaveHistory() async {
    if (state.userId == null || state.messages.length <= 1) return;

    final userMessages = state.messages.where((m) => m.isUser).toList();
    if (userMessages.isEmpty) return;

    try {
      final messagesJson = state.messages.map((m) => m.toJson()).toList();
      final result = await _apiService.saveChatHistory(
        userId: state.userId!,
        role: _role,
        messages: messagesJson,
        historyId: state.currentHistoryId,
      );

      if (result['success'] == true && result['history_id'] != null) {
        final historyId = result['history_id'];
        if (historyId is int && state.currentHistoryId != historyId) {
          setCurrentHistoryId(historyId);
        }
      }
    } catch (e) {
      print('Error auto-saving history: $e');
    }
  }

  Future<void> deleteHistory(int historyId) async {
    try {
      await _apiService.deleteChatHistory(historyId, userId: state.userId);
      loadChatHistories();
    } catch (e) {
      print('Error deleting history: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPaymentMethods() async {
    final result = await _apiService.getMidtransPaymentMethods();
    if (result['success'] != true || result['data'] is! List) {
      return const <Map<String, dynamic>>[];
    }

    return (result['data'] as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> createPaymentForOrder({
    required int orderId,
    required String paymentMethod,
  }) async {
    return _apiService.createMidtransPayment(
      orderId,
      paymentMethod: paymentMethod,
      reuseIfPending: true,
    );
  }

  Future<Map<String, dynamic>> fetchPaymentStatus(String orderRef) async {
    return _apiService.getPaymentStatus(orderRef);
  }
}
