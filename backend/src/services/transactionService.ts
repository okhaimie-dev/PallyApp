import { RpcProvider, CallData } from 'starknet';
import { WalletManagementService } from './walletManagementService';
import { DatabaseService } from './databaseService';

export interface BlockchainTransaction {
  hash: string;
  from: string;
  to: string;
  amount: string;
  token: 'USDC' | 'STRK';
  timestamp: number;
  message?: string;
  senderName?: string;
}

export interface TipTransaction {
  id: string;
  senderEmail: string;
  receiverEmail: string;
  amount: number;
  token: 'USDC' | 'STRK';
  message: string;
  timestamp: Date;
  transactionHash?: string;
}

export class TransactionService {
  private static instance: TransactionService;
  private provider: RpcProvider;
  private walletService: WalletManagementService;
  private databaseService: DatabaseService;

  // Token contract addresses on Starknet mainnet
  private static readonly TOKEN_ADDRESSES = {
    USDC: '0x053c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06b3ad0a6e6',
    STRK: '0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d',
  };

  private constructor() {
    this.provider = new RpcProvider({
      nodeUrl: 'https://starknet-mainnet.public.blastapi.io',
    });
    this.walletService = WalletManagementService.getInstance();
    this.databaseService = DatabaseService.getInstance();
  }

  public static getInstance(): TransactionService {
    if (!TransactionService.instance) {
      TransactionService.instance = new TransactionService();
    }
    return TransactionService.instance;
  }

  /**
   * Get recent transactions for a wallet address
   */
  public async getRecentTransactions(walletAddress: string, limit: number = 5): Promise<BlockchainTransaction[]> {
    try {
      console.log(`🔍 Fetching recent transactions for wallet: ${walletAddress}`);
      
      // For now, we'll simulate getting transactions from the blockchain
      // In a real implementation, you would:
      // 1. Query the Starknet RPC for transaction history
      // 2. Filter for USDC and STRK transfers
      // 3. Parse the transaction data
      
      // Since Starknet doesn't have a direct "get transactions" endpoint like Ethereum,
      // we'll need to use a block explorer API or implement a more complex solution
      
      // For now, return empty array (no transactions found)
      console.log(`📊 No recent transactions found for wallet: ${walletAddress}`);
      return [];
      
    } catch (error) {
      console.error('❌ Error fetching recent transactions:', error);
      return [];
    }
  }

  /**
   * Get tip transactions from the database (platform-sent tips)
   */
  public async getTipTransactions(userEmail: string, limit: number = 5): Promise<TipTransaction[]> {
    try {
      console.log(`🔍 Fetching tip transactions for user: ${userEmail}`);
      
      const rows = this.databaseService.getTipTransactions(userEmail, limit);
      
      const tipTransactions: TipTransaction[] = rows.map(row => ({
        id: row.id.toString(),
        senderEmail: row.senderEmail,
        receiverEmail: row.receiverEmail,
        amount: row.amount,
        token: row.token as 'USDC' | 'STRK',
        message: row.message || 'Great job!',
        timestamp: row.timestamp,
        transactionHash: row.transactionHash,
      }));

      console.log(`📊 Found ${tipTransactions.length} tip transactions`);
      return tipTransactions;
      
    } catch (error) {
      console.error('❌ Error fetching tip transactions:', error);
      return [];
    }
  }

  /**
   * Get user name by wallet address
   */
  public async getUserNameByWalletAddress(walletAddress: string): Promise<string | null> {
    try {
      const wallet = this.databaseService.getWalletByEmail(''); // We need to find by address
      
      // Since DatabaseService doesn't have a method to get wallet by address,
      // we'll need to add that method or use a different approach
      // For now, return null and we'll implement this later
      return null;
    } catch (error) {
      console.error('❌ Error getting user name by wallet address:', error);
      return null;
    }
  }

  /**
   * Get user name by email
   */
  public async getUserNameByEmail(email: string): Promise<string> {
    try {
      // Extract name from email (before @)
      const name = email.split('@')[0];
      if (!name) return 'Unknown User';
      return name.charAt(0).toUpperCase() + name.slice(1);
    } catch (error) {
      console.error('❌ Error getting user name by email:', error);
      return 'Unknown User';
    }
  }

  /**
   * Format wallet address for display
   */
  public formatWalletAddress(address: string): string {
    if (address.length <= 10) return address;
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  }

  /**
   * Get total tips received by a user
   */
  public async getTotalTipsReceived(userEmail: string): Promise<number> {
    try {
      return this.databaseService.getTotalTipsReceived(userEmail);
    } catch (error) {
      console.error('❌ Error getting total tips received:', error);
      return 0;
    }
  }

  /**
   * Create a tip transaction record
   */
  public async createTipTransaction(
    senderEmail: string,
    receiverEmail: string,
    amount: number,
    token: 'USDC' | 'STRK',
    message: string,
    transactionHash?: string
  ): Promise<string> {
    try {
      const id = this.databaseService.createTipTransaction(
        senderEmail,
        receiverEmail,
        amount,
        token,
        message,
        transactionHash
      );

      console.log(`✅ Tip transaction created with ID: ${id}`);
      return id.toString();
      
    } catch (error) {
      console.error('❌ Error creating tip transaction:', error);
      throw error;
    }
  }
}
