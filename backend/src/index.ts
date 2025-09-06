import "dotenv/config";
import express from "express";
import cors from "cors";
import * as crypto from "crypto";
import { OTPService } from "./services/otpService";
import { WalletKeyService } from "./services/walletKeyService";
import { WalletManagementService } from "./services/walletManagementService";
import emailService from "./services/emailService";
import {
  generalLimiter,
  securityHeaders,
  validateRequest,
  securityLogger
} from "./middleware/security";

// -------- CONFIG --------
const NODE_URL = process.env.NODE_URL as string;

// --------- SERVER ---------

const app = express();

// Security middleware
app.use(securityHeaders);
app.use(securityLogger);
app.use(generalLimiter);
app.use(cors());
app.use(express.json({ limit: "1mb" }));
app.use(validateRequest);

// Health check
app.get("/", (_, res) => {
  res.json({ status: "API running 🚀" });
});

// Test email connectivity
app.get("/test-email", async (req, res) => {
  try {
    const emailConfigured = !!(process.env.EMAIL_USER && process.env.EMAIL_PASS);
    
    if (!emailConfigured) {
      res.json({
        success: false,
        message: "Email service not configured",
        emailConfigured: false
      });
      return;
    }

    // Test actual email connection
    const connectionTest = await emailService.testConnection();
    
    res.json({
      success: connectionTest.success,
      message: connectionTest.message,
      emailConfigured: emailConfigured
    });
  } catch (err: any) {
    res.status(500).json({ 
      success: false, 
      error: err.message,
      emailConfigured: !!(process.env.EMAIL_USER && process.env.EMAIL_PASS)
    });
  }
});


// Generate OTP for wallet creation/access
app.post("/generate-otp", async (req, res) => {
  try {
    const { email, openId } = req.body;

    if (!email || !openId) {
      res.status(400).json({ error: "Email and OpenID are required" });
      return;
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      res.status(400).json({ error: "Invalid email format" });
      return;
    }

    // Generate OTP
    const otpCode = OTPService.generateOTP(email, openId);

    // Send OTP via email
    const emailResult = await emailService.sendOTPEmail(email, otpCode);
    
    if (!emailResult.success) {
      console.log(`📧 [EMAIL FAILED] OTP for ${email}: ${otpCode}`);
      // Still return success but log the email failure
    }

    res.json({
      success: true,
      message: "OTP sent to email"
    });

  } catch (err: any) {
    console.error("❌ Error generating OTP:", err);
    res.status(500).json({ error: err.message });
  }
});

// Wallet endpoint - get or create wallet with database storage
app.post("/wallet", async (req, res) => {
  try {
    const { email, openId, otp } = req.body;

    if (!email || !openId || !otp) {
      res.status(400).json({ error: "Email, OpenID, and OTP are required" });
      return;
    }

    // Validate OTP format (6 digits)
    if (!/^\d{6}$/.test(otp)) {
      res.status(400).json({ error: "Invalid OTP format" });
      return;
    }

    // Verify OTP with the service
    const otpVerification = OTPService.verifyOTP(email, otp);
    if (!otpVerification.valid) {
      res.status(400).json({ error: otpVerification.error || "Invalid OTP" });
      return;
    }

    // Ensure the OpenID matches
    if (otpVerification.openId !== openId) {
      res.status(400).json({ error: "OTP verification failed" });
      return;
    }

    // Get or create wallet using the management service
    const walletService = WalletManagementService.getInstance();
    const walletResult = await walletService.getOrCreateWallet(email, openId);

    if (!walletResult.success) {
      res.status(500).json({ error: walletResult.message });
      return;
    }

    console.log(`✅ Wallet ${walletResult.isNewWallet ? 'created' : 'retrieved'} for user: ${email}`);

    res.json({
      success: true,
      message: walletResult.message,
      privateKey: walletResult.privateKey,
      publicKey: walletResult.publicKey,
      accountAddress: walletResult.walletAddress,
      isNewWallet: walletResult.isNewWallet
    });

  } catch (err: any) {
    console.error("❌ Error with wallet operation:", err);
    res.status(500).json({ error: err.message });
  }
});

// Get wallet info endpoint (without private key)
app.get("/wallet/:email", async (req, res) => {
  try {
    const { email } = req.params;

    if (!email) {
      res.status(400).json({ error: "Email is required" });
      return;
    }

    const walletService = WalletManagementService.getInstance();
    const walletInfo = walletService.getWalletInfo(email);

    if (!walletInfo) {
      res.status(404).json({ error: "Wallet not found" });
      return;
    }

    res.json({
      success: true,
      walletAddress: walletInfo.walletAddress,
      publicKey: walletInfo.publicKey
    });

  } catch (err: any) {
    console.error("❌ Error retrieving wallet info:", err);
    res.status(500).json({ error: err.message });
  }
});

// Admin endpoint to get wallet statistics
app.get("/admin/wallet-stats", async (req, res) => {
  try {
    const walletService = WalletManagementService.getInstance();
    const stats = walletService.getWalletStats();

    res.json({
      success: true,
      stats
    });

  } catch (err: any) {
    console.error("❌ Error retrieving wallet stats:", err);
    res.status(500).json({ error: err.message });
  }
});

const PORT = parseInt(process.env.PORT || '3000', 10);
console.log('🚀 Starting server...');
console.log('📡 NODE_URL:', NODE_URL);
console.log('🔧 PORT:', PORT);

app.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ API listening on http://localhost:${PORT}`);
  console.log(`🌐 Network accessible at http://192.168.0.106:${PORT}`);
  console.log('🎯 Available endpoints:');
  console.log('  GET  / - Health check');
  console.log('  GET  /test-email - Test email connectivity');
  console.log('  POST /generate-otp - Generate OTP');
  console.log('  POST /wallet - Create/get wallet with OTP');
  console.log('  GET  /wallet/:email - Get wallet info (without private key)');
  console.log('  GET  /admin/wallet-stats - Get wallet statistics');
});
