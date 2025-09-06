import * as crypto from "crypto";

export interface OTPData {
  code: string;
  email: string;
  openId: string;
  expiresAt: Date;
  attempts: number;
  maxAttempts: number;
}

export class OTPService {
  private static otpStore: Map<string, OTPData> = new Map();
  private static readonly OTP_LENGTH = 6;
  private static readonly OTP_EXPIRY_MINUTES = 10;
  private static readonly MAX_ATTEMPTS = 3;

  /**
   * Generate a 6-digit OTP code
   */
  private static generateOTPCode(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  /**
   * Generate OTP for email verification
   */
  public static generateOTP(email: string, openId: string): string {
    // Clean up expired OTPs
    this.cleanupExpiredOTPs();

    // Check if user already has an active OTP
    const existingOTP = this.otpStore.get(email);
    if (existingOTP && existingOTP.expiresAt > new Date()) {
      throw new Error("OTP already sent. Please wait before requesting a new one.");
    }

    const code = this.generateOTPCode();
    const expiresAt = new Date(Date.now() + this.OTP_EXPIRY_MINUTES * 60 * 1000);

    const otpData: OTPData = {
      code,
      email,
      openId,
      expiresAt,
      attempts: 0,
      maxAttempts: this.MAX_ATTEMPTS
    };

    this.otpStore.set(email, otpData);

    // In production, send email here
    console.log(`📧 OTP sent to ${email}: ${code}`);
    console.log(`⏰ Expires at: ${expiresAt.toISOString()}`);

    return code; // For testing purposes
  }

  /**
   * Verify OTP code
   */
  public static verifyOTP(email: string, code: string): { valid: boolean; openId?: string; error?: string } {
    const otpData = this.otpStore.get(email);

    if (!otpData) {
      return { valid: false, error: "No OTP found for this email" };
    }

    if (otpData.expiresAt < new Date()) {
      this.otpStore.delete(email);
      return { valid: false, error: "OTP has expired" };
    }

    if (otpData.attempts >= otpData.maxAttempts) {
      this.otpStore.delete(email);
      return { valid: false, error: "Maximum attempts exceeded" };
    }

    otpData.attempts++;

    if (otpData.code !== code) {
      if (otpData.attempts >= otpData.maxAttempts) {
        this.otpStore.delete(email);
        return { valid: false, error: "Maximum attempts exceeded" };
      }
      return { valid: false, error: `Invalid OTP. ${otpData.maxAttempts - otpData.attempts} attempts remaining` };
    }

    // OTP is valid, remove it from store
    this.otpStore.delete(email);

    return { valid: true, openId: otpData.openId };
  }

  /**
   * Clean up expired OTPs
   */
  private static cleanupExpiredOTPs(): void {
    const now = new Date();
    for (const [email, otpData] of this.otpStore.entries()) {
      if (otpData.expiresAt < now) {
        this.otpStore.delete(email);
      }
    }
  }

  /**
   * Get OTP status for testing
   */
  public static getOTPStatus(email: string): OTPData | null {
    return this.otpStore.get(email) || null;
  }

  /**
   * Clear all OTPs (for testing)
   */
  public static clearAllOTPs(): void {
    this.otpStore.clear();
  }
}
