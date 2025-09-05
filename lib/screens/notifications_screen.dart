import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    // Mock data - in real app, this would come from your backend
    _notifications = [
      NotificationItem(
        id: '1',
        title: 'New Tip Received!',
        message: 'Alex Johnson sent you a tip of \$25.00',
        type: NotificationType.tip,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isRead: false,
        actionData: {'from': 'Alex Johnson', 'amount': 25.00},
      ),
      NotificationItem(
        id: '2',
        title: 'Group Invitation',
        message: 'You\'ve been invited to join "Flutter Developers"',
        type: NotificationType.groupInvite,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
        actionData: {'groupName': 'Flutter Developers'},
      ),
      NotificationItem(
        id: '3',
        title: 'New Message',
        message: 'Sarah Chen sent a message in "Design Community"',
        type: NotificationType.message,
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        isRead: true,
        actionData: {'sender': 'Sarah Chen', 'groupName': 'Design Community'},
      ),
      NotificationItem(
        id: '4',
        title: 'Tip Sent Successfully',
        message: 'Your tip of \$15.00 to Mike Wilson was sent',
        type: NotificationType.tipSent,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
        actionData: {'to': 'Mike Wilson', 'amount': 15.00},
      ),
      NotificationItem(
        id: '5',
        title: 'Welcome to Pally!',
        message: 'Thanks for joining our community. Start exploring groups!',
        type: NotificationType.system,
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        isRead: true,
        actionData: {},
      ),
    ];
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
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(
              'Mark all read',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _buildNotificationCard(notification);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see notifications for tips, messages, and more here',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return GestureDetector(
      onTap: () => _handleNotificationTap(notification),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead 
              ? const Color(0xFF1A1A1A) 
              : const Color(0xFF1A1A1A).withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: notification.isRead 
              ? null 
              : Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getNotificationColor(notification.type).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: _getNotificationColor(notification.type),
                size: 20,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Notification Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: notification.isRead 
                                ? FontWeight.w500 
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF6366F1),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    _formatTime(notification.timestamp),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.tip:
        return Icons.attach_money;
      case NotificationType.tipSent:
        return Icons.send;
      case NotificationType.message:
        return Icons.message;
      case NotificationType.groupInvite:
        return Icons.group_add;
      case NotificationType.system:
        return Icons.info;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.tip:
        return const Color(0xFF10B981);
      case NotificationType.tipSent:
        return const Color(0xFF6366F1);
      case NotificationType.message:
        return const Color(0xFF8B5CF6);
      case NotificationType.groupInvite:
        return const Color(0xFFF59E0B);
      case NotificationType.system:
        return const Color(0xFF6B7280);
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }

  void _handleNotificationTap(NotificationItem notification) {
    // Mark as read
    setState(() {
      notification.isRead = true;
    });

    // Handle different notification types
    switch (notification.type) {
      case NotificationType.tip:
        _showTipReceivedDialog(notification);
        break;
      case NotificationType.tipSent:
        _showTipSentDialog(notification);
        break;
      case NotificationType.message:
        // Navigate to chat
        break;
      case NotificationType.groupInvite:
        _showGroupInviteDialog(notification);
        break;
      case NotificationType.system:
        // No action needed
        break;
    }
  }

  void _showTipReceivedDialog(NotificationItem notification) {
    final from = notification.actionData['from'] as String;
    final amount = notification.actionData['amount'] as double;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Tip Received!',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '$from sent you a tip of \$${amount.toStringAsFixed(2)}',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Colors.grey[400])),
          ),
        ],
      ),
    );
  }

  void _showTipSentDialog(NotificationItem notification) {
    final to = notification.actionData['to'] as String;
    final amount = notification.actionData['amount'] as double;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Tip Sent!',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Your tip of \$${amount.toStringAsFixed(2)} to $to was sent successfully',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Colors.grey[400])),
          ),
        ],
      ),
    );
  }

  void _showGroupInviteDialog(NotificationItem notification) {
    final groupName = notification.actionData['groupName'] as String;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Group Invitation',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'You\'ve been invited to join "$groupName"',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Decline', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle group join logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  bool isRead;
  final Map<String, dynamic> actionData;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.isRead,
    required this.actionData,
  });
}

enum NotificationType {
  tip,
  tipSent,
  message,
  groupInvite,
  system,
}
