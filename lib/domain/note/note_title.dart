import '../core/value_object.dart';

class NoteTitle extends ValueObject<String> {
  static const int maxLength = 100;
  static const int minLength = 1;

  const NoteTitle(super.value);

  @override
  Either<ValueFailure<String>, String> get validValue {
    if (value.isEmpty) {
      return Either.left(EmptyNoteTitle(failedValue: value));
    }
    if (value.length > maxLength) {
      return Either.left(NoteTitleTooLong(failedValue: value));
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return Either.left(NoteTitleOnlyWhitespace(failedValue: value));
    }
    return Either.right(trimmed);
  }
}

class EmptyNoteTitle extends ValueFailure<String> {
  const EmptyNoteTitle({required super.failedValue})
      : super(message: 'Note title cannot be empty');
}

class NoteTitleTooLong extends ValueFailure<String> {
  const NoteTitleTooLong({required super.failedValue})
      : super(message: 'Note title exceeds maximum length of ${NoteTitle.maxLength}');
}

class NoteTitleOnlyWhitespace extends ValueFailure<String> {
  const NoteTitleOnlyWhitespace({required super.failedValue})
      : super(message: 'Note title cannot contain only whitespace');
}