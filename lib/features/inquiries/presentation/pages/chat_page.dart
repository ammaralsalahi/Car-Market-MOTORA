
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:motora/features/inquiries/data/inquiries_service.dart';

class ChatPage extends StatefulWidget {
  final Map<String, dynamic> inquiry;

  const ChatPage({
    super.key,
    required this.inquiry,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final InquiriesService _service = InquiriesService();

  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController = ScrollController();

  static const Color backgroundColor = Color(0xFF101114);
  static const Color cardColor = Color(0xFF1E2024);
  static const Color accentColor = Color(0xFFF8ED00);
  static const Color secondaryText = Color(0xFF9A9CA3);

  List<Map<String, dynamic>> _messages = [];

  dynamic _channel;

  bool _isLoading = true;
  bool _isSending = false;

  String get _inquiryId => widget.inquiry['id'].toString();

  String get _currentUserId {
    return Supabase.instance.client.auth.currentUser?.id ?? '';
  }

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

 Future<void> _initializeChat() async {
  _channel = _service.subscribeToMessages(
    inquiryId: _inquiryId,
    onNewMessage: () {
      if (!mounted) return;
      _loadMessages();
    },
  );

  await _loadMessages();
}
  Future<void> _loadMessages() async {
    try {
      final messages = await _service.getMessages(_inquiryId);

      if (!mounted) return;

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      debugPrint('Load messages error: $e');
    }
  }

void _scrollToBottom() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted || !_scrollController.hasClients) return;

    final position = _scrollController.position;

    _scrollController.jumpTo(
      position.maxScrollExtent,
    );
  });
}

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();

    if (message.isEmpty || _isSending) return;

    if (_currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to send messages'),
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await _service.sendMessage(
        inquiryId: _inquiryId,
        message: message,
      );

      _messageController.clear();

      await _loadMessages();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not send message: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  String _carName() {
    final car = widget.inquiry['car'] as Map<String, dynamic>?;

    if (car == null) return 'Car';

    final brand = car['brands'];
    final model = car['models'];

    final brandName = brand is Map
        ? brand['name']?.toString() ?? ''
        : '';

    final modelName = model is Map
        ? model['name']?.toString() ?? ''
        : '';

    final parts = [
      brandName,
      modelName,
    ].where((item) => item.isNotEmpty).toList();

    if (parts.isNotEmpty) return parts.join(' ');

    return car['title']?.toString() ?? 'Car';
  }

  String _dealershipName() {
    final car = widget.inquiry['car'] as Map<String, dynamic>?;

    if (car == null) return 'Dealership';

    final dealership = car['dealerships'];

    if (dealership is Map) {
      return dealership['name']?.toString() ?? 'Dealership';
    }

    return 'Dealership';
  }

  String? _carImage() {
    final car = widget.inquiry['car'] as Map<String, dynamic>?;

    if (car == null) return null;

    final images = car['car_images'];

    if (images is! List || images.isEmpty) return null;

    final sortedImages = List<Map<String, dynamic>>.from(
      images.whereType<Map>().map(
        (item) => Map<String, dynamic>.from(item),
      ),
    );

    sortedImages.sort(
      (a, b) => (a['display_order'] ?? 0).compareTo(
        b['display_order'] ?? 0,
      ),
    );

    if (sortedImages.isEmpty) return null;

    return sortedImages.first['image_url']?.toString();
  }

  String _formatTime(dynamic value) {
    if (value == null) return '';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return '';

    final local = date.toLocal();

    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();

    if (_channel != null) {
      _service.unsubscribe(_channel);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _carImage();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 19,
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: const Color(0xFF303238),
              child: const Icon(
                Icons.storefront_rounded,
                color: accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dealershipName(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Dealership conversation',
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildCarHeader(imageUrl),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: accentColor,
                    ),
                  )
                : _buildMessages(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildCarHeader(String? imageUrl) {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 14, 15, 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 62,
              height: 55,
              color: const Color(0xFF303238),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _carPlaceholder(),
                    )
                  : _carPlaceholder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'INQUIRY ABOUT',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _carName(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.directions_car_rounded,
            color: accentColor,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _carPlaceholder() {
    return const Center(
      child: Icon(
        Icons.directions_car_rounded,
        color: secondaryText,
        size: 28,
      ),
    );
  }

  Widget _buildMessages() {
    final initialMessage =
        widget.inquiry['message']?.toString().trim() ?? '';

    // إذا كانت الرسائل موجودة في inquiry_messages
    // فلا نعرض inquiry.message مرة أخرى.
    if (_messages.isEmpty && initialMessage.isNotEmpty) {
      return ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        children: [
          _buildMessageBubble(
            message: initialMessage,
            isMine: true,
            time: widget.inquiry['created_at'],
          ),
        ],
      );
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet',
          style: TextStyle(
            color: secondaryText,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];

        return _buildMessageBubble(
          message: message['message']?.toString() ?? '',
          isMine: message['sender_id']?.toString() == _currentUserId,
          time: message['created_at'],
        );
      },
    );
  }

  Widget _buildMessageBubble({
    required String message,
    required bool isMine,
    required dynamic time,
  }) {
    return Align(
      alignment: isMine
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 8),
        decoration: BoxDecoration(
          color: isMine ? accentColor : cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isMine ? Colors.black : Colors.white,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatTime(time),
              style: TextStyle(
                color: isMine
                    ? Colors.black.withValues(alpha: 0.55)
                    : secondaryText,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Write a message...',
                    hintStyle: TextStyle(
                      color: secondaryText,
                      fontSize: 13,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 9),
            GestureDetector(
              onTap: _isSending ? null : _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.black,
                        size: 21,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
