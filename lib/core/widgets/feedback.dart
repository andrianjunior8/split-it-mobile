import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shows [error] in a snackbar. Repository failures carry user-safe
/// messages via toString().
void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(error.toString()),
        backgroundColor: AppColors.error,
      ),
    );
}

/// Yes/no dialog. Resolves to true only when confirmed.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  String? message,
  String confirmLabel = 'Delete',
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: destructive
              ? TextButton.styleFrom(foregroundColor: AppColors.error)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Single text field dialog. Resolves to the trimmed text, or null if
/// cancelled. [validator] errors are shown inline.
Future<String?> promptText(
  BuildContext context, {
  required String title,
  String? hint,
  String initial = '',
  String submitLabel = 'Save',
  int maxLength = 100,
  String? Function(String value)? validator,
  TextInputType? keyboardType,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _PromptDialog(
      title: title,
      hint: hint,
      initial: initial,
      submitLabel: submitLabel,
      maxLength: maxLength,
      validator: validator,
      keyboardType: keyboardType,
    ),
  );
}

class _PromptDialog extends StatefulWidget {
  const _PromptDialog({
    required this.title,
    required this.hint,
    required this.initial,
    required this.submitLabel,
    required this.maxLength,
    required this.validator,
    required this.keyboardType,
  });

  final String title;
  final String? hint;
  final String initial;
  final String submitLabel;
  final int maxLength;
  final String? Function(String value)? validator;
  final TextInputType? keyboardType;

  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  String? _error;

  void _submit() {
    final value = _controller.text.trim();
    final error = value.isEmpty
        ? 'This field is required'
        : widget.validator?.call(value);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: widget.maxLength,
        keyboardType: widget.keyboardType,
        textCapitalization: TextCapitalization.words,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: widget.hint,
          errorText: _error,
          counterText: '',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: Text(widget.submitLabel)),
      ],
    );
  }
}
