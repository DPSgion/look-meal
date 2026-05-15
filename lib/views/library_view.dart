import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:look_meal/models/recipe_model.dart';
import 'package:look_meal/services/database_service.dart';
import 'package:look_meal/views/recipe_detail_view.dart';
import 'package:look_meal/views/recipe_editor_view.dart';

class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  // --- HÀM SỬA GHI CHÚ ---
  void _showEditNoteDialog(Recipe recipe, bool isFromApi) {
    // Lấy note hiện tại bỏ vào controller để người dùng sửa cho dễ
    TextEditingController editController = TextEditingController(
      text: recipe.personalNote,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Note: ${recipe.title}"),
        content: TextField(
          controller: editController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Enter your cooking tips...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _dbService.addPersonalNote(
                recipe.id,
                editController.text,
                isFromApi,
              );
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Note updated successfully!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'MY LIBRARY',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.cloud_download), text: "Saved"),
              Tab(icon: Icon(Icons.edit_document), text: "Created"),
            ],
            indicatorColor: Colors.deepOrange,
            labelColor: Colors.deepOrange,
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search in library...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildLibraryList(isFromApi: true),
                  _buildLibraryList(isFromApi: false),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Chuyển sang màn hình Edit ở chế độ TẠO MỚI
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RecipeEditorView()),
            );
          },
          backgroundColor: Colors.green,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildLibraryList({required bool isFromApi}) {
    return StreamBuilder<List<Recipe>>(
      stream: isFromApi
          ? _dbService.getSavedRecipes()
          : _dbService.getCreatedRecipes(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final filteredList = snapshot.data!.where((recipe) {
          return recipe.title.toLowerCase().contains(_searchQuery);
        }).toList();

        if (filteredList.isEmpty) {
          return const Center(child: Text("No recipes found in this tab."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final recipe = filteredList[index];
            return _buildRecipeCard(recipe, isFromApi);
          },
        );
      },
    );
  }

  Widget _buildRecipeCard(Recipe recipe, bool isFromApi) {
    // Ưu tiên hiển thị Personal Note, nếu không có mới hiện Instruction
    String displayNote = recipe.personalNote.isNotEmpty
        ? recipe.personalNote
        : recipe.instructions;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior:
          Clip.antiAlias, // Để hiệu ứng InkWell không bị tràn góc bo tròn
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RecipeDetailView(recipe: recipe, isFromApi: isFromApi),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: recipe.thumbnail,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.fastfood),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Note: ${displayNote.length > 45 ? displayNote.substring(0, 45) + '...' : displayNote}",
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.blue,
                            size: 24,
                          ),
                          onPressed: () {
                            if (isFromApi) {
                              _showEditNoteDialog(recipe, isFromApi);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      RecipeEditorView(existingRecipe: recipe),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.only(right: 8),
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 24,
                          ),
                          // Trong library_view.dart -> IconButton (Icons.delete)
                          onPressed: () async {
                            bool? confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Xác nhận xóa'),
                                content: Text(
                                  'Ông giáo có chắc muốn xóa món "${recipe.title}" không?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Hủy'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Xóa ngay'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              // Nếu là Tab Created (không phải API) thì dọn rác trên OCI trước
                              if (!isFromApi && recipe.thumbnail.isNotEmpty) {
                                await _dbService.deleteImageFromOCI(
                                  recipe.thumbnail,
                                );
                              }

                              // Xóa record trong Database
                              await _dbService.deleteRecipe(
                                recipe.id,
                                isFromApi,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
