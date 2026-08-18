class ApiConfig {
  // Production API Base URL (DigitalOcean + Nginx + HTTPS)
  static const String productionBaseUrl = 'https://api.kamjodo.com';

  // Development API Base URL
  static const String developmentBaseUrl = 'http://localhost:4000';

  // Current active API Base URL used by the app
  static String get baseUrl {
    const bool isProduction = bool.fromEnvironment('dart.vm.product');
    return isProduction ? productionBaseUrl : developmentBaseUrl;
  }
}
