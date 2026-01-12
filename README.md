# Zyro - Build Better Habits

<div align="center">
  <img src="assets/screenshots/logo.jpg" width="120" alt="Zyro Logo" />
</div>

Zyro is a premium, minimalist habit tracker designed to help you build and maintain positive routines. With a focus on simplicity, aesthetics, and privacy, Zyro offers a seamless experience for tracking your daily habits and tasks.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Built%20with-Flutter-02569B?logo=flutter)](https://flutter.dev/)

## 🎨 Design & Experience
Zyro adapts to your style with beautiful **Light** and **Dark** modes.

<div align="center">
  <img src="assets/screenshots/light_dashboard.jpg" width="200" alt="Light Mode" />
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="assets/screenshots/home.jpg" width="200" alt="Dark Mode" />
</div>

## ✍️ Seamless Creation
Easily create new habits or one-off tasks with our intuitive interface.

<div align="center">
  <img src="assets/screenshots/new_habit.jpg" width="200" alt="Create Habit" />
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="assets/screenshots/new_task.jpg" width="200" alt="Create Task" />
</div>

## 📊 Track Your Success
Stay motivated with our **Streak Calendar** and detailed **Progress Analytics**.

<div align="center">
  <img src="assets/screenshots/calendar.jpg" width="200" alt="Streak Calendar" />
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="assets/screenshots/analytics.jpg" width="200" alt="Analytics" />
</div>

## ✨ Key Features

- **Habit & Task Management**: Flexible tracking for daily habits and one-off tasks.
- **Smart Reminders**: Never miss a habit with reliable, exact-time notifications and full-screen alarms.
- **Detailed Analytics**: Visualize your consistency with weekly and monthly progress charts.
- **Streak Calendar**: Keep your momentum going by highlighting your active days.
- **Customizable Icons**: Personalize every habit and task with specific icons.
- **Offline First**: Your data stays on your device. No cloud sync, just complete privacy.

## 🛠 Tech Stack

Zyro is engineered for mobile performance using a modern stack:

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **Local Database**: [Hive](https://pub.dev/packages/hive) (Fast, NoSQL)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Charts**: [fl_chart](https://pub.dev/packages/fl_chart)
- **Notifications**: [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- **Navigation**: [go_router](https://pub.dev/packages/go_router)

### Permissions (Android)
To ensure reliable **Alarms**, we use `SCHEDULE_EXACT_ALARM` and `USE_FULL_SCREEN_INTENT`. These are strictly used to make sure you wake up or get reminded exactly when you want, even if your phone is locked.

## 🚀 Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/pavanbharath15/zyro.apk.git
   ```
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Run the app**:
   ```bash
   flutter run
   ```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
