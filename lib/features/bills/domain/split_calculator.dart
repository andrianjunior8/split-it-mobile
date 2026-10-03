/// Pure split-bill math. All amounts are whole rupiah (`int`), percentages are
/// basis points (1000 = 10%). Totals always add up exactly: every rounding
/// remainder is handed out one rupiah at a time, never lost or invented.
library;

class SplitItem {
  const SplitItem({
    required this.id,
    required this.qty,
    required this.unitPrice,
    this.discount = 0,
    this.shares = const {},
  });

  final String id;
  final int qty;
  final int unitPrice;
  final int discount;

  /// participantId → weight. Empty means "shared equally by everyone".
  final Map<String, int> shares;

  int get total => qty * unitPrice - discount;
}

class ParticipantShare {
  const ParticipantShare({
    required this.participantId,
    required this.subtotal,
    required this.service,
    required this.tax,
  });

  final String participantId;
  final int subtotal;
  final int service;
  final int tax;

  int get total => subtotal + service + tax;
}

class SplitResult {
  const SplitResult({
    required this.subtotal,
    required this.service,
    required this.tax,
    required this.shares,
  });

  final int subtotal;
  final int service;
  final int tax;

  /// One entry per participant, in the order they were given.
  final List<ParticipantShare> shares;

  int get total => subtotal + service + tax;
}

class SplitCalculator {
  const SplitCalculator._();

  /// Splits [items] among [participantIds].
  ///
  /// Follows the usual Indonesian receipt: service charge is applied to the
  /// subtotal, then tax (PB1) to subtotal + service. Both are spread over
  /// participants in proportion to what they ordered.
  ///
  /// Rounding leftovers go to participants earlier in the list first, so
  /// put the host first.
  static SplitResult calculate({
    required List<String> participantIds,
    required List<SplitItem> items,
    int serviceBps = 0,
    int taxBps = 0,
  }) {
    if (participantIds.isEmpty) {
      throw ArgumentError.value(participantIds, 'participantIds', 'is empty');
    }
    if (participantIds.toSet().length != participantIds.length) {
      throw ArgumentError.value(
        participantIds,
        'participantIds',
        'has duplicates',
      );
    }
    _checkBps(serviceBps, 'serviceBps');
    _checkBps(taxBps, 'taxBps');

    final index = {
      for (var i = 0; i < participantIds.length; i++) participantIds[i]: i,
    };
    final subtotals = List.filled(participantIds.length, 0);

    for (final item in items) {
      _checkItem(item, index);
      final weights = List.filled(participantIds.length, 0);
      if (item.shares.isEmpty) {
        weights.fillRange(0, weights.length, 1);
      } else {
        item.shares.forEach((id, w) => weights[index[id]!] = w);
      }
      final parts = allocate(item.total, weights);
      for (var i = 0; i < parts.length; i++) {
        subtotals[i] += parts[i];
      }
    }

    final subtotal = subtotals.fold(0, (a, b) => a + b);
    final service = _applyBps(subtotal, serviceBps);
    final tax = _applyBps(subtotal + service, taxBps);
    final services = allocate(service, subtotals);
    final taxes = allocate(tax, subtotals);

    return SplitResult(
      subtotal: subtotal,
      service: service,
      tax: tax,
      shares: [
        for (var i = 0; i < participantIds.length; i++)
          ParticipantShare(
            participantId: participantIds[i],
            subtotal: subtotals[i],
            service: services[i],
            tax: taxes[i],
          ),
      ],
    );
  }

  /// Splits [amount] in proportion to [weights] using the largest remainder
  /// method. The result always sums to [amount]. Ties go to the lower index.
  /// If every weight is zero, the amount is spread equally.
  static List<int> allocate(int amount, List<int> weights) {
    if (amount < 0) throw ArgumentError.value(amount, 'amount', 'is negative');
    if (weights.isEmpty) {
      throw ArgumentError.value(weights, 'weights', 'is empty');
    }
    if (weights.any((w) => w < 0)) {
      throw ArgumentError.value(weights, 'weights', 'has a negative weight');
    }

    final totalWeight = weights.fold(0, (a, b) => a + b);
    if (totalWeight == 0) {
      return allocate(amount, List.filled(weights.length, 1));
    }

    final result = List.filled(weights.length, 0);
    final remainders = List.filled(weights.length, 0);
    var given = 0;
    for (var i = 0; i < weights.length; i++) {
      final exact = amount * weights[i];
      result[i] = exact ~/ totalWeight;
      remainders[i] = exact % totalWeight;
      given += result[i];
    }

    final order = List.generate(weights.length, (i) => i)
      ..sort((a, b) {
        final byRemainder = remainders[b].compareTo(remainders[a]);
        return byRemainder != 0 ? byRemainder : a.compareTo(b);
      });
    for (var k = 0; k < amount - given; k++) {
      result[order[k]]++;
    }
    return result;
  }

  /// Rounds half up to the nearest rupiah.
  static int _applyBps(int amount, int bps) => (amount * bps + 5000) ~/ 10000;

  static void _checkBps(int bps, String name) {
    if (bps < 0 || bps > 10000) {
      throw ArgumentError.value(bps, name, 'must be between 0 and 10000');
    }
  }

  static void _checkItem(SplitItem item, Map<String, int> index) {
    if (item.qty <= 0 || item.unitPrice < 0 || item.discount < 0) {
      throw ArgumentError.value(
        item.id,
        'item',
        'has invalid qty, price or discount',
      );
    }
    if (item.total < 0) {
      throw ArgumentError.value(item.id, 'item', 'discount exceeds its price');
    }
    for (final MapEntry(:key, :value) in item.shares.entries) {
      if (!index.containsKey(key)) {
        throw ArgumentError.value(
          key,
          'item ${item.id}',
          'unknown participant',
        );
      }
      if (value <= 0) {
        throw ArgumentError.value(
          value,
          'item ${item.id}',
          'weight must be positive',
        );
      }
    }
  }
}
