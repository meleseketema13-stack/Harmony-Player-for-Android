import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:harmony_player/l10n/generated/app_localizations.dart';
import 'package:harmony_player/ui/widgets/accessible_seek_bar.dart';
import 'package:harmony_player/ui/widgets/player_controls.dart';

void _noop() {}

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: SizedBox(width: 320, child: child),
      ),
    ),
  );
}

void main() {
  testWidgets('PlayerButton enforces the 48x48 logical-pixel touch target',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const PlayerButton(icon: Icons.play_arrow, label: 'Play'),
    ));
    final size = tester.getSize(find.byType(PlayerButton));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('PlayerButton exposes a single button node with label and tap',
      (tester) async {
    final handle = tester.ensureSemantics();
    var tapped = false;
    await tester.pumpWidget(_wrap(
      PlayerButton(
        icon: Icons.pause,
        label: 'Pause',
        onPressed: () => tapped = true,
      ),
    ));

    expect(
      tester.getSemantics(find.byType(PlayerButton)),
      matchesSemantics(
        label: 'Pause',
        isButton: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );

    await tester.tap(find.byType(PlayerButton));
    expect(tapped, isTrue);
    handle.dispose();
  });

  testWidgets('PlayerButton never exposes switch/toggled state', (tester) async {
    // Regression guard for feedback that Android screen readers prefixed every
    // transport button with "Switch on" / "Switch off" because the node carried
    // SemanticsFlag.isToggled. These are action buttons, not switches.
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(
      const PlayerButton(
        icon: Icons.pause,
        label: 'Pause',
        active: true,
        onPressed: _noop,
      ),
    ));

    final data = tester.getSemantics(find.byType(PlayerButton));

    // matchesSemantics asserts every flag it does not list is false, so leaving
    // hasToggledState/hasCheckedState out is itself the "no switch state"
    // assertion.
    expect(
      data,
      matchesSemantics(
        label: 'Pause',
        isButton: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('PlayerButton conveys on/off state through value, not a toggle',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(
      const PlayerButton(
        icon: Icons.shuffle,
        label: 'Shuffle',
        active: true,
        value: 'On',
        onPressed: _noop,
      ),
    ));

    expect(
      tester.getSemantics(find.byType(PlayerButton)),
      matchesSemantics(
        label: 'Shuffle',
        value: 'On',
        isButton: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets(
      'AccessibleSeekBar is an adjustable slider with increase/decrease and '
      'custom actions', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(
      AccessibleSeekBar(
        position: const Duration(seconds: 30),
        duration: const Duration(minutes: 2),
        onSeek: (_) {},
        onSeekEnd: () {},
      ),
    ));

    expect(
      tester.getSemantics(find.bySemanticsLabel('Seek bar')),
      matchesSemantics(
        isSlider: true,
        isEnabled: true,
        hasEnabledState: true,
        hasIncreaseAction: true,
        hasDecreaseAction: true,
        hasTapAction: true,
        hasScrollLeftAction: true,
        hasScrollRightAction: true,
      ),
    );

    // The two built-in jump actions must be present for TalkBack's context
    // menu and Jieshuo+'s actions menu.
    final node = tester.semantics.find(find.bySemanticsLabel('Seek bar'));
    final actionIds =
        node.getSemanticsData().customSemanticsActionIds ?? const <int>[];
    final actionLabels = actionIds
        .map((id) => CustomSemanticsAction.getAction(id)?.label)
        .toSet();
    expect(actionLabels, containsAll(<String>[
      'Jump forward 10 seconds',
      'Jump backward 10 seconds',
    ]));
    handle.dispose();
  });

  testWidgets('AccessibleSeekBar touch target is at least 48px tall',
      (tester) async {
    await tester.pumpWidget(_wrap(
      AccessibleSeekBar(
        position: Duration.zero,
        duration: const Duration(minutes: 2),
        onSeek: (_) {},
      ),
    ));
    final size = tester.getSize(find.byType(AccessibleSeekBar));
    expect(size.height, greaterThanOrEqualTo(48));
  });
}
