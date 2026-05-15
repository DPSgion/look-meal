class Recipe {
  final String id;
  final String title;
  final String thumbnail;
  final String category;
  final String instructions;
  final List<Ingredient> ingredients;
  final String personalNote;
  final String? userId;

  Recipe({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.category,
    this.instructions = "",
    required this.ingredients,
    this.personalNote = "",
    this.userId,
  });

  // 1. Chuyển từ Map (Firebase) sang Object (Flutter)
  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      thumbnail: map['thumbnail'] ?? '',
      category: map['category'] ?? '',
      instructions: map['instructions'] ?? '',
      personalNote: map['personalNote'] ?? '',
      userId: map['userId'],
      ingredients: map['ingredients'] != null
          ? List<Ingredient>.from(
              (map['ingredients'] as List<dynamic>).map(
                (x) => Ingredient.fromMap(x as Map<String, dynamic>),
              ),
            )
          : [],
    );
  }

  // 2. Chuyển từ Object sang Map để lưu lên Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'thumbnail': thumbnail,
      'category': category,
      'instructions': instructions,
      'personalNote': personalNote,
      'userId': userId,
      'ingredients': ingredients.map((x) => x.toMap()).toList(),
    };
  }

  // Thêm hàm này vào trong class Recipe ở file recipe_model.dart
  factory Recipe.fromJson(Map<String, dynamic> json) {
    List<Ingredient> ingredients = [];

    // Duyệt từ 1 đến 20 để lấy Ingredients và Measures từ API
    for (int i = 1; i <= 20; i++) {
      final name = json['strIngredient$i'];
      final measure = json['strMeasure$i'];

      if (name != null && name.toString().trim().isNotEmpty) {
        ingredients.add(
          Ingredient(name: name.toString(), measure: measure?.toString() ?? ''),
        );
      }
    }

    return Recipe(
      id: json['idMeal'] ?? '',
      title: json['strMeal'] ?? '',
      thumbnail: json['strMealThumb'] ?? '',
      category: json['strCategory'] ?? '',
      instructions: json['strInstructions'] ?? '',
      ingredients: ingredients,
      personalNote: '', // Món từ API mặc định chưa có note
      userId: null,
    );
  }
}

class Ingredient {
  final String name;
  final String measure;

  Ingredient({required this.name, required this.measure});

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(name: map['name'] ?? '', measure: map['measure'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'measure': measure};
  }
}
