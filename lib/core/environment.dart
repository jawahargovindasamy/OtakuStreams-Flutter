class Environment {
  static const String current = String.fromEnvironment('ENVIRONMENT', defaultValue: 'production');
  static const String channel = String.fromEnvironment('CHANNEL', defaultValue: 'stable');

  static String get baseUrl {
    switch (current) {
      case 'development':
        // Uses 10.0.2.2 which is the Android emulator gateway to localhost
        return 'http://10.0.2.2:5000/api';
      case 'staging':
        return 'https://otakustreams-backend-staging.onrender.com/api';
      default:
        return 'https://otakustreams-backend-j3h5.onrender.com/api';
    }
  }
}
