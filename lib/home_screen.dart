import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'sounds.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';

class _Entry {
  final Game? game;
  final AppTile? app;
  const _Entry.game(this.game) : app = null;
  const _Entry.app(this.app) : game = null;

  bool get isGame => game != null;
  String get name => isGame ? game!.name : app!.name;
  String get kindLabel => isGame ? game!.console : app!.kindLabel;
}

const double _gridTop = 260;
const double _tileW = 197;
const double _tileH = 196;
const double _colGap = 35;
const double _rowGap = 33;
const int _rows = 3;

class HomeScreen extends StatefulWidget {
  final AppStore store;
  const HomeScreen({super.key, required this.store});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _row = 0, _col = 0;
  int _gridCols = 1;
  final _scroll = ScrollController();
  final _focus = FocusNode();

  List<_Entry> get _entries {
    final s = widget.store;
    return [
      ...s.games.map((g) => _Entry.game(g)),
      ...s.apps.map((a) => _Entry.app(a)),
    ];
  }

  int get _cols {
    final n = _entries.length;
    return n == 0 ? 1 : ((n + _rows - 1) ~/ _rows);
  }

  _Entry? _entryAt(int r, int c) {
    final i = c * _rows + r;
    final e = _entries;
    return i >= 0 && i < e.length ? e[i] : null;
  }

  void _move(int dr, int dc) {
    final nr = (_row + dr).clamp(0, _rows - 1);
    final nc = (_col + dc).clamp(0, _gridCols - 1);
    if (nr == _row && nc == _col) return;
    setState(() {
      _row = nr;
      _col = nc;
    });
    Sounds.I.navigate();
    _ensureVisible();
  }

  void _ensureVisible() {
    if (!_scroll.hasClients) return;
    final target = (_col * (_tileW + _colGap)) - 2 * (_tileW + _colGap);
    final clamped = target.clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.animateTo(clamped,
        duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
  }

  Future<void> _select() async {
    final e = _entryAt(_row, _col);
    if (e == null) return;
    Sounds.I.select();
    final err = e.isGame
        ? await widget.store.startGame(e.game!)
        : await widget.store.launchApp(e.app!);
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err, style: const TextStyle(fontSize: 22)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  KeyEventResult _onKey(FocusNode n, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    switch (e.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        _move(0, -1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        _move(0, 1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _move(-1, 0);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _move(1, 0);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.space:
        _select();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.backspace:
        Sounds.I.back();
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  ImageProvider? _iconFor(_Entry e) {
    return e.isGame
        ? widget.store.coverFor(e.game!)
        : widget.store.iconFor(e.app!);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final cols = _cols;
        return Scaffold(
          backgroundColor: Colors.black,
          body: LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth, h = c.maxHeight;
            final aspect = (w > 0 && h > 0) ? w / h : kDW / kDH;
            final designW = (kDH * aspect).clamp(kDH, kDH * 4);
            final fillCols = ((designW - 40) / (_tileW + _colGap)).ceil() + 2;
            final renderCols = fillCols > cols ? fillCols : cols;
            _gridCols = renderCols;
            if (_col > renderCols - 1) _col = renderCols - 1;
            final focused = _entryAt(_row, _col);
            return Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Focus(
                  focusNode: _focus,
                  autofocus: true,
                  onKeyEvent: _onKey,
                  child: SizedBox(
                    width: designW,
                    height: kDH,
                    child: Stack(children: [
                      Positioned.fill(child: Container(color: bg)),
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment(-0.05, -0.02),
                              radius: 0.95,
                              colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
                            ),
                          ),
                        ),
                      ),
                      const Positioned.fill(
                          child: CustomPaint(painter: DotsPainter())),

                      // top-left: currently selected title
                      Positioned(
                        left: 48,
                        top: 48,
                        right: 640,
                        child: _SelectedTitle(entry: focused),
                      ),

                      // tile grid
                      Positioned(
                        left: 0,
                        right: 0,
                        top: _gridTop,
                        height: _rows * _tileH + (_rows - 1) * _rowGap,
                        child: _entries.isEmpty
                            ? const Center(
                                child: Text('No games or apps yet',
                                    style: TextStyle(
                                        color: mutedInk,
                                        fontSize: 44,
                                        fontWeight: FontWeight.w700)))
                            : SingleChildScrollView(
                                controller: _scroll,
                                scrollDirection: Axis.horizontal,
                                physics: const NeverScrollableScrollPhysics(),
                                clipBehavior: Clip.none,
                                padding: const EdgeInsets.only(left: 20),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: List.generate(renderCols, (cc) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                          right:
                                              cc == renderCols - 1 ? 0 : _colGap),
                                      child: Column(
                                        children: List.generate(_rows, (rr) {
                                          final entry = _entryAt(rr, cc);
                                          return Padding(
                                            padding: EdgeInsets.only(
                                                bottom:
                                                    rr == _rows - 1 ? 0 : _rowGap),
                                            child: entry == null
                                                ? Tile(
                                                    focused:
                                                        rr == _row && cc == _col,
                                                    label: '',
                                                    empty: true,
                                                  )
                                                : Tile(
                                                    focused:
                                                        rr == _row && cc == _col,
                                                    label: entry.name,
                                                    image: _iconFor(entry),
                                                  ),
                                          );
                                        }),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                      ),

                      // top-right: clock
                      const Positioned(right: 48, top: 40, child: _StatusPill()),

                      // bottom-right: Arcader logo
                      const Positioned(
                          right: 48, bottom: 40, child: Logo(height: 112)),
                    ]),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _SelectedTitle extends StatelessWidget {
  final _Entry? entry;
  const _SelectedTitle({this.entry});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(entry?.name ?? 'Arcader',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: ink, fontWeight: FontWeight.w900, fontSize: 64)),
        if (entry != null) ...[
          const SizedBox(height: 4),
          Text(entry!.kindLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: mutedInk, fontWeight: FontWeight.w700, fontSize: 30)),
        ],
      ],
    );
  }
}

class _StatusPill extends StatefulWidget {
  const _StatusPill();
  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill> {
  Timer? _tick;
  DateTime _now = DateTime.now();
  int? _battery;

  @override
  void initState() {
    super.initState();
    _refresh();
    _tick = Timer.periodic(const Duration(seconds: 20), (_) => _refresh());
  }

  void _refresh() {
    final b = _readBatteryPercent();
    if (mounted) {
      setState(() {
        _now = DateTime.now();
        _battery = b;
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = _battery;
    return Container(
      height: 98,
      decoration: BoxDecoration(
        color: pill,
        borderRadius: BorderRadius.circular(49),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), offset: Offset(4, 6), blurRadius: 14),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            pct != null ? '${_fmtClock(_now)}  |  $pct%' : _fmtClock(_now),
            style: const TextStyle(
                color: ink, fontWeight: FontWeight.w700, fontSize: 42),
          ),
        ],
      ),
    );
  }
}

String _fmtClock(DateTime t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

int? _readBatteryPercent() {
  try {
    final base = Directory('/sys/class/power_supply');
    if (!base.existsSync()) return null;
    for (final e in base.listSync()) {
      final type = File('${e.path}/type');
      final cap = File('${e.path}/capacity');
      if (type.existsSync() &&
          type.readAsStringSync().trim() == 'Battery' &&
          cap.existsSync()) {
        final v = int.tryParse(cap.readAsStringSync().trim());
        if (v != null) return v.clamp(0, 100);
      }
    }
  } catch (_) {}
  return null;
}
