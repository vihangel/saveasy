part of 'notifications_cubit.dart';

@freezed
abstract class NotificationsState with _$NotificationsState {
  const factory NotificationsState({
    @Default(ViewStatus.initial) ViewStatus status,
    @Default(<AppNotification>[]) List<AppNotification> items,
  }) = _NotificationsState;
}
