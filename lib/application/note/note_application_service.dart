import '../../domain/note/note_aggregate.dart';
import '../../domain/note/note_repository.dart';
import '../../domain/note/note_id.dart';
import '../../domain/note/note_content.dart';
import '../../domain/user/user_aggregate.dart';
import '../../domain/user/user_repository.dart';
import '../../domain/user/user_id.dart';
import '../../domain/services/encryption_service.dart';
import '../../domain/services/note_sharing_service.dart';
import '../common/application_service.dart';

class NoteApplicationService extends ApplicationService {
  final NoteRepository noteRepository;
  final UserRepository userRepository;
  final EncryptionService encryptionService;
  final NoteSharingService noteSharingService;

  NoteApplicationService({
    required this.noteRepository,
    required this.userRepository,
    required this.encryptionService,
    required this.noteSharingService,
  });

  @override
  void validate() {
    // All fields are required by constructor, no need to check for null
  }

  Future<CreateNoteResult> createNote({
    required UserId userId,
    required String title,
    String? content,
    bool encrypt = false,
    List<String>? tags,
  }) async {
    try {
      final user = await userRepository.findById(userId);
      if (user == null) {
        return CreateNoteResult.failure('User not found');
      }

      if (!user.isEmailVerified) {
        return CreateNoteResult.failure('Email must be verified to create notes');
      }

      if (user.isLocked) {
        return CreateNoteResult.failure('Account is locked');
      }

      final noteCount = await noteRepository.countNotesByOwner(userId);
      if (noteCount >= 1000) {
        return CreateNoteResult.failure('Note limit reached');
      }

      final existsWithTitle = await noteRepository.existsWithTitle(userId, title);
      if (existsWithTitle) {
        return CreateNoteResult.failure('A note with this title already exists');
      }

      String processedContent = content ?? '';
      String? encryptionKey;

      if (encrypt && processedContent.isNotEmpty) {
        encryptionKey = encryptionService.generateKey();
        processedContent = await encryptionService.encrypt(processedContent, encryptionKey);
      }

      final note = Note.create(
        ownerId: userId,
        title: title,
        content: processedContent,
        encrypt: encrypt,
      );

      if (tags != null) {
        for (final tag in tags) {
          note.addTag(tag);
        }
      }

      await noteRepository.save(note);

      return CreateNoteResult.success(
        note: note,
        encryptionKey: encryptionKey,
      );
    } catch (e) {
      return CreateNoteResult.failure(e.toString());
    }
  }

  Future<UpdateNoteResult> updateNote({
    required UserId userId,
    required String noteId,
    String? newTitle,
    String? newContent,
    List<String>? addTags,
    List<String>? removeTags,
  }) async {
    try {
      final note = await noteRepository.findById(NoteId(noteId));
      if (note == null) {
        return UpdateNoteResult.failure('Note not found');
      }

      if (!note.canBeEditedBy(userId)) {
        return UpdateNoteResult.failure('You do not have permission to edit this note');
      }

      if (newTitle != null) {
        if (newTitle != note.title.value) {
          final existsWithTitle = await noteRepository.existsWithTitle(userId, newTitle);
          if (existsWithTitle) {
            return UpdateNoteResult.failure('A note with this title already exists');
          }
        }
        note.updateTitle(newTitle);
      }

      if (newContent != null) {
        if (note.isEncrypted) {
          return UpdateNoteResult.failure('Cannot update content of encrypted note without decryption key');
        }
        note.updateContent(newContent);
      }

      if (addTags != null) {
        for (final tag in addTags) {
          note.addTag(tag);
        }
      }

      if (removeTags != null) {
        for (final tag in removeTags) {
          note.removeTag(tag);
        }
      }

      await noteRepository.save(note);

      return UpdateNoteResult.success(note);
    } catch (e) {
      return UpdateNoteResult.failure(e.toString());
    }
  }

  Future<DeleteNoteResult> deleteNote({
    required UserId userId,
    required String noteId,
  }) async {
    try {
      final note = await noteRepository.findById(NoteId(noteId));
      if (note == null) {
        return DeleteNoteResult.failure('Note not found');
      }

      if (!note.canBeEditedBy(userId)) {
        return DeleteNoteResult.failure('You do not have permission to delete this note');
      }

      note.markAsDeleted();
      await noteRepository.save(note);

      return DeleteNoteResult.success();
    } catch (e) {
      return DeleteNoteResult.failure(e.toString());
    }
  }

  Future<ShareNoteResult> shareNote({
    required UserId userId,
    required String noteId,
    required String targetUsername,
  }) async {
    try {
      final note = await noteRepository.findById(NoteId(noteId));
      if (note == null) {
        return ShareNoteResult.failure('Note not found');
      }

      final sharingUser = await userRepository.findById(userId);
      if (sharingUser == null) {
        return ShareNoteResult.failure('User not found');
      }

      final result = await noteSharingService.shareNote(
        note: note,
        sharingUser: sharingUser,
        targetUsername: targetUsername,
      );

      if (result.isSuccess) {
        return ShareNoteResult.success(result.targetUser!);
      } else {
        return ShareNoteResult.failure(result.errorMessage!);
      }
    } catch (e) {
      return ShareNoteResult.failure(e.toString());
    }
  }

