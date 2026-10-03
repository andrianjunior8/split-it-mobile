import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/feedback.dart';
import '../../bills/domain/bill_detail.dart';
import '../widgets/bill_step_scaffold.dart';
import 'bill_receipt.dart';
import 'share_text.dart';

/// Preview of the receipt image, with a button that shares it.
class ShareBillScreen extends ConsumerStatefulWidget {
  const ShareBillScreen({super.key, required this.billId});

  final String billId;

  @override
  ConsumerState<ShareBillScreen> createState() => _ShareBillScreenState();
}

class _ShareBillScreenState extends ConsumerState<ShareBillScreen> {
  final _receiptKey = GlobalKey();
  final _buttonKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share(BillDetail detail) async {
    setState(() => _sharing = true);
    try {
      final png = await _capture();
      final params = ShareParams(
        text: buildShareText(detail),
        subject: detail.bill.title,
        files: [XFile.fromData(png, mimeType: 'image/png')],
        fileNameOverrides: [shareFileName(detail)],
        sharePositionOrigin: _buttonRect(),
      );
      await SharePlus.instance.share(params);
    } catch (e) {
      if (mounted) showError(context, 'Could not share: $e');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<Uint8List> _capture() async {
    final boundary =
        _receiptKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  /// Anchor for the share popover on iPad.
  Rect? _buttonRect() {
    final box = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    return BillStepScaffold(
      billId: widget.billId,
      builder: (context, detail) => [
        const SizedBox(height: 8),
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 12),
              ],
              border: Border.all(color: AppColors.placeholder),
            ),
            // Scales down on narrow phones; the captured image keeps the
            // receipt's own fixed width.
            child: FittedBox(
              child: RepaintBoundary(
                key: _receiptKey,
                child: BillReceipt(detail: detail),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          key: _buttonKey,
          onPressed: _sharing || detail.items.isEmpty
              ? null
              : () => _share(detail),
          icon: _sharing
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.share),
          label: const Text('Share'),
        ),
        if (detail.items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Add menu items before sharing.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}
