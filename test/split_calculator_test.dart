import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:splitit/features/bills/domain/split_calculator.dart';

void main() {
  group('allocate', () {
    test('splits evenly when it divides', () {
      expect(SplitCalculator.allocate(90, [1, 1, 1]), [30, 30, 30]);
    });

    test('gives leftover rupiah to earliest participants', () {
      expect(SplitCalculator.allocate(100, [1, 1, 1]), [34, 33, 33]);
      expect(SplitCalculator.allocate(2, [1, 1, 1]), [1, 1, 0]);
    });

    test('respects weights', () {
      expect(SplitCalculator.allocate(30000, [2, 1]), [20000, 10000]);
    });

    test('leftover goes to the largest remainder, not just the first', () {
      // exact: 3.33, 6.67 → floor 3, 6 → the 1 left goes to index 1
      expect(SplitCalculator.allocate(10, [1, 2]), [3, 7]);
    });

    test('zero weights everywhere fall back to equal split', () {
      expect(SplitCalculator.allocate(10, [0, 0]), [5, 5]);
    });

    test('zero-weight participant gets nothing', () {
      expect(SplitCalculator.allocate(10, [1, 0, 1]), [5, 0, 5]);
    });

    test('always sums to the amount (randomized)', () {
      final rng = Random(42);
      for (var run = 0; run < 2000; run++) {
        final weights = List.generate(
          1 + rng.nextInt(8),
          (_) => rng.nextInt(5),
        );
        final amount = rng.nextInt(10000000);
        final parts = SplitCalculator.allocate(amount, weights);
        expect(parts.reduce((a, b) => a + b), amount);
        expect(parts.every((p) => p >= 0), isTrue);
      }
    });

    test('rejects bad input', () {
      expect(() => SplitCalculator.allocate(-1, [1]), throwsArgumentError);
      expect(() => SplitCalculator.allocate(1, []), throwsArgumentError);
      expect(() => SplitCalculator.allocate(1, [1, -1]), throwsArgumentError);
    });
  });

  group('calculate', () {
    const people = ['host', 'frogiii', 'andri'];

    test('shared item without assignees is split by everyone', () {
      final r = SplitCalculator.calculate(
        participantIds: people,
        items: const [SplitItem(id: 'nasi', qty: 1, unitPrice: 30000)],
      );
      expect(r.shares.map((s) => s.total), [10000, 10000, 10000]);
    });

    test('assigned items go only to their assignees', () {
      final r = SplitCalculator.calculate(
        participantIds: people,
        items: const [
          SplitItem(
            id: 'steak',
            qty: 1,
            unitPrice: 120000,
            shares: {'host': 1},
          ),
          SplitItem(
            id: 'tea',
            qty: 2,
            unitPrice: 8000,
            shares: {'frogiii': 1, 'andri': 1},
          ),
        ],
      );
      expect(r.shares.map((s) => s.subtotal), [120000, 8000, 8000]);
      expect(r.subtotal, 136000);
    });

    test('discount reduces the item total', () {
      final r = SplitCalculator.calculate(
        participantIds: const ['a', 'b'],
        items: const [
          SplitItem(id: 'x', qty: 2, unitPrice: 25000, discount: 10000),
        ],
      );
      expect(r.subtotal, 40000);
      expect(r.shares.map((s) => s.subtotal), [20000, 20000]);
    });

    test('service on subtotal, then tax on subtotal + service', () {
      final r = SplitCalculator.calculate(
        participantIds: const ['a'],
        items: const [SplitItem(id: 'x', qty: 1, unitPrice: 100000)],
        serviceBps: 500, // 5%
        taxBps: 1000, // 10%
      );
      expect(r.service, 5000);
      expect(r.tax, 10500);
      expect(r.total, 115500);
    });

    test('service and tax are spread in proportion to what each ordered', () {
      final r = SplitCalculator.calculate(
        participantIds: const ['a', 'b'],
        items: const [
          SplitItem(id: 'x', qty: 1, unitPrice: 75000, shares: {'a': 1}),
          SplitItem(id: 'y', qty: 1, unitPrice: 25000, shares: {'b': 1}),
        ],
        taxBps: 1000,
      );
      expect(r.shares[0].tax, 7500);
      expect(r.shares[1].tax, 2500);
    });

    test('per-person totals always add up to the bill total', () {
      final r = SplitCalculator.calculate(
        participantIds: people,
        items: const [
          SplitItem(id: '1', qty: 3, unitPrice: 17333),
          SplitItem(
            id: '2',
            qty: 1,
            unitPrice: 9999,
            shares: {'host': 2, 'andri': 1},
          ),
          SplitItem(id: '3', qty: 1, unitPrice: 1, shares: {'frogiii': 1}),
        ],
        serviceBps: 550,
        taxBps: 1100,
      );
      expect(r.shares.fold(0, (sum, s) => sum + s.total), r.total);
    });

    test('rejects invalid input', () {
      expect(
        () => SplitCalculator.calculate(
          participantIds: const [],
          items: const [],
        ),
        throwsArgumentError,
      );
      expect(
        () => SplitCalculator.calculate(
          participantIds: const ['a', 'a'],
          items: const [],
        ),
        throwsArgumentError,
      );
      expect(
        () => SplitCalculator.calculate(
          participantIds: const ['a'],
          items: const [
            SplitItem(id: 'x', qty: 1, unitPrice: 10, shares: {'ghost': 1}),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => SplitCalculator.calculate(
          participantIds: const ['a'],
          items: const [
            SplitItem(id: 'x', qty: 1, unitPrice: 10, discount: 11),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => SplitCalculator.calculate(
          participantIds: const ['a'],
          items: const [],
          taxBps: 10001,
        ),
        throwsArgumentError,
      );
    });
  });
}
