import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/circle_next_button.dart';
import '../data/auth_repository.dart';
import 'auth_scaffold.dart';
import 'validators.dart';

/// Profile step after Sign Up: display name and optional photo.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  File? _photo;
  bool _loading = false;
  String? _error;

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _save({required bool skip}) async {
    final repo = ref.read(authRepositoryProvider);
    if (!skip && !_formKey.currentState!.validate()) return;
    final name = skip ? repo.currentUser!.defaultName : _name.text;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Once the user has a name the router redirect sends them home.
      await repo.updateProfile(name: name, avatar: skip ? null : _photo);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600);

    return AuthScaffold(
      title: 'Register',
      bottom: Row(
        children: [
          TextButton(
            onPressed: _loading ? null : () => _save(skip: true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              padding: EdgeInsets.zero,
            ),
            child: const Text('Skip'),
          ),
          const Spacer(),
          CircleNextButton(
            loading: _loading,
            onPressed: () => _save(skip: false),
          ),
        ],
      ),
      children: [
        Text('Name', style: label),
        const SizedBox(height: 6),
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _name,
            decoration: const InputDecoration(hintText: 'Ex:Name'),
            textCapitalization: TextCapitalization.words,
            validator: Validators.required,
          ),
        ),
        const SizedBox(height: 24),
        Text('Photo', style: label),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: _loading ? null : _pickPhoto,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.placeholder,
              backgroundImage: _photo != null ? FileImage(_photo!) : null,
              child: _photo == null
                  ? const Icon(Icons.add, size: 72, color: Colors.white)
                  : null,
            ),
          ),
        ),
        AuthErrorText(_error),
      ],
    );
  }
}
