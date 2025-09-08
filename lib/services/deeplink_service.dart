import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/group.dart';
import '../screens/join_group_sheet.dart';
import '../screens/chat_page.dart';
import 'group_service.dart';

class DeeplinkService {
  static final DeeplinkService _instance = DeeplinkService._internal();
  factory DeeplinkService() => _instance;
  DeeplinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  BuildContext? _context;
  User? _currentUser;
  Uri? _pendingLink;

  /// Initialize the deeplink service
  void initialize(BuildContext context, User? currentUser) {
    _context = context;
    _currentUser = currentUser;
    _initDeepLinks();
    
    // Handle any pending link if user is now available
    if (_pendingLink != null && currentUser != null) {
      print('🔗 Processing pending link: $_pendingLink');
      _handleIncomingLink(_pendingLink!);
      _pendingLink = null;
    }
  }

  /// Update the current user when they sign in/out
  void updateCurrentUser(User? user) {
    _currentUser = user;
  }

  /// Initialize deep link handling
  void _initDeepLinks() {
    print('🔗 Initializing deep link handling...');
    
    // Handle app links while the app is already started - be it in
    // the foreground or in the background.
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        print('🔗 Received link from stream: $uri');
        _handleIncomingLink(uri);
      },
      onError: (err) {
        print('❌ Error handling deep link: $err');
      },
    );

    // Handle app links while the app is already started - be it in
    // the foreground or in the background.
    _appLinks.getInitialLink().then((Uri? uri) {
      if (uri != null) {
        print('🔗 Received initial link: $uri');
        _handleIncomingLink(uri);
      } else {
        print('🔗 No initial link found');
      }
    }).catchError((err) {
      print('❌ Error getting initial link: $err');
    });
  }

  /// Handle incoming deep links
  void _handleIncomingLink(Uri uri) {
    print('🔗 Received deep link: $uri');
    
    if (_context == null) {
      print('❌ Context is null, storing pending link');
      _pendingLink = uri;
      return;
    }

    if (_currentUser == null) {
      print('❌ User is null, storing pending link');
      _pendingLink = uri;
      return;
    }

    // Parse the deep link
    if (uri.scheme == 'pally') {
      // Handle custom scheme: pally://join-group/123
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.length >= 2 && pathSegments[0] == 'join-group') {
        final groupIdStr = pathSegments[1];
        final groupId = int.tryParse(groupIdStr);
        
        if (groupId != null) {
          _handleGroupLink(groupId);
        } else {
          print('❌ Invalid group ID in deep link: $groupIdStr');
        }
      } else {
        print('❌ Invalid path segments for pally scheme: $pathSegments');
      }
    } else if (uri.host == 'pallyapp.onrender.com' || uri.host == 'pally.app') {
      // Handle HTTP/HTTPS deep links: https://pallyapp.onrender.com/join-group/123
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.length >= 2 && pathSegments[0] == 'join-group') {
        final groupIdStr = pathSegments[1];
        final groupId = int.tryParse(groupIdStr);
        
        if (groupId != null) {
          _handleGroupLink(groupId);
        } else {
          print('❌ Invalid group ID in deep link: $groupIdStr');
        }
      }
    } else {
      print('❌ Unsupported deeplink scheme or host: ${uri.scheme}://${uri.host}');
    }
  }

  /// Handle group link - check if user is member and navigate accordingly
  void _handleGroupLink(int groupId) async {

    try {
      // Get the group details
      final group = await GroupService.getGroupById(groupId);
      if (group == null) {
        print('❌ Group not found: $groupId');
        return;
      }

      // Check if user is already a member of the group
      final userGroups = await GroupService.getUserGroups(_currentUser!.email);
      final isMember = userGroups.any((g) => g.id == groupId);

      if (isMember) {
        // User is already a member, navigate directly to group chat
        print('✅ User is already a member, navigating to group chat');
        _navigateToGroupChat(group);
      } else {
        // User is not a member, show join group sheet
        print('👥 User is not a member, showing join group sheet');
        _showJoinGroupSheet(groupId);
      }
    } catch (e) {
      print('❌ Error handling group link: $e');
      // Fallback to showing join group sheet
      _showJoinGroupSheet(groupId);
    }
  }

  /// Navigate to group chat
  void _navigateToGroupChat(Group group) {
    if (_context == null || _currentUser == null) return;

    Navigator.push(
      _context!,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          group: group,
          userEmail: _currentUser!.email,
        ),
      ),
    );
  }

  /// Show the join group sheet
  void _showJoinGroupSheet(int groupId) {
    if (_context == null) return;

    showModalBottomSheet(
      context: _context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => JoinGroupSheet(
          groupId: groupId,
          currentUser: _currentUser,
        ),
      ),
    ).then((result) {
      // Handle the result if needed
      if (result == true) {
        print('✅ User successfully joined group $groupId');
        // You could trigger a refresh of the groups list here
      }
    });
  }

  /// Dispose the service
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _context = null;
    _currentUser = null;
  }
}
