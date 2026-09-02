import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/theme_mode_provider.dart';
import 'widgets/inactivity_guard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sans ça, une erreur pendant le build d'un widget ou dans un callback
  // async (hors Flutter) plante silencieusement ou laisse un écran blanc
  // sans rien dans la console. Ici on logge au minimum ; un service comme
  // Sentry pourra être branché dans ces deux callbacks plus tard.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    developer.log('Erreur Flutter non gérée', error: details.exception, stackTrace: details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    developer.log('Erreur asynchrone non gérée', error: error, stackTrace: stack);
    return true;
  };

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const ProviderScope(child: EleveurApp()));
}

class EleveurApp extends ConsumerWidget {
  const EleveurApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Éleveur Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => InactivityGuard(child: child ?? const SizedBox()),
    );
  }
}
