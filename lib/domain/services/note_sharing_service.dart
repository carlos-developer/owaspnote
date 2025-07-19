import '../note/note_aggregate.dart';
import '../note/note_repository.dart';
import '../user/user_aggregate.dart';
import '../user/user_repository.dart';
import '../user/user_id.dart';

class NoteSharingService {
  final NoteRepository noteRepository;
  final UserRepository userRepository;

  NoteSharingService({
    required this.noteRepository,
    required this.userRepository,
  });

  Future<SharingResult> shareNote({
    required Note note,
    required User sharingUser,
    required String targetUsername,
  }) async {
    if (!note.canBeEditedBy(sharingUser.id)) {
      return SharingResult.failure('You do not have permission to share this note');
    }

    final targetUser = await userRepository.findByUsername(targetUsername);
    if (targetUser == null) {
      return SharingResult.failure('User not found');
    }

    if (!targetUser.isEmailVerified) {
      return SharingResult.failure('Cannot share with unverified users');
    }

    if (targetUser.isLocked) {
      return SharingResult.failure('Cannot share with locked users');
    }

    try {
      note.shareWith(targetUser.id);
      await noteRepository.save(note);
      return SharingResult.success(targetUser);
    } catch (e) {
      return SharingResult.failure(e.toString());
    }
  }

  Future<SharingResult> unshareNote({
    required Note note,
    required User unsharingUser,
    required UserId targetUserId,
  }) async {
    if (!note.canBeEditedBy(unsharingUser.id)) {
      return SharingResult.failure('You do not have permission to unshare this note');
    }

    final targetUser = await userRepository.findById(targetUserId);
    if (targetUser == null) {
      return SharingResult.failure('User not found');
    }

    try {
      note.unshareWith(targetUserId);
      await noteRepository.save(note);
      return SharingResult.success(targetUser);
    } catch (e) {
      return SharingResult.failure(e.toString());
    }
  }

  Future<BulkSharingResult> shareMultipleNotes({
    required List<Note> notes,
    required User sharingUser,
    required String targetUsername,
  }) async {
    final targetUser = await userRepository.findByUsername(targetUsername);
    if (targetUser == null) {
      return BulkSharingResult.failure('User not found');
    }

    final results = <Note, bool>{};
    final errors = <Note, String>{};

    for (final note in notes) {
      try {
        if (!note.canBeEditedBy(sharingUser.id)) {
          results[note] = false;
          errors[note] = 'No permission';
          continue;
        }

        note.shareWith(targetUser.id);
        await noteRepository.save(note);
        results[note] = true;
      } catch (e) {
        results[note] = false;
        errors[note] = e.toString();
      }
    }

    final successCount = results.values.where((v) => v).length;
    final failureCount = results.values.where((v) => !v).length;

    return BulkSharingResult(
      totalNotes: notes.length,
      successCount: successCount,
      failureCount: failureCount,
      results: results,
      errors: errors,
    );
  }
}

class SharingResult {
  final bool isSuccess;
  final User? targetUser;
  final String? errorMessage;

  SharingResult._({
    required this.isSuccess,
    this.targetUser,
    this.errorMessage,
  });

  factory SharingResult.success(User targetUser) {
    return SharingResult._(
      isSuccess: true,
      targetUser: targetUser,
    );
  }

  factory SharingResult.failure(String message) {
    return SharingResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

class BulkSharingResult {
  final int totalNotes;
  final int successCount;
  final int failureCount;
  final Map<Note, bool> results;
  final Map<Note, String> errors;

  BulkSharingResult({
    required this.totalNotes,
    required this.successCount,
    required this.failureCount,
    required this.results,
    required this.errors,
  });

  factory BulkSharingResult.failure(String message) {
    return BulkSharingResult(
      totalNotes: 0,
      successCount: 0,
      failureCount: 0,
      results: {},
      errors: {},
    );
  }

  bool get isCompleteSuccess => successCount == totalNotes;
  bool get isCompleteFailure => failureCount == totalNotes;
  bool get isPartialSuccess => successCount > 0 && failureCount > 0;
}