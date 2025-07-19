import '../core/aggregate_root.dart';
import '../user/user_id.dart';
import 'note_id.dart';
import 'note_title.dart';
import 'note_content.dart';
import 'note_events.dart';

class Note extends AggregateRoot<NoteId> {
  final UserId ownerId;
  NoteTitle title;
  NoteContent content;
  final DateTime createdAt;
  DateTime updatedAt;
  bool isEncrypted;
  bool isDeleted;
  Set<UserId> sharedWith;
  List<String> tags;

  Note({
    required NoteId id,
    required this.ownerId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isEncrypted = false,
    this.isDeleted = false,
    Set<UserId>? sharedWith,
    List<String>? tags,
  })  : sharedWith = sharedWith ?? {},
        tags = tags ?? [],
        super(id) {
    if (!title.isValid()) {
      throw NoteInvariantException('Invalid note title');
    }
    if (!content.isValid()) {
      throw NoteInvariantException('Invalid note content');
    }
    if (updatedAt.isBefore(createdAt)) {
      throw NoteInvariantException('Updated date cannot be before created date');
    }
  }

  factory Note.create({
    required UserId ownerId,
    required String title,
    String content = '',
    bool encrypt = false,
  }) {
    final noteId = NoteId.generate();
    final noteTitle = NoteTitle(title);
    final noteContent = NoteContent(content);
    final now = DateTime.now();

    if (!noteTitle.isValid()) {
      throw NoteCreationException(noteTitle.validValue.left.message ?? 'Invalid title');
    }
    if (!noteContent.isValid()) {
      throw NoteCreationException(noteContent.validValue.left.message ?? 'Invalid content');
    }

    final note = Note(
      id: noteId,
      ownerId: ownerId,
      title: noteTitle,
      content: noteContent,
      createdAt: now,
      updatedAt: now,
      isEncrypted: encrypt,
    );

    note.addDomainEvent(NoteCreatedEvent(
      noteId: noteId,
      ownerId: ownerId,
      title: title,
      isEncrypted: encrypt,
    ));

    return note;
  }

  void updateTitle(String newTitle) {
    final oldTitle = title.value;
    final newNoteTitle = NoteTitle(newTitle);
    
    if (!newNoteTitle.isValid()) {
      throw NoteTitleUpdateException(newNoteTitle.validValue.left.message ?? 'Invalid title');
    }

    title = newNoteTitle;
    updatedAt = DateTime.now();
    
    addDomainEvent(NoteTitleUpdatedEvent(
      noteId: id,
      oldTitle: oldTitle,
      newTitle: newTitle,
    ));
  }

  void updateContent(String newContent) {
    final oldContent = content.value;
    final newNoteContent = NoteContent(newContent);
    
    if (!newNoteContent.isValid()) {
      throw NoteContentUpdateException(newNoteContent.validValue.left.message ?? 'Invalid content');
    }

    content = newNoteContent;
    updatedAt = DateTime.now();
    
    addDomainEvent(NoteContentUpdatedEvent(
      noteId: id,
      previousLength: oldContent.length,
      newLength: newContent.length,
    ));
  }

  void shareWith(UserId userId) {
    if (userId == ownerId) {
      throw NoteSharingException('Cannot share note with yourself');
    }
    if (sharedWith.contains(userId)) {
      throw NoteSharingException('Note already shared with this user');
    }
    if (isDeleted) {
      throw NoteSharingException('Cannot share deleted note');
    }

    sharedWith.add(userId);
    updatedAt = DateTime.now();
    
    addDomainEvent(NoteSharedEvent(
      noteId: id,
      sharedWithUserId: userId,
      sharedByUserId: ownerId,
    ));
  }

  void unshareWith(UserId userId) {
    if (!sharedWith.contains(userId)) {
      throw NoteSharingException('Note not shared with this user');
    }

    sharedWith.remove(userId);
    updatedAt = DateTime.now();
    
    addDomainEvent(NoteUnsharedEvent(
      noteId: id,
      unsharedWithUserId: userId,
    ));
  }

  void markAsDeleted() {
    if (isDeleted) {
      throw NoteDeletionException('Note is already deleted');
    }

    isDeleted = true;
    updatedAt = DateTime.now();
    
    addDomainEvent(NoteDeletedEvent(
      noteId: id,
      deletedByUserId: ownerId,
    ));
  }

  void restore() {
    if (!isDeleted) {
      throw NoteRestoreException('Note is not deleted');
    }

    isDeleted = false;
    updatedAt = DateTime.now();
    
    addDomainEvent(NoteRestoredEvent(noteId: id));
  }

  void encrypt() {
    if (isEncrypted) {
      throw NoteEncryptionException('Note is already encrypted');
    }

    isEncrypted = true;
    updatedAt = DateTime.now();
    
    addDomainEvent(NoteEncryptedEvent(noteId: id));
  }

  void decrypt() {
    if (!isEncrypted) {
      throw NoteEncryptionException('Note is not encrypted');
    }

    isEncrypted = false;
    updatedAt = DateTime.now();
    
    addDomainEvent(NoteDecryptedEvent(noteId: id));
  }

  void addTag(String tag) {
    final normalizedTag = tag.trim().toLowerCase();
    if (normalizedTag.isEmpty) {
      throw NoteTagException('Tag cannot be empty');
    }
    if (tags.contains(normalizedTag)) {
      throw NoteTagException('Tag already exists');
    }
    if (tags.length >= 10) {
      throw NoteTagException('Maximum number of tags reached');
    }

    tags.add(normalizedTag);
    updatedAt = DateTime.now();
    
    addDomainEvent(NoteTaggedEvent(noteId: id, tag: normalizedTag));
  }

  void removeTag(String tag) {
    final normalizedTag = tag.trim().toLowerCase();
    if (!tags.contains(normalizedTag)) {
      throw NoteTagException('Tag does not exist');
    }

    tags.remove(normalizedTag);
    updatedAt = DateTime.now();
    
    addDomainEvent(NoteUntaggedEvent(noteId: id, tag: normalizedTag));
  }

  bool canBeAccessedBy(UserId userId) {
    return ownerId == userId || sharedWith.contains(userId);
  }

  bool canBeEditedBy(UserId userId) {
    return ownerId == userId;
  }
}

class NoteInvariantException implements Exception {
  final String message;
  NoteInvariantException(this.message);
}

class NoteCreationException implements Exception {
  final String message;
  NoteCreationException(this.message);
}

class NoteTitleUpdateException implements Exception {
  final String message;
  NoteTitleUpdateException(this.message);
}

class NoteContentUpdateException implements Exception {
  final String message;
  NoteContentUpdateException(this.message);
}

class NoteSharingException implements Exception {
  final String message;
  NoteSharingException(this.message);
}

class NoteDeletionException implements Exception {
  final String message;
  NoteDeletionException(this.message);
}

class NoteRestoreException implements Exception {
  final String message;
  NoteRestoreException(this.message);
}

class NoteEncryptionException implements Exception {
  final String message;
  NoteEncryptionException(this.message);
}

class NoteTagException implements Exception {
  final String message;
  NoteTagException(this.message);
}