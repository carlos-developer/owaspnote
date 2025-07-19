import '../core/value_object.dart';

class Email extends ValueObject<String> {
  const Email(super.value);

  @override
  Either<ValueFailure<String>, String> get validValue {
    if (value.isEmpty) {
      return Either.left(EmptyEmail(failedValue: value));
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return Either.left(InvalidEmailFormat(failedValue: value));
    }
    
    return Either.right(value.toLowerCase());
  }
}

class EmptyEmail extends ValueFailure<String> {
  const EmptyEmail({required super.failedValue})
      : super(message: 'Email cannot be empty');
}

class InvalidEmailFormat extends ValueFailure<String> {
  const InvalidEmailFormat({required super.failedValue})
      : super(message: 'Invalid email format');
}