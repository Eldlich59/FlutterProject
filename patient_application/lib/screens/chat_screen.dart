// ignore_for_file: unnecessary_cast

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:patient_application/main.dart';
import 'package:timeago/timeago.dart' as timeago;

// Màn hình danh sách bác sĩ để chat
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _recentChats = [];
  bool _isLoading = true;
  String _searchQuery = ''; // Add search query state
  final TextEditingController _searchController =
      TextEditingController(); // Add controller for search

  @override
  void initState() {
    super.initState();
    _loadDoctorsAndChats();
    _searchController.addListener(_onSearchChanged); // Add listener
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  // Filter doctors based on search query
  List<Map<String, dynamic>> get _filteredDoctors {
    if (_searchQuery.isEmpty) {
      return _doctors;
    }
    // Sửa từ 'full_name' thành 'name' cho khớp với model Doctor
    return _doctors.where((doctor) {
      final name = doctor['name']?.toString().toLowerCase() ?? '';
      final specialty = doctor['specialty']?.toString().toLowerCase() ?? '';
      debugPrint(
        'Filtering doctor: Name="$name", Specialty="$specialty", Query="$_searchQuery"',
      );
      return name.contains(_searchQuery) || specialty.contains(_searchQuery);
    }).toList();
  }

  Future<void> _loadDoctorsAndChats() async {
    try {
      setState(() => _isLoading = true);
      debugPrint('Starting to load doctors and chats...');

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _doctors = [];
          _recentChats = [];
          _isLoading = false;
        });
        debugPrint('User not logged in. Cannot load doctors or chats.');
        return;
      }
      debugPrint('User ID: $userId');

      // Tải danh sách bác sĩ từ bảng doctors
      debugPrint('Fetching doctors from Supabase...');
      final doctorsResponse = await supabase.from('doctors').select();
      debugPrint('Raw doctors response from Supabase: $doctorsResponse');

      List<Map<String, dynamic>> fetchedDoctors =
          List<Map<String, dynamic>>.from(doctorsResponse);
      debugPrint('Successfully fetched ${fetchedDoctors.length} doctors.');

      // Tải danh sách chat rooms
      debugPrint('Fetching chat rooms from Supabase...');
      final chatsResponse = await supabase
          .from('chat_rooms')
          .select(
            'id, patient_id, doctor_id, last_message, last_message_time, unread_count',
          )
          .eq('patient_id', userId)
          .order('last_message_time', ascending: false);

      debugPrint('Raw chat rooms response from Supabase: $chatsResponse');
      List<Map<String, dynamic>> fetchedChats = List<Map<String, dynamic>>.from(
        chatsResponse,
      );
      debugPrint('Successfully fetched ${fetchedChats.length} recent chats.');

      // Lấy thông tin bác sĩ cho mỗi chat room
      List<Map<String, dynamic>> enhancedChats = [];
      final Map<String, Map<String, dynamic>> doctorsMap = {};

      // Tạo một map của bác sĩ dựa trên ID để truy cập nhanh
      for (final doctor in fetchedDoctors) {
        if (doctor['id'] != null) {
          doctorsMap[doctor['id'].toString()] = doctor;
        }
      }

      // Thêm thông tin bác sĩ vào cuộc trò chuyện
      for (final chat in fetchedChats) {
        final doctorId = chat['doctor_id']?.toString();
        if (doctorId != null && doctorsMap.containsKey(doctorId)) {
          final doctorInfo = doctorsMap[doctorId]!;
          // Thêm thông tin bác sĩ vào chat
          final enhancedChat = {
            ...chat,
            'doctors': doctorInfo, // Thêm thông tin bác sĩ dưới key 'doctors'
          };
          enhancedChats.add(enhancedChat);
          debugPrint(
            'Added doctor info to chat: ${doctorInfo['name']} (ID: $doctorId)',
          );
        } else {
          debugPrint(
            'Could not find doctor info for chat with doctor_id: $doctorId',
          );
          // Vẫn giữ lại chat mà không có thông tin bác sĩ
          enhancedChats.add(chat);
        }
      }

      // Lấy danh sách ID bác sĩ đã có cuộc trò chuyện
      final Set<String> recentChatDoctorIds = {};
      for (final chat in enhancedChats) {
        if (chat['doctor_id'] != null) {
          final doctorId = chat['doctor_id'].toString();
          recentChatDoctorIds.add(doctorId);
        }
      }
      debugPrint('Doctor IDs from recent chats: $recentChatDoctorIds');

      // Lọc danh sách bác sĩ để hiển thị trong phần "Tất cả bác sĩ"
      final allDoctorsToShow =
          fetchedDoctors.where((doctor) {
            final doctorId = doctor['id']?.toString();
            return doctorId != null && !recentChatDoctorIds.contains(doctorId);
          }).toList();

      debugPrint(
        'Filtered doctors list now has ${allDoctorsToShow.length} entries',
      );

      setState(() {
        _doctors = allDoctorsToShow;
        _recentChats = enhancedChats;
        _isLoading = false;
      });
      debugPrint('State updated. isLoading: $_isLoading');
    } catch (e, stackTrace) {
      debugPrint('--- ERROR loading doctors/chats ---');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('------------------------------------');

      setState(() {
        _doctors = [];
        _recentChats = [];
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadDoctorsAndChats,
                child:
                    _recentChats.isEmpty && _doctors.isEmpty
                        ? _buildEmptyState()
                        : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSearchBar(),
                                const SizedBox(height: 24),
                                if (_recentChats.isNotEmpty) ...[
                                  Text(
                                    'Cuộc trò chuyện gần đây',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 16),
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _recentChats.length,
                                    separatorBuilder:
                                        (context, index) => const Divider(),
                                    itemBuilder: (context, index) {
                                      final chat = _recentChats[index];
                                      final doctor =
                                          chat['doctors']; // Thay đổi từ profiles sang doctors
                                      return _buildChatItem(doctor, chat);
                                    },
                                  ),
                                  const Divider(height: 32),
                                ],
                                Text(
                                  'Tất cả bác sĩ',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 16),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _filteredDoctors.length,
                                  separatorBuilder:
                                      (context, index) => const Divider(),
                                  itemBuilder: (context, index) {
                                    final doctor = _filteredDoctors[index];
                                    return _buildDoctorItem(doctor);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateChatDialog,
        tooltip: 'Tạo cuộc trò chuyện mới',
        heroTag: 'createChatButton',
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Tìm kiếm bác sĩ',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade200,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildChatItem(
    Map<String, dynamic>? doctor, // Make doctor nullable
    Map<String, dynamic> chat,
  ) {
    // Handle cases where doctor data might be missing in the chat relation
    if (doctor == null) {
      debugPrint('Chat item is missing doctor data: $chat');
      // Optionally return an empty container or a placeholder
      return const SizedBox.shrink(); // Or return a ListTile indicating missing data
    }

    // Safely access doctor properties, assuming Supabase columns are 'name', 'avatar_url'
    final doctorName = doctor['name'] ?? 'Bác sĩ không rõ';
    final doctorAvatar = doctor['avatar_url'];
    debugPrint(
      'Building chat item for doctor: $doctorName, Avatar: $doctorAvatar',
    );

    final lastMessageTime =
        DateTime.tryParse(chat['last_message_time'] ?? '') ?? DateTime.now();
    final timeAgo = timeago.format(lastMessageTime, locale: 'vi');
    final unreadCount = chat['unread_count'] ?? 0; // Default to 0 if null

    return ListTile(
      leading: CircleAvatar(
        radius: 26,
        backgroundImage:
            doctorAvatar != null && doctorAvatar.isNotEmpty
                ? CachedNetworkImageProvider(doctorAvatar)
                : const AssetImage('assets/images/default_avatar.png')
                    as ImageProvider,
      ),
      title: Text(
        doctorName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              chat['last_message'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            ' • $timeAgo',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
      trailing:
          unreadCount > 0
              ? CircleAvatar(
                radius: 10,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
              : null,
      onTap: () {
        // Ensure doctor ID is available before navigating
        final doctorId = doctor['id']?.toString();
        if (doctorId == null) {
          debugPrint('Cannot navigate to chat: Doctor ID is missing.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Không thể mở cuộc trò chuyện, thiếu thông tin bác sĩ.',
              ),
            ),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatScreen(
                  doctorId: doctorId,
                  doctorName: doctorName, // Use the safe variable
                  doctorAvatar: doctorAvatar, // Use the safe variable
                  chatRoomId: chat['id'],
                ),
          ),
        );
      },
    );
  }

  Widget _buildDoctorItem(Map<String, dynamic> doctor) {
    // Log the data received for this doctor item
    debugPrint('Building doctor item for "All Doctors": $doctor');

    // IMPORTANT: Ensure these keys match your Supabase 'doctors' table columns!
    final doctorName = doctor['name'] ?? 'Bác sĩ không rõ';
    final specialty = doctor['specialty'] ?? 'Chuyên khoa không rõ';
    final avatarUrl = doctor['avatar_url'];
    final doctorId = doctor['id']?.toString(); // Get ID for navigation

    if (doctorId == null) {
      debugPrint(
        'Skipping doctor item build: Doctor ID is missing. Data: $doctor',
      );
      return const SizedBox.shrink(); // Don't build item if ID is missing
    }

    return ListTile(
      leading: CircleAvatar(
        radius: 26,
        backgroundImage:
            avatarUrl != null && avatarUrl.isNotEmpty
                ? CachedNetworkImageProvider(avatarUrl)
                : const AssetImage('assets/images/default_avatar.png')
                    as ImageProvider,
      ),
      title: Text(
        doctorName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(specialty, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chat_bubble_outline),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatScreen(
                  doctorId: doctorId, // Use the retrieved ID
                  doctorName: doctorName,
                  doctorAvatar: avatarUrl,
                  // No chatRoomId needed when starting a new chat from this list
                ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Chưa có cuộc trò chuyện nào',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Bắt đầu trò chuyện với bác sĩ để tư vấn về vấn đề sức khỏe của bạn',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDoctorsAndChats,
              icon: const Icon(Icons.refresh),
              label: const Text('Tải lại'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateChatDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tạo cuộc trò chuyện mới'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Tìm bác sĩ',
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Nhập tên hoặc chuyên khoa...',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chọn bác sĩ để bắt đầu cuộc trò chuyện:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount:
                          _filteredDoctors.length > 5
                              ? 5
                              : _filteredDoctors.length,
                      itemBuilder: (context, index) {
                        final doctor = _filteredDoctors[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundImage:
                                doctor['avatar_url'] != null
                                    ? CachedNetworkImageProvider(
                                      doctor['avatar_url'],
                                    )
                                    : const AssetImage(
                                          'assets/images/default_avatar.png',
                                        )
                                        as ImageProvider,
                          ),
                          title: Text(doctor['name'] ?? 'Bác sĩ'),
                          subtitle: Text(doctor['specialty'] ?? 'Chuyên khoa'),
                          onTap: () {
                            Navigator.pop(context); // Close dialog
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ChatScreen(
                                      doctorId: doctor['id'],
                                      doctorName: doctor['name'] ?? 'Bác sĩ',
                                      doctorAvatar: doctor['avatar_url'],
                                    ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showAllDoctorsDialog();
                },
                child: const Text('Xem tất cả bác sĩ'),
              ),
            ],
          ),
    );
  }

  void _showAllDoctorsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (context, scrollController) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text(
                            'Danh sách bác sĩ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm bác sĩ',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredDoctors.length,
                        itemBuilder: (context, index) {
                          final doctor = _filteredDoctors[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    doctor['avatar_url'] != null
                                        ? CachedNetworkImageProvider(
                                          doctor['avatar_url'],
                                        )
                                        : const AssetImage(
                                              'assets/images/default_avatar.png',
                                            )
                                            as ImageProvider,
                              ),
                              title: Text(
                                doctor['name'] ?? 'Bác sĩ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(doctor['specialty'] ?? 'Chuyên khoa'),
                                  if (doctor['hospital'] != null)
                                    Text(
                                      doctor['hospital'],
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close modal
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ChatScreen(
                                            doctorId: doctor['id'],
                                            doctorName:
                                                doctor['name'] ?? 'Bác sĩ',
                                            doctorAvatar: doctor['avatar_url'],
                                          ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text('Trò chuyện'),
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

// Màn hình chat với bác sĩ
class ChatScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String? doctorAvatar;
  final String? chatRoomId;

  const ChatScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
    this.doctorAvatar,
    this.chatRoomId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  String? _chatRoomId;
  bool _isLoading = true;
  bool _isSending = false;
  // Change from late to nullable
  Stream<List<Map<String, dynamic>>>? _messagesStream;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      setState(() => _isLoading = true);

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Nếu đã có ID phòng chat, sử dụng nó
      // Nếu không, tạo phòng chat mới
      _chatRoomId = widget.chatRoomId;
      if (_chatRoomId == null) {
        // Kiểm tra xem đã có phòng chat với bác sĩ này chưa
        final existingRoom =
            await supabase
                .from('chat_rooms')
                .select()
                .eq('patient_id', userId)
                .eq('doctor_id', widget.doctorId)
                .maybeSingle();

        if (existingRoom != null) {
          _chatRoomId = existingRoom['id'];
        } else {
          // Tạo phòng chat mới
          final newRoom =
              await supabase.from('chat_rooms').insert({
                'patient_id': userId,
                'doctor_id': widget.doctorId,
                'created_at': DateTime.now().toIso8601String(),
                'last_message_time': DateTime.now().toIso8601String(),
                'last_message': '',
                'unread_count': 0,
                'unread_doctor': 0, // Số tin nhắn chưa đọc của bác sĩ
                'unread_patient': 0, // Số tin nhắn chưa đọc của bệnh nhân
              }).select();

          if (newRoom.isNotEmpty) {
            _chatRoomId = newRoom[0]['id'];
          }
        }
      }

      // Cập nhật trạng thái đã đọc cho bệnh nhân
      if (_chatRoomId != null) {
        await supabase
            .from('chat_rooms')
            .update({'unread_patient': 0})
            .eq('id', _chatRoomId as Object);
      }

      // Thiết lập stream để lắng nghe tin nhắn mới
      _setupMessagesStream();

      // Tải tin nhắn cũ
      await _loadMessages();

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Lỗi khi khởi tạo chat: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupMessagesStream() {
    if (_chatRoomId == null) {
      debugPrint('Không thể thiết lập stream tin nhắn vì chatRoomId là null');
      return;
    }

    try {
      _messagesStream = supabase
          .from('chat_messages')
          .stream(primaryKey: ['id'])
          .eq('chat_room_id', _chatRoomId as Object)
          .order(
            'created_at',
            ascending: true,
          ) // Thay đổi thành ascending: true để tin nhắn cũ hiển thị trên cùng, mới nhất ở dưới
          .map(
            (events) => events.map((e) => e as Map<String, dynamic>).toList(),
          );

      _messagesStream?.listen(
        (messages) {
          if (mounted) {
            setState(() {
              _messages = messages;
            });

            // Cuộn xuống tin nhắn mới nhất sau khi UI được cập nhật
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                try {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                } catch (e) {
                  debugPrint('Lỗi khi cuộn xuống tin nhắn mới: $e');
                }
              }
            });
          }
        },
        onError: (error) {
          debugPrint('Lỗi từ stream tin nhắn: $error');
        },
        cancelOnError: false, // Không hủy stream khi có lỗi
      );
    } catch (e) {
      debugPrint('Lỗi khi thiết lập stream tin nhắn: $e');
    }
  }

  Future<void> _loadMessages() async {
    if (_chatRoomId == null) return;

    try {
      final messagesData = await supabase
          .from('chat_messages')
          .select()
          .eq('chat_room_id', _chatRoomId as Object)
          .order(
            'created_at',
            ascending: true,
          ); // Thay đổi thành ascending: true để hiển thị tin nhắn cũ ở trên, mới ở dưới

      setState(() {
        _messages = messagesData;
      });

      // Cuộn xuống tin nhắn mới nhất
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      debugPrint('Lỗi khi tải tin nhắn: $e');
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending || _chatRoomId == null) return;

    // Lưu bản sao của tin nhắn để khôi phục nếu có lỗi
    final messageContent = message;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception("Người dùng chưa đăng nhập");
      }

      // Tạo timestamp cho tin nhắn
      final timestamp = DateTime.now().toIso8601String();

      // Bước 1: Thêm tin nhắn vào cơ sở dữ liệu
      await supabase.from('chat_messages').insert({
        'chat_room_id': _chatRoomId,
        'sender_id': userId,
        'message': messageContent,
        'created_at': timestamp,
      });

      // Bước 2: Cập nhật thông tin phòng chat - Không sử dụng RPC
      try {
        // Lấy giá trị unread_doctor hiện tại
        final chatRoomData =
            await supabase
                .from('chat_rooms')
                .select('unread_doctor')
                .eq('id', _chatRoomId as Object)
                .single();

        final currentUnreadCount = chatRoomData['unread_doctor'] ?? 0;

        await supabase
            .from('chat_rooms')
            .update({
              'last_message': messageContent,
              'last_message_time': timestamp,
              'unread_count': 1,
              'unread_doctor':
                  currentUnreadCount + 1, // Tăng giá trị thay vì dùng RPC
            })
            .eq('id', _chatRoomId as Object);
      } catch (updateError) {
        // Nếu cập nhật phòng chat gặp lỗi, ghi log nhưng không ảnh hưởng đến người dùng
        // vì tin nhắn đã được thêm thành công
        debugPrint('Lỗi khi cập nhật thông tin phòng chat: $updateError');
        // Không hiển thị lỗi cho người dùng vì tin nhắn vẫn được gửi thành công
      }
    } catch (e) {
      debugPrint('Lỗi khi gửi tin nhắn: $e');

      // Khôi phục tin nhắn trong ô nhập liệu nếu gửi thất bại
      if (mounted) {
        _messageController.text = messageContent;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể gửi tin nhắn: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: () => _sendMessage(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage:
                  widget.doctorAvatar != null
                      ? CachedNetworkImageProvider(widget.doctorAvatar!)
                      : const AssetImage('assets/images/default_avatar.png')
                          as ImageProvider,
            ),
            const SizedBox(width: 8),
            Text(widget.doctorName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Hiển thị thông tin bác sĩ
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      // Handle null _messagesStream with an empty stream
                      stream: _messagesStream ?? Stream.value([]),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            _messages.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final messages = snapshot.data ?? _messages;

                        if (messages.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Chưa có tin nhắn nào',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Hãy bắt đầu cuộc trò chuyện với bác sĩ',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final userId = supabase.auth.currentUser?.id;
                            final isMe = message['sender_id'] == userId;

                            return _buildMessageBubble(message, isMe);
                          },
                        );
                      },
                    ),
                  ),
                  _buildMessageInput(),
                ],
              ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    final messageTime = DateTime.parse(message['created_at']);
    final timeString =
        '${messageTime.hour}:${messageTime.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage:
                  widget.doctorAvatar != null
                      ? CachedNetworkImageProvider(widget.doctorAvatar!)
                      : const AssetImage('assets/images/default_avatar.png')
                          as ImageProvider,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isMe
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message['message'] ?? '',
                    style: TextStyle(color: isMe ? Colors.white : Colors.black),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeString,
                    style: TextStyle(
                      color:
                          isMe
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: () {
                // Chức năng đính kèm tệp
              },
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon:
                    _isSending
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
