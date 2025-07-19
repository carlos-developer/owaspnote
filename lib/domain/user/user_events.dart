import '../core/domain_event.dart';
import 'user_id.dart';

class UserRegisteredEvent extends DomainEvent {
  final UserId userId;
  final String email;
  final String username;

  UserRegisteredEvent({
    required this.userId,
    required this.email,
    required this.username,
  });
}

class UserLoggedInEvent extends DomainEvent {
  final UserId userId;
  final DateTime loginTime;

  UserLoggedInEvent({
    required this.userId,
    required this.loginTime,
  });
}

class UserFailedLoginEvent extends DomainEvent {
  final UserId userId;
  final int attemptNumber;
  final bool isLocked;

  UserFailedLoginEvent({
    required this.userId,
    required this.attemptNumber,
    required this.isLocked,
  });
}

class UserLockedEvent extends DomainEvent {
  final UserId userId;
  final DateTime lockedUntil;
  final String reason;

  UserLockedEvent({
    required this.userId,
    required this.lockedUntil,
    required this.reason,
  });
}

class UserUnlockedEvent extends DomainEvent {
  final UserId userId;

  UserUnlockedEvent({required this.userId});
}

class UserPasswordChangedEvent extends DomainEvent {
  final UserId userId;
  final DateTime changedAt;

  UserPasswordChangedEvent({
    required this.userId,
    required this.changedAt,
  });
}

class UserEmailVerifiedEvent extends DomainEvent {
  final UserId userId;

  UserEmailVerifiedEvent({required this.userId});
}

class UserTwoFactorEnabledEvent extends DomainEvent {
  final UserId userId;

  UserTwoFactorEnabledEvent({required this.userId});
}

class UserTwoFactorDisabledEvent extends DomainEvent {
  final UserId userId;

  UserTwoFactorDisabledEvent({required this.userId});
}

class UserRoleAddedEvent extends DomainEvent {
  final UserId userId;
  final String role;

  UserRoleAddedEvent({
    required this.userId,
    required this.role,
  });
}

class UserRoleRemovedEvent extends DomainEvent {
  final UserId userId;
  final String role;

  UserRoleRemovedEvent({
    required this.userId,
    required this.role,
  });
}

class UserUsernameChangedEvent extends DomainEvent {
  final UserId userId;
  final String oldUsername;
  final String newUsername;

  UserUsernameChangedEvent({
    required this.userId,
    required this.oldUsername,
    required this.newUsername,
  });
}