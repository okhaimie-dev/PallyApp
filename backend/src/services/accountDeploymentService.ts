import { RpcProvider, Account, CallData, hash, ec } from 'starknet';

export interface DeploymentStatus {
  isDeployed: boolean;
  accountAddress: string;
  deploymentHash?: string;
  error?: string;
}

export interface DeploymentResult {
  success: boolean;
  accountAddress: string;
  deploymentHash?: string;
  message: string;
  error?: string;
}

export class AccountDeploymentService {
  private static instance: AccountDeploymentService;
  private provider: RpcProvider;

  // OpenZeppelin account class hash (mainnet)
  private static readonly ACCOUNT_CLASS_HASH = "0x540d7f5ec7ecf317e68d48564934cb99259781b1ee3cedbbc37ec5337f8e688";

  private constructor() {
    // Use public Starknet mainnet RPC
    this.provider = new RpcProvider({
      nodeUrl: 'https://starknet-mainnet.public.blastapi.io',
    });
  }

  public static getInstance(): AccountDeploymentService {
    if (!AccountDeploymentService.instance) {
      AccountDeploymentService.instance = new AccountDeploymentService();
    }
    return AccountDeploymentService.instance;
  }

  /**
   * Check if an account is deployed on Starknet
   */
  public async checkDeploymentStatus(accountAddress: string): Promise<DeploymentStatus> {
    try {
      console.log(`🔍 Checking deployment status for account: ${accountAddress}`);

      // Check if the account contract exists
      const contractCode = await this.provider.getClassHashAt(accountAddress);
      
      if (contractCode && contractCode !== '0x0') {
        console.log(`✅ Account is deployed: ${accountAddress}`);
        return {
          isDeployed: true,
          accountAddress,
        };
      } else {
        console.log(`❌ Account is not deployed: ${accountAddress}`);
        return {
          isDeployed: false,
          accountAddress,
        };
      }
    } catch (error) {
      console.error(`❌ Error checking deployment status for ${accountAddress}:`, error);
      
      // If we get an error, it usually means the account is not deployed
      return {
        isDeployed: false,
        accountAddress,
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }

  /**
   * Deploy an account to Starknet
   */
  public async deployAccount(
    privateKey: string,
    publicKey: string,
    accountAddress: string
  ): Promise<DeploymentResult> {
    try {
      console.log(`🚀 Starting account deployment for: ${accountAddress}`);

      // Validate inputs
      if (!privateKey || !publicKey || !accountAddress) {
        throw new Error('Missing required parameters for deployment');
      }

      // Create account instance
      const account = new Account(
        this.provider,
        accountAddress,
        privateKey
      );

      // Prepare constructor calldata
      const constructorCalldata = CallData.compile({ publicKey });

      // Deploy the account
      const deployAccountPayload = {
        classHash: AccountDeploymentService.ACCOUNT_CLASS_HASH,
        constructorCalldata,
        contractAddress: accountAddress,
        addressSalt: publicKey,
      };

      console.log(`📝 Deploying account with payload:`, {
        classHash: deployAccountPayload.classHash,
        contractAddress: deployAccountPayload.contractAddress,
        addressSalt: deployAccountPayload.addressSalt,
      });

      const { transaction_hash: deploymentHash } = await account.deployAccount(deployAccountPayload);

      console.log(`✅ Account deployment initiated. Hash: ${deploymentHash}`);

      // Wait for deployment to be confirmed
      await this.provider.waitForTransaction(deploymentHash);

      console.log(`🎉 Account deployment confirmed: ${accountAddress}`);

      return {
        success: true,
        accountAddress,
        deploymentHash,
        message: 'Account deployed successfully'
      };

    } catch (error) {
      console.error(`❌ Error deploying account ${accountAddress}:`, error);
      
      return {
        success: false,
        accountAddress,
        message: 'Account deployment failed',
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }

  /**
   * Check if account has sufficient STRK balance for deployment
   */
  public async checkDeploymentRequirements(accountAddress: string): Promise<{
    hasMinimumSTRK: boolean;
    currentBalance: string;
    minimumRequired: string;
    canDeploy: boolean;
  }> {
    try {
      const minimumRequired = '0.5'; // 0.5 STRK minimum
      
      // Get STRK balance
      const balanceService = (await import('./balanceService')).BalanceService.getInstance();
      const balances = await balanceService.getWalletBalances(accountAddress);
      
      const currentBalance = parseFloat(balances.strkBalance);
      const hasMinimumSTRK = currentBalance >= parseFloat(minimumRequired);
      
      return {
        hasMinimumSTRK,
        currentBalance: balances.strkBalance,
        minimumRequired,
        canDeploy: hasMinimumSTRK
      };
    } catch (error) {
      console.error(`❌ Error checking deployment requirements for ${accountAddress}:`, error);
      
      return {
        hasMinimumSTRK: false,
        currentBalance: '0',
        minimumRequired: '0.5',
        canDeploy: false
      };
    }
  }

  /**
   * Get estimated deployment cost
   */
  public async getDeploymentCost(): Promise<{
    estimatedCost: string;
    currency: string;
    description: string;
  }> {
    try {
      // Estimate deployment cost (this is approximate)
      const estimatedCost = '0.001'; // Approximately 0.001 ETH worth of STRK
      
      return {
        estimatedCost,
        currency: 'STRK',
        description: 'Estimated cost for account deployment on Starknet'
      };
    } catch (error) {
      console.error('❌ Error getting deployment cost:', error);
      
      return {
        estimatedCost: '0.001',
        currency: 'STRK',
        description: 'Estimated cost for account deployment on Starknet'
      };
    }
  }
}
