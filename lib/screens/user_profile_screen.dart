import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'deposit_screen.dart';
import 'withdraw_screen.dart';
import 'notification_settings_screen.dart';
import '../services/wallet_service.dart';
import '../services/websocket_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;
  final bool isCurrentUser;

  const UserProfileScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
    this.isCurrentUser = false,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  double _totalTipsReceived = 0.0;
  List<TipTransaction> _tipTransactions = [];
  String? _walletAddress;
  bool _isLoadingWallet = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTipData();
    _loadWalletData();
    // Clear current group ID when on user profile screen so notifications can show
    final wsService = WebSocketService.getInstance();
    wsService.clearCurrentGroupId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadTipData() async {
    if (widget.userEmail.isNotEmpty) {
      try {
        // Load real tip data from backend
        final tipTransactions = await WalletService.getTipTransactions(widget.userEmail, limit: 10);
        final totalTips = await WalletService.getTotalTipsReceived(widget.userEmail);
        
        setState(() {
          _tipTransactions = tipTransactions;
          _totalTipsReceived = totalTips;
        });
      } catch (e) {
        print('Error loading tip data: $e');
        // Fallback to empty data
        setState(() {
          _tipTransactions = [];
          _totalTipsReceived = 0.0;
        });
      }
    }
  }

  void _loadWalletData() async {
    if (widget.isCurrentUser) {
      setState(() {
        _isLoadingWallet = true;
      });
      
      final walletAddress = await WalletService.getWalletAddress();
      
      setState(() {
        _walletAddress = walletAddress;
        _isLoadingWallet = false;
      });
    }
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
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!widget.isCurrentUser)
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () => _showProfileOptions(context),
            ),
        ],
      ),
      body: Column(
        children: [
          // Profile Header
          _buildProfileHeader(),
          
          // Tab Bar
          _buildTabBar(),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAboutTab(),
                _buildTipsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Profile Picture
          GestureDetector(
            onTap: () => _showProfilePicture(context),
            child: CircleAvatar(
              radius: 60,
              backgroundImage: widget.userPhotoUrl != null
                  ? NetworkImage(widget.userPhotoUrl!)
                  : null,
              child: widget.userPhotoUrl == null
                  ? const Icon(Icons.person, size: 60, color: Colors.white70)
                  : null,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Name
          Text(
            widget.userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Email
          Text(
            widget.userEmail,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Wallet Address (for current user)
          if (widget.isCurrentUser) ...[
            if (_isLoadingWallet)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
              )
            else if (_walletAddress != null)
              GestureDetector(
                onTap: () => _copyWalletAddress(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF6366F1), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: const Color(0xFF6366F1),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatWalletAddress(_walletAddress!),
                        style: const TextStyle(
                          color: Color(0xFF6366F1),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.copy,
                        color: Colors.grey[400],
                        size: 14,
                      ),
                    ],
                  ),
                ),
              )
            else
              Text(
                'No wallet found',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
          ],
          
          const SizedBox(height: 20),
          
          // Action Buttons
          if (widget.isCurrentUser) ...[
            // Wallet Actions for Current User
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToDeposit(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Deposit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToWithdraw(context),
                    icon: const Icon(Icons.remove, size: 18),
                    label: const Text('Withdraw'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Tip Button for Other Users
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showTipDialog(context),
                icon: const Icon(Icons.attach_money, size: 18),
                label: const Text('Send Tip'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF6366F1),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[400],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'About'),
          Tab(text: 'Tips'),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.isCurrentUser 
                      ? 'This is your profile. Share your interests, skills, and what you\'re working on!'
                      : 'No bio available yet.',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Stats Section
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Groups', '12', Icons.group),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Posts', '47', Icons.message),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Tips', '\$${_totalTipsReceived.toStringAsFixed(0)}', Icons.attach_money),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Tips Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.attach_money,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  '\$${_totalTipsReceived.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Tips Received',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Recent Tips
          const Text(
            'Recent Tips',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tips List
          ..._tipTransactions.map((tip) => _buildTipTransactionCard(tip)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF6366F1), size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayName(String email) {
    // Extract name from email (before @)
    final emailParts = email.split('@');
    if (emailParts.isNotEmpty) {
      final name = emailParts[0];
      // Capitalize first letter of each word
      return name.split('.').map((word) => 
        word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : ''
      ).join(' ');
    }
    return email;
  }

  Widget _buildTipTransactionCard(TipTransaction tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
            child: Text(
              _getDisplayName(tip.senderEmail)[0].toUpperCase(),
              style: TextStyle(
                color: tip.token == 'USDC' ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDisplayName(tip.senderEmail),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (tip.message.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    tip.message,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatTime(tip.timestamp),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${tip.amount.toStringAsFixed(2)} ${tip.token}',
            style: TextStyle(
              color: tip.token == 'USDC' ? const Color(0xFF10B981) : const Color(0xFF6366F1),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }

  String _formatWalletAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  void _copyWalletAddress() async {
    if (_walletAddress != null) {
      await Clipboard.setData(ClipboardData(text: _walletAddress!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wallet address copied to clipboard'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showTipDialog(BuildContext context) async {
    // Check deployment status of the current user (sender), not the recipient
    final currentUserEmail = await WalletService.getCurrentUserEmail();
    if (currentUserEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get user information'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final deploymentStatus = await WalletService.getDeploymentStatus(currentUserEmail);
    
    if (deploymentStatus?.isDeployed != true) {
      // Show deployment dialog instead
      _showDeploymentRequiredDialog(context);
      return;
    }
    
    // Note: Recipient doesn't need to be deployed to receive tokens
    // Tokens can be sent to any valid address and will be accessible once deployed
    
    // If sender is deployed, show the tip dialog
    _showActualTipDialog(context);
  }

  void _showDeploymentRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Row(
          children: [
            const Icon(
              Icons.cloud_upload,
              color: Color(0xFF6366F1),
              size: 24,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Account Deployment Required',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You need to deploy your account before you can send tips.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF6366F1),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Why deploy?',
                        style: TextStyle(
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Send tips to other users\n• Receive tips from others\n• Withdraw your rewards\n• Full blockchain functionality',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToDeployAccount(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Deploy Account'),
          ),
        ],
      ),
    );
  }


  void _showActualTipDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    String selectedToken = 'USDC';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text(
            'Send Tip to ${widget.userName}',
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Token Selection Dropdown
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[600]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedToken,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2A2A2A),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(
                        value: 'USDC',
                        child: Row(
                          children: [
                            Icon(Icons.attach_money, color: Color(0xFF10B981), size: 20),
                            SizedBox(width: 8),
                            Text('USDC'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'STRK',
                        child: Row(
                          children: [
                            Icon(Icons.diamond, color: Color(0xFF6366F1), size: 20),
                            SizedBox(width: 8),
                            Text('STRK'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedToken = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (${selectedToken == 'USDC' ? '\$' : 'STRK'})',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: selectedToken == 'USDC' ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Message (optional)',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: selectedToken == 'USDC' ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  _sendTip(amount, messageController.text, selectedToken);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedToken == 'USDC' ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
              child: const Text('Send Tip'),
            ),
          ],
        ),
      ),
    );
  }

  void _sendTip(double amount, String message, String token) async {
    try {
      // Get sender's private key
      final senderPrivateKey = await WalletService.getPrivateKey();
      if (senderPrivateKey == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to get wallet information'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Send tip via backend
      final result = await WalletService.sendTip(
        senderPrivateKey: senderPrivateKey,
        selectedToken: token,
        amount: amount,
        recipientEmail: widget.userEmail,
        message: message,
      );

      // Hide loading indicator
      Navigator.pop(context);

      if (result != null && result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tip of ${amount.toStringAsFixed(2)} ${token} sent to ${widget.userName} successfully!'),
            backgroundColor: token == 'USDC' ? const Color(0xFF10B981) : const Color(0xFF6366F1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?.message ?? 'Failed to send tip'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Hide loading indicator if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending tip: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToDeposit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DepositScreen(userEmail: widget.userEmail),
      ),
    );
  }

  void _navigateToWithdraw(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WithdrawScreen(userEmail: widget.userEmail),
      ),
    );
  }

  void _navigateToDeployAccount(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WithdrawScreen(userEmail: widget.userEmail),
      ),
    );
  }

  void _showWithdrawTipsDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    String selectedCurrency = 'USDC';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Withdraw Tips',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Available Balance: \$${_totalTipsReceived.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (\$)',
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCurrency,
              dropdownColor: const Color(0xFF2A2A2A),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Currency',
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1)),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'USDC', child: Text('USDC')),
                DropdownMenuItem(value: 'STRK', child: Text('STRK')),
              ],
              onChanged: (value) {
                selectedCurrency = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0 && amount <= _totalTipsReceived) {
                _withdrawTips(amount, selectedCurrency);
                Navigator.pop(context);
              } else if (amount != null && amount > _totalTipsReceived) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Insufficient balance'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  void _withdrawTips(double amount, String currency) {
    setState(() {
      _totalTipsReceived -= amount;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Withdrew \$${amount.toStringAsFixed(2)} in $currency successfully!'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  void _showProfilePicture(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: widget.userPhotoUrl != null
                  ? Image.network(
                      widget.userPhotoUrl!,
                      fit: BoxFit.contain,
                    )
                  : Container(
                      width: 300,
                      height: 300,
                      color: const Color(0xFF1A1A1A),
                      child: const Icon(
                        Icons.person,
                        size: 100,
                        color: Colors.white70,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _showProfileOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionTile(Icons.notifications, "Notification Settings", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            }),
            _buildOptionTile(Icons.block, "Block User", () {}),
            _buildOptionTile(Icons.report, "Report User", () {}),
            _buildOptionTile(Icons.share, "Share Profile", () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}

