import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';

class WebSocketService {
  static const String _baseUrl = 'http://192.168.0.106:3000'; // Update with your backend URL
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
      return; // Already connected with same user
    }

    await disconnect(); // Disconnect if already connected

    _userEmail = userEmail;

    try {
      _socket = IO.io(_baseUrl, IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build());

      // Wait for connection first
      await _waitForConnection();

      // Setup event handlers after connection is established
      _setupEventHandlers();

      // Authenticate user
      _socket?.emit('authenticate', {'userEmail': userEmail});

      _isConnected = true;
      print('🔌 WebSocket connected for user: $userEmail');
    } catch (e) {
      print('❌ WebSocket connection failed: $e');
      _isConnected = false;
    }
  }

  /// Wait for socket connection
  Future<void> _waitForConnection() async {
    if (_socket == null) return;

    final completer = Completer<void>();
    
    // Set up connection event handlers
    _socket!.onConnect((_) {
      print('✅ WebSocket connection established');
      completer.complete();
    });

    _socket!.onConnectError((error) {
      print('❌ WebSocket connection error: $error');
      completer.completeError(error);
    });

    // Timeout after 10 seconds
    Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        completer.completeError('Connection timeout');
      }
    });

    return completer.future;
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
      return;
    }

    _socket!.emit('join_group', {
      'groupId': groupId,
      'userEmail': _userEmail,
    });

    _currentGroupId = groupId;
    print('👥 Joining group: $groupId');
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
      return;
    }

    _socket!.emit('send_message', {
      'groupId': groupId,
      'senderEmail': _userEmail,
      'content': content,
      'messageType': messageType,
    });

    print('💬 Sending message to group $groupId: $content');
  }

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
