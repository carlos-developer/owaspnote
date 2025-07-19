import '../core/repository.dart';
import '../user/user_id.dart';
import 'note_aggregate.dart';
import 'note_id.dart';

abstract class NoteRepository extends Repository<Note, NoteId> {
  Future<List<Note>> findByOwnerId(UserId ownerId);
  Future<List<Note>> findSharedWithUser(UserId userId);
  Future<List<Note>> findByOwnerIdAndTag(UserId ownerId, String tag);
  Future<List<Note>> searchNotes(UserId userId, String searchTerm);
  Future<List<Note>> findDeletedNotes(UserId ownerId);
  Future<int> countNotesByOwner(UserId ownerId);
  Future<bool> existsWithTitle(UserId ownerId, String title);
}