import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WalletService {
  static const String _baseUrl = 'http://192.168.0.106:3000'; // Update with your backend URL
  static const String _walletKey = 'user_wallet_data';

  /// Get or create wallet for user
  static Future<WalletData?> getOrCreateWallet({
    required String email,
    required String openId,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/wallet'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'openId': openId,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final walletData = WalletData(
            walletAddress: data['accountAddress'],
            privateKey: data['privateKey'],
            publicKey: data['publicKey'],
            isNewWallet: data['isNewWallet'] ?? false,
          );
          
          // Save wallet data securely
          await _saveWalletData(walletData);
          return walletData;
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting/creating wallet: $e');
      return null;
    }
  }

  /// Get wallet info without private key
  static Future<WalletInfo?> getWalletInfo(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wallet/$email'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return WalletInfo(
            walletAddress: data['walletAddress'],
            publicKey: data['publicKey'],
          );
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting wallet info: $e');
      return null;
    }
  }

  /// Get stored wallet data
  static Future<WalletData?> getStoredWalletData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final walletJson = prefs.getString(_walletKey);
      
      if (walletJson != null) {
        final walletMap = jsonDecode(walletJson);
        return WalletData.fromJson(walletMap);
      }
      
      return null;
    } catch (e) {
      print('Error getting stored wallet data: $e');
      return null;
    }
  }

  /// Save wallet data securely
  static Future<void> _saveWalletData(WalletData walletData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_walletKey, jsonEncode(walletData.toJson()));
    } catch (e) {
      print('Error saving wallet data: $e');
    }
  }

  /// Clear stored wallet data
  static Future<void> clearWalletData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_walletKey);
    } catch (e) {
      print('Error clearing wallet data: $e');
    }
  }

  /// Check if user has a wallet
  static Future<bool> hasWallet() async {
    final walletData = await getStoredWalletData();
    return walletData != null;
  }

  /// Get wallet address for display
  static Future<String?> getWalletAddress() async {
    final walletData = await getStoredWalletData();
    return walletData?.walletAddress;
  }
}

class WalletData {
  final String walletAddress;
  final String privateKey;
  final String publicKey;
  final bool isNewWallet;

  WalletData({
    required this.walletAddress,
    required this.privateKey,
    required this.publicKey,
    required this.isNewWallet,
  });

  factory WalletData.fromJson(Map<String, dynamic> json) {
    return WalletData(
      walletAddress: json['walletAddress'],
      privateKey: json['privateKey'],
      publicKey: json['publicKey'],
      isNewWallet: json['isNewWallet'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'walletAddress': walletAddress,
      'privateKey': privateKey,
      'publicKey': publicKey,
      'isNewWallet': isNewWallet,
    };
  }
}

class WalletInfo {
  final String walletAddress;
  final String publicKey;

  WalletInfo({
    required this.walletAddress,
    required this.publicKey,
  });
}
