import 'package:flutter/material.dart';
import 'package:patient_application/models/article.dart';
import 'package:patient_application/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:patient_application/screens/create_article_screen.dart';

class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({super.key});

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  List<Article> _articles = [];
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadArticles();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  Future<void> _loadArticles() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final data = await supabase
          .from('articles')
          .select()
          .order('publish_date', ascending: false);

      // Lấy danh sách các articles từ dữ liệu trả về
      final List<Article> articles = List<Article>.from(
        data.map((json) => Article.fromJson(json)),
      );

      // Trích xuất tất cả các danh mục từ bài viết
      final Set<String> categories = {};
      for (var article in articles) {
        categories.addAll(article.categories);
      }

      setState(() {
        _articles = articles;
        _categories = categories.toList()..sort();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Lỗi khi tải bài viết: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể tải bài viết: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Article> get _filteredArticles {
    return _articles.where((article) {
      // Lọc theo danh mục nếu có
      final categoryMatch =
          _selectedCategory == null ||
          article.categories.contains(_selectedCategory);

      // Lọc theo từ khóa tìm kiếm
      final searchMatch =
          _searchQuery.isEmpty ||
          article.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          article.content.toLowerCase().contains(_searchQuery.toLowerCase());

      return categoryMatch && searchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản tin sức khỏe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tạo bài viết mới',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateArticleScreen(),
                ),
              );

              // Refresh the articles list if a new article was created
              if (result == true) {
                _loadArticles();
              }
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadArticles,
                child: Column(
                  children: [
                    _buildSearchBar(),
                    _buildCategoryFilter(),
                    Expanded(
                      child:
                          _articles.isEmpty
                              ? _buildEmptyState()
                              : _filteredArticles.isEmpty
                              ? _buildNoResultsState()
                              : _buildArticlesList(),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm bài viết...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                  : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Tất cả'),
              selected: _selectedCategory == null,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = null;
                });
              },
            ),
          ),
          ..._categories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category),
                selected: _selectedCategory == category,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? category : null;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildArticlesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredArticles.length,
      itemBuilder: (context, index) {
        final article = _filteredArticles[index];
        return _buildArticleCard(article);
      },
    );
  }

  Widget _buildArticleCard(Article article) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArticleDetailScreen(article: article),
            ),
          );

          // Refresh the articles list if an article was deleted or updated
          if (result == true) {
            _loadArticles();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.thumbnailUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: CachedNetworkImage(
                  imageUrl: article.thumbnailUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  article.isFeatured
                      ? Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Nổi bật',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                      : const SizedBox.shrink(),
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.briefContent,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            child: Text(
                              article.authorName[0],
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            article.authorName,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            article.timeAgo,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children:
                        article.categories.map((category) {
                          return Chip(
                            label: Text(category),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            labelStyle: const TextStyle(fontSize: 10),
                            padding: EdgeInsets.zero,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Chưa có bài viết nào',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy quay lại sau để xem các bài viết mới nhất',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Không tìm thấy kết quả',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử tìm kiếm với từ khóa khác hoặc chọn danh mục khác',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ArticleDetailScreen extends StatelessWidget {
  final Article article;

  const ArticleDetailScreen({super.key, required this.article});

  // Add this function to handle article deletion
  Future<void> _deleteArticle(BuildContext context) async {
    // Show confirmation dialog first
    final bool confirmDelete =
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Xác nhận xóa'),
              content: Text(
                'Bạn có chắc chắn muốn xóa bài viết "${article.title}" không?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmDelete) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // Delete from Supabase
      await supabase.from('articles').delete().eq('id', article.id);

      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      // Show success message and return to articles list
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bài viết đã được xóa thành công')),
        );
        // Pop twice to return to articles list and indicate that refresh is needed
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể xóa bài viết: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                tooltip: 'Xóa bài viết',
                onPressed: () => _deleteArticle(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                article.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background:
                  article.thumbnailUrl != null
                      ? CachedNetworkImage(
                        imageUrl: article.thumbnailUrl!,
                        fit: BoxFit.cover,
                      )
                      : Container(color: Theme.of(context).primaryColor),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(child: Text(article.authorName[0])),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                article.authorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(article.timeAgo),
                            ],
                          ),
                        ],
                      ),
                      Text('${article.viewCount} lượt xem'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        article.categories.map((category) {
                          return Chip(label: Text(category));
                        }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    article.content,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                  if (article.tags != null && article.tags!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Tags:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          article.tags!.map((tag) {
                            return Chip(
                              label: Text('#$tag'),
                              backgroundColor: Colors.grey[200],
                            );
                          }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildRelatedArticlesSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Thêm logic chia sẻ bài viết
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chức năng chia sẻ đang phát triển')),
          );
        },
        tooltip: 'Chia sẻ bài viết',
        child: const Icon(Icons.share),
      ),
    );
  }

  Widget _buildRelatedArticlesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bài viết liên quan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Article>>(
          future: _fetchRelatedArticles(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Text('Lỗi: ${snapshot.error}');
            }

            final relatedArticles = snapshot.data ?? [];

            if (relatedArticles.isEmpty) {
              return const Text('Không có bài viết liên quan');
            }

            return SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: relatedArticles.length,
                itemBuilder: (context, index) {
                  final relatedArticle = relatedArticles[index];
                  return _buildRelatedArticleCard(context, relatedArticle);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRelatedArticleCard(
    BuildContext context,
    Article relatedArticle,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(article: relatedArticle),
          ),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  relatedArticle.thumbnailUrl != null
                      ? CachedNetworkImage(
                        imageUrl: relatedArticle.thumbnailUrl!,
                        height: 120,
                        width: 200,
                        fit: BoxFit.cover,
                      )
                      : Container(
                        height: 120,
                        width: 200,
                        color: Theme.of(context).primaryColor,
                        child: const Icon(Icons.article, color: Colors.white),
                      ),
            ),
            const SizedBox(height: 8),
            Text(
              relatedArticle.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              relatedArticle.timeAgo,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Article>> _fetchRelatedArticles() async {
    try {
      // Don't filter by categories on the server side to avoid type issues
      final data = await supabase
          .from('articles')
          .select()
          .neq('id', article.id)
          .order('publish_date', ascending: false)
          .limit(10);

      List<Article> articles;

      try {
        articles = List<Article>.from(
          data.map((json) => Article.fromJson(json)),
        );
      } catch (e) {
        debugPrint('Error parsing articles: $e');
        return [];
      }

      // Filter related articles on the client side based on matching categories
      final relatedArticles =
          articles
              .where((a) {
                // Check if any category in the current article is contained in this article
                return article.categories.any(
                  (category) => a.categories.contains(category),
                );
              })
              .take(5)
              .toList();

      return relatedArticles;
    } catch (e) {
      debugPrint('Lỗi khi tải bài viết liên quan: $e');
      return [];
    }
  }
}
