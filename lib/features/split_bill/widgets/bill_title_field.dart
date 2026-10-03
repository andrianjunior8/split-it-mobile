import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/feedback.dart';
import '../../bills/presentation/bill_editor_controller.dart';

/// Big underlined bill title with a pencil, as in the design. The host
/// edits it in place; it saves on submit or when focus leaves.
class BillTitleField extends ConsumerStatefulWidget {
  const BillTitleField({super.key, required this.billId});

  final String billId;

  @override
  ConsumerState<BillTitleField> createState() => _BillTitleFieldState();
}

class _BillTitleFieldState extends ConsumerState<BillTitleField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  String get _stored =>
      ref.read(billEditorProvider(widget.billId)).requireValue.bill.title;

  @override
  void initState() {
    super.initState();
    _controller.text = _stored;
    _focus.addListener(() {
      if (!_focus.hasFocus) _save();
    });
  }

  Future<void> _save() async {
    // Focus also drops while the screen is being torn down.
    if (!mounted) return;
    final title = _controller.text.trim();
    if (title.isEmpty) {
      _controller.text = _stored;
      return;
    }
    try {
      await ref.read(billEditorProvider(widget.billId).notifier).rename(title);
    } catch (e) {
      if (!mounted) return;
      _controller.text = _stored;
      showError(context, e);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = ref.watch(isBillHostProvider(widget.billId));

    // Keep in sync with saves made elsewhere while not being edited.
    ref.listen(billEditorProvider(widget.billId), (_, next) {
      final title = next.value?.bill.title;
      if (title != null && !_focus.hasFocus && _controller.text != title) {
        _controller.text = title;
      }
    });

    return TextField(
      controller: _controller,
      focusNode: _focus,
      readOnly: !canEdit,
      maxLength: 100,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _focus.unfocus(),
      style: Theme.of(context).textTheme.headlineSmall,
      decoration: InputDecoration(
        filled: false,
        counterText: '',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        border: const UnderlineInputBorder(),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.placeholder, width: 2),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        suffixIcon: canEdit
            ? IconButton(
                onPressed: _focus.requestFocus,
                tooltip: 'Rename',
                icon: const Icon(Icons.edit_outlined, size: 20),
              )
            : null,
      ),
    );
  }
}
