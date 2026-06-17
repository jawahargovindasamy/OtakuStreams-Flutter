import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';

// COMMON LOGO WIDGET
Widget _buildLogo(BuildContext context) {
  return Column(
    children: [
      Image.asset(
        'assets/Logo Light.png',
        height: 44,
        fit: BoxFit.contain,
      ),
      const SizedBox(height: 8),
      const Text(
        'Your gateway to infinite worlds',
        style: TextStyle(
          color: Color(0xFF94A3B8), // slate-400
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
      ),
    ],
  );
}

// COMMON BACKDROP CONTAINER
Widget _buildAuthBackdrop({required Widget child}) {
  return Stack(
    children: [
      // 1. Background image
      Positioned.fill(
        child: Image.asset(
          'assets/Hero Img.webp',
          fit: BoxFit.cover,
        ),
      ),
      // 2. Dim and vignette overlay
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.85),
                Colors.black.withValues(alpha: 0.5),
                Colors.black.withValues(alpha: 0.95),
              ],
            ),
          ),
        ),
      ),
      // 3. Subtle accent glows
      Positioned(
        top: -80,
        left: -80,
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF3B82F6).withValues(alpha: 0.15), // Blue glow
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
            child: const SizedBox.shrink(),
          ),
        ),
      ),
      Positioned(
        bottom: -80,
        right: -80,
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF6366F1).withValues(alpha: 0.12), // Indigo glow
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
            child: const SizedBox.shrink(),
          ),
        ),
      ),
      // 4. Actual content scrollable
      Positioned.fill(
        child: child,
      ),
    ],
  );
}

// COMMON GLASS CARD CONTAINER
Widget _buildGlassCard(BuildContext context, {required List<Widget> children}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.65), // Translucent dark slate
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              offset: const Offset(0, 12),
            )
          ],
        ),
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    ),
  );
}

// COMMON INPUT DECORATION
InputDecoration _buildInputDecoration({
  required String hintText,
  required Widget prefixIcon,
  Widget? suffixIcon,
  String? errorText,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
    prefixIcon: prefixIcon,
    prefixIconColor: const Color(0xFF94A3B8),
    suffixIcon: suffixIcon,
    suffixIconColor: const Color(0xFF94A3B8),
    errorText: errorText,
    errorStyle: const TextStyle(color: Color(0xFFF87171), fontSize: 11),
    fillColor: Colors.black.withValues(alpha: 0.35),
    filled: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFF87171)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.5),
    ),
  );
}

// COMMON GRADIENT BUTTON
Widget _buildGradientButton({
  required VoidCallback? onPressed,
  required Widget child,
  bool isLoading = false,
}) {
  return Container(
    width: double.infinity,
    height: 50,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF6366F1)], // Blue to Indigo
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    ),
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: EdgeInsets.zero,
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : child,
    ),
  );
}

