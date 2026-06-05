part of 'friend_bloc.dart';

class FriendState extends Equatable {
  final List<FriendModel> friends;
  final List<PendingRequestModel> pendingRequests;
  final List<FriendModel> searchResults;
  final bool isLoading;
  final bool isSearching;
  final String? error;
  final String? successMessage;

  const FriendState({
    this.friends = const [],
    this.pendingRequests = const [],
    this.searchResults = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.error,
    this.successMessage,
  });

  FriendState copyWith({
    List<FriendModel>? friends,
    List<PendingRequestModel>? pendingRequests,
    List<FriendModel>? searchResults,
    bool? isLoading,
    bool? isSearching,
    String? error,
    String? successMessage,
  }) {
    return FriendState(
      friends: friends ?? this.friends,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      error: error,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        friends,
        pendingRequests,
        searchResults,
        isLoading,
        isSearching,
        error,
        successMessage,
      ];
}
