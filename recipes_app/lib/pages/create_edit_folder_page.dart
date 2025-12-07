import 'package:flutter/material.dart';
import 'package:recipes_app/models/folder.dart';
import 'package:recipes_app/services/supabase_service.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class CreateEditFolderPage extends StatefulWidget {
  final Folder? folder;

  const CreateEditFolderPage({super.key, this.folder});

  @override
  State<CreateEditFolderPage> createState() => _CreateEditFolderPageState();
}

class _CreateEditFolderPageState extends State<CreateEditFolderPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedEmoji = '📁';
  bool _isLoading = false;
  bool _showEmojiPicker = false;
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    if (widget.folder != null) {
      _titleController.text = widget.folder!.title;
      _descriptionController.text = widget.folder!.description;
      _selectedEmoji = widget.folder!.emoji;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveFolder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final folder = Folder(
        id: widget.folder?.id ?? '',
        userId: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        emoji: _selectedEmoji,
        createdAt: widget.folder?.createdAt ?? DateTime.now(),
      );

      if (widget.folder == null) {
        await _supabaseService.createFolder(folder);
      } else {
        await _supabaseService.updateFolder(folder);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.folder == null ? 'Новая папка' : 'Редактировать папку',
        ),
        actions: [
          if (!_isLoading)
            IconButton(onPressed: _saveFolder, icon: const Icon(Icons.save)),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _toggleEmojiPicker,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _selectedEmoji,
                          style: const TextStyle(fontSize: 40),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Название папки',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите название папки';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Описание папки',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  if (_isLoading) const CircularProgressIndicator(),
                ],
              ),
            ),
          ),
          if (_showEmojiPicker)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  setState(() => _selectedEmoji = emoji.emoji);
                  _toggleEmojiPicker();
                },
                config: const Config(
                  height: 256,
                  emojiViewConfig: EmojiViewConfig(
                    columns: 7,
                    emojiSizeMax: 32,
                    backgroundColor: Color(0xFFF2F2F2),
                  ),
                  categoryViewConfig: CategoryViewConfig(
                    backgroundColor: Color(0xFFF2F2F2),
                    indicatorColor: Color(0xFF2196F3),
                    iconColor: Colors.grey,
                    iconColorSelected: Color(0xFF2196F3),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
