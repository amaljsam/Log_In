import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'main_screen.dart';
import 'signup_screen.dart';

/// A stateful widget for the login screen.
///
/// This screen provides a user interface for signing in via email/password
/// or phone number, with support for tab-based navigation, password reset,
/// and theme preferences.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

/// The state class for [LoginScreen].
class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  /// Controllers for managing text input from the user.
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();

  /// A key to identify and validate the form.
  final _formKey = GlobalKey<FormState>();

  /// Controller for managing the tab bar and view.
  late TabController _tabController;

  /// Hive box for persisting theme preferences.
  late Box _themeBox;

  /// State variables for managing UI state.
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _verificationId;

  /// Theme state variables and color getters.
  bool _isPurpleTheme = true;
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
    _tabController = TabController(length: 2, vsync: this);
    _themeBox = Hive.box('theme_prefs');
    _loadThemePreference();
  }

  /// Lifecycle method called when the widget is removed from the widget tree.
  /// This is used to dispose of controllers to prevent memory leaks.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _verificationCodeController.dispose();
    _tabController.dispose();
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

  /// Handles email/password sign-in.
  ///
  /// Validates the form, attempts to sign in using Firebase Auth, and
  /// navigates to the main screen on success.
  Future<void> _signInWithEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // Navigate to the main screen on successful login
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        if (e.code == 'user-not-found') {
          errorMessage = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Wrong password provided for that user.';
        } else {
          errorMessage = e.message ?? 'An error occurred. Please try again.';
        }
        _showSnackBar(errorMessage);
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  /// Starts the phone number verification process.
  ///
  /// This method sends an SMS with a verification code to the provided phone number.
  Future<void> _verifyPhoneNumber() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneController.text,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // This callback is called automatically on Android when verification is complete.
          await FirebaseAuth.instance.signInWithCredential(credential);
          _showSnackBar("Login successful!", color: Colors.greenAccent, textColor: Colors.black);
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          _showSnackBar(e.message ?? 'Phone verification failed.');
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _verificationId = verificationId;
            });
          }
          _showSnackBar("A verification code has been sent to your phone.", color: Colors.greenAccent, textColor: Colors.black);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    }
  }

  /// Handles sign-in with the verification code received via SMS.
  ///
  /// This method uses the `verificationId` and the user-entered code to create
  /// a `PhoneAuthCredential` and sign the user in.
  Future<void> _signInWithPhoneCode() async {
    if (_verificationId != null) {
      setState(() {
        _isLoading = true;
      });
      try {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: _verificationCodeController.text.trim(),
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
        _showSnackBar("Login successful!", color: Colors.greenAccent, textColor: Colors.black);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } on FirebaseAuthException catch (e) {
        _showSnackBar(e.message ?? 'Invalid code.');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      _showSnackBar("Please get a verification code first.");
    }
  }

  /// Shows a dialog for password reset.
  ///
  /// Prompts the user to enter their email and sends a password reset link.
  void _showForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();
    bool isSending = false;
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
                'Forgot Password',
                style: GoogleFonts.inter(
                  color: _textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text(
                      'Enter your email to receive a password reset link.',
                      style: GoogleFonts.inter(color: _secondaryTextColor),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: _textColor),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'user@example.com',
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
                    const SizedBox(height: 24.0),
                    Stack(
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(double.infinity, 48.0),
                          ),
                          onPressed: isSending
                              ? null
                              : () async {
                            setStateInDialog(() {
                              isSending = true;
                            });
                            try {
                              await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text.trim());
                              if (mounted) {
                                Navigator.of(context).pop();
                              }
                              _showSnackBar(
                                "Password reset link sent! Check your email.",
                                color: Colors.green,
                              );
                            } on FirebaseAuthException catch (e) {
                              String errorMessage = e.message ?? "Failed to send reset link.";
                              _showSnackBar(errorMessage);
                            } finally {
                              if (mounted) {
                                setStateInDialog(() {
                                  isSending = false;
                                });
                              }
                            }
                          },
                          child: isSending
                              ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                              : Center(
                            child: Text(
                              'Send Reset Link',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 16.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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

  /// Builds the main UI for the login screen.
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
                // Preferences button at the top right
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
                  "Welcome Back!",
                  style: GoogleFonts.inter(
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8.0),
                Text(
                  "Log in to your account",
                  style: GoogleFonts.inter(
                    fontSize: 16.0,
                    color: _secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40.0),

                // Tab bar for switching between email and phone login.
                TabBar(
                  controller: _tabController,
                  indicatorColor: _primaryColor,
                  labelColor: _primaryColor,
                  unselectedLabelColor: _secondaryTextColor,
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'Email'),
                    Tab(text: 'Phone'),
                  ],
                ),
                const SizedBox(height: 24.0),

                SizedBox(
                  height: 450, // Increased height for better layout
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Email Login Tab
                      _buildEmailLogin(),
                      // Phone Login Tab
                      _buildPhoneLogin(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the UI for the email login tab.
  ///
  /// This widget contains the email and password text fields,
  /// a "Forgot Password" button, and the login button.
  Widget _buildEmailLogin() {
    return Column(
      children: [
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
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          style: TextStyle(color: _textColor),
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Enter your password',
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
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters long';
            }
            return null;
          },
        ),
        const SizedBox(height: 8.0),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _showForgotPasswordDialog,
            child: Shimmer.fromColors(
              baseColor: _shimmerBaseColor,
              highlightColor: _shimmerHighlightColor,
              child: Text(
                "Forgot Password?",
                style: GoogleFonts.inter(
                  color: _primaryColor,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24.0),
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
              onPressed: _signInWithEmail,
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
                  'Log In',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 16.0),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24.0),
        // Sign up button added here for consistency
        Shimmer.fromColors(
          baseColor: _shimmerBaseColor,
          highlightColor: _shimmerHighlightColor,
          child: TextButton(
            onPressed: () {
              // Navigate to the signup screen.
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignupScreen()),
              );
            },
            child: RichText(
              text: TextSpan(
                text: "Don't have an account? ",
                style: GoogleFonts.inter(color: _secondaryTextColor),
                children: [
                  TextSpan(
                    text: "Sign Up",
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
    );
  }

  /// Builds the UI for the phone login tab.
  ///
  /// This widget contains a phone number text field, a "Get Verification Code"
  /// button, and a text field for the verification code.
  Widget _buildPhoneLogin() {
    return Column(
      children: [
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: TextStyle(color: _textColor),
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: 'e.g., +1 555-123-4567',
            prefixIcon: Icon(Icons.phone_outlined, color: _secondaryTextColor),
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
              return 'Please enter your phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 24.0),
        Stack(
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
              onPressed: _isLoading ? null : _verifyPhoneNumber,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(double.infinity, 48.0),
              ),
              child: _isLoading
                  ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
                  : Center(
                child: Text(
                  'Get Verification Code',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 16.0),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        if (_verificationId != null) ...[
          TextFormField(
            controller: _verificationCodeController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: _textColor),
            decoration: InputDecoration(
              labelText: 'Verification Code',
              hintText: 'Enter the code from SMS',
              prefixIcon: Icon(Icons.lock_open_outlined, color: _secondaryTextColor),
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
                return 'Please enter the code';
              }
              return null;
            },
          ),
          const SizedBox(height: 24.0),
          Stack(
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
                onPressed: _isLoading ? null : _signInWithPhoneCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(double.infinity, 48.0),
                ),
                child: _isLoading
                    ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
                    : Center(
                  child: Text(
                    'Log In with Phone',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16.0),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24.0),
        // Sign up button added here for consistency
        Shimmer.fromColors(
          baseColor: _shimmerBaseColor,
          highlightColor: _shimmerHighlightColor,
          child: TextButton(
            onPressed: () {
              // Navigate to the signup screen.
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignupScreen()),
              );
            },
            child: RichText(
              text: TextSpan(
                text: "Don't have an account? ",
                style: GoogleFonts.inter(color: _secondaryTextColor),
                children: [
                  TextSpan(
                    text: "Sign Up",
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
    );
  }
}
