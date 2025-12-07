import 'package:flutter/material.dart';
import 'package:recipes_app/models/recipe.dart';
import 'package:recipes_app/services/supabase_service.dart';
import 'package:recipes_app/pages/create_edit_recipe_page.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailPage({super.key, required this.recipe});

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
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
      final url = await _supabaseService.getImageUrl(widget.recipe.imagePath);
      setState(() {
        _imageUrl = url;
        _isLoadingImage = false;
      });
    } else {
      setState(() => _isLoadingImage = false);
    }
  }

  void _editRecipe() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEditRecipePage(recipe: widget.recipe),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.recipe.imagePath.isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: hasImage,
      appBar: AppBar(
        backgroundColor: hasImage ? Colors.transparent : null,
        elevation: hasImage ? 0 : null,
        foregroundColor: hasImage ? Colors.white : null,
        actions: [
          IconButton(onPressed: _editRecipe, icon: const Icon(Icons.edit)),
        ],
      ),
      body: hasImage ? _buildWithImageLayout() : _buildWithoutImageLayout(),
    );
  }

  Widget _buildWithImageLayout() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          backgroundColor: Colors.transparent,
          flexibleSpace: _isLoadingImage
              ? const Center(child: CircularProgressIndicator())
              : _imageUrl != null
              ? Image.network(_imageUrl!, fit: BoxFit.cover)
              : Container(color: Colors.grey[200]),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                widget.recipe.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.recipe.content,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildWithoutImageLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.recipe.title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Text(
            widget.recipe.content,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
