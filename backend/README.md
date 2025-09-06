# Pally Backend

A Node.js TypeScript backend with Starknet integration for creating OpenZeppelin accounts and secure key reconstruction from Google OAuth.

## Features

- Create new OpenZeppelin accounts on Starknet
- **Secure private key reconstruction from Google OAuth data**
- **No storage of sensitive data** - keys are derived deterministically
- **Argon2-based key derivation** for maximum security
- Express.js API server with security middleware
- TypeScript support
- Environment-based configuration

## Setup

1. Install dependencies:
```bash
npm install
```

2. Copy the environment file and configure your variables:
```bash
cp .env.example .env
```

3. Update the `.env` file with your actual values:

### Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `NODE_URL` | Starknet RPC endpoint | `https://starknet-sepolia.public.blastapi.io` |
| `PORT` | Server port | `3000` |
| `SERVER_SECRET` | Secret key for wallet derivation | `your_super_secret_key_here` |

### Optional Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `NODE_ENV` | Environment mode | `development` or `production` |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID (for client-side auth) | `your_google_client_id_here` |
| `EMAIL_SERVICE` | Email service provider | `gmail` |
| `EMAIL_USER` | Email account username | `your-email@gmail.com` |
| `EMAIL_PASS` | Email account password/app password | `your-app-password` |
| `EMAIL_FROM` | From email address | `noreply@pally.app` |

### Security Notes
- **Never commit your `.env` file to version control**
- Use a strong, randomly generated `SERVER_SECRET` in production
- The `SERVER_SECRET` is used to derive wallet keys from user OpenIDs

### Email Setup (Optional)
To enable real email sending for OTP codes:

1. **For Gmail:**
   - Enable 2-factor authentication on your Gmail account
   - Generate an "App Password" in your Google Account settings
   - Use your Gmail address as `EMAIL_USER` and the app password as `EMAIL_PASS`

2. **For other providers:**
   - Update `EMAIL_SERVICE` to your provider (e.g., `outlook`, `yahoo`)
   - Configure appropriate credentials

3. **Test email connectivity:**
   ```bash
   curl http://localhost:3000/test-email
   ```

**Note:** If email is not configured, the system will fall back to console logging for development.

## Running the Server

### Development Mode
```bash
npm run dev
```

### Production Mode
```bash
npm run build
npm start
```

## API Endpoints

### Health Check
- **GET** `/` - Returns API status
- **GET** `/test-email` - Test email service connectivity

### OTP System
- **POST** `/generate-otp` - Generates OTP for wallet creation/access
  - Body: `{ "email": "user@example.com", "openId": "google_user_id" }`
  - Returns: `{ "success": true, "message": "OTP sent to email", "otpCode": "1234" }`

### Wallet Management
- **POST** `/wallet` - Creates/accesses wallet with OTP verification
  - Body: `{ "email": "user@example.com", "openId": "google_user_id", "otp": "1234" }`
  - Returns: `{ "success": true, "privateKey": "0x...", "publicKey": "0x...", "accountAddress": "0x..." }`


## Dependencies

- **starknet**: Starknet.js library for blockchain interactions
- **express**: Web framework for Node.js
- **cors**: Cross-Origin Resource Sharing middleware
- **dotenv**: Environment variable loader
- **argon2**: Secure key derivation function
- **google-auth-library**: Google OAuth token verification
- **express-rate-limit**: Rate limiting middleware
- **helmet**: Security headers middleware
- **typescript**: TypeScript compiler
- **ts-node**: TypeScript execution for Node.js
- **nodemon**: Development server with auto-restart

## Security Features

### 🔐 **Secure Key Reconstruction**
- **No Storage**: Private keys are never stored - they're derived deterministically from Google OAuth data
- **Argon2 KDF**: Uses industry-standard Argon2 for key derivation with high memory cost
- **User-Specific Salt**: Each user gets a unique salt derived from their Google profile data
- **Rate Limiting**: Key reconstruction endpoints are rate-limited to prevent abuse
- **Token Verification**: Google ID tokens are cryptographically verified before use

### 🛡️ **Additional Security**
- **Helmet**: Security headers for XSS, CSRF, and other attacks
- **Request Validation**: Validates content type and request size
- **Security Logging**: Logs all security-relevant events
- **Memory Safety**: Sensitive data is cleared from memory after use

## Security Notes

- Never commit your `.env` file to version control
- Use testnet for development and testing
- Consider using environment-specific configurations for different deployments
- The created accounts will need to be funded separately if you want to use them for transactions
- **Important**: The `/get-private-key` endpoint returns the private key - use with extreme caution in production
- Consider implementing client-side key derivation for maximum security
