import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WalletService {
  static const String _baseUrl = 'https://pallyapp.onrender.com'; // Render deployment URL
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
      
      print('🔍 WalletService: Looking for wallet data with key: $_walletKey');
      print('🔍 WalletService: Found wallet JSON: $walletJson');
      
      if (walletJson != null) {
        final walletMap = jsonDecode(walletJson);
        print('🔍 WalletService: Parsed wallet map: $walletMap');
        return WalletData.fromJson(walletMap);
      }
      
      print('🔍 WalletService: No wallet data found');
      return null;
    } catch (e) {
      print('❌ Error getting stored wallet data: $e');
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

  /// Get private key for export
  static Future<String?> getPrivateKey() async {
    final walletData = await getStoredWalletData();
    return walletData?.privateKey;
  }

  /// Get wallet balances (USDC + STRK)
  static Future<WalletBalances?> getWalletBalances(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wallet/$email/balances'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return WalletBalances.fromJson(data['balances']);
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting wallet balances: $e');
      return null;
    }
  }

  /// Get total balance in USD format
  static Future<String> getTotalBalanceUSD(String email) async {
    final balances = await getWalletBalances(email);
    if (balances != null) {
      return '\$${balances.totalBalanceUSD}';
    }
    return '\$0.00';
  }

  /// Get formatted USDC balance
  static Future<String> getUSDCBalance(String email) async {
    final balances = await getWalletBalances(email);
    if (balances != null) {
      return '${balances.usdcBalance} USDC';
    }
    return '0.00 USDC';
  }

  /// Get formatted STRK balance
  static Future<String> getSTRKBalance(String email) async {
    final balances = await getWalletBalances(email);
    if (balances != null) {
      return '${balances.strkBalance} STRK';
    }
    return '0.00 STRK';
  }

  /// Get current user email from SharedPreferences
  static Future<String?> getCurrentUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userEmail');
    } catch (e) {
      print('Error getting current user email: $e');
      return null;
    }
  }

  /// Get tip transactions for a user
  static Future<List<TipTransaction>> getTipTransactions(String email, {int limit = 5}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wallet/$email/tips?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> transactionsJson = data['tipTransactions'] ?? [];
          return transactionsJson.map((json) => TipTransaction.fromJson(json)).toList();
        }
      }
      
      print('❌ Failed to fetch tip transactions: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ Error fetching tip transactions: $e');
      return [];
    }
  }

  /// Get total tips received by a user
  static Future<double> getTotalTipsReceived(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wallet/$email/tips'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['totalTipsReceived'] ?? 0).toDouble();
        }
      }
      
      print('❌ Failed to fetch total tips received: ${response.statusCode}');
      return 0.0;
    } catch (e) {
      print('❌ Error fetching total tips received: $e');
      return 0.0;
    }
  }

  /// Check deployment status of wallet account
  static Future<DeploymentStatus?> getDeploymentStatus(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wallet/$email/deployment-status'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return DeploymentStatus.fromJson(data);
        }
      }
      
      print('❌ Failed to fetch deployment status: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ Error fetching deployment status: $e');
      return null;
    }
  }

  /// Deploy wallet account to Starknet
  static Future<DeploymentResult?> deployAccount(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/wallet/$email/deploy'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return DeploymentResult.fromJson(data);
        }
      }
      
      print('❌ Failed to deploy account: ${response.statusCode}');
      final errorData = jsonDecode(response.body);
      return DeploymentResult(
        success: false,
        message: errorData['error'] ?? 'Deployment failed',
        accountAddress: '',
      );
    } catch (e) {
      print('❌ Error deploying account: $e');
      return DeploymentResult(
        success: false,
        message: 'Network error: $e',
        accountAddress: '',
      );
    }
  }

  /// Get deployment cost estimate
  static Future<DeploymentCost?> getDeploymentCost() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wallet/deployment-cost'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return DeploymentCost.fromJson(data['costInfo']);
        }
      }
      
      print('❌ Failed to fetch deployment cost: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ Error fetching deployment cost: $e');
      return null;
    }
  }

  /// Send tip to recipient
  static Future<TipSendResult?> sendTip({
    required String senderPrivateKey,
    required String selectedToken,
    required double amount,
    required String recipientEmail,
    String? message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/send-tip'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderPrivateKey': senderPrivateKey,
          'selectedToken': selectedToken,
          'amount': amount,
          'recipientEmail': recipientEmail,
          'message': message ?? 'Great job!',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return TipSendResult(
            success: true,
            message: data['message'],
            transactionHash: data['transactionHash'],
            tipTransactionId: data['tipTransactionId'],
            recipientAddress: data['recipientAddress'],
          );
        }
      }
      
      // Handle error response
      final errorData = jsonDecode(response.body);
      return TipSendResult(
        success: false,
        message: errorData['error'] ?? 'Failed to send tip',
        transactionHash: null,
        tipTransactionId: null,
        recipientAddress: null,
      );
    } catch (e) {
      print('❌ Error sending tip: $e');
      return TipSendResult(
        success: false,
        message: 'Network error: $e',
        transactionHash: null,
        tipTransactionId: null,
        recipientAddress: null,
      );
    }
  }
}

