# Pally - Social Group Chat App with Starknet Integration

## 🚀 Overview

Pally is a comprehensive social group chat application that combines modern messaging features with blockchain integration. Built with Flutter for the frontend and Node.js/TypeScript for the backend, it provides users with the ability to create groups, chat in real-time, and send cryptocurrency tips using the Starknet blockchain.

## 🏗️ Architecture

### Frontend (Flutter)
- **Framework**: Flutter 3.10.0+ with Dart
- **State Management**: StatefulWidget with local state management
- **UI Theme**: Dark theme with custom color scheme
- **Navigation**: MaterialApp with custom routing
- **Real-time Communication**: WebSocket integration for live chat

### Backend (Node.js/TypeScript)
- **Runtime**: Node.js with TypeScript
- **Framework**: Express.js with Socket.IO for WebSocket support
- **Database**: SQLite with better-sqlite3 for data persistence
- **Blockchain Integration**: Starknet.js for blockchain interactions
- **Security**: Helmet, CORS, rate limiting, and encryption

## 📱 Features

### Core Features
- **User Authentication**: Google Sign-In integration
- **Group Management**: Create, join, and manage public/private groups
- **Real-time Chat**: WebSocket-based messaging with typing indicators
- **Categories**: Organized group categories (Tech, Gaming, Sports, etc.)
- **User Profiles**: Customizable user profiles with avatars

### Blockchain Features
- **Wallet Integration**: Automatic Starknet wallet creation and management
- **Token Support**: USDC and STRK token support
- **Tip System**: Send cryptocurrency tips to other users
- **Account Deployment**: Deploy Starknet accounts for full functionality
- **Balance Tracking**: Real-time balance monitoring with USD conversion
- **Transaction History**: Complete transaction and tip history

### Advanced Features
- **Push Notifications**: Local notifications for new messages and tips
- **Deep Linking**: Direct links to specific groups
- **Offline Support**: Local data persistence with SharedPreferences
- **Security**: Encrypted private key storage
- **Real-time Updates**: Live balance and transaction updates

## 🛠️ Technology Stack

### Frontend Dependencies
```yaml
dependencies:
  flutter: sdk
  cupertino_icons: ^1.0.8
  google_sign_in: ^7.1.1          # Google authentication
  http: ^1.2.0                    # HTTP requests
  shared_preferences: ^2.2.2      # Local storage
  socket_io_client: ^2.0.3+1      # WebSocket communication
  flutter_local_notifications: ^17.2.2  # Push notifications
  permission_handler: ^11.3.1     # Permission management
  share_plus: ^10.0.2             # Content sharing
  app_links: ^6.3.2               # Deep linking
```

### Backend Dependencies
```json
{
  "dependencies": {
    "express": "^5.1.0",           # Web framework
    "socket.io": "^4.8.1",         # WebSocket server
    "starknet": "^7.6.4",          # Starknet blockchain integration
    "better-sqlite3": "^11.6.0",   # SQLite database
    "argon2": "^0.44.0",           # Password hashing
    "cors": "^2.8.5",              # CORS middleware
    "helmet": "^8.1.0",            # Security headers
    "express-rate-limit": "^8.1.0", # Rate limiting
    "google-auth-library": "^10.3.0", # Google authentication
    "nodemailer": "^7.0.6",        # Email service
    "dotenv": "^17.2.2"            # Environment variables
  }
}
```

## 🗂️ Project Structure

```
pally/
├── lib/                          # Flutter source code
│   ├── main.dart                 # App entry point
│   ├── models/                   # Data models
│   │   ├── user.dart            # User model
│   │   └── group.dart           # Group and message models
│   ├── screens/                  # UI screens
│   │   ├── signin_page.dart     # Authentication screen
│   │   ├── home_page.dart       # Main dashboard
│   │   ├── chat_page.dart       # Group chat interface
│   │   ├── deposit_screen.dart  # Deposit interface
│   │   ├── withdraw_screen.dart # Withdrawal interface
│   │   └── ...                  # Other screens
│   └── services/                 # Business logic
│       ├── wallet_service.dart  # Wallet management
│       ├── group_service.dart   # Group operations
│       ├── websocket_service.dart # Real-time communication
│       ├── notification_service.dart # Push notifications
│       └── deeplink_service.dart # Deep linking
├── backend/                      # Backend source code
│   ├── src/
│   │   ├── index.ts             # Server entry point
│   │   ├── services/            # Business logic services
│   │   │   ├── walletManagementService.ts
│   │   │   ├── tokenTransferService.ts
│   │   │   ├── groupService.ts
│   │   │   ├── websocketService.ts
│   │   │   ├── balanceService.ts
│   │   │   └── databaseService.ts
│   │   ├── middleware/          # Express middleware
│   │   └── abis/               # Smart contract ABIs
│   └── data/                    # SQLite database files
└── assets/                      # Static assets
    └── images/                  # App icons and images
```

