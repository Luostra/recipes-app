import 'package:flutter/material.dart';
import 'package:recipes_app/models/folder.dart';

class FolderItem extends StatelessWidget {
  final Folder folder;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;
  final bool isFavorites;

  const FolderItem({
    super.key,
    required this.folder,
    this.onDelete,
    this.onEdit,
    this.onTap,
    this.isFavorites = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(folder.id),
      direction: isFavorites
          ? DismissDirection.none
          : DismissDirection.horizontal,
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
              title: const Text('Удалить папку?'),
              content: const Text(
                'Все рецепты в этой папке также будут удалены.',
              ),
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
          onDelete?.call();
        } else if (direction == DismissDirection.startToEnd) {
          onEdit?.call();
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Text(folder.emoji, style: const TextStyle(fontSize: 32)),
          title: Text(
            folder.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            folder.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          trailing: isFavorites
              ? const Icon(Icons.star, color: Colors.amber)
              : const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}
