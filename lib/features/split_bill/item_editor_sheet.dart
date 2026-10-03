import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/input_formatters.dart';
import '../../core/widgets/feedback.dart';
import '../bills/domain/bill.dart';
import '../bills/presentation/bill_editor_controller.dart';

/// Opens the add/edit menu item sheet. [item] null = new item.
Future<void> showItemEditor(
  BuildContext context, {
  required String billId,
  required List<Participant> participants,
  BillItem? item,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) =>
        _ItemEditor(billId: billId, participants: participants, item: item),
  );
}

class _ItemEditor extends ConsumerStatefulWidget {
  const _ItemEditor({
    required this.billId,
    required this.participants,
    required this.item,
  });

  final String billId;
  final List<Participant> participants;
  final BillItem? item;

  @override
  ConsumerState<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends ConsumerState<_ItemEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.item?.name);
  late final _qty = TextEditingController(text: '${widget.item?.qty ?? 1}');
  late final _price = TextEditingController(
    text: widget.item == null ? '' : formatRupiah(widget.item!.unitPrice),
  );
  late final _discount = TextEditingController(
    text: (widget.item?.discount ?? 0) > 0
        ? formatRupiah(widget.item!.discount)
        : '',
  );
  // Participants who share this item; empty = everyone.
  late final Set<String> _sharedBy = {...?widget.item?.shares.keys};
  bool _saving = false;

  int get _qtyValue => int.tryParse(_qty.text) ?? 0;
  int get _priceValue => parseRupiah(_price.text) ?? 0;
  int get _discountValue => parseRupiah(_discount.text) ?? 0;
  int get _total => _qtyValue * _priceValue - _discountValue;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final existing = widget.item;
    final item = BillItem(
      id: existing?.id ?? '',
      billId: widget.billId,
      name: _name.text.trim(),
      qty: _qtyValue,
      unitPrice: _priceValue,
      discount: _discountValue,
      position: existing?.position ?? 0,
    );
    // Keep custom weights for people who stay selected.
    final shares = {for (final id in _sharedBy) id: existing?.shares[id] ?? 1};
    try {
      await ref
          .read(billEditorProvider(widget.billId).notifier)
          .saveItem(item, shares);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showError(context, e);
      }
    }
  }

  Future<void> _delete() async {
    final item = widget.item!;
    final ok = await confirm(context, title: 'Delete ${item.name}?');
    if (!ok || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(billEditorProvider(widget.billId).notifier)
          .deleteItem(item.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showError(context, e);
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    _price.dispose();
    _discount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final label = text.bodySmall?.copyWith(fontWeight: FontWeight.w600);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    Widget field(String title, Widget input) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: label),
          const SizedBox(height: 6),
          input,
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 16 + bottomInset),
      child: Form(
        key: _formKey,
        // Recompute the total preview as the user types.
        onChanged: () => setState(() {}),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item == null ? 'Add Menu' : 'Edit Menu',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              field(
                'Name',
                TextFormField(
                  controller: _name,
                  autofocus: widget.item == null,
                  maxLength: 100,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Paket Bebek + Nasi',
                    counterText: '',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: field(
                      'Qty',
                      TextFormField(
                        controller: _qty,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        validator: (_) => _qtyValue < 1 ? 'Min 1' : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: field(
                      'Price (each)',
                      TextFormField(
                        controller: _price,
                        keyboardType: TextInputType.number,
                        inputFormatters: [RupiahInputFormatter()],
                        decoration: const InputDecoration(prefixText: 'Rp '),
                        validator: (v) => parseRupiah(v ?? '') == null
                            ? 'Price is required'
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              field(
                'Discount (total for this item)',
                TextFormField(
                  controller: _discount,
                  keyboardType: TextInputType.number,
                  inputFormatters: [RupiahInputFormatter()],
                  decoration: const InputDecoration(
                    prefixText: 'Rp ',
                    hintText: '0',
                  ),
                  validator: (_) => _discountValue > _qtyValue * _priceValue
                      ? 'Discount is more than the price'
                      : null,
                ),
              ),
              Text('Split by', style: label),
              const SizedBox(height: 2),
              Text(
                _sharedBy.isEmpty
                    ? 'Nobody selected: split equally by everyone.'
                    : 'Only the selected people pay for this.',
                style: text.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final p in widget.participants)
                    FilterChip(
                      label: Text(p.displayName),
                      selected: _sharedBy.contains(p.id),
                      onSelected: (on) => setState(
                        () => on ? _sharedBy.add(p.id) : _sharedBy.remove(p.id),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Total', style: text.titleSmall),
                  const Spacer(),
                  Text(
                    'Rp ${formatRupiah(_total < 0 ? 0 : _total)}',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (widget.item != null)
                    TextButton(
                      onPressed: _saving ? null : _delete,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: const Text('Delete'),
                    ),
                  const Spacer(),
                  SizedBox(
                    width: 140,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
