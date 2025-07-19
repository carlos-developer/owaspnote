import '../../domain/user/user_aggregate.dart';
import '../../domain/user/user_repository.dart';
import '../../domain/user/user_id.dart';
import '../../domain/services/authentication_service.dart';
import '../../domain/services/password_hasher.dart';
import '../common/application_service.dart';

class UserApplicationService extends ApplicationService {
  final UserRepository userRepository;
  final PasswordHasher passwordHasher;
  final AuthenticationService authenticationService;

  UserApplicationService({
    required this.userRepository,
    required this.passwordHasher,
    required this.authenticationService,
  });

  @override
  void validate() {
    // All fields are required by constructor, no need to check for null
  }

  Future<RegisterUserResult> registerUser({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      final emailExists = await userRepository.existsWithEmail(email);
      if (emailExists) {
        return RegisterUserResult.failure('Email already registered');
      }

      final usernameExists = await userRepository.existsWithUsername(username);
      if (usernameExists) {
        return RegisterUserResult.failure('Username already taken');
      }

      final hashedPassword = await passwordHasher.hash(password);

      final user = User.register(
        email: email,
        username: username,
        password: password,
        hashedPassword: hashedPassword,
      );

      await userRepository.save(user);

      return RegisterUserResult.success(user);
    } catch (e) {
      return RegisterUserResult.failure(e.toString());
    }
  }

  Future<LoginResult> login({
    required String emailOrUsername,
    required String password,
    String? twoFactorCode,
  }) async {
    try {
      final result = await authenticationService.authenticate(
        emailOrUsername: emailOrUsername,
        password: password,
        twoFactorCode: twoFactorCode,
      );

      if (result.isSuccess) {
        return LoginResult.success(result.user!);
      } else if (result.needsTwoFactor) {
        return LoginResult.requiresTwoFactor();
      } else {
        return LoginResult.failure(result.errorMessage!);
      }
    } catch (e) {
      return LoginResult.failure(e.toString());
    }
  }

  Future<ChangePasswordResult> changePassword({
    required UserId userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = await userRepository.findById(userId);
      if (user == null) {
        return ChangePasswordResult.failure('User not found');
      }

      final result = await authenticationService.changePassword(
        user: user,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (result.isSuccess) {
        return ChangePasswordResult.success();
      } else {
        return ChangePasswordResult.failure(result.errorMessage!);
      }
    } catch (e) {
      return ChangePasswordResult.failure(e.toString());
    }
  }

  Future<VerifyEmailResult> verifyEmail({
    required UserId userId,
    required String verificationToken,
  }) async {
    try {
      final user = await userRepository.findById(userId);
      if (user == null) {
        return VerifyEmailResult.failure('User not found');
      }

      if (user.isEmailVerified) {
        return VerifyEmailResult.failure('Email already verified');
      }

      user.verifyEmail();
      await userRepository.save(user);

      return VerifyEmailResult.success();
    } catch (e) {
      return VerifyEmailResult.failure(e.toString());
    }
  }

  Future<EnableTwoFactorResult> enableTwoFactor({
    required UserId userId,
    required String verificationCode,
  }) async {
    try {
      final user = await userRepository.findById(userId);
      if (user == null) {
        return EnableTwoFactorResult.failure('User not found');
      }

      final secret = _generateTwoFactorSecret();
      
      user.enableTwoFactorAuth(secret);
      await userRepository.save(user);

      return EnableTwoFactorResult.success(secret);
    } catch (e) {
      return EnableTwoFactorResult.failure(e.toString());
    }
  }

  Future<DisableTwoFactorResult> disableTwoFactor({
    required UserId userId,
    required String password,
  }) async {
    try {
      final user = await userRepository.findById(userId);
      if (user == null) {
        return DisableTwoFactorResult.failure('User not found');
      }

      final passwordValid = await passwordHasher.verify(
        password,
        user.hashedPassword.value,
      );

      if (!passwordValid) {
        return DisableTwoFactorResult.failure('Invalid password');
      }

      user.disableTwoFactorAuth();
      await userRepository.save(user);

      return DisableTwoFactorResult.success();
    } catch (e) {
      return DisableTwoFactorResult.failure(e.toString());
    }
  }

  Future<UpdateProfileResult> updateProfile({
    required UserId userId,
    String? newUsername,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = await userRepository.findById(userId);
      if (user == null) {
        return UpdateProfileResult.failure('User not found');
      }

      if (newUsername != null && newUsername != user.username.value) {
        final usernameExists = await userRepository.existsWithUsername(newUsername);
        if (usernameExists) {
          return UpdateProfileResult.failure('Username already taken');
        }
        user.updateUsername(newUsername);
      }

      if (metadata != null) {
        user.metadata.addAll(metadata);
      }

      await userRepository.save(user);

      return UpdateProfileResult.success(user);
    } catch (e) {
      return UpdateProfileResult.failure(e.toString());
    }
  }

  Future<GetUserResult> getUser({
    required UserId userId,
  }) async {
    try {
      final user = await userRepository.findById(userId);
      if (user == null) {
        return GetUserResult.failure('User not found');
      }

      return GetUserResult.success(user);
    } catch (e) {
      return GetUserResult.failure(e.toString());
    }
  }

  Future<UnlockUserResult> unlockUser({
    required UserId adminUserId,
    required UserId targetUserId,
  }) async {
    try {
      final admin = await userRepository.findById(adminUserId);
      if (admin == null) {
        return UnlockUserResult.failure('Admin user not found');
      }

      if (!admin.hasRole('admin')) {
        return UnlockUserResult.failure('Insufficient permissions');
      }

      final targetUser = await userRepository.findById(targetUserId);
      if (targetUser == null) {
        return UnlockUserResult.failure('Target user not found');
      }

      targetUser.unlock();
      await userRepository.save(targetUser);

      return UnlockUserResult.success();
    } catch (e) {
      return UnlockUserResult.failure(e.toString());
    }
  }

  String _generateTwoFactorSecret() {
    return 'SECRET${DateTime.now().millisecondsSinceEpoch}';
  }
}

class RegisterUserResult {
  final bool isSuccess;
  final User? user;
  final String? errorMessage;

  RegisterUserResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
  });

  factory RegisterUserResult.success(User user) {
    return RegisterUserResult._(
      isSuccess: true,
      user: user,
    );
  }

  factory RegisterUserResult.failure(String message) {
    return RegisterUserResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

class LoginResult {
  final bool isSuccess;
  final User? user;
  final String? errorMessage;
  final bool requiresTwoFactor;

  LoginResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
    this.requiresTwoFactor = false,
  });

  factory LoginResult.success(User user) {
    return LoginResult._(
      isSuccess: true,
      user: user,
    );
  }

  factory LoginResult.failure(String message) {
    return LoginResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }

  factory LoginResult.requiresTwoFactor() {
    return LoginResult._(
      isSuccess: false,
      requiresTwoFactor: true,
    );
  }
}

class ChangePasswordResult {
  final bool isSuccess;
  final String? errorMessage;

  ChangePasswordResult._({
    required this.isSuccess,
    this.errorMessage,
  });

  factory ChangePasswordResult.success() {
    return ChangePasswordResult._(isSuccess: true);
  }

  factory ChangePasswordResult.failure(String message) {
    return ChangePasswordResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

class VerifyEmailResult {
  final bool isSuccess;
  final String? errorMessage;

  VerifyEmailResult._({
    required this.isSuccess,
    this.errorMessage,
  });

  factory VerifyEmailResult.success() {
    return VerifyEmailResult._(isSuccess: true);
  }

  factory VerifyEmailResult.failure(String message) {
    return VerifyEmailResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

class EnableTwoFactorResult {
  final bool isSuccess;
  final String? secret;
  final String? errorMessage;

  EnableTwoFactorResult._({
    required this.isSuccess,
    this.secret,
    this.errorMessage,
  });

  factory EnableTwoFactorResult.success(String secret) {
    return EnableTwoFactorResult._(
      isSuccess: true,
      secret: secret,
    );
  }

  factory EnableTwoFactorResult.failure(String message) {
    return EnableTwoFactorResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

class DisableTwoFactorResult {
  final bool isSuccess;
  final String? errorMessage;

  DisableTwoFactorResult._({
    required this.isSuccess,
    this.errorMessage,
  });

  factory DisableTwoFactorResult.success() {
    return DisableTwoFactorResult._(isSuccess: true);
  }

  factory DisableTwoFactorResult.failure(String message) {
    return DisableTwoFactorResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

class UpdateProfileResult {
  final bool isSuccess;
  final User? user;
  final String? errorMessage;

  UpdateProfileResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
  });

  factory UpdateProfileResult.success(User user) {
    return UpdateProfileResult._(
      isSuccess: true,
      user: user,
    );
  }

  factory UpdateProfileResult.failure(String message) {
    return UpdateProfileResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

class GetUserResult {
  final bool isSuccess;
  final User? user;
  final String? errorMessage;

  GetUserResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
  });

  factory GetUserResult.success(User user) {
    return GetUserResult._(
      isSuccess: true,
      user: user,
    );
  }

  factory GetUserResult.failure(String message) {
    return GetUserResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

class UnlockUserResult {
  final bool isSuccess;
  final String? errorMessage;

  UnlockUserResult._({
    required this.isSuccess,
    this.errorMessage,
  });

  factory UnlockUserResult.success() {
    return UnlockUserResult._(isSuccess: true);
  }

  factory UnlockUserResult.failure(String message) {
    return UnlockUserResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}