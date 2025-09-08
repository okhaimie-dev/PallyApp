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
import { AccountDeploymentService } from "./services/accountDeploymentService";
import { TokenTransferService } from "./services/tokenTransferService";
import { DatabaseService } from "./services/databaseService";
import { GlobalGroupService } from "./services/globalGroupService";
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

// Add keep-alive headers for better connection stability
app.use((req, res, next) => {
  res.setHeader('Connection', 'keep-alive');
  res.setHeader('Keep-Alive', 'timeout=30, max=1000');
  next();
});

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

// Send tip endpoint
app.post("/send-tip", async (req, res) => {
  try {
    const { senderPrivateKey, selectedToken, amount, recipientEmail, message } = req.body;

    // Validate required fields
    if (!senderPrivateKey || !selectedToken || !amount || !recipientEmail) {
      res.status(400).json({ 
        error: "Missing required fields: senderPrivateKey, selectedToken, amount, recipientEmail" 
      });
      return;
    }

    // Validate token type
    if (!['USDC', 'STRK'].includes(selectedToken)) {
      res.status(400).json({ 
        error: "Invalid token. Must be 'USDC' or 'STRK'" 
      });
      return;
    }

    // Validate amount
    const tipAmount = parseFloat(amount);
    if (isNaN(tipAmount) || tipAmount <= 0) {
      res.status(400).json({ 
        error: "Amount must be a positive number" 
      });
      return;
    }

    // Validate recipient email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(recipientEmail)) {
      res.status(400).json({ 
        error: "Invalid recipient email format" 
      });
      return;
    }

    console.log(`💸 Processing tip: ${tipAmount} ${selectedToken} from sender to ${recipientEmail}`);

    // Get services
    const tokenTransferService = TokenTransferService.getInstance();
    const transactionService = TransactionService.getInstance();
    const wsService = WebSocketService.getInstance();

    // Validate recipient exists in database
    if (!tokenTransferService.validateRecipientEmail(recipientEmail)) {
      res.status(404).json({ 
        error: "Recipient email not found in our system" 
      });
      return;
    }

    // Get recipient wallet address
    const recipientAddress = tokenTransferService.getWalletAddressByEmail(recipientEmail);
    if (!recipientAddress) {
      res.status(404).json({ 
        error: "Recipient wallet address not found" 
      });
      return;
    }

    console.log(`📍 Recipient address: ${recipientAddress}`);

    // Execute token transfer
    const transferResult = await tokenTransferService.transferTokens({
      senderPrivateKey,
      recipientAddress,
      amount: tipAmount,
      token: selectedToken as 'USDC' | 'STRK',
      message: message || 'Great job!'
    });

    if (!transferResult.success) {
      res.status(500).json({ 
        error: transferResult.error || "Token transfer failed" 
      });
      return;
    }

    // Get sender email from private key
    const dbService = DatabaseService.getInstance();
    const senderEmail = dbService.getEmailByPrivateKey(senderPrivateKey);
    
    if (!senderEmail) {
      res.status(400).json({ 
        error: "Sender private key not found in our system" 
      });
      return;
    }

    // Create tip transaction record
    const tipTransactionId = await transactionService.createTipTransaction(
      senderEmail,
      recipientEmail,
      tipAmount,
      selectedToken as 'USDC' | 'STRK',
      message || 'Great job!',
      transferResult.transactionHash
    );

    console.log(`✅ Tip transaction recorded with ID: ${tipTransactionId}`);

    // Send websocket notification to recipient
    const notificationData = {
      type: 'tip_received',
      senderEmail: senderEmail,
      recipientEmail: recipientEmail,
      amount: tipAmount,
      token: selectedToken,
      message: message || 'Great job!',
      transactionHash: transferResult.transactionHash,
      timestamp: new Date().toISOString()
    };

    // Send notification to recipient's personal room
    wsService.sendTipNotification(recipientEmail, notificationData);

    console.log(`📡 Tip notification sent to ${recipientEmail}`);

    res.json({
      success: true,
      message: `Successfully sent ${tipAmount} ${selectedToken} tip`,
      transactionHash: transferResult.transactionHash,
      tipTransactionId: tipTransactionId,
      recipientAddress: recipientAddress
    });

  } catch (err: any) {
    console.error("❌ Error sending tip:", err);
    res.status(500).json({ error: err.message });
  }
});

