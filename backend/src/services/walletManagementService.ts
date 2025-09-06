import { DatabaseService, WalletRecord } from "./databaseService";
import { WalletKeyService, WalletKeyResult } from "./walletKeyService";
import * as crypto from "crypto";

export interface WalletResponse {
  success: boolean;
  walletAddress: string;
  privateKey: string;
  publicKey: string;
  message: string;
  isNewWallet?: boolean;
}

export class WalletManagementService {
  private static instance: WalletManagementService;
  private dbService: DatabaseService;

  private constructor() {
    this.dbService = DatabaseService.getInstance();
  }

  public static getInstance(): WalletManagementService {
    if (!WalletManagementService.instance) {
      WalletManagementService.instance = new WalletManagementService();
    }
    return WalletManagementService.instance;
  }

  /**
   * Get or create wallet for user
   * If wallet exists, return it with decrypted private key
   * If not, create new wallet and save to database
   */
  public async getOrCreateWallet(email: string, openId: string): Promise<WalletResponse> {
    try {
      // Check if wallet already exists
      const existingWallet = this.dbService.getWalletWithPrivateKey(email);
      
      if (existingWallet) {
        console.log(`📋 Retrieved existing wallet for: ${email}`);
        return {
          success: true,
          walletAddress: existingWallet.wallet.accountAddress,
          privateKey: existingWallet.privateKey,
          publicKey: existingWallet.wallet.publicKey,
          message: "Wallet retrieved successfully",
          isNewWallet: false
        };
      }

      // Create new wallet
      console.log(`🆕 Creating new wallet for: ${email}`);
      const walletData = await this.createNewWallet(openId);
      
      // Save to database
      this.dbService.saveWallet(
        email,
        walletData.privateKey,
        walletData.publicKey,
        walletData.accountAddress
      );

      return {
        success: true,
        walletAddress: walletData.accountAddress,
        privateKey: walletData.privateKey,
        publicKey: walletData.publicKey,
        message: "New wallet created successfully",
        isNewWallet: true
      };

    } catch (error) {
      console.error("❌ Error in getOrCreateWallet:", error);
      return {
        success: false,
        walletAddress: "",
        privateKey: "",
        publicKey: "",
        message: `Wallet operation failed: ${error instanceof Error ? error.message : "Unknown error"}`
      };
    }
  }

  /**
   * Create a new wallet using deterministic key derivation
   */
  private async createNewWallet(openId: string): Promise<WalletKeyResult> {
    try {
      // Use the existing WalletKeyService for key derivation
      const walletData = await WalletKeyService.deriveWalletKey(openId);
      
      // Validate the generated keys
      if (!WalletKeyService.validatePrivateKey(walletData.privateKey)) {
        throw new Error("Generated private key is invalid");
      }

      return walletData;
    } catch (error) {
      throw new Error(`Failed to create new wallet: ${error instanceof Error ? error.message : "Unknown error"}`);
    }
  }

  /**
   * Get wallet information without private key (for display purposes)
   */
  public getWalletInfo(email: string): { walletAddress: string; publicKey: string } | null {
    const wallet = this.dbService.getWalletByEmail(email);
    if (!wallet) {
      return null;
    }

    return {
      walletAddress: wallet.accountAddress,
      publicKey: wallet.publicKey
    };
  }

  /**
   * Check if user has a wallet
   */
  public hasWallet(email: string): boolean {
    return this.dbService.walletExists(email);
  }

  /**
   * Get wallet statistics (for admin purposes)
   */
  public getWalletStats(): { totalWallets: number; recentWallets: WalletRecord[] } {
    const allWallets = this.dbService.getAllWallets();
    const recentWallets = allWallets.slice(0, 10); // Last 10 wallets

    return {
      totalWallets: allWallets.length,
      recentWallets
    };
  }

  /**
   * Validate wallet data integrity
   */
  public validateWalletIntegrity(email: string): { isValid: boolean; errors: string[] } {
    const errors: string[] = [];
    
    try {
      const walletData = this.dbService.getWalletWithPrivateKey(email);
      
      if (!walletData) {
        errors.push("Wallet not found");
        return { isValid: false, errors };
      }

      // Validate private key format
      if (!WalletKeyService.validatePrivateKey(walletData.privateKey)) {
        errors.push("Invalid private key format");
      }

      // Validate public key format (basic check)
      if (!/^0x[0-9a-fA-F]{64}$/.test(walletData.wallet.publicKey)) {
        errors.push("Invalid public key format");
      }

      // Validate account address format (basic check)
      if (!/^0x[0-9a-fA-F]{40}$/.test(walletData.wallet.accountAddress)) {
        errors.push("Invalid account address format");
      }

      return {
        isValid: errors.length === 0,
        errors
      };

    } catch (error) {
      errors.push(`Validation error: ${error instanceof Error ? error.message : "Unknown error"}`);
      return { isValid: false, errors };
    }
  }
}
