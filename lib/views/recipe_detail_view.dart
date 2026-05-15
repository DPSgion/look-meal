import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:look_meal/models/recipe_model.dart';
import 'package:look_meal/services/database_service.dart';
import 'package:look_meal/views/recipe_editor_view.dart';

class RecipeDetailView extends StatefulWidget {
  final Recipe recipe;
  final bool isFromApi;

  const RecipeDetailView({
    super.key,
    required this.recipe,
    this.isFromApi = true,
  });

  @override
  State<RecipeDetailView> createState() => _RecipeDetailViewState();
}

class _RecipeDetailViewState extends State<RecipeDetailView> {
  final DatabaseService _dbService = DatabaseService();
  int servings = 1;

  String? _currentNote;
  late Recipe _currentRecipe;
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    _currentRecipe = widget.recipe; // Khởi tạo từ widget truyền vào
    _currentNote = _currentRecipe.personalNote;
    _checkSavedStatus();
  }

  Future<void> _refreshRecipeData() async {
    var updatedRecipe = await _dbService.getRecipeById(
      _currentRecipe.id,
      widget.isFromApi,
    );
    if (updatedRecipe != null) {
      setState(() {
        _currentRecipe = updatedRecipe;
        _currentNote = updatedRecipe.personalNote;
      });
    }
  }

  void _showNoteDialog() {
    TextEditingController noteController = TextEditingController(
      text: _currentNote,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ghi chú cá nhân'),
        content: SizedBox(
          width: double.maxFinite, // Ép Dialog giãn theo chiều ngang
          child: TextField(
            controller: noteController,
            // ĐỘ LẠI KHUNG NHẬP LIỆU
            minLines: 4, // Ép cái hộp cao ít nhất 4 dòng ngay từ đầu
            maxLines: 6, // Cho phép giãn nở tối đa 6 dòng
            decoration: InputDecoration(
              hintText: 'VD: Cho ít muối lại, thêm ớt...',
              alignLabelWithHint: true, // Căn chữ hint lên góc trên
              border:
                  const OutlineInputBorder(), // Biến vạch kẻ thành Khung Viền
              contentPadding: const EdgeInsets.all(
                16,
              ), // Tạo khoảng trống bên trong để gõ cho sướng
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: Colors.deepOrange,
                  width: 2,
                ), // Viền đậm khi click vào
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!isSaved) {
                await _dbService.saveFavoriteRecipe(_currentRecipe);
                setState(() => isSaved = true);
              }

              await _dbService.addPersonalNote(
                _currentRecipe.id,
                noteController.text,
                widget.isFromApi,
              );

              setState(() {
                _currentNote = noteController.text;
              });

              if (mounted) Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã lưu ghi chú thành công!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Lưu ghi chú'),
          ),
        ],
      ),
    );
  }

  void _saveToCloud() async {
    if (isSaved) {
      bool? confirmUnsave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Bỏ lưu công thức?'),
          content: const Text(
            'Ông giáo có chắc muốn xóa món này khỏi thư viện không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xóa luôn'),
            ),
          ],
        ),
      );

      if (confirmUnsave == true) {
        await _dbService.deleteRecipe(
          _currentRecipe.id, // Đổi thành _currentRecipe
          true,
        );
        setState(() => isSaved = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa khỏi thư viện!'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } else {
      await _dbService.saveFavoriteRecipe(
        _currentRecipe,
      ); // Đổi thành _currentRecipe
      setState(() => isSaved = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu vào thư viện!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _checkSavedStatus() async {
    bool saved = await _dbService.isRecipeSaved(
      _currentRecipe.id,
    ); // Đổi thành _currentRecipe
    setState(() {
      isSaved = saved;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Detail'),
        actions: [
          // SỬA GẮT Ở ĐÂY: Chỉ hiện nút Save/Bookmark nếu là món từ API
          if (widget.isFromApi)
            IconButton(
              icon: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: isSaved ? Colors.orange : null,
                size: 28,
              ),
              onPressed: _saveToCloud,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SỬA Ở ĐÂY: Dùng _currentRecipe thay vì widget.recipe
            CachedNetworkImage(
              imageUrl: _currentRecipe.thumbnail,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SỬA Ở ĐÂY
                  Text(
                    _currentRecipe.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // PHẦN HIỂN THỊ GHI CHÚ ĐÃ ĐƯỢC "PHÓNG TO"
                  if (_currentNote != null && _currentNote!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                      ), // Tăng khoảng cách trên dưới
                      child: Container(
                        padding: const EdgeInsets.all(
                          16,
                        ), // Tăng độ dày bên trong hộp
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.4),
                            width: 1.5, // Viền đậm hơn chút
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment
                              .start, // Căn icon lên đầu nếu ghi chú dài
                          children: [
                            const Icon(
                              Icons.stars,
                              color: Colors.amber,
                              size: 23, // Icon to hơn hẳn (cũ là 18)
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.isFromApi
                                    ? "Mẹo của Master Chef: $_currentNote"
                                    : "Ghi chú: $_currentNote",
                                style: const TextStyle(
                                  fontSize:
                                      17, // Tăng size chữ từ 15 lên 19 cho dễ đọc
                                  fontWeight: FontWeight
                                      .w600, // Chữ dày hơn (Medium/Semi-bold)
                                  fontStyle: FontStyle.italic,
                                  color: Color(
                                    0xFF5D4037,
                                  ), // Màu nâu đậm cho sang
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Servings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                if (servings > 1) setState(() => servings--);
                              },
                            ),
                            Text(
                              '$servings',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => setState(() => servings++),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Ingredients:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // SỬA Ở ĐÂY
                  ..._currentRecipe.ingredients.map(
                    (ingredient) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 8,
                            color: Colors.deepOrange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ingredient.name,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          Text(
                            servings == 1
                                ? ingredient.measure
                                : '${ingredient.measure} (x$servings)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Steps to cook:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // SỬA Ở ĐÂY
                  Text(
                    _currentRecipe.instructions,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (widget.isFromApi) ...[
              FloatingActionButton.extended(
                heroTag: 'btn_add_note',
                onPressed: _showNoteDialog,
                icon: const Icon(Icons.edit_note),
                label: const Text('Add Note'),
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
              const SizedBox(width: 12),

              FloatingActionButton.extended(
                heroTag: 'btn_fork_edit',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          RecipeEditorView(existingRecipe: _currentRecipe),
                    ),
                  );
                  _refreshRecipeData();
                },
                icon: const Icon(Icons.restaurant_menu),
                label: const Text('Edit & Save'),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ] else ...[
              FloatingActionButton.extended(
                heroTag: 'btn_main_edit',
                onPressed: () async {
                  final updatedRecipe = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          RecipeEditorView(existingRecipe: _currentRecipe),
                    ),
                  );

                  if (updatedRecipe != null && updatedRecipe is Recipe) {
                    setState(() {
                      _currentRecipe = updatedRecipe;
                    });
                  }
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit Recipe'),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
