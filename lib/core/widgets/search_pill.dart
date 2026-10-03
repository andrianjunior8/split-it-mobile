import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

const _hint = 'Search (For Bills)';

/// Grey rounded search box. Read-only with [onTap] (opens the search
/// screen), or editable when given a [controller].
class SearchPill extends StatelessWidget {
  const SearchPill({
    super.key,
    this.onTap,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  });

  final VoidCallback? onTap;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final hintStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary);

    return Material(
      color: AppColors.inputFill,
      borderRadius: BorderRadius.circular(20),
      elevation: 1,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 36,
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(Icons.search, size: 18, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: onTap != null
                    ? Text(_hint, style: hintStyle)
                    : TextField(
                        controller: controller,
                        autofocus: autofocus,
                        onChanged: onChanged,
                        onSubmitted: onSubmitted,
                        textInputAction: TextInputAction.search,
                        textAlignVertical: TextAlignVertical.center,
                        style: Theme.of(context).textTheme.bodySmall,
                        decoration: InputDecoration(
                          hintText: _hint,
                          hintStyle: hintStyle,
                          filled: false,
                          isCollapsed: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}
