import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'notification_service.dart';
import '../config/app_config.dart';

class WebSocketService {
  static String get _baseUrl => AppConfig.baseUrl;
  static String get _wsUrl => AppConfig.wsUrl;
  static WebSocketService? _instance;
  IO.Socket? _socket;
  String? _userEmail;
  int? _currentGroupId;
  bool _isConnected = false;

  // Stream controllers for real-time updates
  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _typingController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _userActivityController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _groupUpdateController = StreamController.broadcast();
  final NotificationService _notificationService = NotificationService();

  // Getters for streams
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<Map<String, dynamic>> get userActivityStream => _userActivityController.stream;
  Stream<Map<String, dynamic>> get groupUpdateStream => _groupUpdateController.stream;

  WebSocketService._();

  static WebSocketService getInstance() {
    _instance ??= WebSocketService._();
    return _instance!;
  }

  /// Connect to WebSocket server
  Future<void> connect(String userEmail) async {
    if (_isConnected && _userEmail == userEmail) {
      print('🔌 WebSocket already connected for user: $userEmail');
      return; // Already connected with same user
    }

    await disconnect(); // Disconnect if already connected

    _userEmail = userEmail;

    try {
      print('🔌 Attempting to connect to WebSocket server: $_wsUrl');
      
      _socket = IO.io(_wsUrl, IO.OptionBuilder()
          .setTransports(['websocket', 'polling']) // Try WebSocket first
          .enableAutoConnect()
          .setTimeout(30000) // 30 second timeout
          .enableReconnection()
          .setReconnectionAttempts(3)
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(5000)
          .enableForceNew()
          .build());

      // Wait for connection first
      await _waitForConnection();

      // Setup event handlers after connection is established
      _setupEventHandlers();

      // Authenticate user and wait for confirmation
      await _authenticateUser(userEmail);

      _isConnected = true;
      print('🔌 WebSocket connected and authenticated for user: $userEmail');
      
      // Initialize notification service
      await _notificationService.initialize();
    } catch (e) {
      print('❌ WebSocket connection failed: $e');
      _isConnected = false;
      _socket = null;
      throw Exception('Failed to connect to WebSocket: $e');
    }
  }

