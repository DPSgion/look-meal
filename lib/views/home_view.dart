import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/explore_provider.dart';
import '../views/recipe_detail_view.dart';
import '../views/library_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    // Fetch data exactly once when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExploreProvider>().loadHomeData();
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filter Recipes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: context
                    .read<ExploreProvider>()
                    .selectedArea, // Hiển thị đúng nước đang chọn
                decoration: const InputDecoration(
                  labelText: 'Nation / Area',
                  border: OutlineInputBorder(),
                ),
                // DANH SÁCH CÓ THÊM 'All' Ở ĐẦU
                items:
                    [
                      'All',
                      'American',
                      'British',
                      'Canadian',
                      'Chinese',
                      'Croatian',
                      'Dutch',
                      'Egyptian',
                      'Filipino',
                      'French',
                      'Greek',
                      'Indian',
                      'Irish',
                      'Italian',
                      'Jamaican',
                      'Japanese',
                      'Kenyan',
                      'Malaysian',
                      'Mexican',
                      'Moroccan',
                      'Polish',
                      'Portuguese',
                      'Russian',
                      'Spanish',
                      'Thai',
                      'Tunisian',
                      'Turkish',
                      'Ukrainian',
                      'Vietnamese',
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    context.read<ExploreProvider>().filterByArea(newValue);
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận"),
        content: const Text("Master Chef muốn đăng xuất thật à?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              context
                  .read<ExploreProvider>()
                  .clearData(); // Xóa sạch dữ liệu cũ trong máy
              await AuthService().signOut();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Đăng xuất", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // We 'listen' to the provider here to redraw when data arrives
    final provider = context.watch<ExploreProvider>();

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepOrange),
              child: Text(
                'Look Meal',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('My Library'),
              onTap: () {
                Navigator.pop(context); // Đóng drawer trước
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LibraryView()),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text(
          'HOME',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // Bỏ chữ const ở actions đi vì chúng ta dùng IconButton có hàm onPressed
        actions: [
          // Nút mở Thư viện
          IconButton(
            icon: const Icon(Icons.library_books),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LibraryView()),
              );
            },
          ),
          // Avatar người dùng (nằm sát lề phải hơn)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onLongPress: () =>
                  _showLogoutDialog(context), // Đè vào để đăng xuất
              child: CircleAvatar(
                backgroundColor: Colors.deepOrange.withOpacity(0.2),
                // Lấy photoURL từ Firebase Auth
                backgroundImage:
                    FirebaseAuth.instance.currentUser?.photoURL != null
                    ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                    : null,
                // Nếu không có ảnh thì hiện icon mặc định
                child: FirebaseAuth.instance.currentUser?.photoURL == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search food...',
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (value) {
                      // Trigger search when the user hits "Enter"
                      context.read<ExploreProvider>().search(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.filter_alt,
                      color: Colors.deepOrange,
                    ),
                    onPressed: _showFilterBottomSheet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Dynamic Grid
            Expanded(
              child: provider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    ) // Show loading spinner
                  : provider.gridRecipes.isEmpty
                  ? const Center(child: Text("No recipes found."))
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: provider.gridRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = provider.gridRecipes[index];
                        return Card(
                          elevation: 3,
                          clipBehavior: Clip
                              .antiAlias, // Ensures images stay inside rounded corners
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      RecipeDetailView(recipe: recipe),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 3,
                                  // Using CachedNetworkImage for high performance and offline caching
                                  child: CachedNetworkImage(
                                    imageUrl: recipe.thumbnail,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.error),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Center(
                                      child: Text(
                                        recipe.title,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
