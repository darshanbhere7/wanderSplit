# Wandersplit 🚀 | Smart Travel Expense Tracker

Wandersplit is a modern, feature-rich travel expense tracking application built with Flutter and Firebase. It provides a seamless experience for travelers to manage trip expenses, split costs among group members, and track spending with real-time synchronization and beautiful analytics.

This project goes beyond traditional expense tracking by integrating real-time collaboration, smart expense splitting, comprehensive analytics, and an intuitive user interface, creating a complete digital ecosystem for modern travelers.

## 🚀 Core Features

### 🛍️ Trip Management & Planning
- **Trip Creation**: Create detailed trips with categories (Business, Leisure, Family, Other)
- **Budget Planning**: Set budgets and track spending against limits
- **Member Management**: Add team members with different roles (Admin, Member)
- **Location Tracking**: Add trip locations and dates for better organization
- **Currency Support**: Multi-currency expense tracking

### 💰 Smart Expense Tracking
- **Expense Categories**: Organized categories (Food, Transport, Accommodation, Activities, Shopping, Other)
- **Receipt Management**: Upload and store expense receipts with ImageKit integration
- **Expense Splitting**: Smart expense splitting among group members
- **Recurring Expenses**: Set up recurring expenses with custom frequencies
- **Tags System**: Add custom tags for better expense organization

### 📊 Analytics & Insights
- **Real-time Analytics**: Live spending statistics and budget tracking
- **Expense Charts**: Beautiful charts using FL Chart for spending visualization
- **Settlement Tracking**: Automatic calculation of who owes what to whom
- **Spending Limits**: Individual spending limits for group members
- **Export Features**: Export expense reports and settlement summaries

### 👥 Group Collaboration
- **Real-time Sync**: Firebase Firestore for live data synchronization
- **Member Roles**: Admin and member roles with different permissions
- **Group Expenses**: Shared expenses with automatic splitting
- **Activity Feed**: Track all expense activities in real-time

### 🔐 Authentication & Security
- **Firebase Auth**: Secure authentication with email/password
- **Google Sign-in**: One-click Google authentication
- **Password Recovery**: Forgot password functionality
- **User Profiles**: Personalized user dashboards

### 🎨 Modern User Experience
- **Dark/Light Theme**: Toggle between themes for better user experience
- **Responsive Design**: Mobile-first design with smooth animations
- **Custom Fonts**: Poppins font family for modern typography
- **Smooth Animations**: Flutter Animate for engaging interactions

## 🛠️ Tech Stack & Architecture

This application is built using a modern, scalable architecture with the following technologies:

### Frontend (Flutter)
- **Flutter 3.x**: Cross-platform mobile development framework
- **Dart**: Programming language for Flutter
- **Provider**: State management for reactive UI
- **Firebase SDK**: Real-time database and authentication
- **FL Chart**: Beautiful charts and analytics
- **Flutter Animate**: Smooth animations and transitions
- **Image Picker**: Camera and gallery integration
- **URL Launcher**: External link handling

### Backend & Services
- **Firebase Authentication**: Secure user authentication
- **Cloud Firestore**: Real-time NoSQL database
- **Firebase Storage**: File storage for receipts and images
- **ImageKit**: Image optimization and CDN
- **Google Sign-in**: OAuth authentication

### Development Tools
- **Flutter Lints**: Code quality and best practices
- **Provider Pattern**: Clean architecture and state management
- **Custom Fonts**: Poppins font family integration

## 🏗️ System Architecture

```
+------------------+      +-------------------+      +---------------------+
|                  |      |                   |      |                     |
|   Flutter App    |----->|   Firebase Auth   |----->|   Cloud Firestore   |
| (Cross-platform) |      |   & Firestore     |      |   (Database)        |
|                  |      |                   |      |                     |
+--------^---------+      +-------------------+      +---------------------+
         |
         | Real-time
         | Sync
         |
+--------|---------+
|                  |
|  Firebase Storage|
| (File Storage)   |
|                  |
+------------------+
```

## 🚀 Getting Started

Follow these instructions to get a local copy of the project up and running for development and testing purposes.

### Prerequisites
- **Flutter SDK** (3.0.0 or higher)
- **Dart SDK** (3.0.0 or higher)
- **Android Studio** or **VS Code** with Flutter extensions
- **Firebase Account** for backend services
- **ImageKit Account** for image hosting (optional)

### Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/darshanbhere7/wanderSplit.git
   cd wandersplit
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup:**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication (Email/Password and Google Sign-in)
   - Enable Cloud Firestore
   - Enable Firebase Storage
   - Download `google-services.json` for Android
   - Download `GoogleService-Info.plist` for iOS
   - Place these files in the appropriate directories

4. **Configure Firebase:**
   - Update `lib/firebase_options.dart` with your Firebase configuration
   - Configure Firestore security rules
   - Set up Firebase Storage rules

5. **ImageKit Setup (Optional):**
   - Create an ImageKit account
   - Add your ImageKit credentials to the app configuration

6. **Run the application:**
   ```bash
   flutter run
   ```

## 📱 Key Features in Detail

### 🎯 User Experience
- **Responsive Design**: Mobile-first approach with Material Design
- **Theme Toggle**: Dark and light theme support
- **Smooth Animations**: Engaging user interactions
- **Custom Fonts**: Poppins font family for modern typography

### 🔐 Authentication & Security
- **Firebase Auth**: Secure token-based authentication
- **Google Sign-in**: One-click authentication
- **Password Recovery**: Email-based password reset
- **User Profiles**: Personalized user experience

