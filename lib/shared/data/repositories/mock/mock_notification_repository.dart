import '../../datasources/mock_database.dart';
import '../../models/models.dart';
import '../notification_repository.dart';

class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository(this._db);

  final MockDatabase _db;

  @override
  Future<List<AppNotification>> all() async {
    await _db.delay();
    return [..._db.notifications]..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<int> unreadCount() async => _db.notifications.where((n) => !n.read).length;

  @override
  Stream<void> changes() => const Stream.empty();

  @override
  Future<void> markRead(String id) async {
    _db.notifications = [for (final n in _db.notifications) n.id == id ? n.copyWith(read: true) : n];
    await _db.saveNotifications();
  }

  @override
  Future<void> markAllRead() async {
    _db.notifications = [for (final n in _db.notifications) n.copyWith(read: true)];
    await _db.saveNotifications();
  }
}
