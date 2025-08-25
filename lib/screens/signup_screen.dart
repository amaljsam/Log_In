import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// A stateful widget for the sign-up screen.
///
/// This screen handles user registration, form validation, and data persistence
/// in Firebase Authentication and Firestore. It also includes a theme
/// preference feature using Hive for local storage.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

/// The state class for [SignupScreen].
///
/// Manages the state for text controllers, form keys, loading indicators,
/// and theme preferences.
class _SignupScreenState extends State<SignupScreen> {
  /// Controllers for managing text input from the user.
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  /// A key to identify and validate the form.
  final _formKey = GlobalKey<FormState>();

  /// Hive box for persisting theme preferences.
  late Box _themeBox;

  /// State variables for managing UI state and visibility.
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isPurpleTheme = true;

  /// Theme color getters for dynamic styling.
  Color get _primaryColor => _isPurpleTheme ? const Color(0xFF6A0DAD) : Colors.teal;
  Color get _backgroundColor => _isPurpleTheme ? const Color(0xFF1A1A1A) : Colors.white;
  Color get _textColor => _isPurpleTheme ? Colors.white : Colors.black87;
  Color get _secondaryTextColor => _isPurpleTheme ? Colors.white.withOpacity(0.7) : Colors.black54;
  Color get _shimmerBaseColor => _isPurpleTheme ? Colors.deepPurple : Colors.cyan;
  Color get _shimmerHighlightColor => _isPurpleTheme ? Colors.deepPurpleAccent : Colors.tealAccent;
  Color get _textFieldFillColor => _isPurpleTheme ? const Color(0xFF2E2E2E) : Colors.white;

  /// Lifecycle method called when the widget is inserted into the widget tree.
  @override
  void initState() {
    super.initState();
    _themeBox = Hive.box('theme_prefs');
    _loadThemePreference();
  }

  /// Lifecycle method called when the widget is removed from the widget tree.
  /// This is used to dispose of controllers to prevent memory leaks.
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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

  /// Helper method to display a snack bar with a message.
  ///
  /// The message and colors can be customized.
  void _showSnackBar(String message, {Color color = Colors.redAccent, Color textColor = Colors.white}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.inter(color: textColor),
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Handles the sign-up process with email and password.
  ///
  /// This method validates the form, creates a user in Firebase Authentication,
  /// and saves the user's details to a Firestore collection.
  Future<void> _signUpWithEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        /// Creates a new user with the provided email and password.
        final credential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final user = credential.user;
        if (user != null) {
          try {
            /// Saves the user's details to Firestore.
            /// The document ID is set to the user's UID to ensure a unique entry.
            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
              'uid': user.uid,
              'email': _emailController.text.trim(),
              'username': _usernameController.text.trim(),
              'createdAt': FieldValue.serverTimestamp(),
            });

            _showSnackBar("Account created successfully!",
                color: Colors.greenAccent, textColor: Colors.black);
          } catch (e, st) {
            debugPrint("🔥 Firestore error: $e\n$st");
            _showSnackBar("Firestore save failed: $e");
          }
        }
      } on FirebaseAuthException catch (e) {
        _showSnackBar("Signup failed: ${e.message}");
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  /// Shows a dialog for the user to select their theme preferences.
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

  /// Builds the main UI for the sign-up screen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// Preferences button at the top right.
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
                const SizedBox(height: 40.0),
                Text(
                  "Create an account",
                  style: GoogleFonts.inter(
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8.0),
                Text(
                  "Sign up to get started",
                  style: GoogleFonts.inter(
                    fontSize: 16.0,
                    color: _secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40.0),

                /// Email text field with validation.
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: _textColor),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email address',
                    prefixIcon: Icon(Icons.email_outlined, color: _secondaryTextColor),
                    labelStyle: TextStyle(color: _secondaryTextColor),
                    hintStyle: TextStyle(color: _secondaryTextColor),
                    filled: true,
                    fillColor: _textFieldFillColor,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: _secondaryTextColor, width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: _primaryColor, width: 2.0),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),

                /// Username text field with validation.
                TextFormField(
                  controller: _usernameController,
                  style: TextStyle(color: _textColor),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    hintText: 'Enter your username',
                    prefixIcon: Icon(Icons.person_outline, color: _secondaryTextColor),
                    labelStyle: TextStyle(color: _secondaryTextColor),
                    hintStyle: TextStyle(color: _secondaryTextColor),
                    filled: true,
                    fillColor: _textFieldFillColor,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: _secondaryTextColor, width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: _primaryColor, width: 2.0),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),

                /// Password text field with visibility toggle and validation.
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style: TextStyle(color: _textColor),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Create a password',
                    prefixIcon: Icon(Icons.lock_outline, color: _secondaryTextColor),
                    labelStyle: TextStyle(color: _secondaryTextColor),
                    hintStyle: TextStyle(color: _secondaryTextColor),
                    filled: true,
                    fillColor: _textFieldFillColor,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: _secondaryTextColor, width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: _primaryColor, width: 2.0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: _secondaryTextColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),

                /// Confirm Password text field with validation to match the password.
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  style: TextStyle(color: _textColor),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter your password',
                    prefixIcon: Icon(Icons.lock_outline, color: _secondaryTextColor),
                    labelStyle: TextStyle(color: _secondaryTextColor),
                    hintStyle: TextStyle(color: _secondaryTextColor),
                    filled: true,
                    fillColor: _textFieldFillColor,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: _secondaryTextColor, width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: _primaryColor, width: 2.0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: _secondaryTextColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),

                /// Sign-up button with loading indicator.
                _isLoading
                    ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                )
                    : Stack(
                  children: [
                    Shimmer.fromColors(
                      baseColor: _shimmerBaseColor,
                      highlightColor: _shimmerHighlightColor,
                      child: Container(
                        height: 48.0,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _shimmerBaseColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _signUpWithEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(double.infinity, 48.0),
                      ),
                      child: Center(
                        child: Text(
                          'Sign Up',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 16.0),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24.0),

                /// Button to navigate back to the login screen.
                Shimmer.fromColors(
                  baseColor: _shimmerBaseColor,
                  highlightColor: _shimmerHighlightColor,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Already have an account? ",
                        style: GoogleFonts.inter(color: _secondaryTextColor),
                        children: [
                          TextSpan(
                            text: "Log In",
                            style: GoogleFonts.inter(
                              color: _primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
