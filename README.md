# Flutter Authentication & Theming Starter Kit

A comprehensive and production-ready Flutter starter kit featuring a complete, end-to-end user authentication system with dynamic theming. This project is a perfect boilerplate for developers looking to build a secure, scalable, and beautifully designed application.

## ✨ Features

* **🔒 Complete Authentication Flow:** Secure sign-up and login with Firebase Authentication, supporting both email/password and phone number options.

* **🎨 Dynamic Theming:** Users can seamlessly switch between a modern dark/purple theme and a clean light/teal theme.

* **💾 Local Data Persistence:** User theme preferences are saved locally across sessions using the Hive NoSQL database.

* **☁️ Cloud Firestore Integration:** User data, such as usernames, is securely stored and retrieved from a Firestore collection.

* **🔄 Stateful UI:** The app's UI is dynamically updated based on the authentication state and data fetching status.

* **🖼️ Polished UX:** Includes Lottie animations for a smooth splash screen and a shimmering effect on buttons for a premium feel.

* **✅ Robust Form Validation:** Ensures data integrity with comprehensive validation on all input fields.

## 🛠️ Technologies

* **Flutter:** The UI toolkit used to build the application.

* **Firebase:** Provides backend services for Authentication and Firestore.

* **Hive:** A lightweight, fast, and secure local storage solution.

* **Lottie:** Used for smooth, high-quality animations.

* **Google Fonts:** For consistent and professional typography.

## 🚀 Getting Started

Follow these steps to get the project up and running on your local machine.

### Prerequisites

* **Flutter SDK:** [Install Flutter](https://flutter.dev/docs/get-started/install)

* **Firebase CLI:** [Install the Firebase CLI](https://firebase.google.com/docs/cli)

* **IDE:** Visual Studio Code or Android Studio with Flutter and Dart plugins.

### Installation

1. **Clone the repository:**

   ```
   git clone [https://github.com/amaljsam/Log_In.git](https://github.com/amaljsam/Log_In.git)
   cd Log_In
   
   ```

2. **Install dependencies:**

   ```
   flutter pub get
   
   ```

3. **Set up Firebase:**

   * Create a new Firebase project in the [Firebase Console](https://console.firebase.google.com/).

   * Enable **Email/Password** and **Phone Number** authentication providers.

   * Create a Firestore database.

   * From your terminal, use the FlutterFire CLI to link your Firebase project to your Flutter app. This will automatically generate the `lib/firebase_options.dart` file and the necessary configuration for Android and iOS.

   ```
   flutterfire configure
   
   ```

4. **Run the app:**

   ```
   flutter run
   
   ```

## 🤝 Contributing

Contributions are what make the open-source community an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this project better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".

1. Fork the Project

2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)

3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)

4. Push to the Branch (`git push origin feature/AmazingFeature`)

5. Open a Pull Request


## 📞 Contact

Amal J Sam - amaljsamruwi@gmail.com

Project Link: [https://github.com/amaljsam/Log_In](https://github.com/amaljsam/Log_In)
