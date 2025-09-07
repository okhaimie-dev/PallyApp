import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/signin_page.dart';
import 'screens/home_page.dart';
import 'screens/chat_page.dart';
import 'services/notification_service.dart';
import 'services/group_service.dart';

// Global navigator key for navigation from anywhere in the app
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Store pending navigation when app is not ready
int? _pendingGroupId;

/// Navigate to group chat when notification is tapped
void _navigateToGroupChat(int groupId) async {
  try {
    print('📱 Starting navigation to group: $groupId');
    
    // Check if navigator is available
    if (navigatorKey.currentState == null) {
      print('📱 Navigator not ready, storing pending navigation: $groupId');
      _pendingGroupId = groupId;
      return;
    }
    
    // Try to get user email with retry mechanism
    String? userEmail;
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        print('📱 Attempt $attempt: Getting user email from session');
        final prefs = await SharedPreferences.getInstance();
        userEmail = prefs.getString('userEmail');
        
        if (userEmail != null) {
          print('📱 User email found: $userEmail');
          break;
        } else {
          print('📱 No user email found, attempt $attempt');
          if (attempt < 3) {
            await Future.delayed(Duration(milliseconds: 500 * attempt));
          }
        }
      } catch (e) {
        print('📱 Error getting user email, attempt $attempt: $e');
        if (attempt < 3) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }
    }
    
    if (userEmail == null) {
      print('❌ No user email found after 3 attempts - storing pending navigation');
      _pendingGroupId = groupId;
      return;
    }

    // Get the group details
    final group = await GroupService.getGroupById(groupId, userEmail);
    if (group != null) {
      print('📱 Group found: ${group.name}');
      
      // Navigate to the group chat
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => ChatPage(
            group: group,
            userEmail: userEmail!,
          ),
        ),
      );
      print('📱 Navigation completed');
    } else {
      print('❌ Group not found for ID: $groupId');
    }
  } catch (e) {
    print('❌ Error navigating to group chat: $e');
  }
}

/// Execute pending navigation when app is ready
void _executePendingNavigation() {
  if (_pendingGroupId != null) {
    print('📱 Executing pending navigation to group: $_pendingGroupId');
    final groupId = _pendingGroupId!;
    _pendingGroupId = null;
    _navigateToGroupChat(groupId);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service and set up callback
  final notificationService = NotificationService();
  await notificationService.initialize();
  notificationService.onNotificationTapped = (groupId) {
    _navigateToGroupChat(groupId);
  };
  
  runApp(const PallyApp());
}

class PallyApp extends StatelessWidget {
  const PallyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Execute pending navigation when app is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _executePendingNavigation();
    });
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Pally',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1), // Indigo accent
          secondary: Color(0xFF8B5CF6), // Purple accent
          surface: Color(0xFF1E1E1E),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => const SignInPage(),
        '/home': (context) {
          final user = ModalRoute.of(context)!.settings.arguments as dynamic;
          return HomePage(user: user);
        },
      },
    );
  }
}

