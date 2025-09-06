const express = require('express');
const cors = require('cors');
const crypto = require('crypto');
require('dotenv').config();
const emailService = require('./src/services/emailService');

console.log('🚀 Starting working server...');

const app = express();

// Middleware
app.use(cors());
app.use(express.json({ limit: "1mb" }));

// Simple OTP storage (in production, use Redis or database)
const otpStore = new Map();
const OTP_EXPIRY_MS = 10 * 60 * 1000; // 10 minutes
const TEST_OTP = "1234";

// Health check
app.get("/", (req, res) => {
  res.json({ status: "API running 🚀" });
});

// Test email connectivity
app.get("/test-email", async (req, res) => {
  try {
    const result = await emailService.testConnection();
    res.json({
      success: result.success,
      message: result.message,
      emailConfigured: !!process.env.EMAIL_USER && !!process.env.EMAIL_PASS
    });
  } catch (err) {
    res.status(500).json({ 
      success: false, 
      error: err.message,
      emailConfigured: !!process.env.EMAIL_USER && !!process.env.EMAIL_PASS
    });
  }
});

// Generate OTP endpoint
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

    // For testing, always return 1234
    const otpCode = TEST_OTP;
    
    otpStore.set(email, {
      code: otpCode,
      expiry: Date.now() + OTP_EXPIRY_MS,
      openId: openId,
      attempts: 0,
    });

    // Send email with OTP
    const emailResult = await emailService.sendOTPEmail(email, otpCode);
    
    if (emailResult.success) {
      console.log(`📧 OTP email sent successfully to ${email}`);
    } else {
      console.log(`⚠️  Email sending failed for ${email}: ${emailResult.message}`);
      // Still log the OTP for development
      console.log(`📧 [FALLBACK] OTP for ${email}: ${otpCode}`);
    }

    res.json({
      success: true,
      message: emailResult.success ? "OTP sent to email" : "OTP generated (email failed)",
      otpCode: otpCode, // For testing - remove in production
      emailSent: emailResult.success
    });

  } catch (err) {
    console.error("❌ Error generating OTP:", err);
    res.status(500).json({ error: err.message });
  }
});

// Single wallet endpoint - auto-generates everything
app.post("/wallet", (req, res) => {
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

    // Generate deterministic wallet data using Argon2-like approach
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
    
    // Generate public key (simplified - in real implementation use Starknet's ec.starkCurve.getStarkKey)
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

  } catch (err) {
    console.error("❌ Error creating wallet:", err);
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`✅ API listening on http://localhost:${PORT}`);
  console.log('🎯 Available endpoints:');
  console.log('  GET  / - Health check');
  console.log('  GET  /test-email - Test email connectivity');
  console.log('  POST /generate-otp - Generate OTP');
  console.log('  POST /wallet - Create/get wallet with OTP');
});