## 🔧 Setup and Installation

### Prerequisites
- Flutter SDK 3.10.0+
- Node.js 18+
- npm or yarn
- Android Studio / Xcode (for mobile development)

### Development vs Production Configuration

The app automatically detects the environment:
- **Development (Default)**: Uses `192.168.0.106:3000` for backend and `ws://192.168.0.106:3000` for WebSocket
- **Production**: Uses `https://pallyapp.onrender.com` for backend and `wss://pallyapp.onrender.com` for WebSocket

To run in production mode, use:
```bash
flutter run --dart-define=PRODUCTION=true
```

### Backend Setup

1. **Navigate to backend directory**:
   ```bash
   cd backend
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Environment Configuration**:
   Create a `.env` file in the backend directory:
   ```env
   NODE_URL=https://starknet-mainnet.public.blastapi.io
   PORT=3000
   WALLET_ENCRYPTION_KEY=your-secure-encryption-key
   EMAIL_USER=your-email@gmail.com
   EMAIL_PASS=your-app-password
   ```

4. **Start the development server**:
   ```bash
   npm run dev
   ```
   
   The server will start on `http://192.168.0.106:3000` and automatically restart on file changes.

### Frontend Setup

1. **Navigate to project root**:
   ```bash
   cd /path/to/pally
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Google Sign-In**:
   - Add your Google OAuth credentials to `android/app/google-services.json`
   - Configure iOS settings in `ios/Runner/Info.plist`

4. **Run the app in development mode** (default):
   ```bash
   flutter run
   ```
   
   The app will automatically connect to `192.168.0.106:3000` for development.

5. **Run the app in production mode**:
   ```bash
   flutter run --dart-define=PRODUCTION=true
   ```

### Development Workflow

1. **Start the backend server**:
   ```bash
   cd backend
   npm run dev
   ```

2. **Start the Flutter app**:
   ```bash
   flutter run
   ```

3. **Make changes**: The backend will auto-reload, and Flutter supports hot reload for UI changes.

4. **Test WebSocket connection**: The app will automatically connect to the local WebSocket server for real-time features.

### Configuration Details

The app uses environment-based configuration in `lib/config/app_config.dart`:

```dart
// Development (default)
static const String _developmentBaseUrl = 'http://192.168.0.106:3000';
static const String _developmentWsUrl = 'ws://192.168.0.106:3000';

