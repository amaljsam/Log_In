import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shimmer/shimmer.dart';

import 'login_screen.dart';

/// The main application screen widget.
/// This is a stateful widget to manage the user's session,
/// username fetching, and theme preferences.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  /// The currently authenticated user from Firebase Auth.
  final User? currentUser = FirebaseAuth.instance.currentUser;

  /// Hive box for persisting theme preferences.
  late Box _themeBox;

  /// State variables for user data and loading status.
  String? _username;
  bool _isLoadingUsername = true;

  /// Theme state variables and color getters.
  bool _isPurpleTheme = true;
  Color get _primaryColor => _isPurpleTheme ? const Color(0xFF6A0DAD) : Colors.teal;
  Color get _backgroundColor => _isPurpleTheme ? const Color(0xFF1A1A1A) : Colors.white;
  Color get _textColor => _isPurpleTheme ? Colors.white : Colors.black87;
  Color get _secondaryTextColor => _isPurpleTheme ? Colors.white.withOpacity(0.7) : Colors.black54;
  Color get _shimmerBaseColor => _isPurpleTheme ? Colors.deepPurple : Colors.cyan;
  Color get _shimmerHighlightColor => _isPurpleTheme ? Colors.deepPurpleAccent : Colors.tealAccent;

  /// Lifecycle method called when the widget is inserted into the widget tree.
  @override
  void initState() {
    super.initState();
    _themeBox = Hive.box('theme_prefs');
    _loadThemePreference();
    _fetchUsername();
  }

  /// Asynchronously fetches the username from Firestore.
  ///
  /// This method queries the 'users' collection to find a document
  /// where the 'uid' matches the current user's UID.
  Future<void> _fetchUsername() async {
    if (currentUser == null) {
      if (mounted) {
        setState(() {
          _isLoadingUsername = false;
        });
      }
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: currentUser!.uid)
          .limit(1)
          .get();

      if (userDoc.docs.isNotEmpty) {
        final userData = userDoc.docs.first.data();
        if (mounted) {
          setState(() {
            _username = userData['username'];
          });
        }
      }
    } catch (e) {
      // In a production app, this would be a more robust logging solution.
      print("Error fetching username: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUsername = false;
        });
      }
    }
  }

  /// Loads the theme preference from the Hive local storage.
  void _loadThemePreference() {
    final bool? savedTheme = _themeBox.get('isPurpleTheme');
    if (savedTheme != null) {
      if (mounted) {
        setState(() {
          _isPurpleTheme = savedTheme;
        });
      }
    }
  }

  /// Saves the current theme preference to Hive.
  ///
  /// The boolean [isPurple] indicates whether the purple theme is active.
  void _saveThemePreference(bool isPurple) {
    _themeBox.put('isPurpleTheme', isPurple);
  }

  /// Logs the user out of Firebase and navigates back to the login screen.
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        // Use pushReplacement to prevent the user from navigating back to the main screen.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Show an error message if the logout fails.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout Failed: ${e.message}')),
      );
    }
  }

  /// Displays a dialog for the user to select their theme preferences.
  void _showPreferencesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              backgroundColor: _backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: _primaryColor, width: 2),
              ),
              title: Text(
                'Theme Preferences',
                style: GoogleFonts.inter(
                  color: _textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Light Theme', style: GoogleFonts.inter(color: _secondaryTextColor)),
                      Switch(
                        value: _isPurpleTheme,
                        onChanged: (value) {
                          // Update the dialog's state.
                          setStateInDialog(() {
                            _isPurpleTheme = value;
                          });
                          // Update the main widget's state and save the preference.
                          setState(() {
                            _isPurpleTheme = value;
                          });
                          _saveThemePreference(value);
                        },
                        activeColor: _primaryColor,
                        inactiveThumbColor: Colors.grey,
                      ),
                      Text('Dark Theme', style: GoogleFonts.inter(color: _secondaryTextColor)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Builds the main screen UI.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            children: [
              // The row containing the Preferences button, aligned to the right.
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Shimmer.fromColors(
                    baseColor: _shimmerBaseColor,
                    highlightColor: _shimmerHighlightColor,
                    child: TextButton(
                      onPressed: _showPreferencesDialog,
                      child: Text(
                        "Preferences",
                        style: GoogleFonts.inter(
                          color: _primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Main content area, centered vertically.
              SizedBox(
                height: MediaQuery.of(context).size.height - 150,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Welcome text with a shimmer effect.
                      Shimmer.fromColors(
                        baseColor: _shimmerBaseColor,
                        highlightColor: _shimmerHighlightColor,
                        child: Text(
                          "Welcome, ${_username ?? 'User'}!",
                          style: GoogleFonts.inter(
                            fontSize: 32.0,
                            fontWeight: FontWeight.bold,
                            color: _textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      // Sub-text providing context for the user.
                      Text(
                        _isLoadingUsername
                            ? 'Loading your details...'
                            : 'You are successfully logged in with:',
                        style: GoogleFonts.inter(
                          fontSize: 16.0,
                          color: _secondaryTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10.0),
                      // Displaying the user's email.
                      Text(
                        currentUser?.email ?? 'No email available',
                        style: GoogleFonts.inter(
                          fontSize: 16.0,
                          fontStyle: FontStyle.italic,
                          color: _primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24.0),
                      // Logout button section.
                      SizedBox(
                        width: double.infinity,
                        // Using a Stack to place the 'LOGOUT' text over the shimmering ElevatedButton.
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // The shimmering background button.
                            Shimmer.fromColors(
                              baseColor: _shimmerBaseColor,
                              highlightColor: _shimmerHighlightColor,
                              child: ElevatedButton(
                                onPressed: _logout,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                ),
                                child: const SizedBox(
                                  // This empty sized box provides the necessary height for the button.
                                  width: double.infinity,
                                  height: 16,
                                ),
                              ),
                            ),
                            // The text that overlaps the button, ensuring it's always visible.
                            Text(
                              'LOGOUT',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
