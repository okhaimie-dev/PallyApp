const nodemailer = require('nodemailer');

class EmailService {
  constructor() {
    this.transporter = null;
    this.initializeTransporter();
  }

  initializeTransporter() {
    try {
      const emailService = process.env.EMAIL_SERVICE || 'gmail';
      const emailUser = process.env.EMAIL_USER;
      const emailPass = process.env.EMAIL_PASS;

      console.log('🔍 Email config check:', {
        service: emailService,
        user: emailUser ? `${emailUser.substring(0, 5)}...` : 'undefined',
        pass: emailPass ? '***configured***' : 'undefined'
      });

      if (!emailUser || !emailPass) {
        console.warn('⚠️  Email credentials not configured. Email sending will be disabled.');
        return;
      }

      this.transporter = nodemailer.createTransport({
        service: emailService,
        auth: {
          user: emailUser,
          pass: emailPass
        }
      });

      console.log('✅ Email service initialized successfully');
    } catch (error) {
      console.error('❌ Failed to initialize email service:', error.message);
    }
  }

  async sendOTPEmail(email, otpCode) {
    if (!this.transporter) {
      console.log(`📧 [EMAIL DISABLED] OTP for ${email}: ${otpCode}`);
      return { success: false, message: 'Email service not configured' };
    }

    try {
      const mailOptions = {
        from: process.env.EMAIL_FROM || process.env.EMAIL_USER,
        to: email,
        subject: 'Your Pally Wallet OTP Code',
        html: this.generateOTPEmailHTML(otpCode),
        text: this.generateOTPEmailText(otpCode)
      };

      const result = await this.transporter.sendMail(mailOptions);
      console.log(`📧 OTP email sent to ${email}: ${result.messageId}`);
      
      return { 
        success: true, 
        messageId: result.messageId,
        message: 'OTP email sent successfully'
      };
    } catch (error) {
      console.error(`❌ Failed to send OTP email to ${email}:`, error.message);
      return { 
        success: false, 
        error: error.message,
        message: 'Failed to send OTP email'
      };
    }
  }

  generateOTPEmailHTML(otpCode) {
    return `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Your Pally Wallet OTP</title>
        <style>
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                line-height: 1.6;
                color: #333;
                max-width: 600px;
                margin: 0 auto;
                padding: 20px;
                background-color: #f4f4f4;
            }
            .container {
                background-color: white;
                border-radius: 12px;
                padding: 40px;
                box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            }
            .header {
                text-align: center;
                margin-bottom: 30px;
            }
            .logo {
                font-size: 32px;
                font-weight: bold;
                color: #fa7963;
                margin-bottom: 10px;
            }
            .otp-code {
                background-color: #f8f9fa;
                border: 2px solid #e9ecef;
                border-radius: 8px;
                padding: 20px;
                text-align: center;
                margin: 30px 0;
                font-size: 32px;
                font-weight: bold;
                color: #fa7963;
                letter-spacing: 8px;
                font-family: 'Courier New', monospace;
            }
            .warning {
                background-color: #fff3cd;
                border: 1px solid #ffeaa7;
                border-radius: 6px;
                padding: 15px;
                margin: 20px 0;
                color: #856404;
            }
            .footer {
                text-align: center;
                margin-top: 30px;
                padding-top: 20px;
                border-top: 1px solid #e9ecef;
                color: #6c757d;
                font-size: 14px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <div class="logo">Pally</div>
                <h1>Your Wallet Verification Code</h1>
            </div>
            
            <p>Hello!</p>
            
            <p>You're creating or accessing your Pally wallet. Use the verification code below to complete the process:</p>
            
            <div class="otp-code">${otpCode}</div>
            
            <div class="warning">
                <strong>⚠️ Security Notice:</strong>
                <ul>
                    <li>This code expires in 10 minutes</li>
                    <li>Never share this code with anyone</li>
                    <li>Pally will never ask for this code via phone or email</li>
                </ul>
            </div>
            
            <p>If you didn't request this code, please ignore this email.</p>
            
            <div class="footer">
                <p>This email was sent by Pally App</p>
                <p>© 2024 Pally. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    `;
  }

  generateOTPEmailText(otpCode) {
    return `
Pally Wallet - Your Verification Code

Hello!

You're creating or accessing your Pally wallet. Use the verification code below to complete the process:

${otpCode}

Security Notice:
- This code expires in 10 minutes
- Never share this code with anyone
- Pally will never ask for this code via phone or email

If you didn't request this code, please ignore this email.

This email was sent by Pally App
© 2024 Pally. All rights reserved.
    `;
  }

  async testConnection() {
    if (!this.transporter) {
      return { success: false, message: 'Email service not configured' };
    }

    try {
      await this.transporter.verify();
      return { success: true, message: 'Email service connection successful' };
    } catch (error) {
      return { success: false, message: `Email service connection failed: ${error.message}` };
    }
  }
}

module.exports = new EmailService();
