import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_config.dart';

final unreadMessageCountProvider = StreamProvider<int>((ref) {
  final myId = SupabaseConfig.client.auth.currentUser?.id;
  if (myId == null) return const Stream.empty();

  return SupabaseConfig.client
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('receiver_id', myId)
      .map((data) => data.where((m) => m['is_read'] == false).length);
});
