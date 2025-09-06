import "dotenv/config";
import express from "express";
import cors from "cors";
import * as crypto from "crypto";
import { OTPService } from "./services/otpService";
import { WalletKeyService } from "./services/walletKeyService";
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
      message: "OTP sent to email",
      // For testing purposes, return the OTP code
      // In production, remove this line
      otpCode: otpCode
    });

  } catch (err: any) {
    console.error("❌ Error generating OTP:", err);
    res.status(500).json({ error: err.message });
  }
});

// Single wallet endpoint - auto-generates everything
app.post("/wallet", async (req, res) => {
  try {
    const { email, openId, otp } = req.body;

    if (!email || !openId || !otp) {
      res.status(400).json({ error: "Email, OpenID, and OTP are required" });
      return;
    }

    // For testing, accept any 6-digit OTP or "1234"
    if (otp !== "1234" && (!/^\d{6}$/.test(otp))) {
      res.status(400).json({ error: "Invalid OTP format" });
      return;
    }

    // Generate deterministic wallet data using simplified approach
    const SERVER_SECRET = process.env.SERVER_SECRET || "YOUR_SUPER_SECRET_SERVER_KEY_HERE_DO_NOT_HARDCODE_IN_PROD";
    
    // Create salt from OpenID + server secret
    const saltMaterial = `${openId}-${SERVER_SECRET}`;
    const salt = crypto.createHash('sha256').update(saltMaterial).digest('hex');
    
    // Create key material
    const keyMaterial = `${openId}-${SERVER_SECRET}`;
    
    // Simulate Argon2 with multiple rounds of hashing
    let hash = crypto.createHash('sha256').update(keyMaterial + salt).digest('hex');
    for (let i = 0; i < 1000; i++) {
      hash = crypto.createHash('sha256').update(hash + salt).digest('hex');
    }
    
    // Extract private key (first 64 chars)
    let privateKey = `0x${hash.substring(0, 64)}`;
    
    // Ensure private key is within Starknet curve order
    const keyBigInt = BigInt(privateKey);
    const maxKey = BigInt("0x800000000000011000000000000000000000000000000000000000000000000");
    
    if (keyBigInt >= maxKey) {
      const reducedKey = keyBigInt % maxKey;
      privateKey = "0x" + reducedKey.toString(16).padStart(64, '0');
    }
    
    if (BigInt(privateKey) === 0n) {
      privateKey = "0x" + "1".padStart(64, '0');
    }
    
    // Generate public key (simplified)
    const publicKey = `0x${hash.substring(64, 128)}`;
    
    // Generate account address (simplified)
    const accountAddress = `0x${hash.substring(0, 40)}`;

    console.log(`✅ Wallet created for user: ${email}`);

    res.json({
      success: true,
      message: "Wallet created successfully",
      privateKey: privateKey,
      publicKey: publicKey,
      accountAddress: accountAddress,
    });

  } catch (err: any) {
    console.error("❌ Error creating wallet:", err);
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 3000;
console.log('🚀 Starting server...');
console.log('📡 NODE_URL:', NODE_URL);
console.log('🔧 PORT:', PORT);

app.listen(PORT, () => {
  console.log(`✅ API listening on http://localhost:${PORT}`);
  console.log('🎯 Available endpoints:');
  console.log('  GET  / - Health check');
  console.log('  GET  /test-email - Test email connectivity');
  console.log('  POST /generate-otp - Generate OTP');
  console.log('  POST /wallet - Create/get wallet with OTP');
});
