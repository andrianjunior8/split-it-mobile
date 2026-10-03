import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../data/auth_repository.dart';
import 'auth_scaffold.dart';
import 'validators.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final _signUpTap = TapGestureRecognizer()
    ..onTap = () => context.push(Routes.signUp);
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // On success the router redirect takes over navigation.
      await ref
          .read(authRepositoryProvider)
          .signIn(email: _email.text, password: _password.text);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _signUpTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final small = Theme.of(context).textTheme.bodySmall;
    return AuthScaffold(
      title: 'Welcome',
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(hintText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(hintText: 'Password'),
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _submit(),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Password is required' : null,
              ),
            ],
          ),
        ),
        AuthErrorText(_error),
        LoadingButton(label: 'Login', loading: _loading, onPressed: _submit),
        const SizedBox(height: 16),
        Text.rich(
          TextSpan(
            text: "Don't have an account yet? ",
            children: [
              TextSpan(
                text: 'Sign Up',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                recognizer: _signUpTap,
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: small,
        ),
      ],
    );
  }
}
