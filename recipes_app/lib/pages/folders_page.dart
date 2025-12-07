import 'package:flutter/material.dart';
import 'package:recipes_app/models/folder.dart';
import 'package:recipes_app/services/supabase_service.dart';
import 'package:recipes_app/pages/folder_detail_page.dart';
import 'package:recipes_app/pages/create_edit_folder_page.dart';
import 'package:recipes_app/widgets/folder_item.dart';
import 'package:recipes_app/widgets/app_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FoldersPage extends StatefulWidget {
  const FoldersPage({super.key});

  @override
  State<FoldersPage> createState() => _FoldersPageState();
}

class _FoldersPageState extends State<FoldersPage> {
  final SupabaseService _supabaseService = SupabaseService();
  final List<Folder> _folders = [];
  final Folder _favoritesFolder = Folder(
    id: 'favorites',
    userId: '',
    title: 'Избранное',
    description: 'Ваши избранные рецепты',
    emoji: '⭐',
    createdAt: DateTime.now(),
  );

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() => _isLoading = true);
    final folders = await _supabaseService.getUserFolders();
    setState(() {
      _folders.clear();
      _folders.addAll(folders);
      _isLoading = false;
    });
  }

  void _navigateToFolder(Folder folder) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FolderDetailPage(folder: folder)),
    );
  }

  void _createNewFolder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateEditFolderPage()),
    );

    if (result == true) {
      await _loadFolders();
    }
  }

  void _editFolder(Folder folder) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEditFolderPage(folder: folder),
      ),
    );

    if (result == true) {
      await _loadFolders();
    }
  }

  void _deleteFolder(Folder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить папку?'),
        content: const Text('Все рецепты в этой папке также будут удалены.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _supabaseService.deleteFolder(folder.id);
      await _loadFolders();
    }
  }

  String? _userEmail() {
    final session = Supabase.instance.client.auth.currentSession;
    final email = session?.user.email;
    return email ?? 'Гость';
  }

  void _signOut() async {
    await _supabaseService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои папки'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: AppDrawer(
        userEmail: _userEmail(),
        onSignOut: _signOut,
        title: 'RecipesApp',
        subtitle: 'Ваша кулинарная книга',
        icon: Icons.restaurant_menu,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFolders,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _folders.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return GestureDetector(
                      onTap: () => _navigateToFolder(_favoritesFolder),
                      child: FolderItem(
                        folder: _favoritesFolder,
                        onDelete: null,
                        onEdit: null,
                        isFavorites: true,
                      ),
                    );
                  }

                  final folder = _folders[index - 1];
                  return FolderItem(
                    folder: folder,
                    onDelete: () => _deleteFolder(folder),
                    onEdit: () => _editFolder(folder),
                    onTap: () => _navigateToFolder(folder),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewFolder,
        child: const Icon(Icons.add),
      ),
    );
  }
}
