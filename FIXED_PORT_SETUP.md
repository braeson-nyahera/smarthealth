# 🌐 Google Cloud Console Setup - Fixed Port Solution

## What to Add to Google Console

Instead of multiple random ports, you now only need to add **ONE** origin:

### Authorized JavaScript Origins:
```
http://localhost:3000
```

### Steps:
1. Go to: https://console.cloud.google.com/apis/credentials
2. Find your Web Client ID: `816258150287-5j8pltavpk9msl9q3h1gcovvtc45u5vl`
3. Click "Edit"
4. Under "Authorized JavaScript origins", add:
   - `http://localhost:3000`
5. Remove all the random port entries (40373, 35265, etc.)
6. Save changes
7. Wait 5-10 minutes for propagation

## Benefits of Fixed Port:

✅ **Consistent URL**: Always `http://localhost:3000`
✅ **One-time setup**: No more updating Google Console
✅ **Bookmarkable**: You can bookmark the app
✅ **Easier sharing**: Same URL for team members
✅ **Debugging**: Consistent environment
✅ **Development**: Easier to remember

## Usage Options:

### Option 1: Command Line
```bash
flutter run -d chrome --web-port=3000
```

### Option 2: Custom Script
```bash
./start_web.sh
```

### Option 3: VS Code
- Open Run & Debug panel (Ctrl+Shift+D)
- Select "SmartHealth Web (Fixed Port)"
- Click Start Debugging (F5)

## Production Note:
For production deployment, you'll add your actual domain:
```
https://yourdomain.com
https://www.yourdomain.com  
```