import { RpcProvider, Contract, CallData } from 'starknet';

export interface TokenBalance {
  token: string;
  balance: string;
  decimals: number;
  symbol: string;
}

export interface WalletBalances {
  usdcBalance: string;
  strkBalance: string;
  totalBalanceUSD: string;
  walletAddress: string;
}

export class BalanceService {
  private static instance: BalanceService;
  private provider: RpcProvider;

  // Token contract addresses on Starknet mainnet
  private static readonly TOKEN_ADDRESSES = {
    USDC: '0x053c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06b3ad0a6e6', // USDC on Starknet
    STRK: '0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d', // STRK token
  };

  // Token decimals
  private static readonly TOKEN_DECIMALS = {
    USDC: 6,
    STRK: 18,
  };

  // Cache for exchange rates to avoid too many API calls
  private static exchangeRatesCache: { [key: string]: { rate: number; timestamp: number } } = {};
  private static readonly CACHE_DURATION = 300000; // 5 minute cache

  private constructor() {
    // Use RPC URL from environment variables
    const nodeUrl = process.env.NODE_URL || 'https://starknet-mainnet.public.blastapi.io';
    
    this.provider = new RpcProvider({
      nodeUrl: nodeUrl,
    });
    
    console.log(`🔗 BalanceService using RPC: ${nodeUrl}`);
  }

  public static getInstance(): BalanceService {
    if (!BalanceService.instance) {
      BalanceService.instance = new BalanceService();
    }
    return BalanceService.instance;
  }

  /**
   * Get token balance for a specific token
   */
  public async getTokenBalance(walletAddress: string, tokenAddress: string, decimals: number): Promise<string> {
    try {
      // ERC20 balanceOf function selector
      const balanceOfSelector = '0x2e4263af';
      
      const callData = CallData.compile([walletAddress]);
      
      const result = await this.provider.callContract({
        contractAddress: tokenAddress,
        entrypoint: 'balanceOf',
        calldata: callData,
      });

      if (result && result.length > 0 && result[0]) {
        const balance = BigInt(result[0]);
        // Convert from wei to token units
        const divisor = BigInt(10 ** decimals);
        const tokenBalance = balance / divisor;
        const remainder = balance % divisor;
        
        // Format with proper decimal places
        const formattedBalance = tokenBalance.toString() + '.' + remainder.toString().padStart(decimals, '0');
        // Format to 2 decimal places for display
        const balanceNumber = parseFloat(formattedBalance);
        return balanceNumber.toFixed(2);
      }

      return '0';
    } catch (error) {
      console.error(`Error fetching token balance for ${tokenAddress}:`, error);
      return '0';
    }
  }

  /**
   * Get all token balances for a wallet
   */
  public async getWalletBalances(walletAddress: string): Promise<WalletBalances> {
    try {
      console.log(`🔍 Fetching real blockchain balances for wallet: ${walletAddress}`);
      
      // Fetch real blockchain balances and exchange rates
      const [usdcBalance, strkBalance, exchangeRates] = await Promise.all([
        this.getTokenBalance(
          walletAddress, 
          BalanceService.TOKEN_ADDRESSES.USDC, 
          BalanceService.TOKEN_DECIMALS.USDC
        ),
        this.getTokenBalance(
          walletAddress, 
          BalanceService.TOKEN_ADDRESSES.STRK, 
          BalanceService.TOKEN_DECIMALS.STRK
        ),
        this.fetchExchangeRates()
      ]);

      console.log(`💰 Blockchain balances - USDC: ${usdcBalance}, STRK: ${strkBalance}`);

      // Calculate total balance in USD using real exchange rates
      const usdcValue = parseFloat(usdcBalance) * exchangeRates.USDC;
      const strkValue = parseFloat(strkBalance) * exchangeRates.STRK;
      const totalBalanceUSD = (usdcValue + strkValue).toFixed(2);

      console.log(`💵 Total balance in USD: $${totalBalanceUSD}`);

      return {
        usdcBalance,
        strkBalance,
        totalBalanceUSD,
        walletAddress,
      };
    } catch (error) {
      console.error('❌ Error fetching wallet balances from blockchain:', error);
      // Return zero balances instead of mock data
      return {
        usdcBalance: '0',
        strkBalance: '0',
        totalBalanceUSD: '0.00',
        walletAddress,
      };
    }
  }


