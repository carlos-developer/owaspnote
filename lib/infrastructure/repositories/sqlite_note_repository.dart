import 'package:sqflite/sqflite.dart';
import '../../domain/note/note_aggregate.dart';
import '../../domain/note/note_repository.dart';
import '../../domain/note/note_id.dart';
import '../../domain/note/note_title.dart';
import '../../domain/note/note_content.dart';
import '../../domain/user/user_id.dart';

class SqliteNoteRepository implements NoteRepository {
  final Database database;

  SqliteNoteRepository({required this.database});

  @override
  Future<Note?> findById(NoteId id) async {
    final maps = await database.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id.value],
    );

    if (maps.isEmpty) return null;

    return _mapToNote(maps.first);
  }

  @override
  Future<List<Note>> findAll() async {
    final maps = await database.query('notes');
    return maps.map((map) => _mapToNote(map)).toList();
  }

  @override
  Future<void> save(Note entity) async {
    final map = _noteToMap(entity);
    
    await database.insert(
      'notes',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _saveSharedUsers(entity);
    await _saveTags(entity);
  }

  @override
  Future<void> delete(Note entity) async {
    await database.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [entity.id.value],
    );
  }

  @override
  Future<List<Note>> findByOwnerId(UserId ownerId) async {
    final maps = await database.query(
      'notes',
      where: 'owner_id = ?',
      whereArgs: [ownerId.value],
    );

    final notes = <Note>[];
    for (final map in maps) {
      final note = await _mapToNoteWithRelations(map);
      notes.add(note);
    }
    return notes;
  }

  @override
  Future<List<Note>> findSharedWithUser(UserId userId) async {
    final maps = await database.rawQuery('''
      SELECT n.* FROM notes n
      INNER JOIN note_shares ns ON n.id = ns.note_id
      WHERE ns.user_id = ?
    ''', [userId.value]);

    final notes = <Note>[];
    for (final map in maps) {
      final note = await _mapToNoteWithRelations(map);
      notes.add(note);
    }
    return notes;
  }

  @override
  Future<List<Note>> findByOwnerIdAndTag(UserId ownerId, String tag) async {
    final maps = await database.rawQuery('''
      SELECT n.* FROM notes n
      INNER JOIN note_tags nt ON n.id = nt.note_id
      WHERE n.owner_id = ? AND nt.tag = ?
    ''', [ownerId.value, tag]);

    final notes = <Note>[];
    for (final map in maps) {
      final note = await _mapToNoteWithRelations(map);
      notes.add(note);
    }
    return notes;
  }

  @override
  Future<List<Note>> searchNotes(UserId userId, String searchTerm) async {
    final maps = await database.rawQuery('''
      SELECT DISTINCT n.* FROM notes n
      LEFT JOIN note_shares ns ON n.id = ns.note_id
      WHERE (n.owner_id = ? OR ns.user_id = ?)
      AND (n.title LIKE ? OR n.content LIKE ?)
      AND n.is_deleted = 0
    ''', [userId.value, userId.value, '%$searchTerm%', '%$searchTerm%']);

    final notes = <Note>[];
    for (final map in maps) {
      final note = await _mapToNoteWithRelations(map);
      notes.add(note);
    }
    return notes;
  }

  @override
  Future<List<Note>> findDeletedNotes(UserId ownerId) async {
    final maps = await database.query(
      'notes',
      where: 'owner_id = ? AND is_deleted = ?',
      whereArgs: [ownerId.value, 1],
    );

    final notes = <Note>[];
    for (final map in maps) {
      final note = await _mapToNoteWithRelations(map);
      notes.add(note);
    }
    return notes;
  }

  @override
  Future<int> countNotesByOwner(UserId ownerId) async {
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM notes WHERE owner_id = ?',
      [ownerId.value],
    );
    return result.first['count'] as int;
  }

  @override
  Future<bool> existsWithTitle(UserId ownerId, String title) async {
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM notes WHERE owner_id = ? AND title = ?',
      [ownerId.value, title],
    );
    return (result.first['count'] as int) > 0;
  }

  Future<void> _saveSharedUsers(Note note) async {
    await database.delete(
      'note_shares',
      where: 'note_id = ?',
      whereArgs: [note.id.value],
    );

    for (final userId in note.sharedWith) {
      await database.insert('note_shares', {
        'note_id': note.id.value,
        'user_id': userId.value,
      });
    }
  }

  Future<void> _saveTags(Note note) async {
    await database.delete(
      'note_tags',
      where: 'note_id = ?',
      whereArgs: [note.id.value],
    );

    for (final tag in note.tags) {
      await database.insert('note_tags', {
        'note_id': note.id.value,
        'tag': tag,
      });
    }
  }

  Future<Note> _mapToNoteWithRelations(Map<String, dynamic> map) async {
    final note = _mapToNote(map);
    
    final sharesMaps = await database.query(
      'note_shares',
      where: 'note_id = ?',
      whereArgs: [note.id.value],
    );
    
    final sharedWith = sharesMaps
        .map((m) => UserId(m['user_id'] as String))
        .toSet();

    final tagsMaps = await database.query(
      'note_tags',
      where: 'note_id = ?',
      whereArgs: [note.id.value],
    );
    
    final tags = tagsMaps
        .map((m) => m['tag'] as String)
        .toList();

    return Note(
      id: note.id,
      ownerId: note.ownerId,
      title: note.title,
      content: note.content,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      isEncrypted: note.isEncrypted,
      isDeleted: note.isDeleted,
      sharedWith: sharedWith,
      tags: tags,
    );
  }

  Note _mapToNote(Map<String, dynamic> map) {
    return Note(
      id: NoteId(map['id'] as String),
      ownerId: UserId(map['owner_id'] as String),
      title: NoteTitle(map['title'] as String),
      content: NoteContent(map['content'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isEncrypted: map['is_encrypted'] == 1,
      isDeleted: map['is_deleted'] == 1,
    );
  }

  Map<String, dynamic> _noteToMap(Note note) {
    return {
      'id': note.id.value,
      'owner_id': note.ownerId.value,
      'title': note.title.value,
      'content': note.content.value,
      'created_at': note.createdAt.toIso8601String(),
      'updated_at': note.updatedAt.toIso8601String(),
      'is_encrypted': note.isEncrypted ? 1 : 0,
      'is_deleted': note.isDeleted ? 1 : 0,
    };
  }
}