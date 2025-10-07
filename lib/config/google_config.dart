/// Google Services Configuration
///
/// This file contains the configuration for Google Sign-In and Google Fit API.
/// You need to replace the placeholder values with your actual client IDs
/// from the Google Cloud Console.
library;

class GoogleConfig {
  // Get this from: https://console.cloud.google.com/apis/credentials
  static const String webClientId =
      '816258150287-5j8pltavpk9msl9q3h1gcovvtc45u5vl.apps.googleusercontent.com';

  // TODO: Replace with your actual Android Client ID (if different)
  static const String androidClientId =
      'YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com';

  // TODO: Replace with your actual iOS Client ID (if different)
  static const String iosClientId =
      'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';

  /// Instructions to set up Google Sign-In:
  ///
  /// 1. Go to Google Cloud Console: https://console.cloud.google.com/
  /// 2. Create a new project or select existing one
  /// 3. Enable the following APIs:
  ///    - Google Fit API
  ///    - Google+ API (for sign-in)
  /// 4. Go to "Credentials" section
  /// 5. Create "OAuth 2.0 Client IDs" for:
  ///    - Web application (for Flutter web)
  ///    - Android (for Android app)
  ///    - iOS (for iOS app)
  /// 6. For Web client:
  ///    - Add your domain to "Authorized JavaScript origins"
  ///    - Add redirect URIs if needed
  /// 7. Copy the client IDs and replace the values above
  /// 8. Update web/index.html with the web client ID
}
