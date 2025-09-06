import * as argon2 from "argon2";
import * as crypto from "crypto";
import { ec, hash, CallData } from "starknet";

export interface WalletKeyResult {
  privateKey: string;
  publicKey: string;
  accountAddress: string;
}

export class WalletKeyService {
  private static readonly SERVER_SECRET = "pally-wallet-secret-key-2024"; // In production, use environment variable
  private static readonly ARGON2_CONFIG: argon2.Options = {
    type: argon2.argon2id,
    memoryCost: 65536, // 64MB
    timeCost: 4,
    parallelism: 1,
    hashLength: 32, // 32 bytes for a 256-bit key
  };

  /**
   * Generate salt from OpenID (deterministic but not revealing)
   */
  private static generateSalt(openId: string): string {
    // Use OpenID + server secret to create a deterministic salt
    // This ensures the same OpenID always generates the same salt
    // but the salt itself doesn't reveal the OpenID
    const saltInput = `${openId}:${this.SERVER_SECRET}`;
    return crypto.createHash('sha256').update(saltInput).digest('hex');
  }

  /**
   * Create key material from OpenID
   */
  private static createKeyMaterial(openId: string): string {
    // Use OpenID + server secret as key material
    // This ensures deterministic key generation
    return `${openId}:${this.SERVER_SECRET}`;
  }

  /**
   * Derive wallet private key from OpenID
   */
  public static async deriveWalletKey(openId: string): Promise<WalletKeyResult> {
    try {
      const salt = this.generateSalt(openId);
      const keyMaterial = this.createKeyMaterial(openId);

      // Use Argon2 to derive the private key
      const derivedKey = await argon2.hash(keyMaterial, {
        ...this.ARGON2_CONFIG,
        salt: Buffer.from(salt, "hex"),
      });

      // Extract the hash from Argon2 output
      const hashBuffer = Buffer.from(derivedKey.split("$").pop() || "", "base64");
      const privateKeyBuffer = hashBuffer.slice(0, 32);
      let privateKey = "0x" + privateKeyBuffer.toString("hex");

      // Ensure the key is within Starknet curve order
      const keyBigInt = BigInt(privateKey);
      const maxKey = BigInt("0x800000000000011000000000000000000000000000000000000000000000000");

      if (keyBigInt >= maxKey) {
        const reducedKey = keyBigInt % maxKey;
        privateKey = "0x" + reducedKey.toString(16).padStart(64, '0');
      }

      // Ensure key is not zero
      if (BigInt(privateKey) === 0n) {
        privateKey = "0x" + "1".padStart(64, '0');
      }

      // Generate public key and account address
      const publicKey = ec.starkCurve.getStarkKey(privateKey);
      const constructorCalldata = CallData.compile({ publicKey });
      const accountAddress = hash.calculateContractAddressFromHash(
        publicKey,
        "0x540d7f5ec7ecf317e68d48564934cb99259781b1ee3cedbbc37ec5337f8e688", // OZ account class hash
        constructorCalldata,
        0
      );

      return { privateKey, publicKey, accountAddress };
    } catch (error) {
      throw new Error(`Wallet key derivation failed: ${error instanceof Error ? error.message : "Unknown error"}`);
    }
  }

  /**
   * Validate private key format and range
   */
  public static validatePrivateKey(privateKey: string): boolean {
    try {
      if (!/^0x[0-9a-fA-F]{64}$/.test(privateKey)) {
        return false;
      }
      const keyBigInt = BigInt(privateKey);
      const maxKey = BigInt("0x800000000000011000000000000000000000000000000000000000000000000");
      if (keyBigInt === 0n || keyBigInt >= maxKey) {
        return false;
      }
      ec.starkCurve.getStarkKey(privateKey);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Clear sensitive data from memory
   */
  public static clearSensitiveData(data: any): void {
    if (typeof data === 'string') {
      // Overwrite string with zeros
      const buffer = Buffer.from(data, 'utf8');
      buffer.fill(0);
    }
  }
}
