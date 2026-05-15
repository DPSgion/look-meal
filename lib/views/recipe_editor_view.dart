import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:look_meal/models/recipe_model.dart';
import 'package:look_meal/services/database_service.dart';

class RecipeEditorView extends StatefulWidget {
  final Recipe? existingRecipe; 

  const RecipeEditorView({super.key, this.existingRecipe});

  @override
  State<RecipeEditorView> createState() => _RecipeEditorViewState();
}

class _RecipeEditorViewState extends State<RecipeEditorView> {
  final DatabaseService _dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  File? _selectedImage;
  String? _existingImageUrl;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final List<Map<String, TextEditingController>> _ingredients = [];
  final List<TextEditingController> _steps = [];

  @override
  void initState() {
    super.initState();
    _setupInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    for (var item in _ingredients) {
      item['name']?.dispose();
      item['measure']?.dispose();
    }
    for (var step in _steps) {
      step.dispose();
    }
    super.dispose();
  }

  void _setupInitialData() {
    if (widget.existingRecipe != null) {
      final recipe = widget.existingRecipe!;
      _nameController.text = recipe.title;
      _existingImageUrl = recipe.thumbnail;
      _noteController.text = recipe.personalNote;

      for (var ing in recipe.ingredients) {
        _ingredients.add({
          'name': TextEditingController(text: ing.name),
          'measure': TextEditingController(text: ing.measure),
        });
      }

      List<String> stepsList = recipe.instructions.split('\n');
      for (var step in stepsList) {
        if (step.trim().isNotEmpty) {
          _steps.add(TextEditingController(text: step));
        }
      }
    } else {
      _addIngredientRow();
      _addStepRow();
    }
  }

  void _addIngredientRow() {
    setState(() {
      _ingredients.add({
        'name': TextEditingController(),
        'measure': TextEditingController(),
      });
    });
  }

  void _addStepRow() {
    setState(() {
      _steps.add(TextEditingController());
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Hàm kiểm tra: Phải có ít nhất 1 chữ cái (mọi ngôn ngữ) hoặc 1 chữ số
  bool _isValidText(String text) {
    if (text.trim().isEmpty) return false;
    // \p{L} là chữ cái (bao gồm tiếng Việt), \p{N} là số. Bật unicode: true để nhận diện.
    return RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(text);
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null && _existingImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ảnh cho món ăn!')));
      return;
    }

    // KIỂM TRA NGUYÊN LIỆU GẮT HƠN
    bool hasInvalidIngredient = _ingredients.isEmpty || 
        _ingredients.any((ctrl) => !_isValidText(ctrl['name']!.text) || !_isValidText(ctrl['measure']!.text));
        
    if (hasInvalidIngredient) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nguyên liệu chỉ được chứa chữ/số và không được để trống!')));
      return;
    }

    // KIỂM TRA BƯỚC LÀM GẮT HƠN
    bool hasInvalidStep = _steps.isEmpty || _steps.any((ctrl) => !_isValidText(ctrl.text));
    
    if (hasInvalidStep) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bước nấu ăn chỉ được chứa chữ/số và không được để trống!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // LOGIC ID: Nếu là Edit món cũ (My Created) thì giữ ID. Nếu là New hoặc Fork từ API thì cấp ID mới.
      String recipeId;
      bool isForkingFromApi = widget.existingRecipe != null && widget.existingRecipe!.category != "My Created";
      
      if (widget.existingRecipe != null && !isForkingFromApi) {
        recipeId = widget.existingRecipe!.id;
      } else {
        recipeId = "RECIPE_${DateTime.now().millisecondsSinceEpoch}";
      }

      // 2. Upload ảnh (BỎ PHẦN XÓA OCI VÌ LỖI 404/FORBIDDEN)
      String finalImageUrl = _existingImageUrl ?? "";
      if (_selectedImage != null) {
        finalImageUrl = await _dbService.uploadRecipeImage(_selectedImage!, recipeId);
      }

      // 3. Gom dữ liệu
      List<Ingredient> finalIngredients = _ingredients
          .where((ctrl) => ctrl['name']!.text.trim().isNotEmpty)
          .map((ctrl) => Ingredient(
                name: ctrl['name']!.text.trim(),
                measure: ctrl['measure']!.text.trim(),
              ))
          .toList();

      String finalInstructions = _steps
          .map((ctrl) => ctrl.text.trim())
          .where((text) => text.isNotEmpty)
          .join('\n');

      // 4. Đóng gói
      Recipe newRecipe = Recipe(
        id: recipeId,
        title: _nameController.text.trim(),
        thumbnail: finalImageUrl,
        category: "My Created",
        instructions: finalInstructions,
        ingredients: finalIngredients,
        personalNote: _noteController.text.trim(),
      );

      // 5. Lưu vào Firestore (Collection: my_recipes)
      await _dbService.saveCreatedRecipe(newRecipe);

      if (mounted) {
        // LOGIC ĐIỀU HƯỚNG:
        if (isForkingFromApi) {
          // Nếu Fork từ API: Đóng Editor -> Đóng tiếp Detail của API để về Library
          Navigator.pop(context); 
          Navigator.pop(context);
        } else {
          // Nếu là Sửa món cũ hoặc Tạo mới từ đầu: Chỉ cần Pop 1 phát
          Navigator.pop(context, newRecipe);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu vào danh sách món tự nấu!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingRecipe == null ? 'Create Recipe' : 'Edit Recipe'),
        actions: [
          _isLoading
              ? const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: Colors.white))
              : IconButton(icon: const Icon(Icons.check, size: 30), onPressed: _saveRecipe),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              validator: (val) {
                if (val == null || !_isValidText(val)) {
                  return 'Không được chứa kí tự đặc biệt hoặc để trống !';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Personal Note (Mẹo, lưu ý...)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Ingredients:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._ingredients.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 8),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: TextField(controller: item['name'], decoration: const InputDecoration(hintText: 'Tên (VD: Chicken)', isDense: true))),
                  const SizedBox(width: 8),
                  Expanded(flex: 1, child: TextField(controller: item['measure'], decoration: const InputDecoration(hintText: 'Lượng (VD: 1kg)', isDense: true))),
                  IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setState(() => _ingredients.remove(item))),
                ],
              ),
            )),
            Center(child: IconButton(icon: const Icon(Icons.add_box, color: Colors.green, size: 32), onPressed: _addIngredientRow)),
            const SizedBox(height: 10),
            const Text('Steps to cook:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._steps.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${entry.key + 1}. ', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Expanded(child: TextField(controller: entry.value, maxLines: null, decoration: const InputDecoration(hintText: 'Mô tả bước làm...', isDense: true))),
                  IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setState(() => _steps.removeAt(entry.key))),
                ],
              ),
            )),
            Center(child: IconButton(icon: const Icon(Icons.add_box, color: Colors.green, size: 32), onPressed: _addStepRow)),
            const SizedBox(height: 20),
            const Text('Image:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                child: _selectedImage != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_selectedImage!, fit: BoxFit.cover))
                    : _existingImageUrl != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_existingImageUrl!, fit: BoxFit.cover))
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                              Text("Nhấn để chọn ảnh", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}