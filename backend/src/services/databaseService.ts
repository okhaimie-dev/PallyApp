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

export interface GroupRecord {
  id: number;
  name: string;
  description?: string;
  category: string;
  icon?: string;
  color?: string;
  isPrivate: boolean;
  createdBy: string;
  createdAt: string;
  updatedAt: string;
}

export interface GroupMemberRecord {
  id: number;
  groupId: number;
  userEmail: string;
  role: string;
  joinedAt: string;
}

export interface MessageRecord {
  id: number;
  groupId: number;
  senderEmail: string;
  content: string;
  messageType: string;
  createdAt: string;
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

    const createGroupsTable = `
      CREATE TABLE IF NOT EXISTS groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        icon TEXT,
        color TEXT,
        is_private BOOLEAN DEFAULT 0,
        created_by TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `;

    const createGroupMembersTable = `
      CREATE TABLE IF NOT EXISTS group_members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        user_email TEXT NOT NULL,
        role TEXT DEFAULT 'member',
        joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE,
        UNIQUE(group_id, user_email)
      )
    `;

    const createMessagesTable = `
      CREATE TABLE IF NOT EXISTS messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        sender_email TEXT NOT NULL,
        content TEXT NOT NULL,
        message_type TEXT DEFAULT 'text',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE
      )
    `;

    this.db.exec(createWalletsTable);
    this.db.exec(createGroupsTable);
    this.db.exec(createGroupMembersTable);
    this.db.exec(createMessagesTable);
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

  // ========== GROUP MANAGEMENT METHODS ==========

  /**
   * Create a new group
   */
  public createGroup(
    name: string,
    description: string,
    category: string,
    icon: string,
    color: string,
    isPrivate: boolean,
    createdBy: string
  ): GroupRecord {
    const stmt = this.db.prepare(`
      INSERT INTO groups (name, description, category, icon, color, is_private, created_by)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `);

    const result = stmt.run(name, description, category, icon, color, isPrivate ? 1 : 0, createdBy);
    
    // Add creator as admin member
    this.addGroupMember(result.lastInsertRowid as number, createdBy, 'admin');

    return {
      id: result.lastInsertRowid as number,
      name,
      description,
      category,
      icon,
      color,
      isPrivate,
      createdBy,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
  }

  /**
   * Get group by ID
   */
  public getGroupById(groupId: number): GroupRecord | null {
    const stmt = this.db.prepare("SELECT * FROM groups WHERE id = ?");
    const row = stmt.get(groupId) as any;
    
    if (!row) return null;

    return {
      id: row.id,
      name: row.name,
      description: row.description,
      category: row.category,
      icon: row.icon,
      color: row.color,
      isPrivate: Boolean(row.is_private),
      createdBy: row.created_by,
      createdAt: row.created_at,
      updatedAt: row.updated_at
    };
  }

  /**
   * Get groups by user email
   */
  public getGroupsByUser(userEmail: string): GroupRecord[] {
    const stmt = this.db.prepare(`
      SELECT g.* FROM groups g
      INNER JOIN group_members gm ON g.id = gm.group_id
      WHERE gm.user_email = ?
      ORDER BY g.updated_at DESC
    `);
    
    const rows = stmt.all(userEmail) as any[];
    
    return rows.map(row => ({
      id: row.id,
      name: row.name,
      description: row.description,
      category: row.category,
      icon: row.icon,
      color: row.color,
      isPrivate: Boolean(row.is_private),
      createdBy: row.created_by,
      createdAt: row.created_at,
      updatedAt: row.updated_at
    }));
  }

  /**
   * Get public groups by category
   */
  public getPublicGroupsByCategory(category: string): GroupRecord[] {
    const stmt = this.db.prepare(`
      SELECT * FROM groups 
      WHERE category = ? AND is_private = 0
      ORDER BY created_at DESC
    `);
    
    const rows = stmt.all(category) as any[];
    
    return rows.map(row => ({
      id: row.id,
      name: row.name,
      description: row.description,
      category: row.category,
      icon: row.icon,
      color: row.color,
      isPrivate: Boolean(row.is_private),
      createdBy: row.created_by,
      createdAt: row.created_at,
      updatedAt: row.updated_at
    }));
  }

  /**
   * Add member to group
   */
  public addGroupMember(groupId: number, userEmail: string, role: string = 'member'): GroupMemberRecord {
    const stmt = this.db.prepare(`
      INSERT OR REPLACE INTO group_members (group_id, user_email, role)
      VALUES (?, ?, ?)
    `);

    const result = stmt.run(groupId, userEmail, role);
    
    return {
      id: result.lastInsertRowid as number,
      groupId,
      userEmail,
      role,
      joinedAt: new Date().toISOString()
    };
  }

  /**
   * Remove member from group
   */
  public removeGroupMember(groupId: number, userEmail: string): boolean {
    const stmt = this.db.prepare("DELETE FROM group_members WHERE group_id = ? AND user_email = ?");
    const result = stmt.run(groupId, userEmail);
    return result.changes > 0;
  }

  /**
   * Get group members
   */
  public getGroupMembers(groupId: number): GroupMemberRecord[] {
    const stmt = this.db.prepare("SELECT * FROM group_members WHERE group_id = ? ORDER BY joined_at ASC");
    const rows = stmt.all(groupId) as any[];
    
    return rows.map(row => ({
      id: row.id,
      groupId: row.group_id,
      userEmail: row.user_email,
      role: row.role,
      joinedAt: row.joined_at
    }));
  }

  /**
   * Check if user is member of group
   */
  public isGroupMember(groupId: number, userEmail: string): boolean {
    const stmt = this.db.prepare("SELECT 1 FROM group_members WHERE group_id = ? AND user_email = ?");
    const result = stmt.get(groupId, userEmail);
    return !!result;
  }

  // ========== MESSAGE MANAGEMENT METHODS ==========

  /**
   * Add message to group
   */
  public addMessage(groupId: number, senderEmail: string, content: string, messageType: string = 'text'): MessageRecord {
    const stmt = this.db.prepare(`
      INSERT INTO messages (group_id, sender_email, content, message_type)
      VALUES (?, ?, ?, ?)
    `);

    const result = stmt.run(groupId, senderEmail, content, messageType);
    
    // Update group's updated_at timestamp
    const updateStmt = this.db.prepare("UPDATE groups SET updated_at = CURRENT_TIMESTAMP WHERE id = ?");
    updateStmt.run(groupId);
    
    return {
      id: result.lastInsertRowid as number,
      groupId,
      senderEmail,
      content,
      messageType,
      createdAt: new Date().toISOString()
    };
  }

  /**
   * Get messages for group
   */
  public getGroupMessages(groupId: number, limit: number = 50, offset: number = 0): MessageRecord[] {
    const stmt = this.db.prepare(`
      SELECT * FROM messages 
      WHERE group_id = ? 
      ORDER BY created_at DESC 
      LIMIT ? OFFSET ?
    `);
    
    const rows = stmt.all(groupId, limit, offset) as any[];
    
    return rows.map(row => ({
      id: row.id,
      groupId: row.group_id,
      senderEmail: row.sender_email,
      content: row.content,
      messageType: row.message_type,
      createdAt: row.created_at
    })).reverse(); // Reverse to show oldest first
  }

  /**
   * Get recent messages for group
   */
  public getRecentGroupMessages(groupId: number, limit: number = 20): MessageRecord[] {
    return this.getGroupMessages(groupId, limit, 0);
  }

  /**
   * Close database connection
   */
  public close(): void {
    this.db.close();
  }
}
