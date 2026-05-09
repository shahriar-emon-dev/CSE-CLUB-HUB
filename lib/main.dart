import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use env-injected values if available, otherwise fall back to defaults.
  const url = EnvConfig.supabaseUrl;
  const anonKey = EnvConfig.supabaseAnonKey;

  final effectiveUrl = url.isNotEmpty
      ? url
      : 'https://ptlmzzfwbvyohtwfdqlj.supabase.co';
  final effectiveKey = anonKey.isNotEmpty
      ? anonKey
      : 'sb_publishable_UOKzCkOzKMHruHX6JlYh8g_ugviSW25';

  try {
    await Supabase.initialize(
      url: effectiveUrl,
      anonKey: effectiveKey,
    );

    runApp(const ProviderScope(child: App()));
  } catch (error) {
    runApp(_ErrorApp(message: error.toString()));
  }
}

class _ErrorApp extends StatelessWidget {
  const _ErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Startup error',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  SelectableText(message),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

