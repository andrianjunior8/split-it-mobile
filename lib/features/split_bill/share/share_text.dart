import 'package:intl/intl.dart';

import '../../../core/utils/formatters.dart';
import '../../bills/domain/bill_detail.dart';

final _date = DateFormat('d MMMM yyyy');

/// Plain-text version of the split, sent as the caption next to the image
/// (and readable on its own in chat apps that drop the image).
String buildShareText(BillDetail detail) {
  final result = detail.calculate();
  final names = {for (final p in detail.participants) p.id: p.displayName};
  final b = StringBuffer()
    ..writeln(detail.bill.title)
    ..writeln(_date.format(detail.bill.billDate))
    ..writeln();

  for (final share in result.shares) {
    b.writeln('${names[share.participantId]}: Rp ${formatRupiah(share.total)}');
  }

  b
    ..writeln()
    ..writeln('Total: Rp ${formatRupiah(result.total)}');
  if (result.service > 0 || result.tax > 0) {
    final parts = [
      if (result.service > 0) 'service ${formatBps(detail.bill.serviceBps)}',
      if (result.tax > 0) 'tax ${formatBps(detail.bill.taxBps)}',
    ];
    b.writeln('(incl. ${parts.join(', ')})');
  }
  b.write('Split with SplitIt');
  return b.toString();
}

/// Safe file name for the shared image, e.g. "splitit-makan-makan-kaleyo.png".
String shareFileName(BillDetail detail) {
  final slug = detail.bill.title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final safe = slug.isEmpty ? 'bill' : slug;
  return 'splitit-${safe.length > 40 ? safe.substring(0, 40) : safe}.png';
}
