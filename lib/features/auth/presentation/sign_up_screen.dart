import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_repository.dart';
import 'auth_scaffold.dart';
import 'validators.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _username = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // On success the router redirect moves on to the Register step.
      await ref
          .read(authRepositoryProvider)
          .signUp(
            email: _email.text,
            password: _password.text,
            username: _username.text,
          );
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
    _username.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Sign Up',
      onBack: () => context.pop(),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(
                  hintText: 'Email (Sign@gmail.com)',
                ),
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
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: Validators.password,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(hintText: 'Username'),
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newUsername],
                onFieldSubmitted: (_) => _submit(),
                validator: Validators.username,
              ),
            ],
          ),
        ),
        AuthErrorText(_error),
        LoadingButton(label: 'Sign Up', loading: _loading, onPressed: _submit),
      ],
    );
  }
}
