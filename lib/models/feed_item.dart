import 'blog.dart';
import 'event.dart';

enum FeedItemType {
  event,
  blog,
  notice,
}

class FeedItem {
  final FeedItemType type;
  final Event? event;
  final Blog? blog;
  final DateTime sortDate;

  FeedItem({
    required this.type,
    this.event,
    this.blog,
    required this.sortDate,
  }) : assert(
          (type == FeedItemType.event && event != null) ||
          (type == FeedItemType.blog && blog != null),
          'Event or Blog must be provided based on the FeedItemType.',
        );
}