// Production
static const String _productionBaseUrl = 'https://pallyapp.onrender.com';
static const String _productionWsUrl = 'wss://pallyapp.onrender.com';
```

All services automatically use the appropriate URLs based on the environment.

## 🔐 Security Features

### Data Encryption
- **Private Key Encryption**: AES-256-GCM encryption for wallet private keys
- **Environment Variables**: Secure configuration management
- **Rate Limiting**: API rate limiting to prevent abuse
- **CORS Protection**: Cross-origin request security
- **Security Headers**: Helmet.js for security headers

### Authentication
- **Google OAuth**: Secure Google Sign-In integration
- **OTP Verification**: Email-based OTP for wallet operations
- **Session Management**: Secure session handling
- **Input Validation**: Comprehensive input sanitization

## 🌐 API Endpoints

### Authentication & Wallet
- `POST /generate-otp` - Generate OTP for wallet operations
- `POST /wallet` - Create or retrieve wallet with OTP verification
- `GET /wallet/:email` - Get wallet information (without private key)
- `GET /wallet/:email/balances` - Get wallet balances
- `GET /wallet/:email/tips` - Get tip transaction history

### Account Deployment
- `GET /wallet/:email/deployment-status` - Check account deployment status
- `POST /wallet/:email/deploy` - Deploy account to Starknet
- `GET /wallet/deployment-cost` - Get deployment cost estimate

### Token Operations
- `POST /send-tip` - Send cryptocurrency tip to another user
- `POST /transfer-tokens` - Transfer tokens to any address

### Group Management
- `POST /groups` - Create new group
- `GET /groups/user/:userEmail` - Get user's groups
- `GET /groups/public/:category` - Get public groups by category
- `GET /groups/:groupId` - Get group details
- `POST /groups/:groupId/join` - Join group
- `POST /groups/:groupId/leave` - Leave group
- `GET /groups/:groupId/members` - Get group members

### Messaging
- `POST /groups/:groupId/messages` - Send message to group
- `GET /groups/:groupId/messages` - Get group messages

## 🔌 WebSocket Events

### Client to Server
- `authenticate` - Authenticate user session
- `join_group` - Join group chat room
- `leave_group` - Leave group chat room
- `send_message` - Send message to group
- `typing_start/stop` - Typing indicators

### Server to Client
- `authenticated` - Authentication confirmation
- `joined_group` - Group join confirmation
- `new_message` - New message broadcast
- `user_joined/left` - User presence updates
- `user_typing` - Typing indicators
- `tip_notification` - Tip received notification

## 💰 Blockchain Integration

### Supported Tokens
- **USDC**: USD Coin on Starknet (6 decimals)
- **STRK**: Starknet native token (18 decimals)

### Smart Contract Addresses
- **USDC**: `0x053c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06b3ad0a6e6`
- **STRK**: `0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d`

### Wallet Features
- **Deterministic Key Generation**: Secure wallet creation from Google OpenID
- **Account Deployment**: Deploy Starknet accounts for full functionality
- **Balance Monitoring**: Real-time balance tracking with USD conversion
- **Transaction History**: Complete transaction and tip history
- **Gas Management**: Automatic gas fee handling

## 🗄️ Database Schema

### Tables
- **wallets**: User wallet information with encrypted private keys
- **groups**: Group information and metadata
- **group_members**: Group membership relationships
- **messages**: Chat messages with timestamps
- **tip_transactions**: Cryptocurrency tip records

### Key Relationships
- Users can belong to multiple groups
- Groups can have multiple members
- Messages belong to specific groups
- Tips link sender and receiver users

## 🚀 Deployment

### Backend Deployment (Render)
The backend is deployed on Render with the following configuration:
- **URL**: `https://pallyapp.onrender.com`
- **Environment**: Production with environment variables
- **Database**: Persistent SQLite storage
- **Auto-deploy**: Connected to Git repository

### Mobile App Deployment
- **Android**: Build APK/AAB for Google Play Store
- **iOS**: Build for App Store distribution
- **Configuration**: Update API endpoints for production

## 🔄 Development Workflow

### Code Organization
- **Services**: Business logic separated into service classes
- **Models**: Type-safe data models with JSON serialization
- **Middleware**: Reusable Express middleware for security
- **Error Handling**: Comprehensive error handling and logging

### Testing
- **Backend**: Jest testing framework with coverage
- **Frontend**: Flutter widget and integration tests
- **API Testing**: Comprehensive endpoint testing

## 📊 Monitoring and Analytics

### Logging
- **Structured Logging**: Comprehensive logging with emojis for easy reading
- **Error Tracking**: Detailed error logging with stack traces
- **Performance Monitoring**: Request timing and performance metrics

### Metrics
- **User Activity**: Group creation, message sending, tip transactions
- **System Health**: Database connections, WebSocket connections
- **Blockchain Integration**: Transaction success rates, balance updates

## 🔮 Future Enhancements

### Planned Features
- **Multi-language Support**: Internationalization
- **Voice Messages**: Audio message support
- **File Sharing**: Image and document sharing
- **Group Moderation**: Admin tools and moderation features
- **Advanced Notifications**: Push notification customization
- **Analytics Dashboard**: User and system analytics

### Blockchain Enhancements
- **NFT Support**: NFT trading and display
- **DeFi Integration**: Staking and yield farming
- **Cross-chain Support**: Multi-blockchain compatibility
- **Smart Contract Interactions**: Custom contract interactions

## 🤝 Contributing

### Development Guidelines
1. Follow TypeScript/Flutter best practices
2. Write comprehensive tests for new features
3. Update documentation for API changes
4. Use conventional commit messages
5. Ensure security best practices

### Code Style
- **TypeScript**: Strict mode enabled with comprehensive typing
- **Flutter**: Follow Material Design guidelines
- **Database**: Use prepared statements for security
- **API**: RESTful design with consistent error handling

## 📄 License

This project is proprietary software. All rights reserved.

## 🆘 Support

For technical support or questions:
- **Documentation**: This README and inline code comments
- **Issues**: Create GitHub issues for bugs or feature requests
- **Contact**: Reach out to the development team

---

**Pally** - Connecting people through chat and cryptocurrency. Built with ❤️ using Flutter and Starknet.