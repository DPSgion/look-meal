import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../services/api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExploreProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Recipe> gridRecipes = [];
  List<Map<String, String>> categories = [];
  Recipe? featuredRecipe;
  bool isLoading = false;

  // --- QUẢN LÝ TRẠNG THÁI BỘ LỌC ---
  String selectedArea = 'All';
  String lastSearchQuery = '';

  List<Recipe> myRecipes = [];

  // --- LẤY DANH SÁCH MÓN ĂN CỦA TÔI ---
  Future<void> fetchMyRecipes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('user_recipes')
          .where('userId', isEqualTo: user.uid) // Lọc đúng đồ của mình
          .get();

      myRecipes = snapshot.docs
          .map(
            (doc) => Recipe.fromMap(doc.data()),
          ) // Chuyển data về Object Recipe
          .toList();
    } catch (e) {
      print("Lỗi lấy món cá nhân: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPersonalRecipe(Recipe recipe) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newRecipe = Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: recipe.title,
      thumbnail: recipe.thumbnail,
      category: recipe.category,
      ingredients: recipe.ingredients,
      instructions: recipe.instructions,
      userId: user.uid, // Đã có tham số userId trong Model nên sẽ không còn lỗi
    );

    try {
      await FirebaseFirestore.instance
          .collection('user_recipes')
          .doc(newRecipe.id)
          .set(newRecipe.toMap());

      myRecipes.add(newRecipe);
      notifyListeners();
    } catch (e) {
      print("Lỗi khi tạo món: $e");
    }
  }

  Future<void> loadHomeData() async {
    isLoading = true;
    selectedArea = 'All'; // Reset về All khi mới vào app
    lastSearchQuery = '';
    notifyListeners();
    try {
      gridRecipes = await _apiService.searchRecipes('');
      gridRecipes.shuffle(); // Xáo trộn món ăn như ông yêu cầu
      categories = await _apiService.getCategories();
      featuredRecipe = await _apiService.getRandomRecipe();
    } catch (e) {
      print("Error loading home data: $e");
    }
    isLoading = false;
    notifyListeners();
  }

  // --- LOGIC KẾT HỢP: SEARCH TRONG NATION ---
  Future<void> search(String query) async {
    lastSearchQuery = query;
    isLoading = true;
    notifyListeners();

    try {
      if (selectedArea == 'All') {
        // Nếu là All, search toàn hệ thống
        gridRecipes = await _apiService.searchRecipes(query);
      } else {
        // Nếu đang ở 1 Nation, lấy data Nation đó rồi lọc text cục bộ
        List<Recipe> areaRecipes = await _apiService.getRecipesByArea(
          selectedArea,
        );
        gridRecipes = areaRecipes
            .where((r) => r.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    } catch (e) {
      print("Error searching: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> filterByArea(String area) async {
    selectedArea = area;
    isLoading = true;
    notifyListeners();

    try {
      if (area == 'All') {
        // Chọn All thì quay lại search theo keyword hiện tại (nếu có)
        gridRecipes = await _apiService.searchRecipes(lastSearchQuery);
      } else {
        // Lấy data Nation, sau đó lọc theo keyword search hiện tại
        List<Recipe> areaRecipes = await _apiService.getRecipesByArea(area);
        gridRecipes = areaRecipes
            .where(
              (r) =>
                  r.title.toLowerCase().contains(lastSearchQuery.toLowerCase()),
            )
            .toList();
      }
    } catch (e) {
      print("❌ Lỗi lọc khu vực: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearData() {
    gridRecipes = [];
    myRecipes = [];
    notifyListeners();
  }
}
