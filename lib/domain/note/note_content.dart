import '../core/value_object.dart';

class NoteContent extends ValueObject<String> {
  static const int maxLength = 10000;

  const NoteContent(super.value);

  factory NoteContent.empty() => const NoteContent('');

  @override
  Either<ValueFailure<String>, String> get validValue {
    if (value.length > maxLength) {
      return Either.left(NoteContentTooLong(failedValue: value));
    }
    return Either.right(value);
  }

  bool get isEmpty => value.isEmpty;
  bool get isNotEmpty => value.isNotEmpty;
}

class NoteContentTooLong extends ValueFailure<String> {
  const NoteContentTooLong({required super.failedValue})
      : super(message: 'Note content exceeds maximum length of ${NoteContent.maxLength}');
}