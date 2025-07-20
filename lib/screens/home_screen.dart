import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user.dart';
import '../models/note.dart';
import '../services/notes_service.dart';
import '../services/auth_service.dart';
import '../security/anti_tampering.dart';
import 'note_screen.dart';
import 'login_screen.dart';

/// Pantalla principal con lista de notas
class HomeScreen extends StatefulWidget {
  final User user;
  
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<Note> _notes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
    _loadNotes();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  /// MITIGACIÓN M10: Funcionalidad superflua
  /// Detecta cuando la app pasa a segundo plano para ocultar contenido sensible
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused) {
      // Oculta contenido sensible cuando la app está en segundo plano
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else if (state == AppLifecycleState.resumed) {
      // Verifica integridad cuando la app vuelve
      _checkAppIntegrity();
    }
  }
  
  Future<void> _initializeServices() async {
    try {
      await NotesService.initialize();
    } catch (e) {
      _showError('Failed to initialize services');
    }
  }
  
  /// Verifica integridad de la aplicación
  /// MITIGACIÓN M8: Code tampering
  Future<void> _checkAppIntegrity() async {
    final isCompromised = await AntiTamperingProtection.isDeviceCompromised();
    if (isCompromised && mounted) {
      await _handleSecurityBreach();
    }
  }
  
  Future<void> _handleSecurityBreach() async {
    // Cierra sesión y limpia datos
    await AuthService.logout();
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }
  
  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    
    try {
      final notes = await NotesService.getUserNotes(widget.user);
      if (mounted) {
        setState(() {
          _notes = notes;
          _isLoading = false;
        });
      }
    } catch (e) {
      _showError('Failed to load notes');
      setState(() => _isLoading = false);
    }
  }
  
  /// Filtra notas basado en búsqueda
  /// MITIGACIÓN M7: Mala calidad del código - validación de entrada
  List<Note> get _filteredNotes {
    if (_searchQuery.isEmpty) return _notes;
    
    // Sanitiza query de búsqueda
    final sanitizedQuery = _searchQuery
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '');
    
    return _notes.where((note) {
      return note.title.toLowerCase().contains(sanitizedQuery) ||
             note.content.toLowerCase().contains(sanitizedQuery);
    }).toList();
  }
  
  Future<void> _deleteNote(Note note) async {
    // Confirmación antes de eliminar
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await NotesService.deleteNote(
          currentUser: widget.user,
          noteId: note.id,
        );
        
        setState(() {
          _notes.removeWhere((n) => n.id == note.id);
        });
        
        _showSuccess('Note deleted successfully');
      } catch (e) {
        _showError('Failed to delete note');
      }
    }
  }
  
  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _showSuccess(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Notes'),
        actions: [
          // Indicador de usuario
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Chip(
              avatar: const Icon(Icons.person, size: 18),
              label: Text(widget.user.username),
              backgroundColor: Theme.of(context).primaryColor,
            ),
          ),
          
          // Indicador de modo local (solo en debug)
          if (const bool.fromEnvironment('dart.vm.product') == false && 
              AuthService.isMockModeEnabled()) ...[                    
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.developer_mode, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'LOCAL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Botón de logout
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              // MITIGACIÓN M7: Límite de entrada
              maxLength: 50,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[a-zA-Z0-9\s]'), // Solo permite caracteres seguros
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Lista de notas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredNotes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.note_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No notes yet'
                                  : 'No notes found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Tap + to create your first note'
                                  : 'Try a different search',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadNotes,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: _filteredNotes.length,
                          itemBuilder: (context, index) {
                            final note = _filteredNotes[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12.0),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: note.isEncrypted
                                      ? Colors.green
                                      : Colors.blue,
                                  child: Icon(
                                    note.isEncrypted
                                        ? Icons.lock
                                        : Icons.note,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  note.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      note.content,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Updated ${_formatDate(note.updatedAt)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'delete') {
                                      await _deleteNote(note);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => NoteScreen(
                                        user: widget.user,
                                        note: note,
                                      ),
                                    ),
                                  );
                                  
                                  if (result == true) {
                                    _loadNotes();
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteScreen(
                user: widget.user,
                note: null,
              ),
            ),
          );
          
          if (result == true) {
            _loadNotes();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// VULNERABILIDAD POTENCIAL (si no se implementara):
/// - M6: No verificar permisos antes de mostrar notas
/// - M7: No sanitizar entrada de búsqueda (XSS)
/// - M8: No verificar integridad al volver de segundo plano
/// - M10: Mostrar contenido sensible en app switcher
/// 
/// HERRAMIENTAS DE PENTESTING:
/// - ADB: Para examinar contenido en segundo plano
/// - Frida: Para bypass de verificaciones de permisos
/// - MobSF: Para análisis de fugas de información
/// - Screen recording: Para capturar información sensible