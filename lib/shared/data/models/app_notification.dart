import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_notification.freezed.dart';
part 'app_notification.g.dart';

enum NotificationKind {
  follow,
  comment,
  reply,
  participation,
  @JsonValue('coins_received')
  coinsReceived,
  @JsonValue('event_reminder')
  eventReminder,
  system,
}

@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required String title,
    required String body,
    required DateTime date,
    @Default(false) bool read,
    String? postId,
    @JsonKey(unknownEnumValue: NotificationKind.system) @Default(NotificationKind.system) NotificationKind kind,
    String? actorId,
    String? actorName,
    String? actorAvatarUrl,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) => _$AppNotificationFromJson(json);
}
