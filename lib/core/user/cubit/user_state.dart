import 'package:equatable/equatable.dart';
import 'package:casi/core/user/domain/entities/user_profile.dart';

abstract class UserState extends Equatable {
  const UserState();
  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserUnauthenticated extends UserState {}

class UserReady extends UserState {
  final UserProfile user;
  final bool fromCache;
  const UserReady(this.user, {this.fromCache = false});

  @override
  List<Object?> get props => [user, fromCache];
}

class UserError extends UserState {
  final String message;
  const UserError(this.message);
  @override
  List<Object?> get props => [message];
}