  /// Wait for socket connection
  Future<void> _waitForConnection() async {
    if (_socket == null) {
      throw Exception('Socket is null');
    }

    final completer = Completer<void>();
    
    // Set up connection event handlers
    _socket!.onConnect((_) {
      print('✅ WebSocket connection established');
      print('🔌 Socket ID: ${_socket!.id}');
      print('🔌 Transport: ${_socket!.io.engine?.transport?.name ?? 'unknown'}');
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    _socket!.onConnectError((error) {
      print('❌ WebSocket connection error: $error');
      print('🔌 Error details: ${error.toString()}');
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    });
    
    _socket!.onDisconnect((reason) {
      print('🔌 WebSocket disconnected: $reason');
    });

    // Timeout after 30 seconds
    Timer(const Duration(seconds: 30), () {
      if (!completer.isCompleted) {
        completer.completeError('Connection timeout after 30 seconds');
      }
    });

    return completer.future;
  }

  /// Authenticate user and wait for confirmation
  Future<void> _authenticateUser(String userEmail) async {
    if (_socket == null) {
      throw Exception('Socket is null during authentication');
    }

    final completer = Completer<void>();

    // Listen for authentication confirmation
    _socket!.once('authenticated', (data) {
      print('🔐 User authenticated: $data');
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    // Listen for authentication error
    _socket!.once('error', (data) {
      print('❌ Authentication error: $data');
      if (!completer.isCompleted) {
        completer.completeError(data);
      }
    });

    // Send authentication request
    print('🔐 Sending authentication request for: $userEmail');
    _socket!.emit('authenticate', {'userEmail': userEmail});

    // Wait for authentication confirmation with timeout
    try {
      await completer.future.timeout(const Duration(seconds: 5));
    } catch (e) {
      throw Exception('Authentication timeout: $e');
    }
  }

  /// Setup event handlers
  void _setupEventHandlers() {
    if (_socket == null) return;

    // Disconnect event
    _socket!.onDisconnect((_) {
      print('🔌 WebSocket disconnected');
      _isConnected = false;
    });

    // Message events
    _socket!.on('new_message', (data) {
      print('💬 New message received: $data');
      _messageController.add(Map<String, dynamic>.from(data));
      
      // Show notification if message is from another user and not in current group
      _handleMessageNotification(data);
    });

    _socket!.on('message_sent', (data) {
      print('✅ Message sent confirmation: $data');
      // Handle message sent confirmation if needed
    });

    // Typing events
    _socket!.on('user_typing', (data) {
      print('⌨️ User typing: $data');
      _typingController.add(Map<String, dynamic>.from(data));
    });

    // User activity events
    _socket!.on('user_joined', (data) {
      print('👥 User joined: $data');
      _userActivityController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('user_left', (data) {
      print('👋 User left: $data');
      _userActivityController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('new_member', (data) {
      print('🆕 New member: $data');
      _userActivityController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('member_left', (data) {
      print('👋 Member left: $data');
      _userActivityController.add(Map<String, dynamic>.from(data));
    });

    // Group update events
    _socket!.on('group_update', (data) {
      print('🔄 Group update: $data');
      _groupUpdateController.add(Map<String, dynamic>.from(data));
    });

    // Tip events
    _socket!.on('tip_notification', (data) {
      print('💰 Tip notification received: $data');
      _handleTipNotification(data, 'received');
    });

    _socket!.on('tip_received', (data) {
      print('💰 Tip received: $data');
      _handleTipNotification(data, 'received');
    });

    _socket!.on('tip_withdrawn', (data) {
      print('💸 Tip withdrawn: $data');
      _handleTipNotification(data, 'withdrawn');
    });

    // Error events
    _socket!.on('error', (data) {
      print('❌ WebSocket error: $data');
      // Handle errors if needed
    });

    // Join group confirmation
    _socket!.on('joined_group', (data) {
      print('✅ Joined group: $data');
      _currentGroupId = data['groupId'];
    });
  }

  /// Join a group chat
  Future<void> joinGroup(int groupId) async {
    if (_socket == null || !_isConnected || _userEmail == null) {
      print('❌ Cannot join group: WebSocket not connected or user not authenticated');
      throw Exception('WebSocket not connected or user not authenticated');
    }

    final completer = Completer<void>();
    bool isCompleted = false;
    
    // Listen for join confirmation
    _socket!.once('joined_group', (data) {
      if (!isCompleted) {
        isCompleted = true;
        print('✅ Successfully joined group: $data');
        _currentGroupId = groupId;
        completer.complete();
      }
    });

    // Listen for join error
    _socket!.once('error', (data) {
      if (!isCompleted) {
        isCompleted = true;
        print('❌ Error joining group: $data');
        completer.completeError(data);
      }
    });

    _socket!.emit('join_group', {
      'groupId': groupId,
      'userEmail': _userEmail,
    });

    print('👥 Joining group: $groupId');
    
    // Wait for join confirmation with timeout
    try {
      await completer.future.timeout(const Duration(seconds: 5));
    } catch (e) {
      if (!isCompleted) {
        isCompleted = true;
        print('❌ Timeout joining group: $e');
        throw e;
      }
    }
  }

  /// Leave current group
  Future<void> leaveGroup() async {
    if (_socket == null || !_isConnected || _currentGroupId == null) {
      return;
    }

    _socket!.emit('leave_group', {
      'groupId': _currentGroupId,
    });

    print('👋 Leaving group: $_currentGroupId');
    _currentGroupId = null;
  }

  /// Send a message
  Future<void> sendMessage({
    required int groupId,
    required String content,
    String messageType = 'text',
  }) async {
    if (_socket == null || !_isConnected || _userEmail == null) {
      print('❌ Cannot send message: WebSocket not connected or user not authenticated');
      throw Exception('WebSocket not connected or user not authenticated');
    }

    final completer = Completer<void>();
    
    // Listen for message sent confirmation
    _socket!.once('message_sent', (data) {
      print('✅ Message sent successfully: $data');
      // Track that user has messaged in this group for notification purposes
      _trackUserMessagingInGroup(groupId);
      completer.complete();
    });

    // Listen for message error
    _socket!.once('error', (data) {
      print('❌ Error sending message: $data');
      completer.completeError(data);
    });

    _socket!.emit('send_message', {
      'groupId': groupId,
      'senderEmail': _userEmail,
      'content': content,
      'messageType': messageType,
    });

    print('💬 Sending message to group $groupId: $content');
    
    // Wait for confirmation with timeout
    try {
      await completer.future.timeout(const Duration(seconds: 10));
    } catch (e) {
      print('❌ Timeout sending message: $e');
      throw e;
    }
  }
  
  /// Check if real-time features are available
  bool get isRealTimeAvailable => _isConnected && _socket != null && _userEmail != null;

  /// Send typing start indicator
  void startTyping(int groupId) {
    if (_socket == null || !_isConnected || _userEmail == null) {
      return;
    }

    _socket!.emit('typing_start', {
      'groupId': groupId,
      'userEmail': _userEmail,
    });
  }

  /// Send typing stop indicator
  void stopTyping(int groupId) {
    if (_socket == null || !_isConnected || _userEmail == null) {
      return;
    }

    _socket!.emit('typing_stop', {
      'groupId': groupId,
      'userEmail': _userEmail,
    });
  }

  /// Handle message notification
  void _handleMessageNotification(dynamic data) async {
    try {
      final messageData = Map<String, dynamic>.from(data);
      final senderEmail = messageData['senderEmail'] as String?;
      final groupId = messageData['groupId'] as int?;
      final content = messageData['content'] as String?;
      
      // Don't show notification for own messages
      if (senderEmail == _userEmail) return;
      
      // Debug logging
      print('📱 Notification check - Group ID: $groupId, Current Group ID: $_currentGroupId');
      
      // Don't show notification if user is currently in this group
      if (groupId == _currentGroupId) {
        print('📱 Skipping notification - user is currently in group $groupId');
        return;
      }
      
      // Check if user should receive notifications for this group
      final shouldNotify = await _shouldNotifyForGroup(groupId);
      if (!shouldNotify) return;
      
      // Get sender name and group name
      final senderName = _getDisplayName(senderEmail ?? '');
      final groupName = await _getGroupName(groupId);
      
      // Show notification
      await _notificationService.showMessageNotification(
        title: '$senderName sent a message on $groupName',
        body: content ?? 'New message',
        groupName: groupName,
        groupId: groupId ?? 0,
        senderName: senderName,
      );
    } catch (e) {
      print('❌ Error handling message notification: $e');
    }
  }

  /// Check if user should receive notifications for this group
  Future<bool> _shouldNotifyForGroup(int? groupId) async {
    if (groupId == null || _userEmail == null) return false;
    
    try {
      // Check if user has messaged in this group before
      final hasMessaged = await _hasUserMessagedInGroup(groupId);
      if (hasMessaged) {
        print('📱 User has messaged in group $groupId - showing notification');
        return true;
      }
      
      // Check if user created this group
      final isCreator = await _isUserGroupCreator(groupId);
      if (isCreator) {
        print('📱 User created group $groupId - showing notification');
        return true;
      }
      
      print('📱 User has no history with group $groupId - no notification');
      return false;
    } catch (e) {
      print('❌ Error checking group notification eligibility: $e');
      return false;
    }
  }

  /// Check if user has messaged in this group before
  Future<bool> _hasUserMessagedInGroup(int groupId) async {
    try {
      // This would typically make an API call to check message history
      // For now, we'll use a simple approach - check if user is a member
      // In a real implementation, you'd check the message history
      final response = await http.get(
        Uri.parse('$_baseUrl/groups/$groupId/messages?userEmail=$_userEmail&limit=1'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['messages'] != null && (data['messages'] as List).isNotEmpty;
      }
      return false;
    } catch (e) {
      print('❌ Error checking message history: $e');
      return false;
    }
  }

  /// Check if user created this group
  Future<bool> _isUserGroupCreator(int groupId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/groups/$groupId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['creatorEmail'] == _userEmail;
      }
      return false;
    } catch (e) {
      print('❌ Error checking group creator: $e');
      return false;
    }
  }

  /// Get group name by ID
  Future<String> _getGroupName(int? groupId) async {
    if (groupId == null) return 'Unknown Group';
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/groups/$groupId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['name'] ?? 'Group $groupId';
      }
      return 'Group $groupId';
    } catch (e) {
      print('❌ Error getting group name: $e');
      return 'Group $groupId';
    }
  }

  /// Handle tip notifications
  void _handleTipNotification(dynamic data, String type) async {
    try {
      final tipData = Map<String, dynamic>.from(data);
      final amount = tipData['amount'] as double?;
      final senderEmail = tipData['senderEmail'] as String?;
      final recipientEmail = tipData['recipientEmail'] as String?;
      final message = tipData['message'] as String?;
      final token = tipData['token'] as String?;
      
      // Only show notifications for the current user
      if (recipientEmail != _userEmail && senderEmail != _userEmail) return;
      
      String title;
      String body;
      
      if (type == 'received') {
        final senderName = _getDisplayName(senderEmail ?? '');
        title = '💰 Tip Received!';
        body = '$senderName sent you \$${amount?.toStringAsFixed(2) ?? '0.00'} $token';
        if (message != null && message.isNotEmpty && message != 'Great job!') {
          body += ': "$message"';
        }
      } else if (type == 'withdrawn') {
        title = '💸 Tip Withdrawn';
        body = 'You withdrew \$${amount?.toStringAsFixed(2) ?? '0.00'} $token';
      } else {
        return;
      }
      
      // Show notification
      await _notificationService.showMessageNotification(
        title: title,
        body: body,
        groupName: 'Tip',
        groupId: 0, // Use 0 for tip notifications
        senderName: type == 'received' ? _getDisplayName(senderEmail ?? '') : 'You',
      );
    } catch (e) {
      print('❌ Error handling tip notification: $e');
    }
  }

  /// Track that user has messaged in a group (for notification purposes)
  void _trackUserMessagingInGroup(int groupId) {
    // In a real implementation, you might store this locally or send to backend
    // For now, we'll just log it
    print('📝 User $_userEmail has messaged in group $groupId - will receive notifications');
  }

  /// Get display name for user email
  String _getDisplayName(String email) {
    if (email.isEmpty) return 'Unknown User';
    // Extract name from email (before @)
    final name = email.split('@').first;
    // Capitalize first letter
    return name.isNotEmpty ? name[0].toUpperCase() + name.substring(1) : 'User';
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    if (_socket != null) {
      await leaveGroup();
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _isConnected = false;
    _userEmail = null;
    _currentGroupId = null;
    print('🔌 WebSocket disconnected');
  }

  /// Check if connected
  bool get isConnected => _isConnected;
  
  /// Check if WebSocket is available (for graceful degradation)
  bool get isWebSocketAvailable => _socket != null;

  /// Set current group ID (for notification purposes)
  void setCurrentGroupId(int? groupId) {
    _currentGroupId = groupId;
    print('📍 Current group set to: $groupId');
  }

  /// Clear current group ID (for notification purposes)
  void clearCurrentGroupId() {
    _currentGroupId = null;
    print('📍 Current group cleared - notifications will show');
  }

  /// Force clear current group ID (for debugging)
  void forceClearCurrentGroupId() {
    _currentGroupId = null;
    print('📍 Current group FORCE cleared - notifications will show');
  }

  /// Get current user email
  String? get userEmail => _userEmail;

  /// Get current group ID
  int? get currentGroupId => _currentGroupId;

  /// Dispose resources
  void dispose() {
    disconnect();
    _messageController.close();
    _typingController.close();
    _userActivityController.close();
    _groupUpdateController.close();
  }
}
