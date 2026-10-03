import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'formatters.dart';

/// Formats typed digits as rupiah ("25000" → "25.000"). Caps at 12 digits.
class RupiahInputFormatter extends TextInputFormatter {
  static const maxDigits = 12;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return TextEditingValue.empty;
    if (digits.length > maxDigits) return oldValue;
    final text = formatRupiah(int.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// "25.000" → 25000. Null when there are no digits.
int? parseRupiah(String text) {
  final digits = text.replaceAll(RegExp(r'\D'), '');
  return digits.isEmpty ? null : int.parse(digits);
}

/// "10" / "12,5" / "12.5" → basis points (1000 / 1250). Null if not a
/// number between 0 and 100. Empty input means 0.
int? parsePercentToBps(String text) {
  final t = text.trim().replaceAll('%', '').replaceAll(',', '.');
  if (t.isEmpty) return 0;
  final value = double.tryParse(t);
  if (value == null || value < 0 || value > 100) return null;
  return (value * 100).round();
}

/// 1250 → "12,5" for pre-filling a percent field.
String bpsToInput(int bps) => NumberFormat('0.##', 'id_ID').format(bps / 100);
