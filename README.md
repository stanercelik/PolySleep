# PolyNap - Smart Polyphasic Sleep Manager

## 📱 App Overview
PolyNap is a modern iOS application designed to manage polyphasic sleep schedules and provide personalized recommendations. It helps users track their sleep habits, switch between different sleep patterns, and evaluate their sleep quality.

## 📸 Screenshots

<p float="left">
  <img src="https://github.com/user-attachments/assets/c3771891-8e05-47d6-acd7-ea3b9930d557" width="15%" style="margin-right: 24px;" />
  <img src="https://github.com/user-attachments/assets/29783a18-27f7-4e36-9652-f275ff7f28d9" width="15%" style="margin-right: 24px;" />
  <img src="https://github.com/user-attachments/assets/c18aba35-6423-43c7-8016-0af6fdb25f00" width="15%" style="margin-right: 24px;" />
  <img src="https://github.com/user-attachments/assets/1172e8a4-2095-4a9f-bc87-dfb47f35a9ae" width="15%" style="margin-right: 24px;" />
  <img src="https://github.com/user-attachments/assets/b27cae9d-7773-4307-82a6-19d43b9ecc96" width="15%" style="margin-right: 24px;" />
  <img src="https://github.com/user-attachments/assets/7c2808c1-7832-411a-a662-b2ca5c31dcce" width="15%" />
</p>

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

### **Analytics & Tracking**
- **Firebase Analytics**: User behavior and engagement tracking
- **Google Analytics**: Comprehensive analytics integration
- **Custom Events**: Step-by-step onboarding tracking
- **Conversion Funnels**: User acquisition and retention analysis
- **Revenue Analytics**: Subscription and monetization metrics

### **Subscription & Monetization**
- **RevenueCat**: Subscription management
- **StoreKit**: App Store integration
- **Premium Features**: Freemium model
- **Dynamic Paywall System**: Context-aware premium offerings

### **Localization**
- **XCStrings**: Modern localization system
- **Turkish & English**: Multi-language support
- **Dynamic Localization**: Real-time language switching

## 📊 Analytics & Data Strategy

### **Firebase Analytics Integration**
PolyNap implements comprehensive analytics tracking through Firebase Analytics to monitor user behavior, feature adoption, and revenue metrics. The analytics system follows a structured approach with predefined events and custom parameters.

#### **Core Tracked Events**
- **User Lifecycle**: `first_open`, `onboarding_started`, `onboarding_step_completed`, `onboarding_completed`
- **Feature Usage**: `sleep_entry_added`, `schedule_selected`, `schedule_successfully_applied`, `schedule_changed`
- **Revenue**: `app_store_subscription_convert`, `app_store_subscription_renew`, `in_app_purchase`, `purchase`
- **Engagement**: `user_retention`, `close_convert_lead`, `qualify_lead`

#### **Step-by-Step Onboarding Tracking**
The onboarding process is meticulously tracked to identify drop-off points and optimize user activation:

```swift
// Each onboarding step is tracked with detailed parameters
onboarding_step_completed {
  step_number: Int,
  step_name: String,
  time_on_step: Int,
  completion_rate: Double,
  user_selections: [String]
}
```

**Tracked Onboarding Steps:**
1. Welcome screen interaction
2. Sleep experience assessment
3. Current sleep schedule evaluation
4. Lifestyle and preferences survey
5. Schedule recommendation acceptance
6. Initial setup completion

#### **Key Performance Indicators (KPIs)**
- **User Acquisition**: Daily/weekly/monthly new users
- **User Activation**: Onboarding completion rate (target: >75%)
- **User Engagement**: Daily/weekly active users
- **User Retention**: D1, D7, D30 retention rates
- **Revenue Metrics**: MRR, ARPU, conversion rates
- **Feature Adoption**: Schedule selection and sleep tracking rates

### **Advanced Analytics Features**
- **Funnel Analysis**: Complete user journey from acquisition to conversion
- **Cohort Analysis**: User behavior tracking over time
- **Segmentation**: Behavioral and demographic user groups
- **A/B Testing Framework**: Feature and UI optimization
- **Predictive Analytics**: Churn prediction and LTV calculation

## 💰 Dynamic Paywall System

PolyNap implements a sophisticated paywall strategy that adapts to user behavior and engagement patterns. The system presents different premium offerings based on user interaction history.

### **Paywall Display Strategy**
The app uses a multi-layered approach that presents different offers based on how many times a user has encountered the paywall:

#### **Scenario 1: First Encounter - Complete Value Proposition**
- **Trigger**: User completes onboarding and navigates to main screen
- **Action**: Display `all_plans` paywall with full feature overview
- **Goal**: Capture users at peak interest with comprehensive plan comparison
- **Content**: Monthly/yearly plans with savings highlight

#### **Scenario 2: Second Encounter - Reinforcement**
- **Trigger**: User closes first paywall and later attempts to access premium features
- **Action**: Display `all_plans` paywall again
- **Goal**: Provide second chance for informed decision-making
- **Content**: Same comprehensive plan overview with feature benefits

#### **Scenario 3: Special Discount Offer - Conversion Focus**
- **Trigger**: User closes second paywall and attempts premium feature access again
- **Action**: Display `exit_discount` paywall with limited-time offer
- **Goal**: Convert price-sensitive users with exclusive discount
- **Content**: Special pricing with urgency messaging

#### **Scenario 4: Frictionless Approach - Trial Focus**
- **Trigger**: User has seen all previous paywalls and continues accessing premium features
- **Action**: Display `trial_focus` paywall emphasizing free trial
- **Goal**: Minimize friction with low-commitment trial offer
- **Content**: Simplified trial-focused messaging

### **Paywall Optimization**
- **Context-Aware Timing**: Paywalls triggered at optimal user engagement points
- **Progressive Disclosure**: Gradually more targeted offers based on user response
- **Local State Management**: Paywall history stored on-device for privacy
- **A/B Testing Ready**: Framework supports testing different strategies

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

3. **Configure API Keys and Analytics**
- Set your RevenueCat API key in `AppConfiguration.swift`
- Add `RevenueCatAPIKey` key to `Info.plist`
- Configure Firebase Analytics by adding `GoogleService-Info.plist`
- Set up Firebase project and enable Analytics

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
- ✅ Smart alarm system with background processing
- ✅ Detailed sleep analytics and reporting
- ✅ Comprehensive Firebase Analytics integration
- ✅ Step-by-step onboarding tracking and optimization
- ✅ Dynamic paywall system with 4-tier strategy
- ✅ Offline-first data management
- ✅ Turkish/English localization
- ✅ Premium subscription system with RevenueCat
- ✅ Customizable profile management
- ✅ User behavior analytics and funnel tracking

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
