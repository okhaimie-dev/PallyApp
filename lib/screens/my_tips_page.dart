import 'package:flutter/material.dart';
import 'deposit_screen.dart';
import 'withdraw_screen.dart';
import '../services/wallet_service.dart';

class MyTipsPage extends StatefulWidget {
  const MyTipsPage({super.key});

  @override
  State<MyTipsPage> createState() => _MyTipsPageState();
}

class _MyTipsPageState extends State<MyTipsPage> {
  // Tips and wallet state
  double _totalTipsReceived = 0.0; // Will be loaded from backend or calculated
  String _walletBalance = '\$0.00';
  bool _isLoadingBalance = true;
  List<TipTransaction> _tipsHistory = [];

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  void _loadBalance() async {
    try {
      print('🔄 Loading wallet balance and tips...');
      final userEmail = await WalletService.getCurrentUserEmail();
      print('📧 User email: $userEmail');
      
      if (userEmail != null) {
        // Load wallet balance and tip transactions in parallel
        final results = await Future.wait([
          WalletService.getTotalBalanceUSD(userEmail),
          WalletService.getTipTransactions(userEmail),
          WalletService.getTotalTipsReceived(userEmail),
        ]);
        
        final balance = results[0] as String;
        final tipTransactions = results[1] as List<TipTransaction>;
        final totalTipsReceived = results[2] as double;
        
        print('💰 Wallet balance: $balance');
        print('📊 Tip transactions: ${tipTransactions.length}');
        print('💸 Total tips received: $totalTipsReceived');
        
        if (mounted) {
          setState(() {
            _walletBalance = balance;
            _tipsHistory = tipTransactions;
            _totalTipsReceived = totalTipsReceived;
            _isLoadingBalance = false;
          });
          print('✅ Balance and tips updated in UI');
        }
      } else {
        print('❌ No user email found');
        if (mounted) {
          setState(() {
            _walletBalance = '\$0.00';
            _tipsHistory = [];
            _totalTipsReceived = 0.0;
            _isLoadingBalance = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading balance and tips: $e');
      if (mounted) {
        setState(() {
          _walletBalance = '\$0.00';
          _tipsHistory = [];
          _totalTipsReceived = 0.0;
          _isLoadingBalance = false;
        });
      }
    }
  }

  String _calculateTotalBalance() {
    if (_isLoadingBalance) return '\$0.00';
    
    // Extract numeric value from wallet balance string (remove $ and parse)
    final walletAmount = double.tryParse(_walletBalance.replaceAll('\$', '')) ?? 0.0;
    final total = walletAmount + _totalTipsReceived;
    return '\$${total.toStringAsFixed(2)}';
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
          'My Tips',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // Balance Overview Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Total Balance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _isLoadingBalance
                      ? _buildLoadingAnimation()
                      : Text(
                          _calculateTotalBalance(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildWalletBalanceItem('Wallet', _walletBalance, Icons.account_balance_wallet),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      Expanded(
                        child: _buildBalanceItem('Tips', _totalTipsReceived, Icons.attach_money),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToDeposit(context),
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    label: const Text('Deposit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToWithdraw(context),
                    icon: const Icon(Icons.remove_circle_outline, size: 22),
                    label: const Text('Withdraw'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Tips History Section
            Row(
              children: [
                const Icon(
                  Icons.history,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Tips History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_tipsHistory.length} transactions',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Tips List
            ...(_tipsHistory.map((tip) => _buildTipItem(tip)).toList()),
            
            const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // Info Card - Fixed at bottom
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[300],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tips are automatically added to your wallet balance and you can withdraw them anytime',
                    style: TextStyle(
                      color: Colors.blue[300],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(TipTransaction tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF6366F1),
            child: Text(
              tip.senderName.isNotEmpty ? tip.senderName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.senderName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip.message,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(tip.timestamp),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tip.formattedAmount,
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Received',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _navigateToDeposit(BuildContext context) async {
    final userEmail = await WalletService.getCurrentUserEmail();
    if (userEmail != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DepositScreen(userEmail: userEmail),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get user information'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToWithdraw(BuildContext context) async {
    final userEmail = await WalletService.getCurrentUserEmail();
    if (userEmail != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WithdrawScreen(userEmail: userEmail),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get user information'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  Widget _buildBalanceItem(String label, double amount, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWalletBalanceItem(String label, String amount, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        _isLoadingBalance
            ? _buildSmallLoadingAnimation()
            : Text(
                amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ],
    );
  }

  Widget _buildLoadingAnimation() {
    return Container(
      width: 120,
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPulseDot(0),
          const SizedBox(width: 8),
          _buildPulseDot(1),
          const SizedBox(width: 8),
          _buildPulseDot(2),
        ],
      ),
    );
  }

  Widget _buildSmallLoadingAnimation() {
    return Container(
      width: 60,
      height: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSmallPulseDot(0),
          const SizedBox(width: 4),
          _buildSmallPulseDot(1),
          const SizedBox(width: 4),
          _buildSmallPulseDot(2),
        ],
      ),
    );
  }

  Widget _buildPulseDot(int index) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        final delay = index * 0.2;
        final animationValue = (value + delay) % 1.0;
        final scale = 0.5 + (0.5 * (1 - (animationValue - 0.5).abs() * 2).clamp(0.0, 1.0));
        final opacity = 0.3 + (0.7 * (1 - (animationValue - 0.5).abs() * 2).clamp(0.0, 1.0));
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildSmallPulseDot(int index) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        final delay = index * 0.2;
        final animationValue = (value + delay) % 1.0;
        final scale = 0.5 + (0.5 * (1 - (animationValue - 0.5).abs() * 2).clamp(0.0, 1.0));
        final opacity = 0.3 + (0.7 * (1 - (animationValue - 0.5).abs() * 2).clamp(0.0, 1.0));
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }


}
