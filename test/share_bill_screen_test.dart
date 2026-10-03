import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:splitit/features/auth/data/app_user.dart';
import 'package:splitit/features/auth/data/auth_repository.dart';
import 'package:splitit/features/bills/data/bills_repository.dart';
import 'package:splitit/features/bills/data/in_memory_bills_repository.dart';
import 'package:splitit/features/bills/domain/bill.dart';
import 'package:splitit/features/split_bill/share/share_bill_screen.dart';

class FakeSharePlatform extends SharePlatform with MockPlatformInterfaceMixin {
  final calls = <ShareParams>[];

  @override
  Future<ShareResult> share(ShareParams params) async {
    calls.add(params);
    return const ShareResult('ok', ShareResultStatus.success);
  }
}

class FixedAuth extends InMemoryAuthRepository {
  @override
  AppUser? get currentUser =>
      const AppUser(id: 'u1', email: 'a@x.com', name: 'Yoti');
}

void main() {
  late FakeSharePlatform platform;

  setUpAll(() {
    // The receipt logo uses a Google Font; never hit the network in tests.
    GoogleFonts.config.allowRuntimeFetching = false;
    platform = FakeSharePlatform();
    SharePlatform.instance = platform;
  });

  testWidgets('Share sends a PNG of the receipt with a text caption', (
    tester,
  ) async {
    // Missing font files are reported as errors; they don't matter here.
    final onError = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!'${d.exception}'.contains('GoogleFonts')) onError?.call(d);
    };
    addTearDown(() => FlutterError.onError = onError);

    final auth = FixedAuth();
    final repo = InMemoryBillsRepository(currentUser: () => auth.currentUser);
    final bill = await repo.createBill(
      title: 'Makan Makan Kaleyo',
      billDate: DateTime(2025, 1, 16),
    );
    await repo.saveItem(
      BillItem(id: '', billId: bill.id, name: 'Nasi', qty: 2, unitPrice: 10000),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          billsRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(home: ShareBillScreen(billId: bill.id)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Makan Makan Kaleyo'), findsOneWidget);

    await tester.tap(find.text('Share'));
    // Rendering the image to PNG needs real async time.
    await tester.runAsync(() async {
      for (var i = 0; i < 50 && platform.calls.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pumpAndSettle();

    expect(platform.calls, hasLength(1));
    final params = platform.calls.single;
    expect(params.text, startsWith('Makan Makan Kaleyo\n16 January 2025'));
    expect(params.text, contains('Yoti: Rp 20.000'));
    expect(params.fileNameOverrides, ['splitit-makan-makan-kaleyo.png']);

    final file = params.files!.single;
    expect(file.mimeType, 'image/png');
    final bytes = await tester.runAsync(file.readAsBytes);
    // PNG signature, and wider than the 360px receipt at 3x.
    expect(bytes!.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
    final width = bytes.buffer.asByteData().getUint32(16);
    expect(width, 1080);
  });
}
