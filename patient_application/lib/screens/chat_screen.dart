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

  @override
  void initState() {
    super.initState();
    _loadDoctorsAndChats();
  }

  Future<void> _loadDoctorsAndChats() async {
    try {
      setState(() => _isLoading = true);

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Tải danh sách bác sĩ
      final doctorsData = await supabase
          .from('profiles')
          .select()
          .eq('role', 'doctor')
          .order('full_name');

      // Tải danh sách cuộc trò chuyện gần đây
      final chatsData = await supabase
          .from('chat_rooms')
          .select('*, profiles(*)')
          .eq('patient_id', userId)
          .order('last_message_time', ascending: false);

      setState(() {
        _doctors = doctorsData;
        _recentChats = chatsData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Lỗi khi tải danh sách bác sĩ và cuộc trò chuyện: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat với bác sĩ')),
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
                                      final doctor = chat['profiles'];
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
                                  itemCount: _doctors.length,
                                  separatorBuilder:
                                      (context, index) => const Divider(),
                                  itemBuilder: (context, index) {
                                    final doctor = _doctors[index];
                                    return _buildDoctorItem(doctor);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
              ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
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
      onChanged: (value) {
        // Thực hiện tìm kiếm
      },
    );
  }

  Widget _buildChatItem(
    Map<String, dynamic> doctor,
    Map<String, dynamic> chat,
  ) {
    final lastMessageTime = DateTime.parse(chat['last_message_time'] ?? '');
    final timeAgo = timeago.format(lastMessageTime, locale: 'vi');

    return ListTile(
      leading: CircleAvatar(
        radius: 26,
        backgroundImage:
            doctor['avatar_url'] != null
                ? CachedNetworkImageProvider(doctor['avatar_url'])
                : const AssetImage('assets/images/default_avatar.png')
                    as ImageProvider,
      ),
      title: Text(
        doctor['full_name'] ?? 'Bác sĩ',
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
          chat['unread_count'] > 0
              ? CircleAvatar(
                radius: 10,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  chat['unread_count'].toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
              : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatScreen(
                  doctorId: doctor['id'],
                  doctorName: doctor['full_name'] ?? 'Bác sĩ',
                  doctorAvatar: doctor['avatar_url'],
                  chatRoomId: chat['id'],
                ),
          ),
        );
      },
    );
  }

  Widget _buildDoctorItem(Map<String, dynamic> doctor) {
    return ListTile(
      leading: CircleAvatar(
        radius: 26,
        backgroundImage:
            doctor['avatar_url'] != null
                ? CachedNetworkImageProvider(doctor['avatar_url'])
                : const AssetImage('assets/images/default_avatar.png')
                    as ImageProvider,
      ),
      title: Text(
        doctor['full_name'] ?? 'Bác sĩ',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        doctor['specialty'] ?? 'Chuyên khoa',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chat_bubble_outline),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatScreen(
                  doctorId: doctor['id'],
                  doctorName: doctor['full_name'] ?? 'Bác sĩ',
                  doctorAvatar: doctor['avatar_url'],
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
  late Stream<List<Map<String, dynamic>>> _messagesStream;

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
              }).select();

          if (newRoom.isNotEmpty) {
            _chatRoomId = newRoom[0]['id'];
          }
        }
      }

      // Cập nhật trạng thái đã đọc
      if (_chatRoomId != null) {
        await supabase
            .from('chat_rooms')
            .update({'unread_count': 0})
            .eq('id', _chatRoomId as Object);
      }

      // Thiết lập stream để lắng nghe tin nhắn mới
      _setupMessagesStream();

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Lỗi khi khởi tạo chat: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupMessagesStream() {
    if (_chatRoomId == null) return;

    _messagesStream = supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('chat_room_id', _chatRoomId as Object)
        .order('created_at')
        .map((events) => events.map((e) => e as Map<String, dynamic>).toList());

    _messagesStream.listen((messages) {
      setState(() {
        _messages = messages;
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
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending || _chatRoomId == null) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Thêm tin nhắn vào cơ sở dữ liệu
      await supabase.from('chat_messages').insert({
        'chat_room_id': _chatRoomId,
        'sender_id': userId,
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Cập nhật thông tin phòng chat
      await supabase
          .from('chat_rooms')
          .update({
            'last_message': message,
            'last_message_time': DateTime.now().toIso8601String(),
            'unread_count': 1, // Đối với bác sĩ, tin nhắn này chưa đọc
          })
          .eq('id', _chatRoomId as Object);
    } catch (e) {
      debugPrint('Lỗi khi gửi tin nhắn: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể gửi tin nhắn. Vui lòng thử lại.'),
        ),
      );
    } finally {
      setState(() => _isSending = false);
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
                      stream: _messagesStream,
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
