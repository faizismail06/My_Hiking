import '../models/chat_message.dart';

class ChatbotState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isServerConnected;
  final int? userId;
  final int? currentHistoryId;
  final List<Map<String, dynamic>> chatHistories;
  final List<Map<String, dynamic>> friends;
  final Set<int> selectedMemberIds;
  final Map<int, String> selectedMemberNames;

  const ChatbotState({
    this.messages = const [],
    this.isLoading = false,
    this.isServerConnected = false,
    this.userId,
    this.currentHistoryId,
    this.chatHistories = const [],
    this.friends = const [],
    this.selectedMemberIds = const {},
    this.selectedMemberNames = const {},
  });

  ChatbotState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isServerConnected,
    int? userId,
    bool clearUserId = false,
    int? currentHistoryId,
    bool clearCurrentHistoryId = false,
    List<Map<String, dynamic>>? chatHistories,
    List<Map<String, dynamic>>? friends,
    Set<int>? selectedMemberIds,
    Map<int, String>? selectedMemberNames,
  }) {
    return ChatbotState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isServerConnected: isServerConnected ?? this.isServerConnected,
      userId: clearUserId ? null : (userId ?? this.userId),
      currentHistoryId: clearCurrentHistoryId
          ? null
          : (currentHistoryId ?? this.currentHistoryId),
      chatHistories: chatHistories ?? this.chatHistories,
      friends: friends ?? this.friends,
      selectedMemberIds: selectedMemberIds ?? this.selectedMemberIds,
      selectedMemberNames: selectedMemberNames ?? this.selectedMemberNames,
    );
  }
}
