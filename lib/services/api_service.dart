import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:look_meal/models/recipe_model.dart';

class ApiService {
  static const String _baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  // 1. Get a Random Meal for the Home Screen "Hero" card
  Future<Recipe?> getRandomRecipe() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/random.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          return Recipe.fromJson(data['meals'][0]);
        }
      }
      return null;
    } catch (e) {
      print("Error fetching random recipe: $e");
      return null;
    }
  }

  // 2. Search recipes by name (For your "Tra cứu thông minh" feature)
  Future<List<Recipe>> searchRecipes(String query) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/search.php?s=$query'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          return (data['meals'] as List).map((meal) => Recipe.fromJson(meal)).toList();
        }
      }
      return [];
    } catch (e) {
      print("Error searching recipes: $e");
      return [];
    }
  }

  // 3. Get all meal categories (Beef, Chicken, Seafood, etc.)
  Future<List<Map<String, String>>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/categories.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['categories'] != null) {
          return (data['categories'] as List).map((c) => {
            'name': c['strCategory'].toString(),
            'thumb': c['strCategoryThumb'].toString(),
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print("Error fetching categories: $e");
      return [];
    }
  }


  // Hàm lấy món ăn theo khu vực/quốc gia
  Future<List<Recipe>> getRecipesByArea(String area) async {
    final response = await http.get(Uri.parse('https://www.themealdb.com/api/json/v1/1/filter.php?a=$area'));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] != null) {
        return (data['meals'] as List).map((meal) => Recipe.fromJson(meal)).toList();
      }
      return [];
    } else {
      throw Exception('Lỗi khi tải dữ liệu theo khu vực');
    }
  }
}