/// Tip transaction model
class TipTransaction {
  final String id;
  final String senderEmail;
  final String receiverEmail;
  final double amount;
  final String token;
  final String message;
  final DateTime timestamp;
  final String? transactionHash;

  TipTransaction({
    required this.id,
    required this.senderEmail,
    required this.receiverEmail,
    required this.amount,
    required this.token,
    required this.message,
    required this.timestamp,
    this.transactionHash,
  });

  factory TipTransaction.fromJson(Map<String, dynamic> json) {
    return TipTransaction(
      id: json['id'] ?? '',
      senderEmail: json['senderEmail'] ?? '',
      receiverEmail: json['receiverEmail'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      token: json['token'] ?? 'USDC',
      message: json['message'] ?? 'Great job!',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      transactionHash: json['transactionHash'],
    );
  }

  /// Get sender name from email
  String get senderName {
    final name = senderEmail.split('@')[0];
    return name.isNotEmpty ? name[0].toUpperCase() + name.substring(1) : 'Unknown User';
  }

  /// Format amount with token
  String get formattedAmount {
    return '\$${amount.toStringAsFixed(2)} $token';
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

class WalletBalances {
  final String usdcBalance;
  final String strkBalance;
  final String totalBalanceUSD;
  final String walletAddress;

  WalletBalances({
    required this.usdcBalance,
    required this.strkBalance,
    required this.totalBalanceUSD,
    required this.walletAddress,
  });

  factory WalletBalances.fromJson(Map<String, dynamic> json) {
    return WalletBalances(
      usdcBalance: json['usdcBalance'] ?? '0',
      strkBalance: json['strkBalance'] ?? '0',
      totalBalanceUSD: json['totalBalanceUSD'] ?? '0',
      walletAddress: json['walletAddress'] ?? '',
    );
  }
}

/// Deployment status model
class DeploymentStatus {
  final bool isDeployed;
  final String accountAddress;
  final String? deploymentHash;
  final String? error;
  final DeploymentRequirements? requirements;

  DeploymentStatus({
    required this.isDeployed,
    required this.accountAddress,
    this.deploymentHash,
    this.error,
    this.requirements,
  });

  factory DeploymentStatus.fromJson(Map<String, dynamic> json) {
    return DeploymentStatus(
      isDeployed: json['deploymentStatus']?['isDeployed'] ?? false,
      accountAddress: json['deploymentStatus']?['accountAddress'] ?? '',
      deploymentHash: json['deploymentStatus']?['deploymentHash'],
      error: json['deploymentStatus']?['error'],
      requirements: json['requirements'] != null 
          ? DeploymentRequirements.fromJson(json['requirements'])
          : null,
    );
  }
}

/// Deployment requirements model
class DeploymentRequirements {
  final bool hasMinimumSTRK;
  final String currentBalance;
  final String minimumRequired;
  final bool canDeploy;

  DeploymentRequirements({
    required this.hasMinimumSTRK,
    required this.currentBalance,
    required this.minimumRequired,
    required this.canDeploy,
  });

  factory DeploymentRequirements.fromJson(Map<String, dynamic> json) {
    return DeploymentRequirements(
      hasMinimumSTRK: json['hasMinimumSTRK'] ?? false,
      currentBalance: json['currentBalance'] ?? '0',
      minimumRequired: json['minimumRequired'] ?? '0.5',
      canDeploy: json['canDeploy'] ?? false,
    );
  }
}

/// Deployment result model
class DeploymentResult {
  final bool success;
  final String accountAddress;
  final String? deploymentHash;
  final String message;
  final String? error;

  DeploymentResult({
    required this.success,
    required this.accountAddress,
    this.deploymentHash,
    required this.message,
    this.error,
  });

  factory DeploymentResult.fromJson(Map<String, dynamic> json) {
    final deploymentResult = json['deploymentResult'] ?? json;
    return DeploymentResult(
      success: json['success'] ?? false,
      accountAddress: deploymentResult['accountAddress'] ?? '',
      deploymentHash: deploymentResult['deploymentHash'],
      message: json['message'] ?? deploymentResult['message'] ?? '',
      error: deploymentResult['error'],
    );
  }
}

/// Deployment cost model
class DeploymentCost {
  final String estimatedCost;
  final String currency;
  final String description;

  DeploymentCost({
    required this.estimatedCost,
    required this.currency,
    required this.description,
  });

  factory DeploymentCost.fromJson(Map<String, dynamic> json) {
    return DeploymentCost(
      estimatedCost: json['estimatedCost'] ?? '0.001',
      currency: json['currency'] ?? 'STRK',
      description: json['description'] ?? 'Estimated cost for account deployment',
    );
  }
}

/// Tip send result model
class TipSendResult {
  final bool success;
  final String message;
  final String? transactionHash;
  final String? tipTransactionId;
  final String? recipientAddress;

  TipSendResult({
    required this.success,
    required this.message,
    this.transactionHash,
    this.tipTransactionId,
    this.recipientAddress,
  });
}
