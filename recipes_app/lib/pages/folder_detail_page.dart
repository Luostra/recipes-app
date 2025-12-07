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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
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
      _isLoading = false;
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
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _supabaseService.deleteRecipe(recipe.id);
      await _loadRecipes();
    }
  }

  Future<void> _toggleFavorite(Recipe recipe) async {
    await _supabaseService.toggleFavorite(recipe.id, !recipe.isFavour);
    await _loadRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.folder.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRecipes,
              child: _recipes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.folder.emoji,
                            style: const TextStyle(fontSize: 64),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'В этой папке пока нет рецептов',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.folder.id == 'favorites'
                                ? 'Добавляйте рецепты в избранное, нажимая на звездочку'
                                : 'Нажмите + чтобы добавить первый рецепт',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _recipes.length,
                      itemBuilder: (context, index) {
                        final recipe = _recipes[index];
                        return RecipeItem(
                          recipe: recipe,
                          onTap: () => _navigateToRecipe(recipe),
                          onDelete: widget.folder.id == 'favorites'
                              ? null
                              : () => _deleteRecipe(recipe),
                          onEdit: () => _editRecipe(recipe),
                          onToggleFavorite: () => _toggleFavorite(recipe),
                        );
                      },
                    ),
            ),
      floatingActionButton: widget.folder.id == 'favorites'
          ? null
          : FloatingActionButton(
              onPressed: _createNewRecipe,
              child: const Icon(Icons.add),
            ),
    );
  }
}
