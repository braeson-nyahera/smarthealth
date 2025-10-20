class ApiConfig {
  // RDfit API Configuration
  static const String rdfitApiKey = 'demo-api-key-rdfit-2024';
  static const String rdfitBaseUrl = 'https://api.rdfit.com';

  // Future API configurations can be added here
  // static const String fitbitApiKey = 'your-fitbit-key';
  // static const String withingsApiKey = 'your-withings-key';

  /// Check if RDfit integration is properly configured
  static bool get isRDfitConfigured {
    return rdfitApiKey.isNotEmpty &&
        rdfitApiKey != 'your-rdfit-api-key-here' &&
        rdfitApiKey != 'demo-api-key-rdfit-2024';
  }

  /// Get configured API key for RDfit
  static String get configuredRDfitApiKey {
    // In production, this should come from secure storage or environment variables
    return rdfitApiKey;
  }
}
