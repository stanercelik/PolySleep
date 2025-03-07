# PolySleep - Smart Sleep Schedule Manager

## 📱 App Summary
PolySleep is an iOS application designed to manage polyphasic sleep schedules and provide personalized recommendations. The app helps users track sleep habits, switch between different sleep patterns, and evaluate sleep quality.

## ✨ Key Features
- **Personalized Onboarding**
  - Custom sleep schedule recommendations based on user preferences
  - Detailed user profile creation
  - Step-by-step guidance system
  - Daily tip suggestions
  - Sleep block tracking and recommendations

- **24-Hour Sleep Timeline**
  - Customizable sleep blocks
  - Monophasic, Biphasic, Polyphasic and other sleep patterns
  - Adaptation phase tracking
  - Notification system integration

- **Real-Time Synchronization**
  - Local data storage with SwiftData
  - Cloud synchronization with Supabase
  - Offline support
  - Automatic data backup

- **Detailed Analytics Dashboard**
  - Daily, weekly, monthly and yearly sleep records
  - Emoji and star-based rating system
  - Historical sleep data visualization
  - Progress and adaptation reports

- **Cross-Device Sync**
  - Instant synchronization across iOS devices
  - Secure data transfer
  - User-specific data isolation

- **Anonymous & Social Login**
  - Apple ID login
  - Email/password registration
  - Anonymous usage option

## 🛠 Technology Stack
- **UI Framework:**
  - SwiftUI
  - MVVM architecture
  - Custom SwiftUI components

- **Data Storage:**
  - SwiftData (local database)
  - Supabase (cloud database)
  - Row Level Security (RLS)

- **Backend Services:**
  - Supabase REST API
  - Real-time data sync
  - PostgreSQL database

- **Authentication:**
  - Apple SignIn
  - Email/password authentication
  - Anonymous login support

- **Localization:**
  - SwiftGen
  - XCStrings
  - Turkish & English support

## ⚙️ Installation
1. Clone the repository
```bash
git clone https://github.com/yourusername/PolySleep.git
cd PolySleep
```

2. Create `.env` file for Supabase config
```bash
SUPABASE_URL=your_project_url
SUPABASE_ANON_KEY=your_anon_key
```

3. Edit `SupabaseConfig.swift`
```swift
static let supabaseUrl = "your_project_url"
static let supabaseAnonKey = "your_anon_key"
```

4. Configure Google OAuth:
   - Get Client ID & Secret from Google Cloud Console
   - Enable Google OAuth in Supabase Dashboard
   - Add URL scheme: "polysleep://"

5. Open project in Xcode and build

## 🔐 Security
- Row Level Security (RLS) for data isolation
- Secure token management
- API key encryption
- SSL/TLS encrypted data transfer

## 🤝 Contributing
1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📄 License
This project is licensed under MIT License
---
