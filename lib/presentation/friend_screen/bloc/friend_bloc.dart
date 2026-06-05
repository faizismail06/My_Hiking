import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../api/api_service.dart';
import '../../../models/friend_model.dart';

part 'friend_event.dart';
part 'friend_state.dart';

class FriendBloc extends Bloc<FriendEvent, FriendState> {
  final ApiService apiService;

  FriendBloc({required this.apiService}) : super(const FriendState()) {
    on<FriendInitialEvent>(_onInitial);
    on<LoadFriendsEvent>(_onLoadFriends);
    on<LoadPendingRequestsEvent>(_onLoadPendingRequests);
    on<SearchUsersEvent>(_onSearchUsers);
    on<AddFriendEvent>(_onAddFriend);
    on<AcceptFriendEvent>(_onAcceptFriend);
    on<RejectFriendEvent>(_onRejectFriend);
    on<RemoveFriendEvent>(_onRemoveFriend);
    on<ClearSearchEvent>(_onClearSearch);
  }

  Future<void> _onInitial(
    FriendInitialEvent event,
    Emitter<FriendState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    // Load friends and pending requests
    final friendsResponse = await apiService.getFriends(event.userId);
    final pendingResponse = await apiService.getPendingRequests(event.userId);

    List<FriendModel> friends = [];
    List<PendingRequestModel> pendingRequests = [];

    if (friendsResponse['success'] == true) {
      friends = (friendsResponse['data'] as List)
          .map((json) => FriendModel.fromJson(json))
          .toList();
    }

    if (pendingResponse['success'] == true) {
      pendingRequests = (pendingResponse['data'] as List)
          .map((json) => PendingRequestModel.fromJson(json))
          .toList();
    }

    emit(state.copyWith(
      friends: friends,
      pendingRequests: pendingRequests,
      isLoading: false,
    ));
  }

  Future<void> _onLoadFriends(
    LoadFriendsEvent event,
    Emitter<FriendState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final response = await apiService.getFriends(event.userId);

    if (response['success'] == true) {
      final friends = (response['data'] as List)
          .map((json) => FriendModel.fromJson(json))
          .toList();
      emit(state.copyWith(friends: friends, isLoading: false));
    } else {
      emit(state.copyWith(
        error: response['message'],
        isLoading: false,
      ));
    }
  }

  Future<void> _onLoadPendingRequests(
    LoadPendingRequestsEvent event,
    Emitter<FriendState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final response = await apiService.getPendingRequests(event.userId);

    if (response['success'] == true) {
      final pendingRequests = (response['data'] as List)
          .map((json) => PendingRequestModel.fromJson(json))
          .toList();
      emit(state.copyWith(pendingRequests: pendingRequests, isLoading: false));
    } else {
      emit(state.copyWith(
        error: response['message'],
        isLoading: false,
      ));
    }
  }

  Future<void> _onSearchUsers(
    SearchUsersEvent event,
    Emitter<FriendState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(state.copyWith(searchResults: [], isSearching: false));
      return;
    }

    emit(state.copyWith(isSearching: true));

    final response =
        await apiService.searchUsers(event.query, event.currentUserId);

    if (response['success'] == true) {
      final searchResults = (response['data'] as List)
          .map((json) => FriendModel.fromJson(json))
          .toList();
      emit(state.copyWith(searchResults: searchResults, isSearching: false));
    } else {
      emit(state.copyWith(
        error: response['message'],
        isSearching: false,
      ));
    }
  }

  Future<void> _onAddFriend(
    AddFriendEvent event,
    Emitter<FriendState> emit,
  ) async {
    final response = await apiService.addFriend(event.userId, event.friendId);

    if (response['success'] == true) {
      emit(state.copyWith(successMessage: 'Permintaan teman terkirim!'));
      // Refresh search results to update status
      add(SearchUsersEvent('', event.userId));
    } else {
      emit(state.copyWith(error: response['message']));
    }
  }

  Future<void> _onAcceptFriend(
    AcceptFriendEvent event,
    Emitter<FriendState> emit,
  ) async {
    final response =
        await apiService.acceptFriend(event.friendshipId, event.userId);

    if (response['success'] == true) {
      emit(state.copyWith(successMessage: 'Permintaan teman diterima!'));
      // Refresh data
      add(FriendInitialEvent(event.userId));
    } else {
      emit(state.copyWith(error: response['message']));
    }
  }

  Future<void> _onRejectFriend(
    RejectFriendEvent event,
    Emitter<FriendState> emit,
  ) async {
    final response =
        await apiService.rejectFriend(event.friendshipId, event.userId);

    if (response['success'] == true) {
      emit(state.copyWith(successMessage: 'Permintaan teman ditolak'));
      // Refresh pending requests
      add(LoadPendingRequestsEvent(event.userId));
    } else {
      emit(state.copyWith(error: response['message']));
    }
  }

  Future<void> _onRemoveFriend(
    RemoveFriendEvent event,
    Emitter<FriendState> emit,
  ) async {
    final response =
        await apiService.removeFriend(event.friendshipId, event.userId);

    if (response['success'] == true) {
      emit(state.copyWith(successMessage: 'Teman dihapus'));
      // Refresh friends list
      add(LoadFriendsEvent(event.userId));
    } else {
      emit(state.copyWith(error: response['message']));
    }
  }

  void _onClearSearch(
    ClearSearchEvent event,
    Emitter<FriendState> emit,
  ) {
    emit(state.copyWith(searchResults: []));
  }
}
