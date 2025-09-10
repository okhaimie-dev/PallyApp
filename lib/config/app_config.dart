class AppConfig {
  // Environment detection
  static const bool _isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
  
  // Base URLs
  static const String _productionBaseUrl = 'https://pallyapp.onrender.com';
  static const String _developmentBaseUrl = 'http://192.168.0.106:3000';
  
  // WebSocket URLs  
  static const String _productionWsUrl = 'wss://pallyapp.onrender.com';
  static const String _developmentWsUrl = 'ws://192.168.0.106:3000';
  
  // Get the appropriate URLs based on environment
  static String get baseUrl => _isProduction ? _productionBaseUrl : _developmentBaseUrl;
  static String get wsUrl => _isProduction ? _productionWsUrl : _developmentWsUrl;
  
  // Environment info
  static bool get isProduction => _isProduction;
  static bool get isDevelopment => !_isProduction;
  
  // Debug info
  static String get environmentInfo => _isProduction ? 'Production' : 'Development';
  static String get currentBaseUrl => baseUrl;
  static String get currentWsUrl => wsUrl;
}
