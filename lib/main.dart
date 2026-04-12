import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    EnvConfig.validate();
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
    );

    runApp(const ProviderScope(child: App()));
  } on FormatException catch (error) {
    runApp(_MissingConfigApp(message: error.message));
  }
}

class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp({required this.message});

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
                    'Supabase configuration missing',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(message),
                  const SizedBox(height: 16),
                  const SelectableText(
                    'Run with:\n'
                    'flutter run -d chrome --dart-define-from-file=.env/dev.json',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
