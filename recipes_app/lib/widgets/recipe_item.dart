import 'package:flutter/material.dart';
import 'package:recipes_app/models/recipe.dart';
import 'package:recipes_app/services/supabase_service.dart';
//import 'package:supabase_flutter/supabase_flutter.dart';

class RecipeItem extends StatefulWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback onToggleFavorite;
  final bool isInFavoritesFolder; // Новый параметр

  const RecipeItem({
    super.key,
    required this.recipe,
    required this.onTap,
    this.onDelete,
    this.onEdit,
    required this.onToggleFavorite,
    this.isInFavoritesFolder = false, // По умолчанию false
  });

  @override
  State<RecipeItem> createState() => _RecipeItemState();
}

class _RecipeItemState extends State<RecipeItem> {
  final SupabaseService _supabaseService = SupabaseService();
  String? _imageUrl;
  bool _isLoadingImage = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    if (widget.recipe.imagePath.isNotEmpty) {
      try {
        // Используем public URL если bucket публичный
        // или signed URL если приватный
        final url = await _supabaseService.getImageUrl(widget.recipe.imagePath);
        setState(() {
          _imageUrl = url;
          _isLoadingImage = false;
        });
      } catch (e) {
        print('Error loading image: $e');
        setState(() => _isLoadingImage = false);
      }
    } else {
      setState(() => _isLoadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _buildLeading(),
        title: Text(
          widget.recipe.title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          widget.recipe.content.length > 100
              ? '${widget.recipe.content.substring(0, 100)}...'
              : widget.recipe.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        trailing: IconButton(
          icon: Icon(
            widget.recipe.isFavour ? Icons.star : Icons.star_border,
            color: widget.recipe.isFavour ? Colors.amber : Colors.grey,
          ),
          onPressed: widget.onToggleFavorite,
        ),
        onTap: widget.onTap,
      ),
    );

    // Если рецепт в папке "Избранное", не используем Dismissible
    if (widget.isInFavoritesFolder) {
      return content;
    }

    // Для обычных папок используем Dismissible
    return Dismissible(
      key: Key(widget.recipe.id),
      direction: DismissDirection.horizontal,
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Удалить рецепт?'),
              content: const Text('Это действие нельзя отменить.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Удалить',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
          return confirmed ?? false;
        }
        return true;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          widget.onDelete?.call();
        } else if (direction == DismissDirection.startToEnd) {
          widget.onEdit?.call();
        }
      },
      child: content,
    );
  }

  Widget _buildLeading() {
    if (_isLoadingImage) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          _imageUrl!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.photo, color: Colors.grey),
            );
          },
        ),
      );
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.photo, color: Colors.grey),
    );
  }
}
