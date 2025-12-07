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
  final List<Folder> _filteredFolders = [];
  final Folder _favoritesFolder = Folder(
    id: 'favorites',
    userId: '',
    title: 'Избранное',
    description: 'Ваши избранные рецепты',
    emoji: '⭐',
    createdAt: DateTime.now(),
  );

  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFolders();

    // Слушатель для поиска
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterFolders(_searchController.text);
  }

  void _filterFolders(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFolders.clear();
        _filteredFolders.addAll(_folders);
      } else {
        _filteredFolders.clear();
        _filteredFolders.addAll(
          _folders.where((folder) {
            return folder.title.toLowerCase().contains(query.toLowerCase()) ||
                folder.description.toLowerCase().contains(query.toLowerCase());
          }).toList(),
        );
      }
    });
  }

  Future<void> _loadFolders() async {
    setState(() => _isLoading = true);
    final folders = await _supabaseService.getUserFolders();
    setState(() {
      _folders.clear();
      _folders.addAll(folders);
      _filteredFolders.clear();
      _filteredFolders.addAll(folders);
      _isLoading = false;
    });
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
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

  List<Folder> _getDisplayFolders() {
    return _searchController.text.isEmpty ? _folders : _filteredFolders;
  }

  bool _shouldShowFavorites() {
    // Показываем папку "Избранное" только если не активен поиск
    return !_isSearching && _searchController.text.isEmpty;
  }

  bool _hasSearchResults() {
    return _getDisplayFolders().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final displayFolders = _getDisplayFolders();
    final showFavorites = _shouldShowFavorites();
    final hasResults = _hasSearchResults();

    return Scaffold(
      appBar: _isSearching ? _buildSearchAppBar() : _buildNormalAppBar(),
      drawer: _isSearching
          ? null
          : AppDrawer(
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
              child: hasResults
                  ? ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          displayFolders.length + (showFavorites ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Если показываем папку "Избранное" и это первый элемент
                        if (showFavorites && index == 0) {
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

                        // Корректируем индекс для обычных папок
                        final folderIndex = showFavorites ? index - 1 : index;
                        final folder = displayFolders[folderIndex];
                        return FolderItem(
                          folder: folder,
                          onDelete: () => _deleteFolder(folder),
                          onEdit: () => _editFolder(folder),
                          onTap: () => _navigateToFolder(folder),
                        );
                      },
                    )
                  : _buildNoResultsWidget(),
            ),
      floatingActionButton: _isSearching
          ? null
          : FloatingActionButton(
              onPressed: _createNewFolder,
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildNoResultsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            'Папки не найдены',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _searchController.text.isEmpty
                ? 'У вас пока нет папок с рецептами'
                : 'По запросу "${_searchController.text}" ничего не найдено',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  AppBar _buildNormalAppBar() {
    return AppBar(
      title: const Text('Мои папки'),
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _startSearch,
          tooltip: 'Поиск папок с рецептами',
        ),
      ],
    );
  }

  AppBar _buildSearchAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _stopSearch,
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Поиск папок с рецептами...',
          hintStyle: TextStyle(color: Colors.white70),
          // Убираем фон
          filled: false,

          // Полностью убираем все рамки
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
        ),
        style: const TextStyle(color: Colors.white),
        cursorColor: Colors.white,
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
            },
          ),
      ],
    );
  }
}
