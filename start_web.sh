#!/bin/bash

# SmartHealth Flutter Web Startup Script
# This script ensures your app always runs on port 3000

echo "🚀 Starting SmartHealth on Fixed Port 3000"
echo "=========================================="
echo ""
echo "✅ Benefits:"
echo "   - Consistent URL: http://localhost:3000"
echo "   - No need to update Google Console origins"
echo "   - Bookmarkable URL"
echo "   - Easier debugging"
echo ""

# Kill any existing process on port 3000
echo "🧹 Checking if port 3000 is in use..."
if lsof -i :3000 > /dev/null 2>&1; then
    echo "⚠️  Port 3000 is in use, stopping existing process..."
    kill -9 $(lsof -ti :3000) 2>/dev/null || true
    echo "✅ Port 3000 cleared"
else
    echo "✅ Port 3000 is available"
fi

echo ""
echo "🌐 Starting Flutter web on http://localhost:3000"
echo ""

# Start Flutter with fixed port
flutter run -d chrome --web-port=3000

echo ""
echo "📝 To use this consistently:"
echo "   1. Always run:./start_web.sh"
echo "   2. Or use: flutter run -d chrome --web-port=3000"
echo "   3. Your app will always be at: http://localhost:3000"