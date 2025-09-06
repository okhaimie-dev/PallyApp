import Database from "better-sqlite3";
import * as crypto from "crypto";
import * as path from "path";

export interface WalletRecord {
  id: number;
  email: string;
  encryptedPrivateKey: string;
  publicKey: string;
  accountAddress: string;
  createdAt: string;
  updatedAt: string;
}

export class DatabaseService {
  private static instance: DatabaseService;
  private db: Database.Database;
  private encryptionKey: string;

  private constructor() {
    // Initialize database
    const dbPath = path.join(process.cwd(), "data", "wallets.db");
    
    // Ensure data directory exists
    const fs = require("fs");
    const dataDir = path.dirname(dbPath);
    if (!fs.existsSync(dataDir)) {
      fs.mkdirSync(dataDir, { recursive: true });
    }

    this.db = new Database(dbPath);
    this.initializeTables();

    // Get encryption key from environment
    this.encryptionKey = process.env.WALLET_ENCRYPTION_KEY || "default-encryption-key-change-in-production";
    
    if (this.encryptionKey === "default-encryption-key-change-in-production") {
      console.warn("⚠️  WARNING: Using default encryption key. Set WALLET_ENCRYPTION_KEY in .env for production!");
    }
  }

  public static getInstance(): DatabaseService {
    if (!DatabaseService.instance) {
      DatabaseService.instance = new DatabaseService();
    }
    return DatabaseService.instance;
  }

  private initializeTables(): void {
    const createWalletsTable = `
      CREATE TABLE IF NOT EXISTS wallets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        encrypted_private_key TEXT NOT NULL,
        public_key TEXT NOT NULL,
        account_address TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `;

    this.db.exec(createWalletsTable);
    console.log("✅ Database tables initialized");
  }

  /**
   * Encrypt private key using AES-256-GCM
   */
  private encryptPrivateKey(privateKey: string): string {
    const iv = crypto.randomBytes(16);
    const key = crypto.createHash('sha256').update(this.encryptionKey).digest();
    const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
    
    let encrypted = cipher.update(privateKey, "utf8", "hex");
    encrypted += cipher.final("hex");
    
    const authTag = cipher.getAuthTag();
    
    // Combine IV, auth tag, and encrypted data
    return iv.toString("hex") + ":" + authTag.toString("hex") + ":" + encrypted;
  }

  /**
   * Decrypt private key using AES-256-GCM
   */
  private decryptPrivateKey(encryptedData: string): string {
    const parts = encryptedData.split(":");
    if (parts.length !== 3) {
      throw new Error("Invalid encrypted data format");
    }

    const iv = Buffer.from(parts[0]!, "hex");
    const authTag = Buffer.from(parts[1]!, "hex");
    const encrypted = parts[2]!;

    const key = crypto.createHash('sha256').update(this.encryptionKey).digest();
    const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
    decipher.setAuthTag(authTag);

    let decrypted = decipher.update(encrypted, "hex", "utf8");
    decrypted += decipher.final("utf8");

    return decrypted;
  }

  /**
   * Save wallet to database
   */
  public saveWallet(email: string, privateKey: string, publicKey: string, accountAddress: string): WalletRecord {
    const encryptedPrivateKey = this.encryptPrivateKey(privateKey);
    
    const stmt = this.db.prepare(`
      INSERT OR REPLACE INTO wallets (email, encrypted_private_key, public_key, account_address, updated_at)
      VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
    `);

    const result = stmt.run(email, encryptedPrivateKey, publicKey, accountAddress);
    
    return {
      id: result.lastInsertRowid as number,
      email,
      encryptedPrivateKey,
      publicKey,
      accountAddress,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
  }

  /**
   * Get wallet by email
   */
  public getWalletByEmail(email: string): WalletRecord | null {
    const stmt = this.db.prepare("SELECT * FROM wallets WHERE email = ?");
    const row = stmt.get(email) as any;
    
    if (!row) {
      return null;
    }

    return {
      id: row.id,
      email: row.email,
      encryptedPrivateKey: row.encrypted_private_key,
      publicKey: row.public_key,
      accountAddress: row.account_address,
      createdAt: row.created_at,
      updatedAt: row.updated_at
    };
  }

  /**
   * Get wallet with decrypted private key
   */
  public getWalletWithPrivateKey(email: string): { wallet: WalletRecord; privateKey: string } | null {
    const wallet = this.getWalletByEmail(email);
    if (!wallet) {
      return null;
    }

    try {
      const privateKey = this.decryptPrivateKey(wallet.encryptedPrivateKey);
      return { wallet, privateKey };
    } catch (error) {
      console.error("Failed to decrypt private key:", error);
      return null;
    }
  }

  /**
   * Check if wallet exists for email
   */
  public walletExists(email: string): boolean {
    const stmt = this.db.prepare("SELECT 1 FROM wallets WHERE email = ?");
    const result = stmt.get(email);
    return !!result;
  }

  /**
   * Get all wallets (for admin purposes)
   */
  public getAllWallets(): WalletRecord[] {
    const stmt = this.db.prepare("SELECT * FROM wallets ORDER BY created_at DESC");
    const rows = stmt.all() as any[];
    
    return rows.map(row => ({
      id: row.id,
      email: row.email,
      encryptedPrivateKey: row.encrypted_private_key,
      publicKey: row.public_key,
      accountAddress: row.account_address,
      createdAt: row.created_at,
      updatedAt: row.updated_at
    }));
  }

  /**
   * Delete wallet by email
   */
  public deleteWallet(email: string): boolean {
    const stmt = this.db.prepare("DELETE FROM wallets WHERE email = ?");
    const result = stmt.run(email);
    return result.changes > 0;
  }

  /**
   * Close database connection
   */
  public close(): void {
    this.db.close();
  }
}
