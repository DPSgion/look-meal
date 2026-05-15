import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:look_meal/models/recipe_model.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

const String ociParUrl =
    "https://objectstorage.ap-singapore-1.oraclecloud.com/p/j-WQm23UA4c6S8TSCL0vZI7pm8XXqORFvstU2h-W3nrWjw4bvXA5LZucCPiSBA4g/n/axqv9e1of21u/b/lookmeal_storage/o/";

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ID giả lập để test
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // --- 1. LƯU DỮ LIỆU ---

  // Lưu công thức từ API vào mục 'favorites'
  Future<void> saveFavoriteRecipe(Recipe recipe) async {
    if (currentUserId == null) return;
    try {
      await _db
          .collection('users')
          .doc(currentUserId!)
          .collection('favorites')
          .doc(recipe.id)
          .set({
            'id': recipe.id,
            'title': recipe.title,
            'thumbnail': recipe.thumbnail,
            'category': recipe.category,
            'instructions': recipe.instructions,
            'personalNote': '',
            'ingredients': recipe.ingredients.map((i) => i.toMap()).toList(),
            'savedAt': FieldValue.serverTimestamp(),
          });
      print("✅ Đã lưu ${recipe.title} kèm đầy đủ các bước nấu!");
    } catch (e) {
      print("❌ Lỗi lưu recipe: $e");
    }
  }

  Future<String> uploadRecipeImage(File imageFile, String recipeId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // 1. Nén ảnh (Giữ nguyên logic cũ để tối ưu tài nguyên)
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          "${tempDir.path}/compressed_${recipeId}_$timestamp.jpg";

      var compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: 70,
      );

      if (compressedFile == null) return "";

      // 2. Chuyển file thành mảng byte
      final bytes = await File(compressedFile.path).readAsBytes();

      // 3. Chuẩn bị Endpoint URL
      String finalUploadUrl = "$ociParUrl${recipeId}_$timestamp.jpg";

      // 4. Bắn HTTP PUT lên OCI
      final response = await http.put(
        Uri.parse(finalUploadUrl),
        headers: {'Content-Type': 'image/jpeg'},
        body: bytes,
      );

      // 5. Xử lý phản hồi và bóc tách URL Public
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Thủ thuật: URL PAR chứa chuỗi token bảo mật (/p/<token>/).
        // Vì bucket đã set Public, ta dùng Regex cắt bỏ token này đi để lấy link sạch,
        // giúp widget CachedNetworkImage render nhanh và nhẹ hơn.
        String publicUrl = finalUploadUrl.replaceAll(RegExp(r'/p/[^/]+/'), '/');

        print("✅ Upload OCI thành công: $publicUrl");
        return publicUrl;
      } else {
        print("❌ Lỗi OCI: HTTP ${response.statusCode} - ${response.body}");
        return "";
      }
    } catch (e) {
      print("❌ Exception khi gọi OCI: $e");
      return "";
    }
  }

  // Trong DatabaseService
  Future<Recipe?> getRecipeById(String id, bool isFromApi) async {
    try {
      String collection = isFromApi ? 'favorites' : 'my_recipes';
      var doc = await _db
          .collection('users')
          .doc(currentUserId)
          .collection(collection)
          .doc(id)
          .get();

      if (doc.exists) {
        return Recipe.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print("❌ Lỗi lấy chi tiết món: $e");
      return null;
    }
  }

  // Hàm xóa ảnh khỏi OCI
  Future<void> deleteImageFromOCI(String? publicUrl) async {
    if (publicUrl == null || publicUrl.isEmpty) return;

    try {
      // Bóc tách lấy đúng cái tên file ở cuối đường link
      Uri uri = Uri.parse(publicUrl);
      String fileName = uri.pathSegments.last;

      // Nối tên file vào PAR URL (cái link có chứa token bảo mật)
      String deleteUrl = "$ociParUrl$fileName";

      final response = await http.delete(Uri.parse(deleteUrl));

      if (response.statusCode == 200 || response.statusCode == 204) {
        print("🗑️ Đã dọn dẹp ảnh cũ trên OCI thành công!");
      } else {
        print("❌ Lỗi xóa ảnh OCI: HTTP ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Exception khi xóa ảnh OCI: $e");
    }
  }

  // Trong database_service.dart

  // Lưu món ăn tự chế vào mục 'my_recipes'
  Future<void> saveCreatedRecipe(Recipe recipe) async {
    try {
      await _db
          .collection('users')
          .doc(currentUserId)
          .collection('my_recipes')
          .doc(recipe.id) // ID này mình sẽ tự tạo bằng UUID hoặc Timestamp
          .set({
            'id': recipe.id,
            'title': recipe.title,
            'thumbnail': recipe.thumbnail, // Link ảnh từ Cloud Storage trả về
            'category': recipe.category,
            'instructions': recipe.instructions,
            'personalNote': recipe.personalNote,
            'ingredients': recipe.ingredients.map((i) => i.toMap()).toList(),
            'createdAt':
                FieldValue.serverTimestamp(), // Để sắp xếp món mới lên đầu
          });
      print("✅ Đã tạo món mới thành công!");
    } catch (e) {
      print("❌ Lỗi lưu món tự tạo: $e");
      rethrow;
    }
  }

  // Trong database_service.dart
  Future<bool> isRecipeSaved(String recipeId) async {
    try {
      var doc = await _db
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .doc(recipeId)
          .get();
      return doc.exists; // Trả về true nếu món ăn đã có trong favorites
    } catch (e) {
      return false;
    }
  }

  // --- 2. LẤY DỮ LIỆU (STREAM) ---

  // Lấy danh sách món từ API (Tab 1)
  Stream<List<Recipe>> getSavedRecipes() {
    return _db
        .collection('users')
        .doc(currentUserId)
        .collection('favorites')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Recipe.fromMap(doc.data())).toList(),
        );
  }

  // Lấy danh sách món tự tạo (Tab 2)
  Stream<List<Recipe>> getCreatedRecipes() {
    return _db
        .collection('users')
        .doc(currentUserId)
        .collection('my_recipes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Recipe.fromMap(doc.data())).toList(),
        );
  }

  // --- 3. CẬP NHẬT GHI CHÚ ---

  // Cập nhật note cho cả 2 loại (Dùng isFromApi để biết cần update ở đâu)
  Future<void> addPersonalNote(
    String recipeId,
    String note,
    bool isFromApi,
  ) async {
    try {
      String collection = isFromApi ? 'favorites' : 'my_recipes';
      await _db
          .collection('users')
          .doc(currentUserId)
          .collection(collection)
          .doc(recipeId)
          .update({'personalNote': note});
      print("✅ Đã cập nhật ghi chú!");
    } catch (e) {
      print("❌ Lỗi cập nhật ghi chú: $e");
    }
  }

  // --- 4. XÓA DỮ LIỆU ---

  Future<void> deleteRecipe(String recipeId, bool isFromApi) async {
    try {
      String collection = isFromApi ? 'favorites' : 'my_recipes';
      await _db
          .collection('users')
          .doc(currentUserId)
          .collection(collection)
          .doc(recipeId)
          .delete();
      print("🗑️ Đã xóa món ăn khỏi thư viện");
    } catch (e) {
      print("❌ Lỗi xóa recipe: $e");
    }
  }
}
