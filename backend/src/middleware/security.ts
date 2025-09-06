import { Request, Response, NextFunction } from "express";
import rateLimit from "express-rate-limit";
import helmet from "helmet";

/**
 * Security Middleware
 * 
 * Provides additional security measures for the API endpoints
 */

// Rate limiting for key reconstruction endpoints
export const keyReconstructionLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // Limit each IP to 10 requests per windowMs
  message: {
    error: "Too many key reconstruction requests, please try again later.",
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// General API rate limiting
export const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: {
    error: "Too many requests, please try again later.",
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Security headers middleware
export const securityHeaders = helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true,
  },
});

// Request validation middleware
export const validateRequest = (req: Request, res: Response, next: NextFunction): void => {
  // Check for required headers
  if (!req.headers["content-type"] || !req.headers["content-type"].includes("application/json")) {
    res.status(400).json({ error: "Content-Type must be application/json" });
    return;
  }

  // Check request size (limit to 1MB)
  const contentLength = parseInt(req.headers["content-length"] || "0");
  if (contentLength > 1024 * 1024) {
    res.status(413).json({ error: "Request too large" });
    return;
  }

  next();
};

// Logging middleware for security events
export const securityLogger = (req: Request, res: Response, next: NextFunction) => {
  const start = Date.now();
  
  res.on("finish", () => {
    const duration = Date.now() - start;
    const logData = {
      method: req.method,
      url: req.url,
      status: res.statusCode,
      duration: `${duration}ms`,
      ip: req.ip,
      userAgent: req.get("User-Agent"),
      timestamp: new Date().toISOString(),
    };

    // Log security-relevant events
    if (res.statusCode >= 400) {
      console.warn("⚠️ Security Event:", logData);
    } else {
      console.log("📝 Request:", logData);
    }
  });

  next();
};
