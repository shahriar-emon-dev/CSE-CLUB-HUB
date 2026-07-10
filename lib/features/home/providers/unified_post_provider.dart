import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/club_post.dart';
import 'post_interaction_provider.dart';

// Forwarding alias to the per-post comments provider for backward compatibility
final unifiedCommentsProvider = FutureProvider.family<List<ClubPostComment>, String>((ref, entityId) async {
  return ref.watch(postCommentsProvider(entityId).future);
});
