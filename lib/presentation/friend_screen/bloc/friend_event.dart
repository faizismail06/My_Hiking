part of 'friend_bloc.dart';

abstract class FriendEvent extends Equatable {
  const FriendEvent();

  @override
  List<Object?> get props => [];
}

class FriendInitialEvent extends FriendEvent {
  final int userId;
  
  const FriendInitialEvent(this.userId);
  
  @override
  List<Object?> get props => [userId];
}

class LoadFriendsEvent extends FriendEvent {
  final int userId;
  
  const LoadFriendsEvent(this.userId);
  
  @override
  List<Object?> get props => [userId];
}

class LoadPendingRequestsEvent extends FriendEvent {
  final int userId;
  
  const LoadPendingRequestsEvent(this.userId);
  
  @override
  List<Object?> get props => [userId];
}

class SearchUsersEvent extends FriendEvent {
  final String query;
  final int currentUserId;
  
  const SearchUsersEvent(this.query, this.currentUserId);
  
  @override
  List<Object?> get props => [query, currentUserId];
}

class AddFriendEvent extends FriendEvent {
  final int userId;
  final int friendId;
  
  const AddFriendEvent(this.userId, this.friendId);
  
  @override
  List<Object?> get props => [userId, friendId];
}

class AcceptFriendEvent extends FriendEvent {
  final int friendshipId;
  final int userId;
  
  const AcceptFriendEvent(this.friendshipId, this.userId);
  
  @override
  List<Object?> get props => [friendshipId, userId];
}

class RejectFriendEvent extends FriendEvent {
  final int friendshipId;
  final int userId;
  
  const RejectFriendEvent(this.friendshipId, this.userId);
  
  @override
  List<Object?> get props => [friendshipId, userId];
}

class RemoveFriendEvent extends FriendEvent {
  final int friendshipId;
  final int userId;
  
  const RemoveFriendEvent(this.friendshipId, this.userId);
  
  @override
  List<Object?> get props => [friendshipId, userId];
}

class ClearSearchEvent extends FriendEvent {}
