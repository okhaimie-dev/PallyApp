import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../screens/join_group_sheet.dart';

class DeeplinkService {
  static final DeeplinkService _instance = DeeplinkService._internal();
  factory DeeplinkService() => _instance;
  DeeplinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  BuildContext? _context;
  User? _currentUser;

  /// Initialize the deeplink service
  void initialize(BuildContext context, User? currentUser) {
    _context = context;
    _currentUser = currentUser;
    _initDeepLinks();
  }

  /// Update the current user when they sign in/out
  void updateCurrentUser(User? user) {
    _currentUser = user;
  }

  /// Initialize deep link handling
  void _initDeepLinks() {
    // Handle app links while the app is already started - be it in
    // the foreground or in the background.
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleIncomingLink(uri);
      },
      onError: (err) {
        print('Error handling deep link: $err');
      },
    );

    // Handle app links while the app is already started - be it in
    // the foreground or in the background.
    _appLinks.getInitialLink().then((Uri? uri) {
      if (uri != null) {
        _handleIncomingLink(uri);
      }
    });
  }

  /// Handle incoming deep links
  void _handleIncomingLink(Uri uri) {
    print('🔗 Received deep link: $uri');
    
    if (_context == null) {
      print('❌ Context is null, cannot handle deep link');
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
          _showJoinGroupSheet(groupId);
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
          _showJoinGroupSheet(groupId);
        } else {
          print('❌ Invalid group ID in deep link: $groupIdStr');
        }
      }
    } else {
      print('❌ Unsupported deeplink scheme or host: ${uri.scheme}://${uri.host}');
    }
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
