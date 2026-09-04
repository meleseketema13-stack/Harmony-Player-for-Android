import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'audio/harmony_audio_handler.dart';
import 'state/audio_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // One handler instance for the whole app. It is created here, handed to
  // audio_service, and injected into the widget tree via a ProviderScope
  // override — so the UI and the platform media session always talk to the
  // exact same object.
  final handler = HarmonyAudioHandler();
  await handler.init();

  await AudioService.init(
    builder: () => handler,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.harmonyplayer.audio.channel',
      androidNotificationChannelName: 'HarmonyPlayer playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      // Must be a monochrome icon on a transparent background for the
      // notification seek bar to render on some devices.
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidNotificationClickStartsActivity: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: <Override>[
        audioHandlerProvider.overrideWithValue(handler),
      ],
      child: const HarmonyApp(),
    ),
  );
}
