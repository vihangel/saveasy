import '../datasources/mock_database.dart';
import '../models/models.dart';

class NotificationRepository {
  NotificationRepository(this._db);

  final MockDatabase _db;

  Future<List<AppNotification>> all() async {
    await _db.delay();
    return [..._db.notifications]..sort((a, b) => b.date.compareTo(a.date));
  }

  int unreadCount() => _db.notifications.where((n) => !n.read).length;

  Future<void> markAllRead() async {
    _db.notifications = [for (final n in _db.notifications) n.copyWith(read: true)];
    await _db.saveNotifications();
  }
}
