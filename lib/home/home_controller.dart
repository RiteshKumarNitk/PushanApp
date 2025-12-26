import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_config.dart';
import '../../shared/models/tea.dart';

final teaListProvider = FutureProvider<List<Tea>>((ref) async {
  final response = await SupabaseConfig.client
      .from('products')
      .select()
      // .order('is_popular', ascending: false) // Removed as column doesn't exist
      .order('created_at', ascending: false); // Then new

  final data = response as List<dynamic>;
  return data.map((e) => Tea.fromJson(e)).toList();
});

final popularTeasProvider = Provider<AsyncValue<List<Tea>>>((ref) {
  final teas = ref.watch(teaListProvider);
  return teas.whenData((list) => list.where((tea) => tea.isPopular).toList());
});

final newArrivalsProvider = Provider<AsyncValue<List<Tea>>>((ref) {
  final teas = ref.watch(teaListProvider);
  return teas.whenData((list) => list.where((tea) => tea.isNew).toList());
});
