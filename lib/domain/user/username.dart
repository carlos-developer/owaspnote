import '../core/value_object.dart';

class Username extends ValueObject<String> {
  static const int minLength = 3;
  static const int maxLength = 30;

  const Username(super.value);

  @override
  Either<ValueFailure<String>, String> get validValue {
    if (value.length < minLength) {
      return Either.left(UsernameTooShort(failedValue: value));
    }
    
    if (value.length > maxLength) {
      return Either.left(UsernameTooLong(failedValue: value));
    }
    
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) {
      return Either.left(UsernameInvalidCharacters(failedValue: value));
    }
    
    return Either.right(value.toLowerCase());
  }
}

class UsernameTooShort extends ValueFailure<String> {
  const UsernameTooShort({required super.failedValue})
      : super(message: 'Username must be at least ${Username.minLength} characters');
}

class UsernameTooLong extends ValueFailure<String> {
  const UsernameTooLong({required super.failedValue})
      : super(message: 'Username cannot exceed ${Username.maxLength} characters');
}

class UsernameInvalidCharacters extends ValueFailure<String> {
  const UsernameInvalidCharacters({required super.failedValue})
      : super(message: 'Username can only contain letters, numbers, and underscores');
}