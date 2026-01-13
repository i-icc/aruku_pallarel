import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../env/env.dart';
import '../../features/authentication/provider/user_profile_provider.dart';
import '../../features/share/services/backend_exception.dart';
import '../../router/app_router.dart';

@RoutePage()
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'test@example.com');
  final _passwordController = TextEditingController(text: 'password123');
  final _nicknameController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (Firebase.apps.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.router.replaceAll(const [BaseRoute()]);
        });
      }
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
      context.router.replaceAll(const [BaseRoute()]);
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
      context.router.replaceAll(const [BaseRoute()]);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 8),
            ],
            ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign In'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _isLoading ? null : _signUp,
              child: const Text('Sign Up'),
            ),
            const SizedBox(height: 12),
            Text(
              'Backend: ${Env.backendBaseUrl}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
