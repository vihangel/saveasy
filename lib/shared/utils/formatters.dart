import 'package:intl/intl.dart';

abstract final class Formatters {
  static final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
  static final _decimal = NumberFormat.decimalPattern('pt_BR');
  static final _date = DateFormat("dd/MM/yyyy", 'pt_BR');
  static final _dateTime = DateFormat("EEE, dd MMM · HH:mm", 'pt_BR');
  static final _shortDateTime = DateFormat('dd/MM · HH:mm', 'pt_BR');

  static String currency(num value) => _currency.format(value);

  static String number(num value) => _decimal.format(value);

  /// 12000 → 12k, 2500 → 2,5k
  static String compact(num value) {
    if (value < 1000) return value.toString();
    final k = value / 1000;
    return '${k.toStringAsFixed(k >= 10 || k == k.roundToDouble() ? 0 : 1).replaceAll('.', ',')}k';
  }

  static String date(DateTime date) => _date.format(date);

  static String dateTime(DateTime date) => _dateTime.format(date).toUpperCase();

  static String relative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    if (diff.inDays < 7) return 'há ${diff.inDays} d';
    return Formatters.date(date);
  }

  /// "Em 5 dias", "Em 1 dia", "Hoje", "Finalizado".
  static String countdown(DateTime date) {
    if (date.isBefore(DateTime.now())) return 'Finalizado';
    final days = _calendarDaysUntil(date);
    if (days == 0) return 'Hoje';
    return days == 1 ? 'Amanhã' : 'Em $days dias';
  }

  static String daysLeft(DateTime date) {
    if (date.isBefore(DateTime.now())) return 'Encerrada';
    final days = _calendarDaysUntil(date);
    if (days == 0) return 'Último dia';
    return days == 1 ? '1 dia rest.' : '$days dias rest.';
  }

  /// Data curta para campos de formulário: 24/09 · 09:00
  static String shortDateTime(DateTime date) => _shortDateTime.format(date);

  static int _calendarDaysUntil(DateTime date) {
    final now = DateTime.now();
    return DateTime(date.year, date.month, date.day).difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  static String plural(int count, String singular, String plural) => '$count ${count == 1 ? singular : plural}';

  static String duration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}min';
    return m == 0 ? '${h}h' : '${h}h e ${m}min';
  }
}
