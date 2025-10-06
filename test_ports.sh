#!/bin/bash

echo "🔧 Flutter Web Port Tester for Google Sign-In"
echo "============================================="
echo ""
echo "Your app was running on: localhost:40373"
echo "Most common Flutter web ports: 3000, 8080, 40373"
echo ""
echo "Choose how to fix the popup_closed error:"
echo ""
echo "Option 1: Update Google Cloud Console"
echo "   ➡️  Add http://localhost:40373 to authorized origins"
echo ""
echo "Option 2: Use consistent port"
echo "   ➡️  Run: flutter run -d chrome --web-port=3000"
echo ""
echo "Testing different ports..."
echo ""

# Test if ports are available
for port in 3000 8080 40373; do
    if ! lsof -i :$port > /dev/null 2>&1; then
        echo "✅ Port $port is available"
    else
        echo "❌ Port $port is in use"
    fi
done

echo ""
echo "💡 Recommended action:"
echo "   1. Add http://localhost:40373 to Google Cloud Console"
echo "   2. Wait 5-10 minutes for changes to propagate"  
echo "   3. Clear browser cache (Ctrl+Shift+Delete)"
echo "   4. Restart your Flutter app"
echo ""
echo "🎯 Current client ID: 816258150287-5j8pltavpk9msl9q3h1gcovvtc45u5vl.apps.googleusercontent.com"