import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../a11y/a11y_engine.dart';
import '../../l10n/generated/app_localizations.dart';

/// A fully accessible, adjustable seek bar.
///
/// Semantics contract:
///  * `slider: true` + [value] + [onIncrease]/[onDecrease] makes the node
///    "adjustable". TalkBack and Jieshuo+ then offer swipe up/down scrubbing
///    and VoiceOver exposes it via its adjustable rotor.
///  * [increasedValue]/[decreasedValue] describe the resulting position after
///    an increase/decrease gesture. Engines such as Jieshuo+ read these
///    directly, which is what makes scrub progress accurate for third-party
///    screen readers without any plugin.
///  * Up to 5 [CustomSemanticsAction]s (jump ±10s, favorite, playlist,
///    shuffle) appear in the TalkBack context menu and Jieshuo+ actions menu.
///  * Visual touches are handled by a `GestureDetector` nested *inside* the
///    `Semantics` node. The gesture detector declares no tap/drag semantics
///    actions of its own (only `onTapDown`/drag callbacks, which do not create
///    semantics), so exactly one node is exposed.
///  * Touch target: 48 logical pixels tall ([A11yEngine.minTouchTarget]).
class AccessibleSeekBar extends StatefulWidget {
  const AccessibleSeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.onSeekStart,
    this.onSeekEnd,
    this.customActions = const <CustomSemanticsAction, VoidCallback>{},
    this.jump = const Duration(seconds: 10),
    this.enabled = true,
  });

  final Duration position;
  final Duration duration;

  /// Called for every seek, including accessible increase/decrease gestures.
  final ValueChanged<Duration> onSeek;
  final VoidCallback? onSeekStart;
  final VoidCallback? onSeekEnd;

  /// Secondary actions merged with the built-in ±[jump] actions.
  final Map<CustomSemanticsAction, VoidCallback> customActions;

  /// How far the built-in jump actions (and swipe-adjust step on long tracks)
  /// scrub by. Kept in sync with the user's seek-interval setting.
  final Duration jump;
  final bool enabled;

  @override
  State<AccessibleSeekBar> createState() => _AccessibleSeekBarState();
}

class _AccessibleSeekBarState extends State<AccessibleSeekBar> {
  /// Granular step for swipe up/down adjust gestures: the configured jump on
  /// long tracks, otherwise 1% of the duration.
  Duration get _step {
    final duration = widget.duration;
    if (duration <= Duration.zero) return const Duration(seconds: 1);
    if (duration >= const Duration(minutes: 1)) return widget.jump;
    return duration ~/ 100;
  }

  double _percent(Duration position) {
    final duration = widget.duration;
    if (duration <= Duration.zero) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  void _scrubToFraction(double fraction) {
    final clamped = fraction.clamp(0.0, 1.0);
    final duration = widget.duration;
    widget.onSeek(
      Duration(milliseconds: (duration.inMilliseconds * clamped).round()),
    );
  }

  void _scrubRelative(Duration delta, A11yEngine engine) {
    var target = widget.position + delta;
    final duration = widget.duration;
    if (duration > Duration.zero && target > duration) target = duration;
    if (target < Duration.zero) target = Duration.zero;
    widget.onSeek(target);
    engine.announceSeek((_percent(target) * 100).round());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final engine = A11yEngine(l10n, View.of(context));
    final position = widget.position;
    final duration = widget.duration;
    final percent = _percent(position);
    final step = _step;

    Duration bound(Duration d) {
      if (duration > Duration.zero && d > duration) return duration;
      if (d < Duration.zero) return Duration.zero;
      return d;
    }

    final valueText =
        '${engine.formatDuration(position)} of ${engine.formatDuration(duration)}';
    final increasedText =
        '${engine.formatDuration(bound(position + step))} of ${engine.formatDuration(duration)}';
    final decreasedText =
        '${engine.formatDuration(bound(position - step))} of ${engine.formatDuration(duration)}';

    final customActions = <CustomSemanticsAction, VoidCallback>{
      ...widget.customActions,
      CustomSemanticsAction(label: l10n.jumpBackward(engine.seekIntervalLabel(widget.jump.inSeconds))):
          () => _scrubRelative(-widget.jump, engine),
      CustomSemanticsAction(label: l10n.jumpForward(engine.seekIntervalLabel(widget.jump.inSeconds))):
          () => _scrubRelative(widget.jump, engine),
    };

    return Semantics(
      container: true,
      slider: true,
      enabled: widget.enabled,
      label: l10n.seekBarLabel,
      value: valueText,
      increasedValue: increasedText,
      decreasedValue: decreasedText,
      hint: l10n.seekHint,
      onIncrease: () => _scrubRelative(step, engine),
      onDecrease: () => _scrubRelative(-step, engine),
      customSemanticsActions: customActions,
      child: SizedBox(
        height: A11yEngine.minTouchTarget,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final width = constraints.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: widget.enabled
                  ? (details) =>
                      _scrubToFraction(details.localPosition.dx / width)
                  : null,
              onHorizontalDragStart: widget.enabled
                  ? (_) => widget.onSeekStart?.call()
                  : null,
              onHorizontalDragUpdate: widget.enabled
                  ? (details) =>
                      _scrubToFraction(details.localPosition.dx / width)
                  : null,
              onHorizontalDragEnd:
                  widget.enabled ? (_) => widget.onSeekEnd?.call() : null,
              child: _SeekBarVisual(percent: percent),
            );
          },
        ),
      ),
    );
  }
}

/// Purely visual track/fill/thumb. No semantics of its own.
class _SeekBarVisual extends StatelessWidget {
  const _SeekBarVisual({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: percent.clamp(0.0, 1.0),
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment(percent.clamp(0.0, 1.0) * 2 - 1, 0),
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: scheme.surface, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
