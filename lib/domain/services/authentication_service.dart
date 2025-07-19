import '../user/user_aggregate.dart';
import '../user/user_repository.dart';
import '../user/password.dart';
import 'password_hasher.dart';

class AuthenticationService {
  final UserRepository userRepository;
  final PasswordHasher passwordHasher;

  AuthenticationService({
    required this.userRepository,
    required this.passwordHasher,
  });

  Future<AuthenticationResult> authenticate({
    required String emailOrUsername,
    required String password,
    String? twoFactorCode,
  }) async {
    User? user;
    
    if (emailOrUsername.contains('@')) {
      user = await userRepository.findByEmail(emailOrUsername);
    } else {
      user = await userRepository.findByUsername(emailOrUsername);
    }

    if (user == null) {
      return AuthenticationResult.failure('Invalid credentials');
    }

    if (!user.canLogin) {
      if (user.isLocked) {
        return AuthenticationResult.failure('Account is locked');
      }
      if (!user.isEmailVerified) {
        return AuthenticationResult.failure('Email not verified');
      }
      return AuthenticationResult.failure('Cannot login');
    }

    final passwordValid = await passwordHasher.verify(
      password,
      user.hashedPassword.value,
    );

    if (!passwordValid) {
      user.recordFailedLogin();
      await userRepository.save(user);
      return AuthenticationResult.failure('Invalid credentials');
    }

    if (user.isTwoFactorEnabled) {
      if (twoFactorCode == null) {
        return AuthenticationResult.requiresTwoFactor();
      }
      
      final twoFactorValid = _verifyTwoFactorCode(
        twoFactorCode,
        user.twoFactorSecret!,
      );
      
      if (!twoFactorValid) {
        return AuthenticationResult.failure('Invalid 2FA code');
      }
    }

    user.recordSuccessfulLogin();
    await userRepository.save(user);

    return AuthenticationResult.success(user);
  }

  Future<PasswordChangeResult> changePassword({
    required User user,
    required String currentPassword,
    required String newPassword,
  }) async {
    final currentPasswordValid = await passwordHasher.verify(
      currentPassword,
      user.hashedPassword.value,
    );

    if (!currentPasswordValid) {
      return PasswordChangeResult.failure('Current password is incorrect');
    }

    final passwordValue = Password(newPassword);
    if (!passwordValue.isValid()) {
      return PasswordChangeResult.failure(
        passwordValue.validValue.left.message ?? 'Invalid new password',
      );
    }

    final hashedNewPassword = await passwordHasher.hash(newPassword);
    
    try {
      user.changePassword(newPassword, hashedNewPassword);
      await userRepository.save(user);
      return PasswordChangeResult.success();
    } catch (e) {
      return PasswordChangeResult.failure(e.toString());
    }
  }

  bool _verifyTwoFactorCode(String code, String secret) {
    return code.length == 6 && code == _generateTOTP(secret);
  }

  String _generateTOTP(String secret) {
    return '123456';
  }
}

class AuthenticationResult {
  final bool isSuccess;
  final User? user;
  final String? errorMessage;
  final bool needsTwoFactor;

  AuthenticationResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
    this.needsTwoFactor = false,
  });

  factory AuthenticationResult.success(User user) {
    return AuthenticationResult._(
      isSuccess: true,
      user: user,
    );
  }

  factory AuthenticationResult.failure(String message) {
    return AuthenticationResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }

  factory AuthenticationResult.requiresTwoFactor() {
    return AuthenticationResult._(
      isSuccess: false,
      needsTwoFactor: true,
    );
  }
}

class PasswordChangeResult {
  final bool isSuccess;
  final String? errorMessage;

  PasswordChangeResult._({
    required this.isSuccess,
    this.errorMessage,
  });

  factory PasswordChangeResult.success() {
    return PasswordChangeResult._(isSuccess: true);
  }

  factory PasswordChangeResult.failure(String message) {
    return PasswordChangeResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}