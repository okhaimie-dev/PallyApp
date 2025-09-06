import { OAuth2Client } from "google-auth-library";
import { GoogleUserData } from "./secureKeyService.js";

/**
 * Google OAuth Service
 * 
 * This service handles Google OAuth authentication and token verification
 * to securely extract user data for key derivation.
 */

export class GoogleAuthService {
  private static client: OAuth2Client;

  /**
   * Initialize the Google OAuth client
   */
  public static initialize(clientId: string): void {
    this.client = new OAuth2Client(clientId);
  }

  /**
   * Verifies a Google ID token and extracts user data
   * This is the secure way to get user information from Google
   */
  public static async verifyIdToken(idToken: string): Promise<GoogleUserData> {
    if (!this.client) {
      throw new Error("Google OAuth client not initialized. Call initialize() first.");
    }

    try {
      // Verify the ID token
      const ticket = await this.client.verifyIdToken({
        idToken,
        audience: process.env.GOOGLE_CLIENT_ID || "",
      });

      const payload = ticket.getPayload();
      
      if (!payload) {
        throw new Error("Invalid token payload");
      }

      // Extract and validate required user data
      const userData: GoogleUserData = {
        id: payload.sub,
        email: payload.email || "",
        name: payload.name || "",
        picture: payload.picture,
        verified_email: payload.email_verified || false,
      };

      // Validate required fields
      if (!userData.id || !userData.email || !userData.name) {
        throw new Error("Missing required user data in token");
      }

      if (!userData.verified_email) {
        throw new Error("Email not verified by Google");
      }

      return userData;
    } catch (error) {
      throw new Error(`Google token verification failed: ${error instanceof Error ? error.message : "Unknown error"}`);
    }
  }

  /**
   * Validates that the user data is complete and secure
   */
  public static validateUserData(userData: GoogleUserData): boolean {
    return !!(
      userData.id &&
      userData.email &&
      userData.name &&
      userData.verified_email &&
      userData.id.length > 0 &&
      userData.email.length > 0 &&
      userData.name.length > 0
    );
  }

  /**
   * Creates a secure hash of user data for logging/auditing (without sensitive info)
   */
  public static createUserHash(userData: GoogleUserData): string {
    const crypto = require("crypto");
    const hashInput = `${userData.id}|${userData.email}|${userData.verified_email}`;
    return crypto.createHash("sha256").update(hashInput).digest("hex").slice(0, 16);
  }
}