  /**
   * Fetch real-time exchange rates from multiple sources
   */
  private async fetchExchangeRates(): Promise<{ USDC: number; STRK: number }> {
    try {
      // Check cache first
      const now = Date.now();
      const cachedUSDC = BalanceService.exchangeRatesCache['USDC'];
      const cachedSTRK = BalanceService.exchangeRatesCache['STRK'];
      
      if (cachedUSDC && cachedSTRK && 
          (now - cachedUSDC.timestamp) < BalanceService.CACHE_DURATION &&
          (now - cachedSTRK.timestamp) < BalanceService.CACHE_DURATION) {
        return {
          USDC: cachedUSDC.rate,
          STRK: cachedSTRK.rate
        };
      }

      // Try multiple sources for STRK price
      let strkPrice = await this.fetchSTRKPrice();
      
      // USDC is always 1:1 with USD
      const usdcPrice = 1.0;

      // Cache the rates
      BalanceService.exchangeRatesCache['USDC'] = { rate: usdcPrice, timestamp: now };
      BalanceService.exchangeRatesCache['STRK'] = { rate: strkPrice, timestamp: now };

      console.log(`📊 Fetched exchange rates: USDC=${usdcPrice}, STRK=${strkPrice}`);

      return {
        USDC: usdcPrice,
        STRK: strkPrice
      };
    } catch (error) {
      console.error('❌ Error fetching exchange rates:', error);
      
      // Fallback to cached rates or default values
      const cachedUSDC = BalanceService.exchangeRatesCache['USDC'];
      const cachedSTRK = BalanceService.exchangeRatesCache['STRK'];
      
      return {
        USDC: cachedUSDC?.rate || 1.0,
        STRK: cachedSTRK?.rate || 0.124 // Updated fallback rate based on current STRK price
      };
    }
  }

  /**
   * Fetch STRK price from multiple sources
   */
  private async fetchSTRKPrice(): Promise<number> {
    const sources = [
      // Try CoinGecko first (most reliable)
      async () => {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 10000); // Increased to 10 seconds
        
        try {
          const response = await fetch('https://api.coingecko.com/api/v3/simple/price?ids=starknet&vs_currencies=usd', {
            signal: controller.signal,
            headers: {
              'User-Agent': 'Mozilla/5.0 (compatible; PallyApp/1.0)'
            }
          });
          clearTimeout(timeoutId);
          if (!response.ok) throw new Error(`CoinGecko API error: ${response.status}`);
          const data = await response.json();
          return data.starknet.usd;
        } catch (error) {
          clearTimeout(timeoutId);
          throw error;
        }
      },
      // Try Binance as fallback
      async () => {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 10000); // Increased to 10 seconds
        
        try {
          const response = await fetch('https://api.binance.com/api/v3/ticker/price?symbol=STRKUSDC', {
            signal: controller.signal,
            headers: {
              'User-Agent': 'Mozilla/5.0 (compatible; PallyApp/1.0)'
            }
          });
          clearTimeout(timeoutId);
          if (!response.ok) throw new Error(`Binance API error: ${response.status}`);
          const data = await response.json();
          return parseFloat(data.price);
        } catch (error) {
          clearTimeout(timeoutId);
          throw error;
        }
      }
    ];

    // Try each source until one works
    for (const source of sources) {
      try {
        const price = await source();
        console.log(`✅ Successfully fetched STRK price: $${price}`);
        return price;
      } catch (error) {
        console.warn(`⚠️ Failed to fetch STRK price from source:`, error);
        continue;
      }
    }

    // If all sources fail, return a reasonable fallback
    console.warn('⚠️ All price sources failed, using fallback rate');
    return 0.124; // Updated fallback rate based on current STRK price
  }

  /**
   * Get exchange rates (fetches from Binance API with caching)
   */
  public async getExchangeRates(): Promise<{ USDC: number; STRK: number }> {
    return await this.fetchExchangeRates();
  }
}