// COMMON SOCIAL SIGN IN SECTION
Widget _buildSocialLoginSection(BuildContext context) {
  return Column(
    children: [
      const SizedBox(height: 24),
      Row(
        children: [
          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08))),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'OR SIGN IN WITH',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08))),
        ],
      ),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: _buildSocialButton(
              icon: LucideIcons.chrome,
              label: 'Google',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Google Authentication is not configured for this demo.'),
                    backgroundColor: Color(0xFF1E293B),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSocialButton(
              icon: LucideIcons.apple,
              label: 'Apple',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Apple Authentication is not configured for this demo.'),
                    backgroundColor: Color(0xFF1E293B),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _buildSocialButton({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );
}

// LOGIN SCREEN
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  String? _generalError;
  final Map<String, String> _errors = {};

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _generalError = null;
      _errors.clear();
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) _errors['email'] = 'Email is required';
    if (password.isEmpty) _errors['password'] = 'Password is required';

    if (_errors.isNotEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await auth.apiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
        await auth.login(response.data['data']);
        if (mounted) {
          context.go('/home');
        }
      } else {
        setState(() {
          _generalError = response.data?['message'] ?? 'Login failed';
        });
      }
    } catch (e) {
      debugPrint('Login error: $e');
      setState(() {
        _generalError = 'Invalid email or password. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildAuthBackdrop(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(context),
                const SizedBox(height: 32),
                _buildGlassCard(
                  context,
                  children: [
                    const Center(
                      child: Text(
                        'Welcome Back',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        'Enter your credentials to continue watching',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_generalError != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.alertTriangle, color: Color(0xFFF87171), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _generalError!,
                                style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Email Field
                    const Text('Email Address', style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: _buildInputDecoration(
                        hintText: 'shinji@nerv.com',
                        prefixIcon: const Icon(LucideIcons.mail, size: 18),
                        errorText: _errors['email'],
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Password Field
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Password', style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, fontWeight: FontWeight.w500)),
                        GestureDetector(
                          onTap: () => context.push('/forgot-password'),
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(color: Color(0xFF60A5FA), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: _buildInputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(LucideIcons.lock, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(_showPassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 18),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                        errorText: _errors['password'],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Sign In Button
                    _buildGradientButton(
                      onPressed: _handleLogin,
                      isLoading: _isLoading,
                      child: const Text(
                        'Sign In',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    _buildSocialLoginSection(context),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                    GestureDetector(
                      onTap: () => context.push('/register'),
                      child: const Text(
                        'Create account',
                        style: TextStyle(color: Color(0xFF60A5FA), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// REGISTER SCREEN
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  String? _generalError;
  final Map<String, String> _errors = {};

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() {
      _isLoading = true;
      _generalError = null;
      _errors.clear();
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty) _errors['username'] = 'Username is required';
    if (email.isEmpty) _errors['email'] = 'Email is required';
    if (password.isEmpty) _errors['password'] = 'Password is required';

    if (_errors.isNotEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await auth.apiClient.dio.post('/auth/register', data: {
        'username': username,
        'email': email,
        'password': password,
      });

      if (response.statusCode == 201 && response.data != null && response.data['success'] == true) {
        await auth.login(response.data['data']);
        if (mounted) {
          context.go('/home');
        }
      } else {
        setState(() {
          _generalError = response.data?['message'] ?? 'Registration failed';
        });
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      setState(() {
        _generalError = 'Registration failed. Email might already be in use.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildAuthBackdrop(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(context),
                const SizedBox(height: 32),
                _buildGlassCard(
                  context,
                  children: [
                    const Center(
                      child: Text(
                        'Create Account',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        'Join us and start watching your favorite anime',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_generalError != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.alertTriangle, color: Color(0xFFF87171), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _generalError!,
                                style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Username Field
                    const Text('Username', style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: _buildInputDecoration(
                        hintText: 'shinji_ikari',
                        prefixIcon: const Icon(LucideIcons.user, size: 18),
                        errorText: _errors['username'],
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Email Field
                    const Text('Email Address', style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: _buildInputDecoration(
                        hintText: 'shinji@nerv.com',
                        prefixIcon: const Icon(LucideIcons.mail, size: 18),
                        errorText: _errors['email'],
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Password Field
                    const Text('Password', style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: _buildInputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(LucideIcons.lock, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(_showPassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 18),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                        errorText: _errors['password'],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Register Button
                    _buildGradientButton(
                      onPressed: _handleRegister,
                      isLoading: _isLoading,
                      child: const Text(
                        'Create Account',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? ", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(color: Color(0xFF60A5FA), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// FORGOT PASSWORD SCREEN
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    setState(() {
      _isLoading = true;
      _successMessage = null;
      _errorMessage = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Email address is required';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await auth.apiClient.dio.post('/auth/forgot-password', data: {
        'email': email,
      });

      if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
        setState(() {
          _successMessage = 'A password reset link has been sent to your email.';
        });
      } else {
        setState(() {
          _errorMessage = response.data?['message'] ?? 'Failed to send reset link.';
        });
      }
    } catch (e) {
      debugPrint('Reset error: $e');
      setState(() {
        _errorMessage = 'Error occurred. Please verify your email address.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildAuthBackdrop(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(context),
                const SizedBox(height: 32),
                _buildGlassCard(
                  context,
                  children: [
                    const Center(
                      child: Text(
                        'Reset Password',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        'Enter your email to receive a password reset link',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_successMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.checkCircle, color: Color(0xFF34D399), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.alertTriangle, color: Color(0xFFF87171), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Email Field
                    const Text('Email Address', style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: _buildInputDecoration(
                        hintText: 'shinji@nerv.com',
                        prefixIcon: const Icon(LucideIcons.mail, size: 18),
                        errorText: _errorMessage != null ? '' : null,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Submit Button
                    _buildGradientButton(
                      onPressed: _handleReset,
                      isLoading: _isLoading,
                      child: const Text(
                        'Send Reset Link',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.arrowLeft, color: Color(0xFF60A5FA), size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Back to Sign In',
                        style: TextStyle(color: Color(0xFF60A5FA), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
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
}
