import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/layout/responsive_layout.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../home/providers/shopping_providers.dart';
import 'providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userIdCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _isAdminMode = false;

  String? _validateUserId(String? v) {
    if (v == null || v.trim().isEmpty) return 'User ID is required';
    if (v.trim().length < 2) return 'Enter a valid User ID';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    await ref.read(authProvider.notifier).login(
          userId: _userIdCtrl.text.trim(),
          password: _passCtrl.text,
        );
  }

  void _toggleAdminMode() {
    setState(() {
      _isAdminMode = !_isAdminMode;
      if (_isAdminMode) {
        _userIdCtrl.clear();
        _passCtrl.clear();
      }
    });
  }

  @override
  void dispose() {
    _userIdCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final rememberMe = ref.watch(rememberMeProvider);
    final theme = Theme.of(context);

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        if (next.isAdmin) {
          context.goNamed('admin_dashboard');
          return;
        }
        ref.read(cartProvider.notifier).fetchCart();
        ref.read(wishlistProvider.notifier).fetchWishlist();
        ref.read(addressProvider.notifier).fetchAddresses();
        context.goNamed('home');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: CenteredMaxWidth(
            maxWidth: AppBreakpoints.authFormMaxWidth,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // ── Header with admin mode indicator ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isAdminMode ? 'Admin\nLogin' : 'Welcome\nBack',
                                style: theme.textTheme.displaySmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isAdminMode
                                    ? 'Sign in with your admin ID'
                                    : 'Sign in with your User ID',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isAdminMode)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.admin_panel_settings,
                                    size: 16,
                                    color: theme.colorScheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'ADMIN',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    if (authState.status == AuthStatus.error &&
                        authState.errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: theme.colorScheme.error
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: theme.colorScheme.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authState.errorMessage!,
                                style: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    AppTextField(
                      labelText: _isAdminMode ? 'Admin ID' : 'User ID',
                      hintText: 'bock1',
                      controller: _userIdCtrl,
                      keyboardType: TextInputType.text,
                      validator: _validateUserId,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      validator: _validatePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: rememberMe,
                            onChanged: (v) => ref
                                .read(rememberMeProvider.notifier)
                                .set(v ?? false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Remember Me'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      text: _isAdminMode ? 'Sign In as Admin' : 'Sign In',
                      isLoading: authState.status == AuthStatus.loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 24),

                    // ── Admin / User toggle ──
                    Center(
                      child: TextButton.icon(
                        onPressed: _toggleAdminMode,
                        icon: Icon(
                          _isAdminMode
                              ? Icons.person_outline
                              : Icons.admin_panel_settings_outlined,
                          size: 18,
                        ),
                        label: Text(
                          _isAdminMode
                              ? 'Switch to User Login'
                              : 'Login as Admin',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (!_isAdminMode)
                      Center(
                        child: TextButton(
                          onPressed: () => context.pushNamed('register'),
                          child: RichText(
                            text: TextSpan(
                              text: "Don't have an account? ",
                              style: theme.textTheme.bodyMedium,
                              children: [
                                TextSpan(
                                  text: 'Sign Up',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
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
        ),
      ),
    );
  }
}
