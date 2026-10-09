import '../models/models.dart';

/// Notificações geradas pelo banco. Implementações:
/// [MockNotificationRepository] e [SupabaseNotificationRepository].
abstract interface class NotificationRepository {
  Future<List<AppNotification>> all();

  Future<void> markRead(String id);

  Future<void> markAllRead();

  Future<int> unreadCount();

  /// Avisa quando chega notificação nova (Realtime).
  Stream<void> changes();
}
