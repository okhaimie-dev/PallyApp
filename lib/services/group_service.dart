import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/group.dart';
import '../config/app_config.dart';

class GroupService {
  static String get _baseUrl => AppConfig.baseUrl;

  /// Create a new group
  static Future<GroupResponse?> createGroup({
    required String name,
    required String description,
    required String category,
    required String icon,
    required String color,
    required bool isPrivate,
    required String userEmail,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/groups'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'description': description,
          'category': category,
          'icon': icon,
          'color': color,
          'isPrivate': isPrivate,
          'userEmail': userEmail,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return GroupResponse.fromJson(data);
        }
      }
      
      return null;
    } catch (e) {
      print('Error creating group: $e');
      return null;
    }
  }

  /// Get user's groups
  static Future<List<Group>> getUserGroups(String userEmail) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/groups/user/$userEmail'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final groupsJson = data['groups'] as List;
          return groupsJson.map((json) => Group.fromJson(json)).toList();
        }
      }
      
      return [];
    } catch (e) {
      print('Error getting user groups: $e');
      return [];
    }
  }

  /// Get public groups by category
  static Future<List<Group>> getPublicGroupsByCategory(String category) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/groups/public/$category'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final groupsJson = data['groups'] as List;
          return groupsJson.map((json) => Group.fromJson(json)).toList();
        }
      }
      
      return [];
    } catch (e) {
      print('Error getting public groups: $e');
      return [];
    }
  }

  /// Get group by ID (for invite links - no userEmail required)
  static Future<Group?> getGroupById(int groupId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/groups/$groupId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Group.fromJson(data['group']);
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting group by ID: $e');
      return null;
    }
  }

  /// Join a group
  static Future<bool> joinGroup(int groupId, String userEmail) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/groups/$groupId/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userEmail': userEmail,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error joining group: $e');
      return false;
    }
  }

  /// Leave a group
  static Future<bool> leaveGroup(int groupId, String userEmail) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/groups/$groupId/leave'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userEmail': userEmail,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error leaving group: $e');
      return false;
    }
  }

  /// Get group members
  static Future<List<GroupMember>> getGroupMembers(int groupId, String userEmail) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/groups/$groupId/members?userEmail=$userEmail'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final membersJson = data['members'] as List;
          return membersJson.map((json) => GroupMember.fromJson(json)).toList();
        }
      }
      
      return [];
    } catch (e) {
      print('Error getting group members: $e');
      return [];
    }
  }

  /// Send message to group
  static Future<ChatMessage?> sendMessage({
    required int groupId,
    required String senderEmail,
    required String content,
    String messageType = 'text',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/groups/$groupId/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderEmail': senderEmail,
          'content': content,
          'messageType': messageType,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return ChatMessage.fromJson(data['message']);
        }
      }
      
      return null;
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }

  /// Get group messages
  static Future<List<ChatMessage>> getGroupMessages({
    required int groupId,
    required String userEmail,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/groups/$groupId/messages?userEmail=$userEmail&limit=$limit&offset=$offset'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final messagesJson = data['messages'] as List;
          return messagesJson.map((json) => ChatMessage.fromJson(json)).toList();
        }
      }
      
      return [];
    } catch (e) {
      print('Error getting group messages: $e');
      return [];
    }
  }
}