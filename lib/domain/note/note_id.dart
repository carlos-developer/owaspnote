import '../core/value_object.dart';

class NoteId extends ValueObject<String> {
  const NoteId(super.value);

  factory NoteId.generate() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000 + (timestamp % 1000)).toString();
    return NoteId('note_$random');
  }

  @override
  Either<ValueFailure<String>, String> get validValue {
    if (value.isEmpty) {
      return Either.left(EmptyNoteId(failedValue: value));
    }
    if (!value.startsWith('note_')) {
      return Either.left(InvalidNoteIdFormat(failedValue: value));
    }
    return Either.right(value);
  }
}

class EmptyNoteId extends ValueFailure<String> {
  const EmptyNoteId({required super.failedValue})
      : super(message: 'Note ID cannot be empty');
}

class InvalidNoteIdFormat extends ValueFailure<String> {
  const InvalidNoteIdFormat({required super.failedValue})
      : super(message: 'Note ID must start with "note_"');
}