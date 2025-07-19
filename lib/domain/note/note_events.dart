import '../core/domain_event.dart';
import '../user/user_id.dart';
import 'note_id.dart';

class NoteCreatedEvent extends DomainEvent {
  final NoteId noteId;
  final UserId ownerId;
  final String title;
  final bool isEncrypted;

  NoteCreatedEvent({
    required this.noteId,
    required this.ownerId,
    required this.title,
    required this.isEncrypted,
  });
}

class NoteTitleUpdatedEvent extends DomainEvent {
  final NoteId noteId;
  final String oldTitle;
  final String newTitle;

  NoteTitleUpdatedEvent({
    required this.noteId,
    required this.oldTitle,
    required this.newTitle,
  });
}

class NoteContentUpdatedEvent extends DomainEvent {
  final NoteId noteId;
  final int previousLength;
  final int newLength;

  NoteContentUpdatedEvent({
    required this.noteId,
    required this.previousLength,
    required this.newLength,
  });
}

class NoteSharedEvent extends DomainEvent {
  final NoteId noteId;
  final UserId sharedWithUserId;
  final UserId sharedByUserId;

  NoteSharedEvent({
    required this.noteId,
    required this.sharedWithUserId,
    required this.sharedByUserId,
  });
}

class NoteUnsharedEvent extends DomainEvent {
  final NoteId noteId;
  final UserId unsharedWithUserId;

  NoteUnsharedEvent({
    required this.noteId,
    required this.unsharedWithUserId,
  });
}

class NoteDeletedEvent extends DomainEvent {
  final NoteId noteId;
  final UserId deletedByUserId;

  NoteDeletedEvent({
    required this.noteId,
    required this.deletedByUserId,
  });
}

class NoteRestoredEvent extends DomainEvent {
  final NoteId noteId;

  NoteRestoredEvent({required this.noteId});
}

class NoteEncryptedEvent extends DomainEvent {
  final NoteId noteId;

  NoteEncryptedEvent({required this.noteId});
}

class NoteDecryptedEvent extends DomainEvent {
  final NoteId noteId;

  NoteDecryptedEvent({required this.noteId});
}

class NoteTaggedEvent extends DomainEvent {
  final NoteId noteId;
  final String tag;

  NoteTaggedEvent({
    required this.noteId,
    required this.tag,
  });
}

class NoteUntaggedEvent extends DomainEvent {
  final NoteId noteId;
  final String tag;

  NoteUntaggedEvent({
    required this.noteId,
    required this.tag,
  });
}