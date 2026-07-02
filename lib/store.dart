import 'dart:async';
import 'package:flutter/widgets.dart';

import 'arcaderd.dart';
import 'models.dart';

/// Holds all frontend state and is the single place that talks to the daemon.
///
/// Follows the golden rule from the frontend docs: **cache freely, but react to
/// every event.** Games/apps/covers are cached in memory; `GAMES_UPDATED`,
/// `APPS_UPDATED`, `COVER_UPDATED`, `COIN_STATUS` and `UPDATE_SCREEN` events
/// invalidate the cache and drive the UI live.
class AppStore extends ChangeNotifier {
  final ArcaderClient client;

  bool connected = false;
  List<Game> games = [];
  List<AppTile> apps = [];
  CoinStatus coin = const CoinStatus();

  /// `LOADING` | `SELECTION` | `COIN` — mirrors the daemon's `UPDATE_SCREEN`.
  String screen = 'SELECTION';

  // In-game pause overlay (driven by OVERLAY_* events).
  bool overlayOpen = false;
  bool overlayTimeMode = false;
  int overlayRemaining = 0;
  int overlaySelection = 0; // 0 = Resume, 1 = Exit

  final Map<String, ImageProvider?> _covers = {};
  final Map<String, ImageProvider?> _icons = {};

  AppStore(this.client) {
    client.connection.listen((c) {
      connected = c;
      if (c) {
        _bootstrap();
      }
      notifyListeners();
    });
    client.events.listen(_onEvent);
  }

  Future<void> _bootstrap() async {
    await Future.wait([refreshCoin(), refreshGames(), refreshApps()]);
    // No UPDATE_SCREEN is sent on connect, so derive the initial screen.
    screen = coin.derivedScreen;
    notifyListeners();
  }

  Future<void> refreshGames() async {
    try {
      final r = await client.request('GET_GAMES');
      final list = (r['data']?['games'] as List?) ?? const [];
      games = list
          .whereType<Map<String, dynamic>>()
          .map(Game.fromJson)
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshApps() async {
    try {
      final r = await client.request('GET_APPS');
      final list = (r['data']?['apps'] as List?) ?? const [];
      apps = list
          .whereType<Map<String, dynamic>>()
          .map(AppTile.fromJson)
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshCoin() async {
    try {
      final r = await client.request('GET_COIN_STATUS');
      final data = (r['data'] as Map?)?.cast<String, dynamic>() ?? const {};
      coin = CoinStatus.fromJson(data);
      notifyListeners();
    } catch (_) {}
  }

  void _onEvent(Map<String, dynamic> e) {
    final type = e['type'];
    final data = (e['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    switch (type) {
      case 'UPDATE_SCREEN':
        final s = data['screen'];
        if (s is String) screen = s;
        break;
      case 'COIN_STATUS':
      case 'COIN_INSERTED':
        coin = CoinStatus.fromJson(data);
        // Follow the coin state between COIN/SELECTION, but never yank the user
        // out of a running game (LOADING).
        if (screen == 'COIN' || screen == 'SELECTION') {
          screen = coin.derivedScreen;
        }
        break;
      case 'GAMES_UPDATED':
        _covers.clear();
        refreshGames();
        break;
      case 'COVER_UPDATED':
        _covers.remove(data['gameId']);
        break;
      case 'APPS_UPDATED':
        _icons.clear();
        refreshApps();
        break;
      case 'TIMER_START':
      case 'TIMER_TICK':
      case 'TIMER_STOP':
        final rem = data['remainingSeconds'];
        if (rem is int) overlayRemaining = rem;
        break;
      case 'OVERLAY_OPEN':
        overlayOpen = true;
        overlayTimeMode = data['timeMode'] == true;
        overlayRemaining = (data['remainingSeconds'] as int?) ?? 0;
        overlaySelection = 0;
        break;
      case 'OVERLAY_NAV':
        _overlayNav(data['action']?.toString());
        break;
      case 'OVERLAY_CLOSE':
        overlayOpen = false;
        break;
    }
    notifyListeners();
  }

  void _overlayNav(String? action) {
    switch (action) {
      case 'up':
        overlaySelection = 0;
        break;
      case 'down':
        overlaySelection = 1;
        break;
      case 'select':
        overlaySelection == 0 ? overlayResume() : overlayExit();
        break;
      case 'back':
        overlayResume();
        break;
    }
  }

  // ---- lazy cover / icon loaders (cache + fetch-on-demand) ----

  ImageProvider? coverFor(Game g) {
    if (!g.coverArt) return null;
    if (_covers.containsKey(g.id)) return _covers[g.id];
    _covers[g.id] = null; // mark in-flight
    client.request('GET_COVER', {'gameId': g.id}).then((r) {
      _covers[g.id] = decodeBase64Image(r['data']?['coverData'] as String?);
      notifyListeners();
    }).catchError((_) {});
    return null;
  }

  ImageProvider? iconFor(AppTile a) {
    if (!a.hasIcon) return null;
    if (_icons.containsKey(a.id)) return _icons[a.id];
    _icons[a.id] = null;
    client.request('GET_APP_ICON', {'appId': a.id}).then((r) {
      _icons[a.id] = decodeBase64Image(r['data']?['iconData'] as String?);
      notifyListeners();
    }).catchError((_) {});
    return null;
  }

  // ---- actions ----

  /// Launch an app. Returns null on success, or an error message. The daemon
  /// switches the screen to LOADING via UPDATE_SCREEN on success.
  Future<String?> launchApp(AppTile a) async {
    try {
      final r = await client.request('LAUNCH_APP', {'appId': a.id});
      if (r['type'] == 'LAUNCH_APP_ERROR') {
        return (r['error'] ?? 'Failed to launch').toString();
      }
      return null;
    } catch (_) {
      return 'Failed to launch ${a.name}';
    }
  }

  /// Start a game. Returns null on success, or an error message.
  Future<String?> startGame(Game g) async {
    try {
      final r = await client.request('START_GAME', {'gameUuid': g.id});
      if (r['type'] == 'START_GAME_ERROR') {
        return (r['error'] ?? 'Failed to start').toString();
      }
      return null;
    } catch (_) {
      return 'Failed to start ${g.name}';
    }
  }

  void setOverlaySelection(int i) {
    overlaySelection = i;
    notifyListeners();
  }

  void overlayResume() => client.send('RESUME_GAME');
  void overlayExit() => client.send('EXIT_GAME');
}
