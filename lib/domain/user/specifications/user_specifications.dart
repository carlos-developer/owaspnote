import '../../core/specification.dart';
import '../user_aggregate.dart';

class UserActiveSpecification extends Specification<User> {
  @override
  bool isSatisfiedBy(User candidate) {
    return !candidate.isLocked && candidate.isEmailVerified;
  }
}

class UserLockedSpecification extends Specification<User> {
  @override
  bool isSatisfiedBy(User candidate) {
    return candidate.isLocked;
  }
}

class UserEmailVerifiedSpecification extends Specification<User> {
  @override
  bool isSatisfiedBy(User candidate) {
    return candidate.isEmailVerified;
  }
}

class UserWithRoleSpecification extends Specification<User> {
  final String role;

  UserWithRoleSpecification(this.role);

  @override
  bool isSatisfiedBy(User candidate) {
    return candidate.hasRole(role);
  }
}

class UserWithAnyRoleSpecification extends Specification<User> {
  final Set<String> roles;

  UserWithAnyRoleSpecification(this.roles);

  @override
  bool isSatisfiedBy(User candidate) {
    return candidate.hasAnyRole(roles);
  }
}

class UserWithAllRolesSpecification extends Specification<User> {
  final Set<String> roles;

  UserWithAllRolesSpecification(this.roles);

  @override
  bool isSatisfiedBy(User candidate) {
    return candidate.hasAllRoles(roles);
  }
}

class UserWithExpiredPasswordSpecification extends Specification<User> {
  @override
  bool isSatisfiedBy(User candidate) {
    return candidate.isPasswordExpired;
  }
}

class UserWithTwoFactorEnabledSpecification extends Specification<User> {
  @override
  bool isSatisfiedBy(User candidate) {
    return candidate.isTwoFactorEnabled;
  }
}

class UserCreatedAfterSpecification extends Specification<User> {
  final DateTime date;

  UserCreatedAfterSpecification(this.date);

  @override
  bool isSatisfiedBy(User candidate) {
    return candidate.createdAt.isAfter(date);
  }
}

class UserLastLoginAfterSpecification extends Specification<User> {
  final DateTime date;

  UserLastLoginAfterSpecification(this.date);

  @override
  bool isSatisfiedBy(User candidate) {
    return candidate.lastLoginAt.isAfter(date);
  }
}

class UserCanLoginSpecification extends Specification<User> {
  @override
  bool isSatisfiedBy(User candidate) {
    return candidate.canLogin;
  }
}

class UserWithFailedLoginAttemptsSpecification extends Specification<User> {
  final int minAttempts;

  UserWithFailedLoginAttemptsSpecification({this.minAttempts = 1});

  @override
  bool isSatisfiedBy(User candidate) {
    return candidate.failedLoginAttempts >= minAttempts;
  }
}