import 'package:intl/intl.dart';

final _rupiah = NumberFormat.decimalPattern('id_ID');

/// 86300 → "86.300". Add the "Rp" prefix where the design shows it.
String formatRupiah(int amount) => _rupiah.format(amount);

/// 1000 basis points → "10%", 1250 → "12,5%".
String formatBps(int bps) =>
    '${NumberFormat.decimalPattern('id_ID').format(bps / 100)}%';
