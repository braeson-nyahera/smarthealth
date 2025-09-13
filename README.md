# 🏥 SmartHealth Dashboard

A premium Flutter health tracking application that provides comprehensive health metrics visualization through Google Fit integration. Built with a sleek, minimalist design inspired by professional health apps.

## ✨ Features

### 🎯 Core Functionality
- **Google Fit Integration** - Seamless connection to Google Fit for comprehensive health data
- **Real-time Health Metrics** - Track steps, distance, calories, heart rate, sleep, and more
- **Interactive Charts** - Beautiful data visualizations with period selection (24h, 7d, 30d, 90d)
- **Trend Analysis** - Smart trend indicators showing health metric patterns
- **Category Organization** - Organized health data by Fitness, Health, and other categories

### 🎨 Premium Design System
- **iOS-inspired UI** - Clean, minimalist design with professional aesthetics
- **Cohesive Color Palette** - Primary blues (#0A84FF), accent colors, and subtle gradients
- **Responsive Layout** - Optimized for mobile, tablet, and web platforms
- **Smooth Animations** - Subtle transitions and interactive elements
- **Professional Typography** - Carefully crafted text hierarchy and spacing

## 🏗️ Architecture

### Modular Structure
```
lib/
├── constants/          
│   ├── app_theme.dart     
│   └── health_metrics.dart 
├── models/             
│   └── health_models.dart 
├── services/           
│   └── health_data_service.dart 
├── utils/              
│   └── health_utils.dart  
├── widgets/            
│   ├── user_header.dart    
│   ├── category_header.dart 
│   ├── metric_card.dart    
│   ├── detailed_chart.dart 
│   └── detailed_stats.dart 
├── pages/             
│   └── health_data_page.dart 
├── main.dart           
└── demo_main.dart      # Standalone demo (no Google auth)
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0+)
- Dart SDK (3.0+)
- Google Fit account (for full functionality)
- Web browser or mobile device for testing

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/braeson-nyahera/smarthealth.git
   cd smarthealth
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the demo version** (no Google auth required)
   ```bash
   flutter run -t lib/demo_main.dart
   ```

4. **Run the full app** (requires Google Fit setup)
   ```bash
   flutter run
   ```

### Google Fit Setup (Optional)

For full functionality with real health data:

1. **Enable Google Fit API** in Google Cloud Console
2. **Configure OAuth 2.0** credentials
3. **Add client ID** to `web/index.html`:
   ```html
   <meta name="google-signin-client_id" content="YOUR_CLIENT_ID.googleusercontent.com">
   ```

## 📱 Usage

### Demo Mode
The app includes a demo mode (`demo_main.dart`) that showcases the premium UI without requiring Google authentication. Perfect for:
- UI/UX demonstrations
- Design system showcase
- Development testing

### Full App Mode
When properly configured with Google Fit:
1. **Sign in** with your Google account
2. **Grant permissions** for health data access
3. **View comprehensive metrics** across multiple categories
4. **Interact with charts** to explore different time periods
5. **Track trends** and analyze your health patterns

## 🎨 Design Philosophy

### Premium Minimalism
- **Content-first approach** - Health data takes center stage
- **Subtle visual hierarchy** - Clear information architecture
- **Consistent spacing** - Professional grid system
- **Cohesive color usage** - Purposeful color application

### User Experience
- **Intuitive navigation** - Clear, accessible interface
- **Progressive disclosure** - Detailed views on demand
- **Responsive feedback** - Interactive elements with visual feedback
- **Accessibility focus** - Proper contrast ratios and touch targets

## 🛠️ Technical Details

### Supported Platforms
- ✅ **Web** - Progressive web app capabilities
- ✅ **Android** - Native mobile experience
- ✅ **iOS** - Native mobile experience
- ✅ **Linux** - Desktop support
- ✅ **macOS** - Desktop support
- ✅ **Windows** - Desktop support

### Health Metrics Supported
- **Fitness**: Steps, Distance, Calories, Active Minutes, Exercise Sessions
- **Health**: Heart Rate, Sleep Duration, Weight, Body Fat Percentage
- **Vitals**: Blood Pressure, Blood Glucose (with proper device integration)

## 🎯 Performance

### Optimizations
- **Efficient data fetching** - Smart caching and pagination
- **Smooth animations** - 60fps target for all interactions
- **Memory management** - Proper widget lifecycle management
- **Network efficiency** - Minimal API calls with intelligent updates

## 🔧 Development

### Code Quality
- **Lint rules** - Strict Flutter/Dart linting
- **Type safety** - Full null safety implementation
- **Error handling** - Comprehensive error states
- **Testing ready** - Modular architecture supports unit testing


## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🙏 Acknowledgments

- **Flutter Team** - For the amazing framework
- **Google Fit API** - For health data integration
- **FL Chart** - For beautiful chart components
- **Material Design 3** - For design inspiration

---

**Built with ❤️** 