  Future<GetNoteResult> getNote({
    required UserId userId,
    required String noteId,
    String? decryptionKey,
  }) async {
    try {
      final note = await noteRepository.findById(NoteId(noteId));
      if (note == null) {
        return GetNoteResult.failure('Note not found');
      }

      if (!note.canBeAccessedBy(userId)) {
        return GetNoteResult.failure('You do not have permission to access this note');
      }

      Note processedNote = note;
      
      if (note.isEncrypted && decryptionKey != null) {
        final decryptedContent = await encryptionService.decrypt(
          note.content.value,
          decryptionKey,
        );
        
        processedNote = Note(
          id: note.id,
          ownerId: note.ownerId,
          title: note.title,
          content: NoteContent(decryptedContent),
          createdAt: note.createdAt,
          updatedAt: note.updatedAt,
          isEncrypted: note.isEncrypted,
          isDeleted: note.isDeleted,
          sharedWith: note.sharedWith,
          tags: note.tags,
        );
      }

      return GetNoteResult.success(processedNote);
    } catch (e) {
      return GetNoteResult.failure(e.toString());
    }
  }

  Future<ListNotesResult> listUserNotes({
    required UserId userId,
    bool includeShared = false,
    bool includeDeleted = false,
    String? tag,
  }) async {
    try {
      final user = await userRepository.findById(userId);
      if (user == null) {
        return ListNotesResult.failure('User not found');
      }

      final ownNotes = await noteRepository.findByOwnerId(userId);
      final notes = <Note>[];

      for (final note in ownNotes) {
        if (note.isDeleted && !includeDeleted) continue;
        if (tag != null && !note.tags.contains(tag)) continue;
        notes.add(note);
      }

      if (includeShared) {
        final sharedNotes = await noteRepository.findSharedWithUser(userId);
        for (final note in sharedNotes) {
          if (note.isDeleted && !includeDeleted) continue;
          if (tag != null && !note.tags.contains(tag)) continue;
          notes.add(note);
        }
      }

      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return ListNotesResult.success(notes);
    } catch (e) {
      return ListNotesResult.failure(e.toString());
    }
  }

  Future<SearchNotesResult> searchNotes({
    required UserId userId,
    required String searchTerm,
  }) async {
    try {
      if (searchTerm.length < 3) {
        return SearchNotesResult.failure('Search term must be at least 3 characters');
      }

      final notes = await noteRepository.searchNotes(userId, searchTerm);
      
      return SearchNotesResult.success(notes);
    } catch (e) {
      return SearchNotesResult.failure(e.toString());
    }
  }
}

class CreateNoteResult {
  final bool isSuccess;
  final Note? note;
  final String? encryptionKey;
  final String? errorMessage;

  CreateNoteResult._({
    required this.isSuccess,
    this.note,
    this.encryptionKey,
    this.errorMessage,
  });

  factory CreateNoteResult.success({
    required Note note,
    String? encryptionKey,
  }) {
    return CreateNoteResult._(
      isSuccess: true,
      note: note,
      encryptionKey: encryptionKey,
    );
  }

  factory CreateNoteResult.failure(String message) {
    return CreateNoteResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

class UpdateNoteResult {
  final bool isSuccess;
  final Note? note;
  final String? errorMessage;

  UpdateNoteResult._({
    required this.isSuccess,
    this.note,
    this.errorMessage,
  });

  factory UpdateNoteResult.success(Note note) {
    return UpdateNoteResult._(
      isSuccess: true,
      note: note,
    );
  }

  factory UpdateNoteResult.failure(String message) {
    return UpdateNoteResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

class DeleteNoteResult {
  final bool isSuccess;
  final String? errorMessage;

  DeleteNoteResult._({
    required this.isSuccess,
    this.errorMessage,
  });

  factory DeleteNoteResult.success() {
    return DeleteNoteResult._(isSuccess: true);
  }

  factory DeleteNoteResult.failure(String message) {
    return DeleteNoteResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

class ShareNoteResult {
  final bool isSuccess;
  final User? sharedWithUser;
  final String? errorMessage;

  ShareNoteResult._({
    required this.isSuccess,
    this.sharedWithUser,
    this.errorMessage,
  });

  factory ShareNoteResult.success(User sharedWithUser) {
    return ShareNoteResult._(
      isSuccess: true,
      sharedWithUser: sharedWithUser,
    );
  }

  factory ShareNoteResult.failure(String message) {
    return ShareNoteResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

class GetNoteResult {
  final bool isSuccess;
  final Note? note;
  final String? errorMessage;

  GetNoteResult._({
    required this.isSuccess,
    this.note,
    this.errorMessage,
  });

  factory GetNoteResult.success(Note note) {
    return GetNoteResult._(
      isSuccess: true,
      note: note,
    );
  }

  factory GetNoteResult.failure(String message) {
    return GetNoteResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

class ListNotesResult {
  final bool isSuccess;
  final List<Note>? notes;
  final String? errorMessage;

  ListNotesResult._({
    required this.isSuccess,
    this.notes,
    this.errorMessage,
  });

  factory ListNotesResult.success(List<Note> notes) {
    return ListNotesResult._(
      isSuccess: true,
      notes: notes,
    );
  }

  factory ListNotesResult.failure(String message) {
    return ListNotesResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

class SearchNotesResult {
  final bool isSuccess;
  final List<Note>? notes;
  final String? errorMessage;

  SearchNotesResult._({
    required this.isSuccess,
    this.notes,
    this.errorMessage,
  });

  factory SearchNotesResult.success(List<Note> notes) {
    return SearchNotesResult._(
      isSuccess: true,
      notes: notes,
    );
  }

  factory SearchNotesResult.failure(String message) {
    return SearchNotesResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}