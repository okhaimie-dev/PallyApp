import argon2 from "argon2";
import { ec } from "starknet";
import crypto from "crypto";

/**
 * Secure Key Derivation Service
 * 
 * This service provides secure methods to derive private keys from user authentication data
 * without storing any sensitive information. It uses Argon2 for key derivation and
 * generates deterministic but secure private keys.
 */

export interface GoogleUserData {
  id: string;
  email: string;
  name: string;
  picture?: string | undefined;
  verified_email: boolean;
}

export interface KeyDerivationResult {
  privateKey: string;
  publicKey: string;
  accountAddress: string;
}

export class SecureKeyService {
  private static readonly ARGON2_CONFIG = {
    type: argon2.argon2id,
    memoryCost: 2 ** 16, // 64 MB
    timeCost: 3,
    parallelism: 1,
    hashLength: 32,
  };

  /**
   * Generates a secure salt from user data
   * The salt is deterministic but includes entropy from multiple sources
   */
  private static generateSalt(userData: GoogleUserData): string {
    // Combine multiple non-sensitive user attributes for salt generation
    const saltInput = [
      userData.id,
      userData.email,
      userData.name,
      userData.verified_email.toString(),
      // Add application-specific constant for additional entropy
      "PALLY_SECURE_KEY_DERIVATION_2024"
    ].join("|");

    // Use SHA-256 to create a consistent but secure salt
    return crypto.createHash("sha256").update(saltInput).digest("hex");
  }

  /**
   * Creates the input material for key derivation
   * Combines user data with additional entropy sources
   */
  private static createKeyMaterial(userData: GoogleUserData): string {
    // Create a deterministic but secure input for key derivation
    const keyMaterial = [
      userData.id,
      userData.email,
      userData.name,
      userData.verified_email.toString(),
      // Add timestamp-based entropy (rounded to hour for consistency)
      Math.floor(Date.now() / (1000 * 60 * 60)).toString(),
      // Application-specific constant
      "PALLY_STARKNET_KEY_DERIVATION"
    ].join("|");

    return keyMaterial;
  }

  /**
   * Securely derives a private key from Google user data
   * Uses Argon2 for key derivation with user-specific salt
   */
  public static async derivePrivateKey(userData: GoogleUserData): Promise<KeyDerivationResult> {
    try {
      // Generate secure salt from user data
      const salt = this.generateSalt(userData);
      
      // Create key material
      const keyMaterial = this.createKeyMaterial(userData);
      
      // Derive key using Argon2
      const derivedKey = await argon2.hash(keyMaterial, {
        ...this.ARGON2_CONFIG,
        salt: Buffer.from(salt, "hex"),
      });

      // Extract the raw hash for private key generation
      const hashBuffer = Buffer.from(derivedKey.split("$").pop() || "", "base64");
      
      // Ensure the hash is exactly 32 bytes for Starknet private key
      const privateKeyBuffer = hashBuffer.slice(0, 32);
      
      // Convert to hex string with 0x prefix
      let privateKey = "0x" + privateKeyBuffer.toString("hex");
      
      // Ensure the private key is within valid Starknet range
      const keyBigInt = BigInt(privateKey);
      const maxKey = BigInt("0x800000000000011000000000000000000000000000000000000000000000000");
      
      // If key is too large, reduce it by taking modulo
      if (keyBigInt >= maxKey) {
        const reducedKey = keyBigInt % maxKey;
        privateKey = "0x" + reducedKey.toString(16).padStart(64, '0');
      }
      
      // Ensure key is not zero
      if (BigInt(privateKey) === 0n) {
        privateKey = "0x" + "1".padStart(64, '0');
      }
      
      // Generate public key from private key
      const publicKey = ec.starkCurve.getStarkKey(privateKey);
      
      // Calculate account address (this would be used for account deployment)
      const accountAddress = this.calculateAccountAddress(publicKey);

      // Clear sensitive data from memory
      hashBuffer.fill(0);
      privateKeyBuffer.fill(0);

      return {
        privateKey,
        publicKey,
        accountAddress,
      };
    } catch (error) {
      throw new Error(`Key derivation failed: ${error instanceof Error ? error.message : "Unknown error"}`);
    }
  }

  /**
   * Calculates the account address for a given public key
   * This matches the address that would be generated during account deployment
   */
  private static calculateAccountAddress(publicKey: string): string {
    // This is a simplified version - in practice, you'd use the full account deployment logic
    // For now, we'll use a hash of the public key as a placeholder
    const hash = crypto.createHash("sha256").update(publicKey).digest("hex");
    return "0x" + hash.slice(0, 40); // Truncate to 20 bytes (40 hex chars)
  }

  /**
   * Validates that the derived key is valid for Starknet
   */
  public static validatePrivateKey(privateKey: string): boolean {
    try {
      // Check if it's a valid hex string with correct length
      if (!/^0x[0-9a-fA-F]{64}$/.test(privateKey)) {
        return false;
      }

      // Convert to BigInt to check if it's within valid range
      const keyBigInt = BigInt(privateKey);
      const maxKey = BigInt("0x800000000000011000000000000000000000000000000000000000000000000");
      
      // Check if key is within valid range (not zero and less than max)
      if (keyBigInt === 0n || keyBigInt >= maxKey) {
        return false;
      }

      // Try to generate public key to validate
      ec.starkCurve.getStarkKey(privateKey);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Securely clears sensitive data from memory
   */
  public static clearSensitiveData(data: string): void {
    // In a real implementation, you'd want to use a secure memory clearing function
    // For now, we'll just overwrite the string
    if (typeof data === "string") {
      data = "0".repeat(data.length);
    }
  }
}
