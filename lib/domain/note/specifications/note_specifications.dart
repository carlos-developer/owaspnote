import '../../core/specification.dart';
import '../note_aggregate.dart';
import '../../user/user_id.dart';

class NoteOwnedByUserSpecification extends Specification<Note> {
  final UserId userId;

  NoteOwnedByUserSpecification(this.userId);

  @override
  bool isSatisfiedBy(Note candidate) {
    return candidate.ownerId == userId;
  }
}

class NoteSharedWithUserSpecification extends Specification<Note> {
  final UserId userId;

  NoteSharedWithUserSpecification(this.userId);

  @override
  bool isSatisfiedBy(Note candidate) {
    return candidate.sharedWith.contains(userId);
  }
}

class NoteAccessibleByUserSpecification extends Specification<Note> {
  final UserId userId;

  NoteAccessibleByUserSpecification(this.userId);

  @override
  bool isSatisfiedBy(Note candidate) {
    return candidate.canBeAccessedBy(userId);
  }
}

class NoteEncryptedSpecification extends Specification<Note> {
  @override
  bool isSatisfiedBy(Note candidate) {
    return candidate.isEncrypted;
  }
}

class NoteDeletedSpecification extends Specification<Note> {
  @override
  bool isSatisfiedBy(Note candidate) {
    return candidate.isDeleted;
  }
}

class NoteWithTagSpecification extends Specification<Note> {
  final String tag;

  NoteWithTagSpecification(this.tag);

  @override
  bool isSatisfiedBy(Note candidate) {
    return candidate.tags.contains(tag.toLowerCase());
  }
}

class NoteCreatedAfterSpecification extends Specification<Note> {
  final DateTime date;

  NoteCreatedAfterSpecification(this.date);

  @override
  bool isSatisfiedBy(Note candidate) {
    return candidate.createdAt.isAfter(date);
  }
}

class NoteUpdatedAfterSpecification extends Specification<Note> {
  final DateTime date;

  NoteUpdatedAfterSpecification(this.date);

  @override
  bool isSatisfiedBy(Note candidate) {
    return candidate.updatedAt.isAfter(date);
  }
}

class NoteTitleContainsSpecification extends Specification<Note> {
  final String searchTerm;

  NoteTitleContainsSpecification(this.searchTerm);

  @override
  bool isSatisfiedBy(Note candidate) {
    return candidate.title.value
        .toLowerCase()
        .contains(searchTerm.toLowerCase());
  }
}

class NoteContentLengthSpecification extends Specification<Note> {
  final int minLength;
  final int? maxLength;

  NoteContentLengthSpecification({
    required this.minLength,
    this.maxLength,
  });

  @override
  bool isSatisfiedBy(Note candidate) {
    final length = candidate.content.value.length;
    if (maxLength != null) {
      return length >= minLength && length <= maxLength!;
    }
    return length >= minLength;
  }
}