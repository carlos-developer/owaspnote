import '../core/aggregate_root.dart';
import 'user_id.dart';
import 'email.dart';
import 'username.dart';
import 'password.dart';
import 'user_events.dart';

class User extends AggregateRoot<UserId> {
  final Email email;
  Username username;
  HashedPassword hashedPassword;
  final DateTime createdAt;
  DateTime lastLoginAt;
  DateTime passwordChangedAt;
  bool isEmailVerified;
  bool isLocked;
  int failedLoginAttempts;
  DateTime? lockedUntil;
  bool isTwoFactorEnabled;
  String? twoFactorSecret;
  Set<String> roles;
  Map<String, dynamic> metadata;

  User({
    required UserId id,
    required this.email,
    required this.username,
    required this.hashedPassword,
    required this.createdAt,
    required this.lastLoginAt,
    required this.passwordChangedAt,
    this.isEmailVerified = false,
    this.isLocked = false,
    this.failedLoginAttempts = 0,
    this.lockedUntil,
    this.isTwoFactorEnabled = false,
    this.twoFactorSecret,
    Set<String>? roles,
    Map<String, dynamic>? metadata,
  })  : roles = roles ?? {'user'},
        metadata = metadata ?? {},
        super(id) {
    _validateInvariants();
  }

  void _validateInvariants() {
    if (!email.isValid()) {
      throw UserInvariantException('Invalid email');
    }
    if (!username.isValid()) {
      throw UserInvariantException('Invalid username');
    }
    if (!hashedPassword.isValid()) {
      throw UserInvariantException('Invalid hashed password');
    }
    if (passwordChangedAt.isBefore(createdAt)) {
      throw UserInvariantException('Password changed date cannot be before created date');
    }
    if (roles.isEmpty) {
      throw UserInvariantException('User must have at least one role');
    }
  }

  factory User.register({
    required String email,
    required String username,
    required String password,
    required String hashedPassword,
  }) {
    final userId = UserId.generate();
    final userEmail = Email(email);
    final userUsername = Username(username);
    final userPassword = Password(password);
    final userHashedPassword = HashedPassword(hashedPassword);
    final now = DateTime.now();

    if (!userEmail.isValid()) {
      throw UserRegistrationException(userEmail.validValue.left.message ?? 'Invalid email');
    }
    if (!userUsername.isValid()) {
      throw UserRegistrationException(userUsername.validValue.left.message ?? 'Invalid username');
    }
    if (!userPassword.isValid()) {
      throw UserRegistrationException(userPassword.validValue.left.message ?? 'Invalid password');
    }
    if (!userHashedPassword.isValid()) {
      throw UserRegistrationException('Invalid hashed password');
    }

    final user = User(
      id: userId,
      email: userEmail,
      username: userUsername,
      hashedPassword: userHashedPassword,
      createdAt: now,
      lastLoginAt: now,
      passwordChangedAt: now,
    );

    user.addDomainEvent(UserRegisteredEvent(
      userId: userId,
      email: email,
      username: username,
    ));

    return user;
  }

  void recordSuccessfulLogin() {
    if (isLocked && lockedUntil != null && DateTime.now().isAfter(lockedUntil!)) {
      unlock();
    }

    if (isLocked) {
      throw UserAuthenticationException('Account is locked');
    }

    failedLoginAttempts = 0;
    lastLoginAt = DateTime.now();

    addDomainEvent(UserLoggedInEvent(
      userId: id,
      loginTime: lastLoginAt,
    ));
  }

  void recordFailedLogin() {
    failedLoginAttempts++;

    if (failedLoginAttempts >= 5) {
      lock(Duration(minutes: 30));
    }

    addDomainEvent(UserFailedLoginEvent(
      userId: id,
      attemptNumber: failedLoginAttempts,
      isLocked: isLocked,
    ));
  }

  void lock(Duration duration) {
    if (isLocked) {
      throw UserLockException('User is already locked');
    }

    isLocked = true;
    lockedUntil = DateTime.now().add(duration);

    addDomainEvent(UserLockedEvent(
      userId: id,
      lockedUntil: lockedUntil!,
      reason: 'Too many failed login attempts',
    ));
  }

