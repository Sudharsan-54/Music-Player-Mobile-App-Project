import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/music_handler.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_providers.dart';
import 'routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the background audio handler via audio_service
  final musicHandler = await AudioService.init(
    builder: () => MusicHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.jazzmusic.channel.audio',
      androidNotificationChannelName: 'Jazz Music Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        // Inject the singleton MusicHandler into Riverpod
        musicHandlerProvider.overrideWithValue(musicHandler),
      ],
      child: const JazzMusicApp(),
    ),
  );
}

class JazzMusicApp extends ConsumerWidget {
  const JazzMusicApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Jazz Music Player',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(),
      routerConfig: router,
    );
  }
}
