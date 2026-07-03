import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabase = SupabaseClient('url', 'key');
  int count = await supabase.from('profiles').count(CountOption.exact);
  // ignore: avoid_print
  print(count);
}
