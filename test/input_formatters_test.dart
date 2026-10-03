import 'package:flutter_test/flutter_test.dart';
import 'package:splitit/core/utils/input_formatters.dart';

void main() {
  group('RupiahInputFormatter', () {
    final f = RupiahInputFormatter();
    TextEditingValue type(String text, {String old = ''}) => f.formatEditUpdate(
      TextEditingValue(text: old),
      TextEditingValue(text: text),
    );

    test('adds thousand separators and keeps the cursor at the end', () {
      final v = type('25000');
      expect(v.text, '25.000');
      expect(v.selection.baseOffset, 6);
    });

    test('ignores non-digits and leading zeros', () {
      expect(type('Rp 0012a3').text, '123');
    });

    test('clears to empty', () {
      expect(type('').text, '');
    });

    test('rejects more than 12 digits', () {
      expect(
        type('1234567890123', old: '123.456.789.012').text,
        '123.456.789.012',
      );
    });
  });

  test('parseRupiah', () {
    expect(parseRupiah('1.637.690'), 1637690);
    expect(parseRupiah(''), isNull);
  });

  test('parsePercentToBps', () {
    expect(parsePercentToBps('10'), 1000);
    expect(parsePercentToBps('12,5'), 1250);
    expect(parsePercentToBps('5.5%'), 550);
    expect(parsePercentToBps(''), 0);
    expect(parsePercentToBps('101'), isNull);
    expect(parsePercentToBps('-1'), isNull);
    expect(parsePercentToBps('abc'), isNull);
  });

  test('bpsToInput', () {
    expect(bpsToInput(1000), '10');
    expect(bpsToInput(1250), '12,5');
    expect(bpsToInput(0), '0');
  });
}
