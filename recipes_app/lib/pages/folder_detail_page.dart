import 'package:flutter/material.dart';
import 'package:recipes_app/models/folder.dart';
import 'package:recipes_app/models/recipe.dart';
import 'package:recipes_app/services/supabase_service.dart';
import 'package:recipes_app/pages/create_edit_recipe_page.dart';
import 'package:recipes_app/pages/recipe_detail_page.dart';
import 'package:recipes_app/widgets/recipe_item.dart';

class FolderDetailPage extends StatefulWidget {
  final Folder folder;

  const FolderDetailPage({super.key, required this.folder});

  @override
  State<FolderDetailPage> createState() => _FolderDetailPageState();
}

class _FolderDetailPageState extends State<FolderDetailPage> {
  final SupabaseService _supabaseService = SupabaseService();
  final List<Recipe> _recipes = [];
  final List<Recipe> _filteredRecipes = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRecipes();

    // Слушатель для поиска
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterRecipes(_searchController.text);
  }

  void _filterRecipes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRecipes.clear();
        _filteredRecipes.addAll(_recipes);
      } else {
        _filteredRecipes.clear();
        _filteredRecipes.addAll(
          _recipes.where((recipe) {
            return recipe.title.toLowerCase().contains(query.toLowerCase()) ||
                recipe.content.toLowerCase().contains(query.toLowerCase());
          }).toList(),
        );
      }
    });
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);
    List<Recipe> recipes;

    if (widget.folder.id == 'favorites') {
      recipes = await _supabaseService.getFavoriteRecipes();
    } else {
      recipes = await _supabaseService.getRecipesByFolder(widget.folder.id);
    }

    setState(() {
      _recipes.clear();
      _recipes.addAll(recipes);
      _filteredRecipes.clear();
      _filteredRecipes.addAll(recipes);
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

  void _navigateToRecipe(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RecipeDetailPage(recipe: recipe)),
    );
  }

  void _createNewRecipe() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEditRecipePage(folderId: widget.folder.id),
      ),
    );

    if (result == true) {
      await _loadRecipes();
    }
  }

  void _editRecipe(Recipe recipe) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEditRecipePage(recipe: recipe),
      ),
    );

    if (result == true) {
      await _loadRecipes();
    }
  }

  void _deleteRecipe(Recipe recipe) async {
    // Удаляем рецепт (подтверждение уже показывается в Dismissible.confirmDismiss)
    await _supabaseService.deleteRecipe(recipe.id);

    // Показать одно уведомление о результате
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Рецепт удалён')));

    // Обновить список
    await _loadRecipes();
  }

  Future<void> _toggleFavorite(Recipe recipe) async {
    await _supabaseService.toggleFavorite(recipe.id, !recipe.isFavour);
    await _loadRecipes();
  }

  void _backToFolders() {
    Navigator.pop(context);
  }

  List<Recipe> _getDisplayRecipes() {
    return _searchController.text.isEmpty ? _recipes : _filteredRecipes;
  }

  @override
  Widget build(BuildContext context) {
    final displayRecipes = _getDisplayRecipes();

    return Scaffold(
      appBar: _isSearching ? _buildSearchAppBar() : _buildNormalAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRecipes,
              child: displayRecipes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_searchController.text.isEmpty)
                            Text(
                              widget.folder.emoji,
                              style: const TextStyle(fontSize: 64),
                            )
                          else
                            const Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'В этой папке пока нет рецептов'
                                : 'Рецепты не найдены',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchController.text.isEmpty
                                ? widget.folder.id == 'favorites'
                                      ? 'Добавляйте рецепты в избранное, нажимая на звездочку'
                                      : 'Нажмите + чтобы добавить первый рецепт'
                                : 'Попробуйте изменить запрос поиска',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: displayRecipes.length,
                      // В методе build, в ListView.builder:
                      itemBuilder: (context, index) {
                        final recipe = displayRecipes[index];
                        return RecipeItem(
                          recipe: recipe,
                          onTap: () => _navigateToRecipe(recipe),
                          onDelete: widget.folder.id == 'favorites'
                              ? null // В папке "Избранное" не удаляем рецепты
                              : () => _deleteRecipe(recipe),
                          onEdit: () => _editRecipe(recipe),
                          onToggleFavorite: () => _toggleFavorite(recipe),
                          isInFavoritesFolder:
                              widget.folder.id ==
                              'favorites', // Передаем true для папки "Избранное"
                        );
                      },
                    ),
            ),
      floatingActionButton: (_isSearching || widget.folder.id == 'favorites')
          ? null
          : FloatingActionButton(
              onPressed: _createNewRecipe,
              child: const Icon(Icons.add),
            ),
    );
  }

  AppBar _buildNormalAppBar() {
    return AppBar(
      title: Text(widget.folder.title),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _backToFolders,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _startSearch,
          tooltip: 'Поиск рецептов',
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
          hintText: 'Поиск рецептов...',
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
