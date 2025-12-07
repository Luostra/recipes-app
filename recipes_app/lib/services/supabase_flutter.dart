import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/folder.dart';
import '../models/recipe.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;
  final _storage = Supabase.instance.client.storage;

  // User operations
  Future<User?> getCurrentUser() async {
    return _supabase.auth.currentUser;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Folder operations
  Future<List<Folder>> getUserFolders() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('folders')
        .select()
        .eq('user_id', user.id)
        .order('created_at');

    return response.map((json) => Folder.fromJson(json)).toList();
  }

  Future<String> createFolder(Folder folder) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final response = await _supabase.from('folders').insert({
      'user_id': user.id,
      'title': folder.title,
      'description': folder.description,
      'emoji': folder.emoji,
    }).select();

    return response.first['id'];
  }

  Future<void> updateFolder(Folder folder) async {
    await _supabase
        .from('folders')
        .update({
          'title': folder.title,
          'description': folder.description,
          'emoji': folder.emoji,
        })
        .eq('id', folder.id);
  }

  Future<void> deleteFolder(String folderId) async {
    await _supabase.from('folders').delete().eq('id', folderId);
  }

  // Recipe operations
  Future<List<Recipe>> getRecipesByFolder(String folderId) async {
    final response = await _supabase
        .from('recipes')
        .select()
        .eq('folder_id', folderId)
        .order('created_at', ascending: false);

    return response.map((json) => Recipe.fromJson(json)).toList();
  }

  Future<List<Recipe>> getFavoriteRecipes() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('recipes')
        .select()
        .eq('is_favour', true)
        .order('created_at', ascending: false);

    return response.map((json) => Recipe.fromJson(json)).toList();
  }

  Future<String> createRecipe(Recipe recipe) async {
    final response = await _supabase
        .from('recipes')
        .insert(recipe.toJson())
        .select();

    return response.first['id'];
  }

  Future<void> updateRecipe(Recipe recipe) async {
    await _supabase.from('recipes').update(recipe.toJson()).eq('id', recipe.id);
  }

  Future<void> deleteRecipe(String recipeId) async {
    await _supabase.from('recipes').delete().eq('id', recipeId);
  }

  Future<void> toggleFavorite(String recipeId, bool isFavorite) async {
    await _supabase
        .from('recipes')
        .update({'is_favour': isFavorite})
        .eq('id', recipeId);
  }

  // Image operations
  Future<String?> uploadImage(File imageFile, String fileName) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final storagePath = '${user.id}/$fileName';

    try {
      // Загружаем файл
      await _storage
          .from('dishes')
          .upload(
            storagePath,
            imageFile,
            fileOptions: FileOptions(upsert: true, contentType: 'image/jpeg'),
          );

      return storagePath;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<String?> getImageUrl(String imagePath) async {
    if (imagePath.isEmpty) return null;

    try {
      final response = await _storage
          .from('dishes')
          .createSignedUrl(imagePath, 60 * 60); // URL действителен 1 час

      return response;
    } catch (e) {
      print('Error getting image URL: $e');
      return null;
    }
  }

  Future<String?> getPublicImageUrl(String imagePath) async {
    if (imagePath.isEmpty) return null;

    try {
      final response = _storage.from('dishes').getPublicUrl(imagePath);

      return response;
    } catch (e) {
      print('Error getting public image URL: $e');
      return null;
    }
  }

  Future<void> deleteImage(String imagePath) async {
    if (imagePath.isEmpty) return;

    try {
      await _storage.from('dishes').remove([imagePath]);
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  // Получение всех рецептов с предзагрузкой изображений (опционально)
  Future<List<Recipe>> getRecipesWithImages(String folderId) async {
    final recipes = await getRecipesByFolder(folderId);

    // Если нужно предзагрузить URL изображений
    for (var recipe in recipes) {
      if (recipe.imagePath.isNotEmpty) {
        // URL будут загружаться по мере необходимости
        // или можно использовать getPublicUrl если bucket публичный
      }
    }

    return recipes;
  }
}
