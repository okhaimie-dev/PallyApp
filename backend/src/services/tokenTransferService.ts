import { RpcProvider, Account, CallData, Contract, uint256 } from 'starknet';
import { STRK_ABI } from '../abis/strk_abi';
import { USDC_ABI } from '../abis/usdc_abi';
import { DatabaseService } from './databaseService';

export interface TokenTransferResult {
  success: boolean;
  transactionHash?: string;
  error?: string;
  message?: string;
}

export interface TokenTransferParams {
  senderPrivateKey: string;
  recipientAddress: string;
  amount: number;
  token: 'USDC' | 'STRK';
  message?: string;
}

export class TokenTransferService {
  private static instance: TokenTransferService;
  private provider: RpcProvider;
  private databaseService: DatabaseService;

  // Token contract addresses on Starknet mainnet
  private static readonly TOKEN_ADDRESSES = {
    USDC: '0x053c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06b3ad0a6e6',
    STRK: '0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d',
  };

  // Token decimals
  private static readonly TOKEN_DECIMALS = {
    USDC: 6,
    STRK: 18,
  };

  private constructor() {
    this.provider = new RpcProvider({
      nodeUrl: process.env.NODE_URL || 'https://starknet-mainnet.public.blastapi.io',
    });
    this.databaseService = DatabaseService.getInstance();
  }

  public static getInstance(): TokenTransferService {
    if (!TokenTransferService.instance) {
      TokenTransferService.instance = new TokenTransferService();
    }
    return TokenTransferService.instance;
  }

  /**
   * Transfer tokens from sender to recipient
   */
  public async transferTokens(params: TokenTransferParams): Promise<TokenTransferResult> {
    try {
      console.log(`🔄 Starting token transfer: ${params.amount} ${params.token} to ${params.recipientAddress}`);

      // Get sender account
      const senderAccount = new Account(this.provider, params.senderPrivateKey, params.senderPrivateKey);
      
      // Get token contract
      const tokenAddress = TokenTransferService.TOKEN_ADDRESSES[params.token];
      const tokenABI = params.token === 'USDC' ? USDC_ABI : STRK_ABI;
      const tokenContract = new Contract(tokenABI, tokenAddress, this.provider);

      // Convert amount to proper units (considering decimals)
      const decimals = TokenTransferService.TOKEN_DECIMALS[params.token];
      const amountInWei = uint256.bnToUint256(BigInt(params.amount * Math.pow(10, decimals)));

      console.log(`💰 Transferring ${params.amount} ${params.token} (${amountInWei.low.toString()} wei)`);

      // Check sender balance
      const balance = await tokenContract.balance_of(senderAccount.address);
      const currentBalance = Number(uint256.uint256ToBN(balance)) / Math.pow(10, decimals);
      
      if (currentBalance < params.amount) {
        return {
          success: false,
          error: `Insufficient ${params.token} balance. Current: ${currentBalance.toFixed(6)}, Required: ${params.amount}`,
        };
      }

      console.log(`✅ Sender balance: ${currentBalance.toFixed(6)} ${params.token}`);

      // Prepare transfer call
      const transferCall = tokenContract.populate('transfer', [
        params.recipientAddress,
        amountInWei,
      ]);

      // Execute transfer
      const result = await senderAccount.execute([transferCall]);
      
      console.log(`✅ Transfer transaction submitted: ${result.transaction_hash}`);

      // Wait for transaction to be accepted
      await this.provider.waitForTransaction(result.transaction_hash);

      console.log(`✅ Transfer completed successfully: ${result.transaction_hash}`);

      return {
        success: true,
        transactionHash: result.transaction_hash,
        message: `Successfully transferred ${params.amount} ${params.token}`,
      };

    } catch (error: any) {
      console.error('❌ Token transfer failed:', error);
      return {
        success: false,
        error: error.message || 'Token transfer failed',
      };
    }
  }

  /**
   * Get token balance for an address
   */
  public async getTokenBalance(address: string, token: 'USDC' | 'STRK'): Promise<number> {
    try {
      const tokenAddress = TokenTransferService.TOKEN_ADDRESSES[token];
      const tokenABI = token === 'USDC' ? USDC_ABI : STRK_ABI;
      const tokenContract = new Contract(tokenABI, tokenAddress, this.provider);

      const balance = await tokenContract.balance_of(address);
      const decimals = TokenTransferService.TOKEN_DECIMALS[token];
      
      return Number(uint256.uint256ToBN(balance)) / Math.pow(10, decimals);
    } catch (error) {
      console.error(`❌ Error getting ${token} balance:`, error);
      return 0;
    }
  }

  /**
   * Get wallet address by email
   */
  public getWalletAddressByEmail(email: string): string | null {
    const wallet = this.databaseService.getWalletByEmail(email);
    return wallet ? wallet.accountAddress : null;
  }

  /**
   * Validate recipient email exists in database
   */
  public validateRecipientEmail(email: string): boolean {
    return this.databaseService.walletExists(email);
  }
}