  void unlock() {
    if (!isLocked) {
      throw UserLockException('User is not locked');
    }

    isLocked = false;
    lockedUntil = null;
    failedLoginAttempts = 0;

    addDomainEvent(UserUnlockedEvent(userId: id));
  }

  void changePassword(String newPassword, String newHashedPassword) {
    final password = Password(newPassword);
    final hashedPass = HashedPassword(newHashedPassword);

    if (!password.isValid()) {
      throw UserPasswordChangeException(password.validValue.left.message ?? 'Invalid password');
    }
    if (!hashedPass.isValid()) {
      throw UserPasswordChangeException('Invalid hashed password');
    }

    hashedPassword = hashedPass;
    passwordChangedAt = DateTime.now();

    addDomainEvent(UserPasswordChangedEvent(
      userId: id,
      changedAt: passwordChangedAt,
    ));
  }

  void verifyEmail() {
    if (isEmailVerified) {
      throw UserEmailVerificationException('Email is already verified');
    }

    isEmailVerified = true;

    addDomainEvent(UserEmailVerifiedEvent(userId: id));
  }

  void enableTwoFactorAuth(String secret) {
    if (isTwoFactorEnabled) {
      throw UserTwoFactorException('Two-factor authentication is already enabled');
    }
    if (!isEmailVerified) {
      throw UserTwoFactorException('Email must be verified before enabling 2FA');
    }

    isTwoFactorEnabled = true;
    twoFactorSecret = secret;

    addDomainEvent(UserTwoFactorEnabledEvent(userId: id));
  }

  void disableTwoFactorAuth() {
    if (!isTwoFactorEnabled) {
      throw UserTwoFactorException('Two-factor authentication is not enabled');
    }

    isTwoFactorEnabled = false;
    twoFactorSecret = null;

    addDomainEvent(UserTwoFactorDisabledEvent(userId: id));
  }

  void addRole(String role) {
    if (roles.contains(role)) {
      throw UserRoleException('User already has this role');
    }

    roles.add(role);

    addDomainEvent(UserRoleAddedEvent(
      userId: id,
      role: role,
    ));
  }

  void removeRole(String role) {
    if (!roles.contains(role)) {
      throw UserRoleException('User does not have this role');
    }
    if (roles.length == 1) {
      throw UserRoleException('Cannot remove last role');
    }

    roles.remove(role);

    addDomainEvent(UserRoleRemovedEvent(
      userId: id,
      role: role,
    ));
  }

  void updateUsername(String newUsername) {
    final newUserUsername = Username(newUsername);
    
    if (!newUserUsername.isValid()) {
      throw UserUsernameUpdateException(newUserUsername.validValue.left.message ?? 'Invalid username');
    }

    final oldUsername = username.value;
    username = newUserUsername;

    addDomainEvent(UserUsernameChangedEvent(
      userId: id,
      oldUsername: oldUsername,
      newUsername: newUsername,
    ));
  }

  bool hasRole(String role) => roles.contains(role);
  bool hasAnyRole(Set<String> checkRoles) => checkRoles.any((role) => roles.contains(role));
  bool hasAllRoles(Set<String> checkRoles) => checkRoles.every((role) => roles.contains(role));
  bool get canLogin => !isLocked && isEmailVerified;
  bool get isPasswordExpired => DateTime.now().difference(passwordChangedAt).inDays > 90;
}

class UserInvariantException implements Exception {
  final String message;
  UserInvariantException(this.message);
}

class UserRegistrationException implements Exception {
  final String message;
  UserRegistrationException(this.message);
}

class UserAuthenticationException implements Exception {
  final String message;
  UserAuthenticationException(this.message);
}

class UserLockException implements Exception {
  final String message;
  UserLockException(this.message);
}

class UserPasswordChangeException implements Exception {
  final String message;
  UserPasswordChangeException(this.message);
}

class UserEmailVerificationException implements Exception {
  final String message;
  UserEmailVerificationException(this.message);
}

class UserTwoFactorException implements Exception {
  final String message;
  UserTwoFactorException(this.message);
}

class UserRoleException implements Exception {
  final String message;
  UserRoleException(this.message);
}

class UserUsernameUpdateException implements Exception {
  final String message;
  UserUsernameUpdateException(this.message);
}