### 💰 Expense Management
- **Smart Categorization**: Predefined and custom expense categories
- **Receipt Upload**: Camera and gallery integration
- **Expense Splitting**: Automatic cost distribution
- **Recurring Expenses**: Set up periodic expenses
- **Tags System**: Custom tagging for organization

### 📊 Analytics & Insights
- **Real-time Charts**: FL Chart integration for spending visualization
- **Budget Tracking**: Live budget vs spending comparison
- **Settlement Calculator**: Automatic debt calculation
- **Export Features**: Share expense reports

### 👥 Group Features
- **Member Management**: Add/remove trip members
- **Role-based Access**: Admin and member permissions
- **Real-time Sync**: Live updates across devices
- **Activity Tracking**: Complete expense history


## 🎨 UI/UX Features

### Design System
- **Material Design 3**: Modern design principles
- **Custom Theme**: Light and dark theme support
- **Typography**: Poppins font family
- **Color Palette**: Consistent color scheme
- **Icons**: Material Icons integration

### Animations
- **Page Transitions**: Smooth navigation animations
- **Loading States**: Engaging loading animations
- **Micro-interactions**: Subtle UI feedback
- **Chart Animations**: Animated data visualization

## 🔧 Development Features

### Code Quality
- **Flutter Lints**: Enforced code quality standards
- **Provider Pattern**: Clean state management
- **Null Safety**: Full null safety implementation
- **Error Handling**: Comprehensive error management

### Performance
- **Lazy Loading**: Efficient data loading
- **Image Optimization**: Compressed image handling
- **Memory Management**: Optimized memory usage
- **Offline Support**: Basic offline functionality

## 📸 Screenshots & Demo
<p align="center"> <img src="https://github.com/user-attachments/assets/42488f7d-7831-428f-8514-c4af8127fedf" width="30%" style="margin:5px;" /> <img src="https://github.com/user-attachments/assets/caca3ac5-0319-4fea-a1cc-dfb6a763cd74" width="30%" style="margin:5px;" /> <img src="https://github.com/user-attachments/assets/5eefbc44-088e-4b5f-a756-d7e1692f25a3" width="30%" style="margin:5px;" /> </p> <p align="center"> <img src="https://github.com/user-attachments/assets/7fe4be62-815b-4ccb-a449-384fd290818b" width="30%" style="margin:5px;" /> <img src="https://github.com/user-attachments/assets/4ebda638-13ef-45d3-b577-e0cc4ec9a2a0" width="30%" style="margin:5px;" /> <img src="https://github.com/user-attachments/assets/4029762a-dc06-4081-a0a9-e51a974e4377" width="30%" style="margin:5px;" /> </p> <p align="center"> <img src="https://github.com/user-attachments/assets/cd4277e8-a690-4174-ae31-5e66cfadbcce" width="30%" style="margin:5px;" /> <img src="https://github.com/user-attachments/assets/96d0a5cf-1526-49fc-aaec-d364776f4645" width="30%" style="margin:5px;" /> <img src="https://github.com/user-attachments/assets/4700c094-ce9c-42fd-b586-09258e687c92" width="30%" style="margin:5px;" /> </p> <p align="center"> <img src="https://github.com/user-attachments/assets/4fc2bd64-591b-499b-9b00-7f64619507a5" width="30%" style="margin:5px;" /> <img src="https://github.com/user-attachments/assets/5f1ebf14-b667-4436-944e-12b72ccf4c2c" width="30%" style="margin:5px;" /> <img src="https://github.com/user-attachments/assets/4085ba38-6ff6-4838-af0b-06e53021e2e7" width="30%" style="margin:5px;" /> </p>


### Key Screenshots to Add:
- **Splash Screen**: App launch and introduction
- **Authentication**: Login and registration screens
- **Home Dashboard**: Main trip overview
- **Trip Creation**: Add new trip flow
- **Expense Tracking**: Add and manage expenses
- **Analytics**: Charts and spending insights
- **Settlement**: Debt calculation and settlement
- **Profile**: User settings and preferences

## 🚀 Future Enhancements

### Planned Features
- **Offline Mode**: Full offline functionality
- **Export Options**: PDF and Excel export
- **Push Notifications**: Expense reminders
- **Multi-language**: Internationalization support
- **Advanced Analytics**: Machine learning insights
- **Social Features**: Share trips and expenses
- **Integration**: Bank account and credit card sync

### Technical Improvements
- **Performance**: Further optimization
- **Testing**: Unit and widget tests
- **CI/CD**: Automated deployment pipeline
- **Documentation**: Comprehensive API docs

## 🤝 Contributing

Contributions make the open-source community an amazing place to learn, inspire, and create. Any contributions you make are greatly appreciated.

### How to Contribute
1. **Fork the Project**
2. **Create your Feature Branch** (`git checkout -b feature/AmazingFeature`)
3. **Commit your Changes** (`git commit -m 'Add some AmazingFeature'`)
4. **Push to the Branch** (`git push origin feature/AmazingFeature`)
5. **Open a Pull Request**

### Development Guidelines
- Follow Flutter best practices
- Maintain code quality with lints
- Write meaningful commit messages
- Add tests for new features
- Update documentation as needed

## 📄 License

This project is distributed under the MIT License. See `LICENSE` for more information.


## 🙏 Acknowledgments

- **Flutter Team**: For the amazing framework
- **Firebase**: For robust backend services
- **FL Chart**: For beautiful data visualization
- **Poppins Font**: For modern typography
- **Open Source Community**: For inspiration and support

---

**Built with ❤️ using Flutter and Firebase**

*Wandersplit - Making travel expenses simple and fair for everyone*
