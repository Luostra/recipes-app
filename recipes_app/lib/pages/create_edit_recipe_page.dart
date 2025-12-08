import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recipes_app/models/recipe.dart';
import 'package:recipes_app/services/supabase_service.dart';
import 'package:recipes_app/services/image_service.dart';
import 'dart:io';

class CreateEditRecipePage extends StatefulWidget {
  final String? folderId;
  final Recipe? recipe;

  const CreateEditRecipePage({super.key, this.folderId, this.recipe});

  @override
  State<CreateEditRecipePage> createState() => _CreateEditRecipePageState();
}

class _CreateEditRecipePageState extends State<CreateEditRecipePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();
  final ImageService _imageService = ImageService();
  File? _selectedImage;
  String _imagePath = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.recipe != null) {
      _titleController.text = widget.recipe!.title;
      _contentController.text = widget.recipe!.content;
      _imagePath = widget.recipe!.imagePath;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Сделать фото'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Выбрать из галереи'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      File? imageFile;
      if (source == ImageSource.camera) {
        imageFile = await _imageService.takeAndCropPhoto();
      } else {
        imageFile = await _imageService.pickAndCropImage();
      }

      if (imageFile != null && mounted) {
        setState(() => _selectedImage = imageFile);
      }
    }
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String imagePath = widget.recipe?.imagePath ?? '';

      // Upload image if selected
      if (_selectedImage != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final uploadedPath = await _supabaseService.uploadImage(
          _selectedImage!,
          fileName,
        );
        if (uploadedPath != null) {
          imagePath = uploadedPath;

          // Удаляем старое изображение если оно было
          if (widget.recipe?.imagePath.isNotEmpty == true &&
              widget.recipe?.imagePath != uploadedPath) {
            await _supabaseService.deleteImage(widget.recipe!.imagePath);
          }
        }
      }

      if (widget.recipe == null) {
        // Создаем новый рецепт - НЕ передаем ID
        final recipe = Recipe(
          id: '', // Оставляем пустым, Supabase сам сгенерирует
          folderId: widget.folderId!,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          isFavour: false,
          imagePath: imagePath,
          createdAt: DateTime.now(),
        );

        await _supabaseService.createRecipe(recipe);
      } else {
        // Обновляем существующий рецепт
        final recipe = Recipe(
          id: widget.recipe!.id,
          folderId: widget.recipe!.folderId,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          isFavour: widget.recipe!.isFavour,
          imagePath: imagePath,
          createdAt: widget.recipe!.createdAt,
        );

        await _supabaseService.updateRecipe(recipe);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imagePath = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.recipe == null ? 'Новый рецепт' : 'Редактировать рецепт',
        ),
        actions: [
          if (!_isLoading)
            IconButton(onPressed: _saveRecipe, icon: const Icon(Icons.check)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Image preview
                    if (_selectedImage != null || _imagePath.isNotEmpty)
                      Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 400,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[200],
                            ),
                            child: _selectedImage != null
                                ? Image.file(_selectedImage!, fit: BoxFit.cover)
                                : FutureBuilder<String?>(
                                    future: _supabaseService.getImageUrl(
                                      _imagePath,
                                    ),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                      if (snapshot.hasData &&
                                          snapshot.data != null) {
                                        return Image.network(
                                          snapshot.data!,
                                          fit: BoxFit.cover,
                                        );
                                      }
                                      return const Center(
                                        child: Icon(
                                          Icons.photo,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: _removeImage,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[200],
                          border: Border.all(
                            color: const Color.fromARGB(255, 224, 224, 224),
                          ),
                        ),
                        child: TextButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Добавить фото готового блюда'),
                        ),
                      ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Название блюда',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите название блюда';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'Рецепт',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 15,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите рецепт';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
