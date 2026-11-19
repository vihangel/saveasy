import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:saveeasy2026/shared/data/models/models.dart';
import 'package:saveeasy2026/shared/utils/formatters.dart';

Post _post(PostType type, {DateTime? startsAt, DateTime? endsAt}) => Post(
  id: 'p',
  type: type,
  title: 'Teste',
  description: '',
  authorId: 'u',
  authorName: 'Autor',
  authorType: AccountType.community,
  createdAt: DateTime(2026),
  startsAt: startsAt,
  endsAt: endsAt,
);

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  group('campanha de doação', () {
    test('aceita doações até o fim do dia de encerramento', () {
      final post = _post(PostType.donation, endsAt: today);
      expect(post.donationsClosed, isFalse);
      expect(post.isOpen, isTrue);
      expect(Formatters.daysLeft(today), isNot('Encerrada'));
    });

    test('encerrada depois da data não aceita doações', () {
      final post = _post(PostType.donation, endsAt: today.subtract(const Duration(days: 1)));
      expect(post.donationsClosed, isTrue);
      expect(post.isOpen, isFalse);
      expect(Formatters.daysLeft(post.endsAt!), 'Encerrada');
    });

    test('recorrente (sem data) continua aberta', () {
      expect(_post(PostType.donation).donationsClosed, isFalse);
    });
  });

  test('evento que já começou e terminou sai dos destaques', () {
    final past = _post(PostType.event, startsAt: now.subtract(const Duration(days: 2)));
    final future = _post(PostType.event, startsAt: now.add(const Duration(days: 2)));
    expect(past.isOpen, isFalse);
    expect(future.isOpen, isTrue);
    // A regra de doação não vale para outros tipos.
    expect(past.donationsClosed, isFalse);
  });

  test('datas em UTC são mostradas no horário local', () {
    final utc = DateTime.utc(2026, 11, 20, 12);
    expect(Formatters.shortDateTime(utc), Formatters.shortDateTime(utc.toLocal()));
  });
}
