import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  List<String> _recentEmails = [];

  @override
  void initState() {
    super.initState();
    _loadRecentEmails();
  }

  void _loadRecentEmails() {
    setState(() {
      _recentEmails = HiveStorage.recentEmails;
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    final email = _emailCtrl.text.trim();
    HiveStorage.saveRecentEmail(email);
    _loadRecentEmails();
    context.read<AuthBloc>().add(
      LoginSubmitted(
        email: email,
        password: _passwordCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          HiveStorage.saveRecentEmail(_emailCtrl.text.trim());
          context.go(AppRoutes.dashboard);
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Soft ambient glow orbs in the background
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.04),
                ),
              ),
            ),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Top flexible spacer to center form vertically
                              const Spacer(flex: 3),

                              // Brand logo (centered)
                              Center(
                                child:
                                    Image.asset(
                                          'assets/icons/gov_icon.png',
                                          width: 180,
                                          fit: BoxFit.contain,
                                        )
                                        .animate()
                                        .fadeIn(duration: 600.ms)
                                        .scale(
                                          begin: const Offset(0.9, 0.9),
                                          duration: 700.ms,
                                          curve: Curves.easeOut,
                                        ),
                              ),

                              const SizedBox(height: 32),

                              // Welcome back header (centered)
                              Center(
                                child: Column(
                                  children: [
                                    Text(
                                      'Welcome back',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(
                                        color: AppColors.secondary,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sign in to continue',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF64748B),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Email field
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildLabel('Email Address'),
                                  if (_recentEmails.isNotEmpty)
                                    PopupMenuButton<String>(
                                      tooltip: 'Recent Emails',
                                      color: Colors.white,
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      onSelected: (email) {
                                        setState(() {
                                          _emailCtrl.text = email;
                                        });
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem<String>(
                                          enabled: false,
                                          height: 32,
                                          child: Text(
                                            'Recent Accounts (${_recentEmails.length}/5)',
                                            style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ),
                                        ..._recentEmails.map(
                                          (email) => PopupMenuItem<String>(
                                            value: email,
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.history_rounded,
                                                  size: 16,
                                                  color: AppColors.primary,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    email,
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          AppColors.secondary,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.history_rounded,
                                              size: 14,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Recent (${_recentEmails.length})',
                                              style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const Icon(
                                              Icons.arrow_drop_down_rounded,
                                              size: 18,
                                              color: AppColors.primary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _emailCtrl,
                                hintText: 'you@company.com',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                suffixIcon: _recentEmails.isNotEmpty
                                    ? PopupMenuButton<String>(
                                        tooltip: 'Select from recent emails',
                                        icon: const Icon(
                                          Icons.arrow_drop_down_circle_outlined,
                                          color: Color(0xFF94A3B8),
                                          size: 20,
                                        ),
                                        color: Colors.white,
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          side: const BorderSide(
                                            color: Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        onSelected: (email) {
                                          setState(() {
                                            _emailCtrl.text = email;
                                          });
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem<String>(
                                            enabled: false,
                                            height: 32,
                                            child: Text(
                                              'Select Recent Email',
                                              style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ),
                                          ..._recentEmails.map(
                                            (email) => PopupMenuItem<String>(
                                              value: email,
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.history_rounded,
                                                    size: 16,
                                                    color: AppColors.primary,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      email,
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: AppColors
                                                            .secondary,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : null,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!v.contains('@')) {
                                    return 'Invalid email address';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 18),

                              // Password field
                              _buildLabel('Password'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _passwordCtrl,
                                hintText: '••••••••',
                                prefixIcon: Icons.lock_outline_rounded,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF64748B),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (v.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 14),

                              // Remember me & Forgot Password row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  InkWell(
                                    onTap: () => setState(
                                      () => _rememberMe = !_rememberMe,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            activeColor: AppColors.primary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFFCBD5E1),
                                              width: 1.5,
                                            ),
                                            onChanged: (v) => setState(
                                              () => _rememberMe = v ?? false,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Remember me',
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF64748B),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .hideCurrentSnackBar();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          backgroundColor: Colors.transparent,
                                          elevation: 0,
                                          behavior: SnackBarBehavior.floating,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 12,
                                          ),
                                          duration: const Duration(seconds: 6),
                                          content: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: const Color(0xFFE2E8F0),
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.10),
                                                  blurRadius: 18,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    7,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary
                                                        .withValues(alpha: 0.12),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.info_outline_rounded,
                                                    color: AppColors.primary,
                                                    size: 18,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        'Default Credentials',
                                                        style:
                                                            GoogleFonts.outfit(
                                                              color: AppColors
                                                                  .secondary,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              fontSize: 13,
                                                            ),
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        'Default role password: PropCare@123. Contact CRRM admin for credentials.',
                                                        style:
                                                            GoogleFonts.outfit(
                                                              color: const Color(
                                                                0xFF64748B,
                                                              ),
                                                              fontSize: 12,
                                                              height: 1.45,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                GestureDetector(
                                                  onTap: () =>
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).hideCurrentSnackBar(),
                                                  child: const Icon(
                                                    Icons.close_rounded,
                                                    color: Color(0xFF94A3B8),
                                                    size: 18,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Forgot Password?',
                                      style: GoogleFonts.outfit(
                                        color: AppColors.primaryDark,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 22),

                              // Sign In button with arrow icon
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  final isLoading = state is AuthLoading;
                                  return GestureDetector(
                                    onTap: isLoading ? null : _submit,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      height: 54,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            AppColors.primary,
                                            AppColors.primaryDark,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.35,
                                            ),
                                            blurRadius: 18,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: isLoading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2.5,
                                                    ),
                                              )
                                            : Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'Sign In',
                                                    style: GoogleFonts.outfit(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      letterSpacing: 0.3,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Icon(
                                                    Icons.arrow_forward_rounded,
                                                    color: Colors.white,
                                                    size: 19,
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 24),

                              // Need access / Contact admin
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Need portal access? ',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF64748B),
                                      fontSize: 13,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Please contact your PropCare Governance Administrator for access.',
                                          ),
                                          backgroundColor: AppColors.secondary,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Contact Admin',
                                      style: GoogleFonts.outfit(
                                        color: AppColors.primaryDark,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Bottom flexible spacer to keep content centered
                              const Spacer(flex: 3),

                              const SizedBox(height: 20),

                              // Footer
                              Center(
                                child: Text(
                                  '© 2024 Casa Grande PropCare Governance',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF94A3B8),
                                    fontSize: 11,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        color: AppColors.secondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.outfit(
        color: AppColors.secondary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.outfit(
          color: const Color(0xFF94A3B8),
          fontSize: 15,
        ),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF64748B), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: GoogleFonts.outfit(color: AppColors.error, fontSize: 12),
      ),
    );
  }
}
