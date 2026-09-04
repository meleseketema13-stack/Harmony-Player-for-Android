import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../a11y/a11y_engine.dart';
import '../audio/track_store.dart';
import '../l10n/generated/app_localizations.dart';
import '../state/audio_providers.dart';

/// Settings page with grouped sections: Playback, Accessibility.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final engine = A11yEngine(l10n, View.of(context));
    final contentFirst = ref.watch(contentFirstSemanticsProvider);
    final handler = ref.watch(audioHandlerProvider);
    final interval = ref.watch(seekIntervalProvider).valueOrNull ??
        TrackStore.defaultSeekIntervalSeconds;
    final sleepTimer = ref.watch(sleepTimerProvider).valueOrNull ?? 0;
    final sleepRemaining = ref.watch(sleepTimerRemainingProvider).valueOrNull ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Text(
            l10n.settings,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Expanded(
          child: ListView(
            children: <Widget>[
              // --- Playback section ---
              _SectionHeader(title: l10n.playback, subtitle: l10n.playbackHint),

              // Sleep Timer
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: Text(l10n.sleepTimer),
                subtitle: Text(
                  sleepTimer > 0
                      ? l10n.sleepTimerActive(
                          _formatRemaining(sleepRemaining))
                      : l10n.sleepTimerOff,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: <ButtonSegment<int>>[
                    for (final minutes in TrackStore.sleepTimerOptions)
                      ButtonSegment<int>(
                        value: minutes,
                        label: Text(minutes == 0
                            ? l10n.sleepTimerOff
                            : _formatMinutes(minutes)),
                      ),
                  ],
                  selected: <int>{sleepTimer},
                  onSelectionChanged: (selection) async {
                    final value = selection.first;
                    await handler.setSleepTimerMinutes(value);
                    if (context.mounted) {
                      final eng = A11yEngine(l10n, View.of(context));
                      if (value > 0) {
                        eng.announceSleepTimerSet(_formatMinutes(value));
                      } else {
                        eng.announceSleepTimerCancelled();
                      }
                    }
                  },
                ),
              ),
              const Divider(),

              // Seek Intervals (expandable sub-setting)
              ExpansionTile(
                leading: const Icon(Icons.fast_forward_rounded),
                title: Text(l10n.seekIntervalSetting),
                subtitle: Text(l10n.seekIntervalSettingHint),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SegmentedButton<int>(
                      showSelectedIcon: false,
                      segments: <ButtonSegment<int>>[
                        for (final seconds in TrackStore.seekIntervalOptions)
                          ButtonSegment<int>(
                            value: seconds,
                            label: Text(engine.seekIntervalLabelShort(seconds)),
                          ),
                      ],
                      selected: <int>{interval},
                      onSelectionChanged: (selection) => unawaited(
                        handler.setSeekIntervalSeconds(selection.first),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(),

              // --- Accessibility section ---
              _SectionHeader(
                  title: l10n.accessibility,
                  subtitle: l10n.accessibilityHint),

              SwitchListTile(
                secondary: const Icon(Icons.record_voice_over_rounded),
                title: Text(l10n.contentFirstOrder),
                subtitle: Text(l10n.contentFirstOrderHint),
                value: contentFirst,
                onChanged: (_) =>
                    ref.read(contentFirstSemanticsProvider.notifier).toggle(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatMinutes(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }
    return '${minutes}m';
  }

  static String _formatRemaining(int seconds) {
    if (seconds <= 0) return '0:00';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
