import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/wallet_service.dart';

class TokenTransferScreen extends StatefulWidget {
  final String userEmail;
  
  const TokenTransferScreen({super.key, required this.userEmail});

  @override
  State<TokenTransferScreen> createState() => _TokenTransferScreenState();
}

class _TokenTransferScreenState extends State<TokenTransferScreen> {
  String _selectedToken = 'USDC';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final List<String> _tokens = ['USDC', 'STRK'];
  
  // Balance state
  String _usdcBalance = '0.00 USDC';
  String _strkBalance = '0.00 STRK';
  bool _isLoadingBalance = true;

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _recipientController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _loadBalances() async {
    try {
      final usdcBalance = await WalletService.getUSDCBalance(widget.userEmail);
      final strkBalance = await WalletService.getSTRKBalance(widget.userEmail);
      
      if (mounted) {
        setState(() {
          _usdcBalance = usdcBalance;
          _strkBalance = strkBalance;
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      print('Error loading balances: $e');
      if (mounted) {
        setState(() {
          _usdcBalance = '0.00 USDC';
          _strkBalance = '0.00 STRK';
          _isLoadingBalance = false;
        });
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
          'Transfer Tokens',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            
            const SizedBox(height: 24),
            
            // Token Selection
            const Text(
              'Select Token',
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
                value: _selectedToken,
                dropdownColor: const Color(0xFF2A2A2A),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
                items: _tokens.map((token) {
                  return DropdownMenuItem(
                    value: token,
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/${token.toLowerCase()}.png',
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(token),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedToken = value!;
                  });
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Recipient Address
            const Text(
              'Recipient Address',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            TextField(
              controller: _recipientController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter Starknet wallet address (0x...)',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.account_balance_wallet, color: Colors.grey[400]),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste, color: Colors.grey),
                  onPressed: _pasteFromClipboard,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF10B981)),
                ),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
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
                hintText: 'Enter amount to transfer',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.attach_money, color: Colors.grey[400]),
                suffixText: _selectedToken,
                suffixStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF10B981)),
                ),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
              ),
            ),
            
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
                  child: _buildQuickAmountButton('10'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAmountButton('50'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAmountButton('100'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAmountButton('Max'),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Message (Optional)
            const Text(
              'Message (Optional)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Add a message to the transfer',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF10B981)),
                ),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Transfer Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _processTransfer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Transfer Tokens',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Info Card
            Container(
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
                      'Transfers are processed on the Starknet blockchain. Make sure the recipient address is correct.',
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

  Widget _buildQuickAmountButton(String amount) {
    return GestureDetector(
      onTap: () {
        if (amount == 'Max') {
          _setMaxAmount();
        } else {
          _amountController.text = amount;
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Text(
          amount == 'Max' ? 'Max' : '$amount $_selectedToken',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      _recipientController.text = clipboardData!.text!;
    }
  }

  void _setMaxAmount() async {
    try {
      final balances = await WalletService.getWalletBalances(widget.userEmail);
      if (balances != null) {
        final balance = _selectedToken == 'USDC' 
            ? double.tryParse(balances.usdcBalance) ?? 0.0
            : double.tryParse(balances.strkBalance) ?? 0.0;
        
        // Leave a small amount for gas fees (0.01)
        final maxAmount = (balance - 0.01).clamp(0.0, balance);
        _amountController.text = maxAmount.toStringAsFixed(6);
      }
    } catch (e) {
      print('Error getting max amount: $e');
    }
  }

  void _processTransfer() async {
    final amount = double.tryParse(_amountController.text);
    final recipient = _recipientController.text.trim();
    
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (recipient.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter recipient address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (!recipient.startsWith('0x') || recipient.length != 66) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid Starknet address (0x + 64 characters)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Confirm Transfer',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to transfer:',
              style: TextStyle(color: Colors.grey[300]),
            ),
            const SizedBox(height: 8),
            Text(
              '${amount.toStringAsFixed(6)} $_selectedToken',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'To: ${recipient.substring(0, 10)}...${recipient.substring(recipient.length - 6)}',
              style: TextStyle(color: Colors.grey[300]),
            ),
            if (_messageController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Message: ${_messageController.text}',
                style: TextStyle(color: Colors.grey[300]),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
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
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
            const SizedBox(height: 16),
            Text(
              'Processing transfer...',
              style: TextStyle(color: Colors.grey[300]),
            ),
          ],
        ),
      ),
    );
    
    try {
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
        tokenName: _selectedToken,
        amount: amount,
        recipientAddress: recipient,
        message: _messageController.text.isNotEmpty ? _messageController.text : 'Token transfer',
      );
      
      Navigator.pop(context); // Close loading dialog
      
      if (transferResult?.success == true) {
        Navigator.pop(context); // Close transfer screen
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully transferred ${amount.toStringAsFixed(6)} $_selectedToken'),
            backgroundColor: const Color(0xFF10B981),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
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
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transfer failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
