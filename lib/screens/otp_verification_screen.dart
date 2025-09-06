import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final String openId;
  final bool isNewWallet;

  const OTPVerificationScreen({
    Key? key,
    required this.email,
    required this.openId,
    required this.isNewWallet,
  }) : super(key: key);

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _generateOTP();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _generateOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/generate-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': widget.email,
          'openId': widget.openId,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        setState(() {
          _successMessage = 'OTP sent to ${widget.email}';
          // For testing, show the OTP code
          if (data['otpCode'] != null) {
            _successMessage = 'OTP sent to ${widget.email}\nTest OTP: ${data['otpCode']}';
          }
        });
      } else {
        setState(() {
          _errorMessage = data['error'] ?? 'Failed to send OTP';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/wallet'), // Use the new single endpoint
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': widget.email,
          'openId': widget.openId,
          'otp': _otpController.text,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        setState(() {
          _successMessage = data['message'] ?? 'Verification successful!';
        });

        // Go back to the previous screen with wallet data
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.of(context).pop(data);
        });
      } else {
        setState(() {
          _errorMessage = data['error'] ?? 'OTP verification failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Verify OTP',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            
            // Logo
            Center(
              child: Image.asset(
                'assets/images/pally.png',
                height: 80,
                width: 80,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Title
            const Text(
              'Enter Verification Code',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Subtitle
            Text(
              'We sent a 6-digit code to\n${widget.email}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40),
            
            // OTP Input Field
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              textAlign: TextAlign.center,
              onChanged: (value) {
                // Auto-close keyboard and verify when 6 digits are entered
                if (value.length == 6) {
                  FocusScope.of(context).unfocus();
                  _verifyOTP();
                }
              },
              decoration: InputDecoration(
                hintText: '000000',
                hintStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 24,
                  letterSpacing: 8,
                ),
                counterText: '',
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            
            // Success Message
            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _successMessage!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            
            // Verify Button
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Verify OTP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            
            const SizedBox(height: 24),
            
            // Resend OTP Button
            TextButton(
              onPressed: _isLoading ? null : _generateOTP,
              child: const Text(
                'Resend OTP',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                ),
              ),
            ),
            
            const Spacer(),
            
            // Test OTP Button (for development)
            if (widget.isNewWallet)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () {
                    _otpController.text = '1234';
                    _verifyOTP();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Use Test OTP (1234)',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
