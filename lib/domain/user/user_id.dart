import '../core/value_object.dart';

class UserId extends ValueObject<String> {
  const UserId(super.value);

  factory UserId.generate() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000 + (timestamp % 1000)).toString();
    return UserId('user_$random');
  }

  @override
  Either<ValueFailure<String>, String> get validValue {
    if (value.isEmpty) {
      return Either.left(EmptyUserId(failedValue: value));
    }
    if (!value.startsWith('user_')) {
      return Either.left(InvalidUserIdFormat(failedValue: value));
    }
    return Either.right(value);
  }
}

class EmptyUserId extends ValueFailure<String> {
  const EmptyUserId({required super.failedValue})
      : super(message: 'User ID cannot be empty');
}

class InvalidUserIdFormat extends ValueFailure<String> {
  const InvalidUserIdFormat({required super.failedValue})
      : super(message: 'User ID must start with "user_"');
}