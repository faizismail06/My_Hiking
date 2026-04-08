import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/chat_message.dart';
import 'chatbot_state.dart';

class ChatbotCubit extends Cubit<ChatbotState> {
  ChatbotCubit() : super(const ChatbotState());

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

  void removeSelectedMember(int id) {
    final nextIds = Set<int>.from(state.selectedMemberIds)..remove(id);
    final nextNames = Map<int, String>.from(state.selectedMemberNames)
      ..remove(id);
    emit(state.copyWith(
      selectedMemberIds: nextIds,
      selectedMemberNames: nextNames,
    ));
  }
}
