import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/utils/view_status.dart';

part 'notifications_cubit.freezed.dart';
part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository) : super(const NotificationsState()) {
    _changes = _repository.changes().listen((_) => load());
  }

  final NotificationRepository _repository;
  late final StreamSubscription<void> _changes;

  Future<void> load() async {
    if (isClosed) return;
    emit(state.copyWith(status: state.items.isEmpty ? ViewStatus.loading : state.status));
    try {
      final items = await _repository.all();
      if (!isClosed) emit(state.copyWith(status: ViewStatus.success, items: items));
    } on AppException {
      if (!isClosed) emit(state.copyWith(status: ViewStatus.failure));
    }
  }

  Future<void> markAllRead() async {
    await _repository.markAllRead();
    await load();
  }

  Future<void> open(AppNotification notification) async {
    if (notification.read) return;
    emit(state.copyWith(items: [for (final n in state.items) n.id == notification.id ? n.copyWith(read: true) : n]));
    await _repository.markRead(notification.id);
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
