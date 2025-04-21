import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
//import 'package:patient_application/models/article.dart';
import 'package:patient_application/main.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

class CreateArticleScreen extends StatefulWidget {
  const CreateArticleScreen({super.key});

  @override
  State<CreateArticleScreen> createState() => _CreateArticleScreenState();
}

class _CreateArticleScreenState extends State<CreateArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _authorNameController = TextEditingController();
  final List<String> _selectedCategories = [];
  List<String> _availableCategories = [];
  final List<String> _tags = [];
  String _tagInput = '';
  File? _thumbnailImage;
  bool _isFeatured = false;
  bool _isLoading = false;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _authorNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final userData =
          await supabase
              .from('patients')
              .select('full_name')
              .eq('id', userId)
              .single();

      if (userData['full_name'] != null) {
        setState(() {
          _authorNameController.text = userData['full_name'];
        });
      }
    } catch (e) {
      debugPrint('Error loading user info: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      setState(() => _isLoadingCategories = true);

      // Get all articles to extract all available categories
      final data = await supabase.from('articles').select('categories');

      // Extract unique categories from all articles
      final Set<String> categories = {};
      for (var article in data) {
        if (article['categories'] != null) {
          categories.addAll(List<String>.from(article['categories']));
        }
      }

      setState(() {
        _availableCategories = categories.toList()..sort();
        _isLoadingCategories = false;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _thumbnailImage = File(image.path));
    }
  }

  Future<String?> _uploadThumbnail() async {
    if (_thumbnailImage == null) return null;

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final ext = path.extension(_thumbnailImage!.path);
      final fileName = '${const Uuid().v4()}$ext';
      final filePath = 'articles/$userId/$fileName';

      await supabase.storage
          .from('article_thumbnails')
          .upload(filePath, _thumbnailImage!);

      // Get public URL for the uploaded image
      final imageUrl = supabase.storage
          .from('article_thumbnails')
          .getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading thumbnail: $e');
      return null;
    }
  }

  void _addTag() {
    if (_tagInput.isNotEmpty && !_tags.contains(_tagInput)) {
      setState(() {
        _tags.add(_tagInput);
        _tagInput = '';
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _submitArticle() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một danh mục')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn phải đăng nhập để tạo bài viết')),
        );
        return;
      }

      // Upload thumbnail if selected
      String? thumbnailUrl;
      if (_thumbnailImage != null) {
        thumbnailUrl = await _uploadThumbnail();
      }

      // Create article object
      final article = {
        'title': _titleController.text,
        'content': _contentController.text,
        'author_name': _authorNameController.text,
        'thumbnail_url': thumbnailUrl,
        'publish_date': DateTime.now().toIso8601String(),
        'categories': _selectedCategories,
        'is_featured': _isFeatured,
        'view_count': 0,
        'tags': _tags.isEmpty ? null : _tags,
        'author_id': userId, // Track who created the article
      };

      // Save to Supabase
      await supabase.from('articles').insert(article);

      // Show success message and return to articles screen
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo bài viết thành công')),
      );

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi tạo bài viết: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo bài viết mới'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _submitArticle,
            icon:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.check),
            label: const Text('Đăng'),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail selection
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              image:
                                  _thumbnailImage != null
                                      ? DecorationImage(
                                        image: FileImage(_thumbnailImage!),
                                        fit: BoxFit.cover,
                                      )
                                      : null,
                            ),
                            child:
                                _thumbnailImage == null
                                    ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          size: 48,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Thêm ảnh bìa',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    )
                                    : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Tiêu đề',
                          border: OutlineInputBorder(),
                        ),
                        maxLength: 100,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập tiêu đề';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Author name
                      TextFormField(
                        controller: _authorNameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên tác giả',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập tên tác giả';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Content
                      TextFormField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          labelText: 'Nội dung',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 10,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập nội dung';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Categories
                      Text(
                        'Danh mục',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _isLoadingCategories
                          ? const CircularProgressIndicator()
                          : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // Option to create new category
                              InputChip(
                                avatar: const Icon(
                                  Icons.add_circle_outline,
                                  size: 18,
                                ),
                                label: const Text('Danh mục mới'),
                                onPressed:
                                    () => _showAddCategoryDialog(context),
                              ),
                              // Available categories
                              ..._availableCategories.map((category) {
                                final isSelected = _selectedCategories.contains(
                                  category,
                                );
                                return FilterChip(
                                  label: Text(category),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedCategories.add(category);
                                      } else {
                                        _selectedCategories.remove(category);
                                      }
                                    });
                                  },
                                );
                              }),
                            ],
                          ),
                      if (_selectedCategories.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Vui lòng chọn ít nhất một danh mục',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Tags
                      Text(
                        'Tags',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                hintText: 'Nhập tag và nhấn Thêm',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) => _tagInput = value,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addTag,
                            child: const Text('Thêm'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _tags
                                .map(
                                  (tag) => Chip(
                                    label: Text(tag),
                                    onDeleted: () => _removeTag(tag),
                                    deleteIcon: const Icon(
                                      Icons.close,
                                      size: 16,
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 24),

                      // Featured article toggle
                      SwitchListTile(
                        title: const Text('Đánh dấu là bài viết nổi bật'),
                        subtitle: const Text(
                          'Bài viết nổi bật sẽ xuất hiện ở trang chủ',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _isFeatured,
                        onChanged: (value) {
                          setState(() {
                            _isFeatured = value;
                          });
                        },
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
    );
  }

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Thêm danh mục mới'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Tên danh mục'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Thêm'),
              onPressed: () {
                final newCategory = controller.text.trim();
                if (newCategory.isNotEmpty) {
                  setState(() {
                    if (!_availableCategories.contains(newCategory)) {
                      _availableCategories.add(newCategory);
                      _availableCategories.sort();
                    }
                    _selectedCategories.add(newCategory);
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
