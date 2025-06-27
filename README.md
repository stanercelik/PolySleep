# PolySleep - Smart Polyphasic Sleep Manager

## 📱 App Overview
PolySleep is a modern iOS application designed to manage polyphasic sleep schedules and provide personalized recommendations. It helps users track their sleep habits, switch between different sleep patterns, and evaluate their sleep quality.

## 📸 Screenshots

*Screenshots will be added here soon...*

<!-- 
You can add screenshots here like:
![Main Screen](screenshots/main-screen.png)
![Analytics](screenshots/analytics.png)
![Sleep Schedule](screenshots/sleep-schedule.png)
-->

## ✨ Key Features

### 📝 Personalized Onboarding
- Custom sleep schedule recommendations based on user preferences
- Detailed user profile creation
- Step-by-step guidance system
- Daily tip suggestions
- Sleep block tracking and recommendations

### ⏰ 24-Hour Sleep Timeline
- Customizable sleep blocks
- Monophasic, Biphasic, Polyphasic and other sleep patterns
- Adaptation phase tracking
- Notification system integration
- Dynamic circular sleep chart

### 🚨 Smart Alarm System
- Wake-up alarms at the end of sleep blocks
- Critical notifications bypass Focus/Silent mode
- Customizable alarm sounds and settings
- Snooze functionality with configurable duration
- Fallback alerts when notification permission is denied
- Just-in-time scheduling (max 64 pending notifications)

### 📊 Detailed Analytics Dashboard
- Daily, weekly, monthly and yearly sleep records
- Emoji and star-based rating system
- Historical sleep data visualization
- Progress and adaptation reports
- Premium features with advanced analytics

### 💾 Local Data Storage (Offline-First)
- Powerful local database with SwiftData
- Fully offline capability
- Privacy-focused design
- Automatic data backup

### 🔐 Anonymous Usage & Authentication
- Full anonymous usage support
- Local user account management
- Profile photo and name customization
- Privacy-first approach

### 💎 Premium Features
- RevenueCat integration for subscription management
- Advanced analytics charts
- Premium sleep schedules
- Custom sleep programs

## 🛠 Technology Stack

### **Frontend**
- **SwiftUI**: Modern UI framework
- **MVVM Architecture**: Clean and maintainable code structure
- **Custom Components**: Custom SwiftUI components
- **Charts Framework**: Native iOS charting support

### **Data Management**
- **SwiftData**: iOS 17+ native database solution
- **Offline-First**: No internet connection required
- **Repository Pattern**: Data access layer abstraction
- **CRUD Operations**: Full data management support

### **Application Services**
- **UserNotifications**: Alarm and notification system
- **Background Tasks**: Background processing
- **Critical Alerts**: Emergency notifications
- **Audio Services**: Alarm sound management

### **Subscription & Monetization**
- **RevenueCat**: Subscription management
- **StoreKit**: App Store integration
- **Premium Features**: Freemium model

### **Localization**
- **XCStrings**: Modern localization system
- **Turkish & English**: Multi-language support
- **Dynamic Localization**: Real-time language switching

## ⚙️ Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/PolySleep.git
cd PolySleep
```

2. **Open project in Xcode**
```bash
open polynap.xcodeproj
```

3. **Configure RevenueCat API Key**
- Set your RevenueCat API key in `AppConfiguration.swift`
- Add `RevenueCatAPIKey` key to `Info.plist`

4. **Set up notification permissions**
- The app will automatically request notification permissions
- Critical alerts may require special permissions

5. **Build and run**
- Requires iOS 17.0+
- iPhone/iPad compatibility available

## 📋 Project Structure

```
polynap/
├── App/                        # Main application file
├── Screen/                     # Screen modules
│   ├── MainScreen/            # Main screen
│   ├── Analytics/             # Analytics dashboard
│   ├── History/               # Sleep history
│   ├── Profile/               # User profile
│   ├── Settings/              # Settings
│   ├── OnboardingScreen/      # Onboarding guide
│   └── SleepScheduleScreen/   # Sleep schedule selection
├── Services/                   # Business logic services
│   ├── Repository/            # Data access layer
│   ├── Auth/                  # Authentication
│   └── NotificationService/   # Notification management
├── Models/                     # Data models
├── Components/                 # Reusable components
├── Managers/                   # System managers
├── Resources/                  # Resources and localization
└── Utils/                      # Utility tools
```

## 🔒 Security & Privacy

- **Offline-First Approach**: Data is stored entirely on device
- **Anonymous Usage**: No authentication required
- **Data Encryption**: Sensitive data stored securely
- **Minimal Permissions**: Only necessary permissions requested

## 🎨 Design System

- **Apple Human Interface Guidelines** compliance
- **SF Pro Font** family usage
- **Dark Mode** full support
- **Dynamic Type** accessibility support
- **Modern and minimal** interface design

## 🚀 Features

### Current Features
- ✅ 10+ different sleep schedule support
- ✅ Smart alarm system
- ✅ Detailed sleep analytics
- ✅ Offline-first data management
- ✅ Turkish/English localization
- ✅ Premium subscription system
- ✅ Customizable profile management

### Upcoming Updates
- 🔄 Apple Watch integration
- 🔄 HealthKit synchronization
- 🔄 Social features
- 🔄 AI-powered sleep recommendations

## 🤝 Contributing

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 📞 Contact

- **Developer**: Taner Çelik
- **Email**: [tanercelik2001@gmail.com]
- **GitHub**: [@tanercelik](https://github.com/tanercelik)

---

**Optimize your polyphasic sleep schedule with PolySleep!** 🌙✨
