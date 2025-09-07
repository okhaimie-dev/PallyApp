import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/signin_page.dart';
import 'screens/home_page.dart';
import 'screens/chat_page.dart';
import 'services/notification_service.dart';
import 'services/group_service.dart';

// Global navigator key for navigation from anywhere in the app
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const PallyApp());
}

class PallyApp extends StatelessWidget {
  const PallyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set up notification callback
    final notificationService = NotificationService();
    notificationService.onNotificationTapped = (groupId) {
      _navigateToGroupChat(groupId);
    };

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

  /// Navigate to group chat when notification is tapped
  void _navigateToGroupChat(int groupId) async {
    try {
      // Get user email from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('user_email');
      
      if (userEmail == null) {
        print('❌ No user email found in session');
        return;
      }

      // Get the group details
      final group = await GroupService.getGroupById(groupId, userEmail);
      if (group != null) {
        // Navigate to the group chat
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ChatPage(
              group: group,
              userEmail: userEmail,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error navigating to group chat: $e');
    }
  }
}

