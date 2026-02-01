import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/authentication/provider/user_profile_provider.dart';
import '../../features/share/services/backend_exception.dart';
import '../../router/app_router.dart';
import '../../theme/app_styles.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_primary_button.dart';

@RoutePage()
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (Firebase.apps.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          return;
        }
        try {
          final token = await user.getIdToken().timeout(
                const Duration(seconds: 8),
              );
          if (token == null || token.isEmpty) {
            await FirebaseAuth.instance.signOut();
            return;
          }
        } catch (_) {
          await FirebaseAuth.instance.signOut();
          return;
        }
        if (!mounted) {
          return;
        }
        context.router.replaceAll(const [HomeRoute()]);
      });
    }
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final nickname = _resolveNickname();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await ref
          .read(userProfileNotifierProvider.notifier)
          .refreshProfile(fallbackNickname: nickname);
      if (!mounted) {
        return;
      }
      context.router.replaceAll(const [HomeRoute()]);
    } on FirebaseAuthException catch (error) {
      setState(() {
        _error = error.message ?? 'Login failed.';
      });
    } on BackendException catch (error) {
      setState(() {
        _error = error.message;
      });
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final nickname = _resolveNickname();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await ref
          .read(userProfileNotifierProvider.notifier)
          .refreshProfile(fallbackNickname: nickname);
      if (!mounted) {
        return;
      }
      context.router.replaceAll(const [HomeRoute()]);
    } on FirebaseAuthException catch (error) {
      setState(() {
        _error = error.message ?? 'Sign up failed.';
      });
    } on BackendException catch (error) {
      setState(() {
        _error = error.message;
      });
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  String _resolveNickname() {
    final nickname = _nicknameController.text.trim();
    if (nickname.isNotEmpty) {
      return nickname;
    }
    final email = _emailController.text.trim();
    final atIndex = email.indexOf('@');
    if (atIndex > 0) {
      return email.substring(0, atIndex);
    }
    return 'user';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: AppBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sign in',
                  style: theme.textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Keep your walking timeline in sync.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nicknameController,
                        decoration: const InputDecoration(
                          labelText: 'Nickname (Sign Up)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(AppRadii.small),
                            border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _error!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      AppPrimaryButton(
                        label: 'Sign In',
                        icon: Icons.login,
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _signIn,
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: _isLoading ? null : _signUp,
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
