import "dotenv/config";
import express from "express";
import cors from "cors";
import * as crypto from "crypto";
import { createServer } from "http";
import { OTPService } from "./services/otpService";
import { WalletKeyService } from "./services/walletKeyService";
import { WalletManagementService } from "./services/walletManagementService";
import { GroupService } from "./services/groupService";
import { WebSocketService } from "./services/websocketService";
import { BalanceService } from "./services/balanceService";
import { TransactionService } from "./services/transactionService";
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

// Get wallet balances endpoint
app.get("/wallet/:email/balances", async (req, res) => {
  try {
    const { email } = req.params;

    if (!email) {
      res.status(400).json({ error: "Email is required" });
      return;
    }

    // Get wallet address first
    const walletService = WalletManagementService.getInstance();
    const walletInfo = walletService.getWalletInfo(email);

    if (!walletInfo) {
      res.status(404).json({ error: "Wallet not found" });
      return;
    }

    // Get balances
    const balanceService = BalanceService.getInstance();
    const balances = await balanceService.getWalletBalances(walletInfo.walletAddress);

    res.json({
      success: true,
      balances
    });

  } catch (err: any) {
    console.error("❌ Error retrieving wallet balances:", err);
    res.status(500).json({ error: err.message });
  }
});

// Get tip transactions endpoint
app.get("/wallet/:email/tips", async (req, res) => {
  try {
    const { email } = req.params;
    const limit = parseInt(req.query.limit as string) || 5;

    if (!email) {
      res.status(400).json({ error: "Email is required" });
      return;
    }

    const transactionService = TransactionService.getInstance();
    const tipTransactions = await transactionService.getTipTransactions(email, limit);
    const totalTipsReceived = await transactionService.getTotalTipsReceived(email);

    res.json({
      success: true,
      tipTransactions,
      totalTipsReceived
    });

  } catch (err: any) {
    console.error("❌ Error retrieving tip transactions:", err);
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

// ========== GROUP CHAT API ENDPOINTS ==========

// Create a new group
app.post("/groups", async (req, res) => {
  try {
    const { name, description, category, icon, color, isPrivate, userEmail } = req.body;

    if (!name || !category || !userEmail) {
      res.status(400).json({ error: "Name, category, and userEmail are required" });
      return;
    }

    const groupService = GroupService.getInstance();
    const result = groupService.createGroup({
      name,
      description: description || "",
      category,
      icon: icon || "group",
      color: color || "#6366F1",
      isPrivate: Boolean(isPrivate),
      createdBy: userEmail
    });

    if (result.success) {
      res.status(201).json(result);
    } else {
      res.status(400).json(result);
    }

  } catch (err: any) {
    console.error("❌ Error creating group:", err);
    res.status(500).json({ error: err.message });
  }
});

// Get user's groups
app.get("/groups/user/:userEmail", async (req, res) => {
  try {
    const { userEmail } = req.params;

    if (!userEmail) {
      res.status(400).json({ error: "User email is required" });
      return;
    }

    const groupService = GroupService.getInstance();
    const result = groupService.getUserGroups(userEmail);

    res.json(result);

  } catch (err: any) {
    console.error("❌ Error getting user groups:", err);
    res.status(500).json({ error: err.message });
  }
});

// Get public groups by category
app.get("/groups/public/:category", async (req, res) => {
  try {
    const { category } = req.params;

    if (!category) {
      res.status(400).json({ error: "Category is required" });
      return;
    }

    const groupService = GroupService.getInstance();
    const result = groupService.getPublicGroupsByCategory(category);

    res.json(result);

  } catch (err: any) {
    console.error("❌ Error getting public groups:", err);
    res.status(500).json({ error: err.message });
  }
});

// Get group by ID
app.get("/groups/:groupId", async (req, res) => {
  try {
    const { groupId } = req.params;
    const { userEmail } = req.query;

    if (!groupId || !userEmail) {
      res.status(400).json({ error: "Group ID and user email are required" });
      return;
    }

    const groupService = GroupService.getInstance();
    const result = groupService.getGroupById(parseInt(groupId), userEmail as string);

    if (result.success) {
      res.json(result);
    } else {
      res.status(404).json(result);
    }

  } catch (err: any) {
    console.error("❌ Error getting group:", err);
    res.status(500).json({ error: err.message });
  }
});

// Join a group
app.post("/groups/:groupId/join", async (req, res) => {
  try {
    const { groupId } = req.params;
    const { userEmail } = req.body;

    if (!groupId || !userEmail) {
      res.status(400).json({ error: "Group ID and user email are required" });
      return;
    }

    const groupService = GroupService.getInstance();
    const result = groupService.joinGroup(parseInt(groupId), userEmail);

    if (result.success) {
      res.json(result);
    } else {
      res.status(400).json(result);
    }

  } catch (err: any) {
    console.error("❌ Error joining group:", err);
    res.status(500).json({ error: err.message });
  }
});

// Leave a group
app.post("/groups/:groupId/leave", async (req, res) => {
  try {
    const { groupId } = req.params;
    const { userEmail } = req.body;

    if (!groupId || !userEmail) {
      res.status(400).json({ error: "Group ID and user email are required" });
      return;
    }

    const groupService = GroupService.getInstance();
    const result = groupService.leaveGroup(parseInt(groupId), userEmail);

    if (result.success) {
      res.json(result);
    } else {
      res.status(400).json(result);
    }

  } catch (err: any) {
    console.error("❌ Error leaving group:", err);
    res.status(500).json({ error: err.message });
  }
});

// Get group members
app.get("/groups/:groupId/members", async (req, res) => {
  try {
    const { groupId } = req.params;
    const { userEmail } = req.query;

    if (!groupId || !userEmail) {
      res.status(400).json({ error: "Group ID and user email are required" });
      return;
    }

    const groupService = GroupService.getInstance();
    const result = groupService.getGroupMembers(parseInt(groupId), userEmail as string);

    res.json(result);

  } catch (err: any) {
    console.error("❌ Error getting group members:", err);
    res.status(500).json({ error: err.message });
  }
});

// Send message to group
app.post("/groups/:groupId/messages", async (req, res) => {
  try {
    const { groupId } = req.params;
    const { senderEmail, content, messageType } = req.body;

    if (!groupId || !senderEmail || !content) {
      res.status(400).json({ error: "Group ID, sender email, and content are required" });
      return;
    }

    const groupService = GroupService.getInstance();
    const result = groupService.sendMessage(
      parseInt(groupId), 
      senderEmail, 
      content, 
      messageType || 'text'
    );

    if (result.success) {
      // Broadcast message via WebSocket to all connected clients
      const wsService = WebSocketService.getInstance();
      wsService.broadcastMessage({
        groupId: parseInt(groupId),
        senderEmail: senderEmail,
        content: content,
        messageType: messageType || 'text',
        createdAt: result.message?.createdAt || new Date().toISOString()
      });
      
      res.status(201).json(result);
    } else {
      res.status(400).json(result);
    }

  } catch (err: any) {
    console.error("❌ Error sending message:", err);
    res.status(500).json({ error: err.message });
  }
});

// Get group messages
app.get("/groups/:groupId/messages", async (req, res) => {
  try {
    const { groupId } = req.params;
    const { userEmail, limit, offset } = req.query;

    if (!groupId || !userEmail) {
      res.status(400).json({ error: "Group ID and user email are required" });
      return;
    }

    const groupService = GroupService.getInstance();
    const result = groupService.getGroupMessages(
      parseInt(groupId), 
      userEmail as string,
      limit ? parseInt(limit as string) : 50,
      offset ? parseInt(offset as string) : 0
    );

    res.json(result);

  } catch (err: any) {
    console.error("❌ Error getting group messages:", err);
    res.status(500).json({ error: err.message });
  }
});

const PORT = parseInt(process.env.PORT || '3000', 10);
console.log('🚀 Starting server...');
console.log('📡 NODE_URL:', NODE_URL);
console.log('🔧 PORT:', PORT);

// Create HTTP server
const httpServer = createServer(app);

// Initialize WebSocket service
const wsService = WebSocketService.getInstance(httpServer);

// Connect services
const groupService = GroupService.getInstance();
groupService.setWebSocketService(wsService);

// Start server
httpServer.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ API listening on http://localhost:${PORT}`);
  console.log(`🌐 Network accessible at http://192.168.0.106:${PORT}`);
  console.log(`🔌 WebSocket server running on ws://localhost:${PORT}`);
  console.log('🎯 Available endpoints:');
  console.log('  GET  / - Health check');
  console.log('  GET  /test-email - Test email connectivity');
  console.log('  POST /generate-otp - Generate OTP');
  console.log('  POST /wallet - Create/get wallet with OTP');
  console.log('  GET  /wallet/:email - Get wallet info (without private key)');
  console.log('  GET  /admin/wallet-stats - Get wallet statistics');
  console.log('  POST /groups - Create new group');
  console.log('  GET  /groups/user/:userEmail - Get user groups');
  console.log('  GET  /groups/public/:category - Get public groups by category');
  console.log('  GET  /groups/:groupId - Get group details');
  console.log('  POST /groups/:groupId/join - Join group');
  console.log('  POST /groups/:groupId/leave - Leave group');
  console.log('  GET  /groups/:groupId/members - Get group members');
  console.log('  POST /groups/:groupId/messages - Send message');
  console.log('  GET  /groups/:groupId/messages - Get group messages');
  console.log('🔌 WebSocket events:');
  console.log('  authenticate - Authenticate user');
  console.log('  join_group - Join group chat');
  console.log('  leave_group - Leave group chat');
  console.log('  send_message - Send message');
  console.log('  typing_start/stop - Typing indicators');
});