// General token transfer endpoint (not just tips)
app.post("/transfer-tokens", async (req, res) => {
  try {
    const { senderPrivateKey, tokenName, amount, recipientAddress, message } = req.body;

    // Validate required fields
    if (!senderPrivateKey || !tokenName || !amount || !recipientAddress) {
      res.status(400).json({ 
        error: "Missing required fields: senderPrivateKey, tokenName, amount, recipientAddress" 
      });
      return;
    }

    // Validate token type
    if (!['USDC', 'STRK'].includes(tokenName.toUpperCase())) {
      res.status(400).json({ 
        error: "Invalid token. Must be 'USDC' or 'STRK'" 
      });
      return;
    }

    // Validate amount
    const transferAmount = parseFloat(amount);
    if (isNaN(transferAmount) || transferAmount <= 0) {
      res.status(400).json({ 
        error: "Amount must be a positive number" 
      });
      return;
    }

    // Validate recipient address format (basic Starknet address validation)
    if (!recipientAddress.startsWith('0x') || recipientAddress.length !== 66) {
      res.status(400).json({ 
        error: "Invalid recipient address format. Must be a valid Starknet address (0x + 64 hex characters)" 
      });
      return;
    }

    console.log(`💸 Processing token transfer: ${transferAmount} ${tokenName} to ${recipientAddress}`);

    // Get token transfer service
    const tokenTransferService = TokenTransferService.getInstance();

    // Execute token transfer
    const transferResult = await tokenTransferService.transferTokens({
      senderPrivateKey,
      recipientAddress,
      amount: transferAmount,
      token: tokenName.toUpperCase() as 'USDC' | 'STRK',
      message: message || 'Token transfer'
    });

    if (!transferResult.success) {
      res.status(500).json({ 
        error: transferResult.error || "Token transfer failed" 
      });
      return;
    }

    console.log(`✅ Token transfer completed: ${transferResult.transactionHash}`);

    res.json({
      success: true,
      message: `Successfully transferred ${transferAmount} ${tokenName}`,
      transactionHash: transferResult.transactionHash
    });

  } catch (err: any) {
    console.error("❌ Error transferring tokens:", err);
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

// ========== ACCOUNT DEPLOYMENT ENDPOINTS ==========

// Check if wallet account is deployed
app.get("/wallet/:email/deployment-status", async (req, res) => {
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

    // Check deployment status
    const deploymentService = AccountDeploymentService.getInstance();
    const deploymentStatus = await deploymentService.checkDeploymentStatus(walletInfo.walletAddress);

    // Check deployment requirements
    const requirements = await deploymentService.checkDeploymentRequirements(walletInfo.walletAddress);

    res.json({
      success: true,
      deploymentStatus,
      requirements
    });

  } catch (err: any) {
    console.error("❌ Error checking deployment status:", err);
    res.status(500).json({ error: err.message });
  }
});

// Deploy wallet account
app.post("/wallet/:email/deploy", async (req, res) => {
  try {
    const { email } = req.params;

    if (!email) {
      res.status(400).json({ error: "Email is required" });
      return;
    }

    // Get wallet with private key
    const walletService = WalletManagementService.getInstance();
    const dbService = (await import("./services/databaseService")).DatabaseService.getInstance();
    const walletData = dbService.getWalletWithPrivateKey(email);

    if (!walletData) {
      res.status(404).json({ error: "Wallet not found" });
      return;
    }

    // Check if already deployed
    const deploymentService = AccountDeploymentService.getInstance();
    const deploymentStatus = await deploymentService.checkDeploymentStatus(walletData.wallet.accountAddress);

    if (deploymentStatus.isDeployed) {
      res.status(400).json({ 
        error: "Account is already deployed",
        deploymentStatus 
      });
      return;
    }

    // Check deployment requirements
    const requirements = await deploymentService.checkDeploymentRequirements(walletData.wallet.accountAddress);

    if (!requirements.canDeploy) {
      res.status(400).json({ 
        error: "Insufficient STRK balance for deployment",
        requirements,
        message: `Minimum ${requirements.minimumRequired} STRK required, current balance: ${requirements.currentBalance} STRK`
      });
      return;
    }

    // Deploy the account
    const deploymentResult = await deploymentService.deployAccount(
      walletData.privateKey,
      walletData.wallet.publicKey,
      walletData.wallet.accountAddress
    );

    if (deploymentResult.success) {
      res.json({
        success: true,
        message: "Account deployed successfully",
        deploymentResult
      });
    } else {
      res.status(500).json({
        success: false,
        error: deploymentResult.error || "Deployment failed",
        deploymentResult
      });
    }

  } catch (err: any) {
    console.error("❌ Error deploying account:", err);
    res.status(500).json({ error: err.message });
  }
});

// Get deployment cost estimate
app.get("/wallet/deployment-cost", async (req, res) => {
  try {
    const deploymentService = AccountDeploymentService.getInstance();
    const costInfo = await deploymentService.getDeploymentCost();

    res.json({
      success: true,
      costInfo
    });

  } catch (err: any) {
    console.error("❌ Error getting deployment cost:", err);
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

    if (!groupId) {
      res.status(400).json({ error: "Group ID is required" });
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

// Initialize global groups service
const globalGroupService = GlobalGroupService.getInstance();

// Start server
httpServer.listen(PORT, '0.0.0.0', async () => {
  console.log(`✅ API listening on http://localhost:${PORT}`);
  console.log(`🌐 Network accessible at http://192.168.0.106:${PORT}`);
  console.log(`🔌 WebSocket server running on ws://localhost:${PORT}`);
  
  // Initialize global groups after server starts
  console.log('🚀 Initializing global groups...');
  try {
    const result = await globalGroupService.createAllGlobalGroups();
    if (result.success) {
      console.log(`✅ Global groups initialization completed: ${result.message}`);
    } else {
      console.log(`⚠️ Global groups initialization failed: ${result.message}`);
    }
  } catch (error) {
    console.error('❌ Error initializing global groups:', error);
  }
  console.log('🎯 Available endpoints:');
  console.log('  GET  / - Health check');
  console.log('  GET  /test-email - Test email connectivity');
  console.log('  POST /generate-otp - Generate OTP');
  console.log('  POST /wallet - Create/get wallet with OTP');
  console.log('  GET  /wallet/:email - Get wallet info (without private key)');
  console.log('  GET  /wallet/:email/balances - Get wallet balances');
  console.log('  GET  /wallet/:email/tips - Get tip transactions');
  console.log('  GET  /wallet/:email/deployment-status - Check account deployment status');
  console.log('  POST /wallet/:email/deploy - Deploy account to Starknet');
  console.log('  GET  /wallet/deployment-cost - Get deployment cost estimate');
  console.log('  POST /send-tip - Send tip to recipient');
  console.log('  POST /transfer-tokens - Transfer tokens to any address');
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
