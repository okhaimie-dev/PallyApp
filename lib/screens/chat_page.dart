import 'dart:async';
import 'package:flutter/material.dart';
import 'user_profile_screen.dart';
import '../services/group_service.dart';
import '../services/websocket_service.dart';

class ChatPage extends StatefulWidget {
  final Group group;
  final String userEmail;

  const ChatPage({
    super.key,
    required this.group,
    required this.userEmail,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  List<ChatMessage> _messages = [];
  bool _isLoadingMessages = false;
  bool _isSendingMessage = false;
  late WebSocketService _wsService;
  bool _isTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _wsService = WebSocketService.getInstance();
    _loadMessages();
    _setupWebSocket();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _typingTimer?.cancel();
    _wsService.leaveGroup();
    super.dispose();
  }

  void _setupWebSocket() async {
    // Connect to WebSocket if not already connected
    if (!_wsService.isConnected) {
      await _wsService.connect(widget.userEmail);
    }

    // Join the group
    await _wsService.joinGroup(widget.group.id);

    // Listen for new messages
    _wsService.messageStream.listen((data) {
      if (data['groupId'] == widget.group.id) {
        setState(() {
          _messages.add(ChatMessage(
            text: data['content'],
            isMe: data['senderEmail'] == widget.userEmail,
            senderName: data['senderEmail'] == widget.userEmail ? "You" : _getDisplayName(data['senderEmail']),
            timestamp: DateTime.parse(data['createdAt']),
          ));
        });
      }
    });

    // Listen for typing indicators
    _wsService.typingStream.listen((data) {
      if (data['groupId'] == widget.group.id && data['userEmail'] != widget.userEmail) {
        // Handle typing indicators if needed
        print('User ${data['userEmail']} is ${data['isTyping'] ? 'typing' : 'not typing'}');
      }
    });
  }

  void _loadMessages() async {
    setState(() {
      _isLoadingMessages = true;
    });

    try {
      final messages = await GroupService.getGroupMessages(
        groupId: widget.group.id,
        userEmail: widget.userEmail,
        limit: 50,
      );

      setState(() {
        _messages = messages.map((msg) => ChatMessage(
          text: msg.content,
          isMe: msg.senderEmail == widget.userEmail,
          senderName: msg.senderEmail == widget.userEmail ? "You" : _getDisplayName(msg.senderEmail),
          timestamp: DateTime.parse(msg.createdAt),
        )).toList();
        _isLoadingMessages = false;
      });
    } catch (e) {
      print('Error loading messages: $e');
      setState(() {
        _isLoadingMessages = false;
      });
    }
  }

  String _getDisplayName(String email) {
    // Extract name from email (simple implementation)
    return email.split('@')[0];
  }

  IconData _getIconFromString(String iconString) {
    switch (iconString) {
      case 'computer':
        return Icons.computer;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'music_note':
        return Icons.music_note;
      case 'palette':
        return Icons.palette;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'business':
        return Icons.business;
      case 'school':
        return Icons.school;
      default:
        return Icons.group;
    }
  }

  Color _getColorFromString(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF6366F1);
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSendingMessage) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isSendingMessage = true;
    });

    try {
      // Send message via WebSocket for real-time delivery
      await _wsService.sendMessage(
        groupId: widget.group.id,
        content: messageText,
      );

      // Stop typing indicator
      _wsService.stopTyping(widget.group.id);
      _isTyping = false;

      // The message will be added to the list via WebSocket stream
      // No need to add it manually here
    } catch (e) {
      print('Error sending message: $e');
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    } finally {
      setState(() {
        _isSendingMessage = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getColorFromString(widget.group.color).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_getIconFromString(widget.group.icon), color: _getColorFromString(widget.group.color), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.group.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.group.isPrivate ? 'Private Group' : 'Public Group',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () => _showGroupOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _isLoadingMessages
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
          
          // Message Input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              border: Border(
                top: BorderSide(color: Color(0xFF2A2A2A), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      onChanged: (text) {
                        if (text.isNotEmpty && !_isTyping) {
                          _isTyping = true;
                          _wsService.startTyping(widget.group.id);
                        }
                        
                        // Reset typing timer
                        _typingTimer?.cancel();
                        _typingTimer = Timer(const Duration(seconds: 2), () {
                          if (_isTyping) {
                            _isTyping = false;
                            _wsService.stopTyping(widget.group.id);
                          }
                        });
                      },
                      onSubmitted: (value) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isSendingMessage ? null : _sendMessage,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _getColorFromString(widget.group.color),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: _isSendingMessage
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 18,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isMe) ...[
            GestureDetector(
              onTap: () => _navigateToUserProfile(message.senderName),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: _getColorFromString(widget.group.color).withOpacity(0.3),
                child: Text(
                  message.senderName[0].toUpperCase(),
                  style: TextStyle(
                    color: _getColorFromString(widget.group.color),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isMe 
                    ? _getColorFromString(widget.group.color)
                    : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!message.isMe)
                    Text(
                      message.senderName,
                      style: TextStyle(
                        color: _getColorFromString(widget.group.color),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (!message.isMe) const SizedBox(height: 4),
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isMe ? Colors.white : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: message.isMe 
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[400],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return "now";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes}m";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}h";
    } else {
      return "${difference.inDays}d";
    }
  }


  void _navigateToUserProfile(String userName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userName: userName,
          userEmail: userName == "You" ? "you@example.com" : "${userName.toLowerCase().replaceAll(' ', '.')}@example.com",
          userPhotoUrl: null,
          isCurrentUser: userName == "You",
        ),
      ),
    );
  }

  void _showGroupOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionTile(Icons.info_outline, "Group Info", () {}),
            _buildOptionTile(Icons.notifications, "Notifications", () {}),
            _buildOptionTile(Icons.people, "Members", () {}),
            _buildOptionTile(Icons.settings, "Settings", () {}),
            _buildOptionTile(Icons.exit_to_app, "Leave Group", () {}, isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.white70,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}

class ChatMessage {
  final String text;
  final bool isMe;
  final String senderName;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.senderName,
    required this.timestamp,
  });
}
