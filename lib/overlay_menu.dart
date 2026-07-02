import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'store.dart';
import 'theme.dart';

/// The in-game pause menu. Opened/closed/navigated by the daemon's OVERLAY_*
/// events (an arcade chord press). Selecting an item sends RESUME_GAME or
/// EXIT_GAME back to the daemon. Local arrow/enter/esc keys work too, for dev.
class OverlayMenu extends StatelessWidget {
  final AppStore store;
  const OverlayMenu({super.key, required this.store});

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  KeyEventResult _onKey(FocusNode n, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    switch (e.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        store.setOverlaySelection(0);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        store.setOverlaySelection(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.space:
        store.overlaySelection == 0 ? store.overlayResume() : store.overlayExit();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.backspace:
        store.overlayResume();
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final items = ['Resume', 'Exit game'];
    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Container(
        color: const Color(0xCC000000),
        alignment: Alignment.center,
        child: Container(
          width: 620,
          padding: const EdgeInsets.fromLTRB(48, 44, 48, 44),
          decoration: BoxDecoration(
            color: pill,
            borderRadius: BorderRadius.circular(40),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x66000000), blurRadius: 50, offset: Offset(0, 18)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Paused',
                  style: TextStyle(
                      color: ink, fontWeight: FontWeight.w900, fontSize: 52)),
              if (store.overlayTimeMode) ...[
                const SizedBox(height: 8),
                Text('Time left  ${_fmt(store.overlayRemaining)}',
                    style: const TextStyle(
                        color: mutedInk,
                        fontWeight: FontWeight.w700,
                        fontSize: 30)),
              ],
              const SizedBox(height: 32),
              for (var i = 0; i < items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _MenuItem(
                    label: items[i],
                    focused: store.overlaySelection == i,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String label;
  final bool focused;
  const _MenuItem({required this.label, required this.focused});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 22),
      decoration: BoxDecoration(
        gradient: focused ? focusGradient : null,
        color: focused ? null : const Color(0xFFE7E7EA),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(label,
          style: TextStyle(
              color: focused ? Colors.white : ink,
              fontWeight: FontWeight.w800,
              fontSize: 40)),
    );
  }
}
