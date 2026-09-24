import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/data/models/models.dart';
import '../../shared/data/repositories/repositories.dart';
import '../../shared/utils/view_status.dart';

part 'notifications_cubit.freezed.dart';
part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository) : super(const NotificationsState());

  final NotificationRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: state.items.isEmpty ? ViewStatus.loading : state.status));
    emit(state.copyWith(status: ViewStatus.success, items: await _repository.all()));
  }

  Future<void> markAllRead() async {
    await _repository.markAllRead();
    await load();
  }
}
