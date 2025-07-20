import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user.dart';
import '../models/note.dart';
import '../services/notes_service.dart';
import '../security/security_config.dart';

/// Pantalla para crear/editar notas
class NoteScreen extends StatefulWidget {
  final User user;
  final Note? note;
  
  const NoteScreen({
    super.key,
    required this.user,
    this.note,
  });

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  bool _isLoading = false;
  bool _encryptContent = true;
  bool _hasUnsavedChanges = false;
  
  @override
  void initState() {
    super.initState();
    
    // Si es edición, carga los datos
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _encryptContent = widget.note!.isEncrypted;
    }
    
    // Listeners para detectar cambios
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }
  
  void _onTextChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }
  
  /// MITIGACIÓN M10: Funcionalidad superflua
  /// Pregunta antes de salir si hay cambios sin guardar
  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // MITIGACIÓN M7: Mala calidad del código
      // Sanitiza entrada antes de guardar
      final sanitizedTitle = SecurityConfig.sanitizeInput(_titleController.text.trim());
      final sanitizedContent = SecurityConfig.sanitizeInput(_contentController.text.trim());
      
      if (widget.note == null) {
        // Crear nueva nota
        await NotesService.createNote(
          currentUser: widget.user,
          title: sanitizedTitle,
          content: sanitizedContent,
          encrypt: _encryptContent,
        );
        
        _showSuccess('Note created successfully');
      } else {
        // Actualizar nota existente
        await NotesService.updateNote(
          currentUser: widget.user,
          noteId: widget.note!.id,
          title: sanitizedTitle,
          content: sanitizedContent,
          encrypt: _encryptContent,
        );
        
        _showSuccess('Note updated successfully');
      }
      
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showError('Failed to save note: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
          actions: [
            // Indicador de cifrado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Chip(
                avatar: Icon(
                  _encryptContent ? Icons.lock : Icons.lock_open,
                  size: 18,
                  color: _encryptContent ? Colors.green : Colors.orange,
                ),
                label: Text(_encryptContent ? 'Encrypted' : 'Not Encrypted'),
                backgroundColor: _encryptContent
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
            
            // Botón de guardar
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _saveNote,
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              // Switch de cifrado
              Container(
                color: Theme.of(context).primaryColor,
                child: SwitchListTile(
                  title: const Text('Encrypt this note'),
                  subtitle: const Text(
                    'Enable to encrypt the content with AES-256',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _encryptContent,
                  onChanged: (value) {
                    setState(() {
                      _encryptContent = value;
                      _hasUnsavedChanges = true;
                    });
                  },
                  secondary: Icon(
                    _encryptContent ? Icons.security : Icons.warning_amber,
                    color: _encryptContent ? Colors.green : Colors.orange,
                  ),
                ),
              ),
              
              // Campos del formulario
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Campo de título
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'Enter note title',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        // MITIGACIÓN M7: Límite de entrada
                        maxLength: 100,
                        inputFormatters: [
                          // Previene caracteres peligrosos
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9\s\-._]'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          if (value.trim().length < 3) {
                            return 'Title must be at least 3 characters';
                          }
                          return null;
                        },
                        enabled: !_isLoading,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Campo de contenido
                      TextFormField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          labelText: 'Content',
                          hintText: 'Enter your note content',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: null,
                        minLines: 10,
                        // MITIGACIÓN M7: Límite de entrada para prevenir DoS
                        maxLength: 10000,
                        inputFormatters: [
                          // Permite más caracteres pero previene scripts
                          FilteringTextInputFormatter.deny(
                            RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter some content';
                          }
                          return null;
                        },
                        enabled: !_isLoading,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Información de seguridad
                      if (_encryptContent)
                        Card(
                          color: Colors.green,
                          child: const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'This note will be encrypted with AES-256 before '
                                    'being stored. Only you can decrypt and read it.',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Card(
                          color: Colors.orange,
                          child: const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'This note will be stored without encryption. '
                                    'Consider enabling encryption for sensitive information.',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 20),
                      
                      // Información de validación
                      if (widget.note != null && widget.note!.contentHash != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(
                                  widget.note!.verifyIntegrity()
                                      ? Icons.verified_user
                                      : Icons.error,
                                  color: widget.note!.verifyIntegrity()
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.note!.verifyIntegrity()
                                        ? 'Note integrity verified'
                                        : 'Note integrity check failed',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: widget.note!.verifyIntegrity()
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _titleController.removeListener(_onTextChanged);
    _contentController.removeListener(_onTextChanged);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}

/// VULNERABILIDAD POTENCIAL (si no se implementara):
/// - M5: Almacenar notas sin cifrado
/// - M7: No validar/sanitizar entrada (XSS, inyecciones)
/// - M7: No limitar tamaño de entrada (DoS)
/// - M8: No verificar integridad de notas
/// 
/// HERRAMIENTAS DE PENTESTING:
/// - Burp Suite: Para fuzzing de campos
/// - XSSer: Para probar XSS en campos de texto
/// - SQLMap: Para inyección SQL
/// - Wireshark: Para verificar cifrado en tránsito