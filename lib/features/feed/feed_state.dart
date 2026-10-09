part of 'feed_cubit.dart';

@freezed
abstract class FeedState with _$FeedState {
  const factory FeedState({
    @Default(ViewStatus.initial) ViewStatus status,
    @Default(FeedTab.popular) FeedTab tab,
    PostCategory? category,
    @Default('') String query,
    @Default(<Post>[]) List<Post> posts,
    @Default(<Story>[]) List<Story> stories,

    /// Posts impulsionados (anúncios) misturados à lista.
    @Default(<AdCampaign>[]) List<AdCampaign> sponsored,
    String? error,
  }) = _FeedState;
}
