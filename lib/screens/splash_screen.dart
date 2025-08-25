import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:login/screens/login_screen.dart';

/// A stateful widget that displays a splash screen for a set duration.
///
/// This widget handles the initial loading animation and navigates to the
/// [LoginScreen] after a minimum of 3 seconds.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// The state class for [SplashScreen].
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    /// Starts a timer to delay navigation.
    ///
    /// This ensures that the splash screen is visible to the user for a
    /// a minimum of three seconds before transitioning to the login screen.
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        /// Replaces the current screen with the login screen.
        ///
        /// [pushReplacement] is used to prevent the user from
        /// navigating back to the splash screen.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  /// Disposes of any resources used by the state.
  @override
  void dispose() {
    super.dispose();
  }

  /// Builds the UI for the splash screen.
  @override
  Widget build(BuildContext context) {
    /// The main scaffold for the screen.
    return Scaffold(
      /// Centers the content on the screen.
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// Displays the Lottie animation from the assets folder.
            Lottie.asset(
              'assets/animations/splash_lottie.json',
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),

          ],
        ),
      ),
    );
  }
}
