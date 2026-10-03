import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splitit/features/search/recent_searches_repository.dart';

void main() {
  late RecentSearchesRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = RecentSearchesRepository(await SharedPreferences.getInstance());
  });

  test('newest first, trimmed, empty ignored', () async {
    await repo.add('Bebek Kaleyo');
    await repo.add('  KLEB HOLIWING TIO ');
    await repo.add('   ');
    expect(repo.load(), ['KLEB HOLIWING TIO', 'Bebek Kaleyo']);
  });

  test(
    're-adding moves to top without duplicates (case-insensitive)',
    () async {
      await repo.add('warkop');
      await repo.add('dinner');
      await repo.add('WARKOP');
      expect(repo.load(), ['WARKOP', 'dinner']);
    },
  );

  test('keeps at most maxEntries', () async {
    for (var i = 0; i < 8; i++) {
      await repo.add('q$i');
    }
    expect(repo.load(), hasLength(RecentSearchesRepository.maxEntries));
    expect(repo.load().first, 'q7');
  });

  test('remove deletes one entry', () async {
    await repo.add('a');
    await repo.add('b');
    await repo.remove('a');
    expect(repo.load(), ['b']);
  });
}
