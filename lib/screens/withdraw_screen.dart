import 'package:flutter/material.dart';
import '../services/wallet_service.dart';

class WithdrawScreen extends StatefulWidget {
  final String userEmail;
  
  const WithdrawScreen({super.key, required this.userEmail});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  String _selectedCurrency = 'USDC';
  String _selectedMethod = 'Bank Transfer';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _walletAddressController = TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();

  final List<String> _currencies = ['USDC', 'STRK'];
  final List<String> _withdrawMethods = ['Bank Transfer', 'PayPal', 'Crypto Wallet'];
  
  // Balance state
  String _totalBalance = '\$0.00';
  String _usdcBalance = '0.00 USDC';
  String _strkBalance = '0.00 STRK';
  bool _isLoadingBalance = true;
  
  // Deployment state
  bool _isDeployed = false;
  bool _isLoadingDeployment = true;
  bool _isDeploying = false;
  String _deploymentMessage = '';
  DeploymentRequirements? _deploymentRequirements;

  @override
  void initState() {
    super.initState();
    _loadBalance();
    _loadDeploymentStatus();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _walletAddressController.dispose();
    _bankAccountController.dispose();
    super.dispose();
  }

  void _loadBalance() async {
    try {
      final totalBalance = await WalletService.getTotalBalanceUSD(widget.userEmail);
      final usdcBalance = await WalletService.getUSDCBalance(widget.userEmail);
      final strkBalance = await WalletService.getSTRKBalance(widget.userEmail);
      
      if (mounted) {
        setState(() {
          _totalBalance = totalBalance;
          _usdcBalance = usdcBalance;
          _strkBalance = strkBalance;
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      print('Error loading balance: $e');
      if (mounted) {
        setState(() {
          _totalBalance = '\$0.00';
          _usdcBalance = '0.00 USDC';
          _strkBalance = '0.00 STRK';
          _isLoadingBalance = false;
        });
      }
    }
  }

  void _loadDeploymentStatus() async {
    try {
      final deploymentStatus = await WalletService.getDeploymentStatus(widget.userEmail);
      if (mounted) {
        setState(() {
          _isDeployed = deploymentStatus?.isDeployed ?? false;
          _deploymentRequirements = deploymentStatus?.requirements;
          _isLoadingDeployment = false;
        });
      }
    } catch (e) {
      print('Error loading deployment status: $e');
      if (mounted) {
        setState(() {
          _isDeployed = false;
          _isLoadingDeployment = false;
        });
      }
    }
  }

  void _deployAccount() async {
    if (_isDeploying) return;

    setState(() {
      _isDeploying = true;
      _deploymentMessage = 'Deploying your account to Starknet...';
    });

    try {
      final result = await WalletService.deployAccount(widget.userEmail);
      
      if (mounted) {
        setState(() {
          _isDeploying = false;
        });

        if (result?.success == true) {
          setState(() {
            _isDeployed = true;
            _deploymentMessage = 'Account deployed successfully!';
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deployed successfully! You can now withdraw rewards.'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        } else {
          setState(() {
            _deploymentMessage = result?.message ?? 'Deployment failed';
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result?.message ?? 'Deployment failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeploying = false;
          _deploymentMessage = 'Deployment failed: $e';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deployment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          'Withdraw',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Deployment Section
            if (!_isDeployed) _buildDeploymentSection(),
            
            // Balance Cards
            Row(
              children: [
                Expanded(
                  child: _buildBalanceCard('USDC', _usdcBalance, const Color(0xFF2775CA)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBalanceCard('STRK', _strkBalance, const Color(0xFF6366F1)),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Total Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Total Available Balance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _isLoadingBalance
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _totalBalance,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Currency Selection
            const Text(
              'Select Currency',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedCurrency,
                dropdownColor: const Color(0xFF2A2A2A),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
                items: _currencies.map((currency) {
                  return DropdownMenuItem(
                    value: currency,
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/${currency.toLowerCase()}.png',
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(currency),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCurrency = value!;
                  });
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Withdrawal Method Selection
            const Text(
              'Withdrawal Method',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedMethod,
                dropdownColor: const Color(0xFF2A2A2A),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
                items: _withdrawMethods.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Row(
                      children: [
                        Icon(
                          _getWithdrawMethodIcon(method),
                          color: Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(method),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMethod = value!;
                  });
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Amount Input
            const Text(
              'Amount',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            TextField(
              controller: _amountController,
              style: const TextStyle(color: Colors.white),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Enter amount to withdraw',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: _getTokenIcon(_selectedCurrency),
                suffixText: _selectedCurrency,
                suffixStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEF4444)),
                ),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Destination Input based on method
            if (_selectedMethod == 'Crypto Wallet') ...[
              const Text(
                'Wallet Address',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 12),
              
              TextField(
                controller: _walletAddressController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter wallet address',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.account_balance_wallet, color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFEF4444)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                ),
              ),
            ] else if (_selectedMethod == 'Bank Transfer') ...[
              const Text(
                'Bank Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 12),
              
              TextField(
                controller: _bankAccountController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter bank account number',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.account_balance, color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFEF4444)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Quick Amount Buttons
            const Text(
              'Quick Amounts',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildQuickAmountButton('50'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAmountButton('100'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAmountButton('250'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAmountButton('500'),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Withdraw Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isMethodComingSoon() ? null : _processWithdrawal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isMethodComingSoon() 
                      ? Colors.grey[600] 
                      : const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _isMethodComingSoon() ? 'Coming Soon' : 'Withdraw',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Coming Soon Text
            if (_isMethodComingSoon()) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Coming Soon',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange[300],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Crypto withdrawals are instant. Bank transfers may take 1-3 business days. Minimum withdrawal: 0.01 tokens. 0.1 tokens reserved for gas fees.',
                      style: TextStyle(
                        color: Colors.orange[300],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeploymentSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cloud_upload,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Deploy Your Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_isLoadingDeployment)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
              else if (_isDeployed)
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 24,
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          const Text(
            'Deploy your account to enable withdrawal of rewards',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Minimum amount of STRK needed: ${_deploymentRequirements?.minimumRequired ?? '0.5'}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          
          if (_deploymentRequirements != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Current STRK balance: ${_deploymentRequirements!.currentBalance}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          
          if (_deploymentMessage.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (_isDeploying)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  else if (_isDeployed)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 16,
                    )
                  else
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 16,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _deploymentMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isDeploying || _isLoadingDeployment || (_deploymentRequirements?.canDeploy != true)
                  ? null
                  : _deployAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isDeploying
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Deploying...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      _deploymentRequirements?.canDeploy == true
                          ? 'Deploy Account'
                          : 'Insufficient STRK Balance',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountButton(String amount) {
    return GestureDetector(
      onTap: () {
        _amountController.text = amount;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Text(
          '$amount $_selectedCurrency',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }


  Widget _buildBalanceCard(String token, String balance, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/${token.toLowerCase()}.png',
            width: 24,
            height: 24,
          ),
          const SizedBox(height: 8),
          Text(
            token,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          _isLoadingBalance
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  balance,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _getTokenIcon(String token) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Image.asset(
        'assets/images/${token.toLowerCase()}.png',
        width: 20,
        height: 20,
      ),
    );
  }

  double _getCurrentTokenBalance() {
    final balanceString = _selectedCurrency == 'USDC' ? _usdcBalance : _strkBalance;
    final balanceValue = balanceString.split(' ')[0];
    return double.tryParse(balanceValue) ?? 0.0;
  }

  IconData _getWithdrawMethodIcon(String method) {
    switch (method) {
      case 'Bank Transfer':
        return Icons.account_balance;
      case 'PayPal':
        return Icons.payment;
      case 'Crypto Wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.money_off;
    }
  }

  bool _isMethodComingSoon() {
    return _selectedMethod == 'Bank Transfer' || _selectedMethod == 'PayPal';
  }

  void _processWithdrawal() async {
    final amount = double.tryParse(_amountController.text);
    
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Check token-specific balance with 0.1 minimum remaining
    final currentBalance = _getCurrentTokenBalance();
    const minimumReserve = 0.1;
    final maxWithdrawable = currentBalance - minimumReserve;
    
    if (amount > maxWithdrawable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient $_selectedCurrency balance. Available: ${maxWithdrawable.toStringAsFixed(6)} $_selectedCurrency (0.1 $_selectedCurrency reserved)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (amount < 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum withdrawal amount is 0.01'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Validate destination based on method
    if (_selectedMethod == 'Crypto Wallet' && _walletAddressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter wallet address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedMethod == 'Bank Transfer' && _bankAccountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter bank account number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Show processing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
            ),
            const SizedBox(height: 16),
            Text(
              'Processing withdrawal...',
              style: TextStyle(color: Colors.grey[300]),
            ),
          ],
        ),
      ),
    );
    
    try {
      if (_selectedMethod == 'Crypto Wallet') {
        // Use real token transfer for crypto wallet withdrawals
        final privateKey = await WalletService.getPrivateKey();
        if (privateKey == null) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to access wallet private key'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        final transferResult = await WalletService.transferTokens(
          senderPrivateKey: privateKey,
          tokenName: _selectedCurrency,
          amount: amount,
          recipientAddress: _walletAddressController.text.trim(),
          message: 'Withdrawal to external wallet',
        );
        
        Navigator.pop(context); // Close loading dialog
        
        if (transferResult?.success == true) {
          Navigator.pop(context); // Close withdraw screen
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully transferred ${amount.toStringAsFixed(6)} $_selectedCurrency to ${_walletAddressController.text.substring(0, 10)}...'),
              backgroundColor: const Color(0xFF10B981),
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () {
                  // You could add functionality to view the transaction on a block explorer
                  print('Transaction Hash: ${transferResult?.transactionHash}');
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(transferResult?.message ?? 'Transfer failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // For non-crypto methods, simulate processing (as before)
        await Future.delayed(const Duration(seconds: 2));
        Navigator.pop(context); // Close loading dialog
        Navigator.pop(context); // Close withdraw screen
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Withdrawal request submitted for ${amount.toStringAsFixed(6)} $_selectedCurrency'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Withdrawal failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
