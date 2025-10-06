# Google Sign-In Web Setup Guide

## Problem
The error "ClientID not set" occurs when trying to use Google Sign-In on Flutter web because the web client ID is not properly configured.

## Solution Steps

### 1. Google Cloud Console Setup

1. **Go to Google Cloud Console**: https://console.cloud.google.com/
2. **Create or select a project** for your SmartHealth app
3. **Enable required APIs**:
   - Google Fit API
   - Google+ API (for authentication)
   - Go to "APIs & Services" > "Library"
   - Search and enable each API

### 2. Create OAuth 2.0 Credentials

1. **Go to "APIs & Services" > "Credentials"**
2. **Click "Create Credentials" > "OAuth 2.0 Client IDs"**
3. **Create Web Application credential**:
   - Application type: Web application
   - Name: SmartHealth Web
   - Authorized JavaScript origins: 
     - `http://localhost:3000` (for local development)
     - `https://yourdomain.com` (for production)
   - Authorized redirect URIs (if needed):
     - `http://localhost:3000/auth/callback`

### 3. Get Your Client IDs

After creating credentials, you'll get:
- **Web Client ID**: `xxxxx.apps.googleusercontent.com`
- **Client Secret**: (keep this secure)

### 4. Update Configuration Files

#### A. Update `lib/config/google_config.dart`:
```dart
class GoogleConfig {
  static const String webClientId = 'YOUR_ACTUAL_WEB_CLIENT_ID.apps.googleusercontent.com';
  // ... rest of the config
}
```

#### B. Update `web/index.html`:
```html
<meta name="google-signin-client_id" content="YOUR_ACTUAL_WEB_CLIENT_ID.apps.googleusercontent.com">
```

### 5. Test the Setup

1. **Clean and rebuild**:
   ```bash
   flutter clean
   flutter pub get
   flutter run -d chrome
   ```

2. **Check for errors** in browser console
3. **Try signing in** - should work without the ClientID error

## Troubleshooting

### Common Issues:
1. **Wrong Client ID**: Make sure you're using the WEB client ID, not Android/iOS
2. **Domain not authorized**: Add your domain to authorized origins
3. **API not enabled**: Ensure Google Fit API is enabled
4. **Cache issues**: Clear browser cache and restart Flutter

### Debug Steps:
1. Open browser developer tools (F12)
2. Check Console tab for JavaScript errors
3. Check Network tab for failed requests
4. Verify the client ID in the HTML source

## Security Notes

- **Never commit real client IDs to version control**
- **Use environment variables** for production
- **Keep client secrets secure** (server-side only)
- **Regularly rotate credentials** for security

## Next Steps

After fixing the web authentication:
1. Test on different browsers
2. Set up production domain credentials
3. Configure proper redirect URLs
4. Test the 2-minute auto-refresh functionality