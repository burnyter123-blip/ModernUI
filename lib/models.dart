import 'dart:convert';
import 'package:flutter/widgets.dart';

/// A game as returned by `GET_GAMES`.
class Game {
  final String id;
  final String name;
  final String console;
  final String extension;
  final String filename;
  final bool coverArt;

  Game({
    required this.id,
    required this.name,
    required this.console,
    required this.extension,
    required this.filename,
    required this.coverArt,
  });

  factory Game.fromJson(Map<String, dynamic> j) => Game(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        console: (j['console'] ?? '').toString(),
        extension: (j['extension'] ?? '').toString(),
        filename: (j['filename'] ?? '').toString(),
        coverArt: j['cover_art'] == true,
      );
}

/// An app tile as returned by `GET_APPS`. `type` is `web` or `native`.
class AppTile {
  final String id;
  final String name;
  final String type;
  final String? url;
  final String? exec;
  final List<String> args;
  final bool hasIcon;

  AppTile({
    required this.id,
    required this.name,
    required this.type,
    this.url,
    this.exec,
    this.args = const [],
    this.hasIcon = false,
  });

  factory AppTile.fromJson(Map<String, dynamic> j) => AppTile(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        type: (j['type'] ?? '').toString(),
        url: j['url'] as String?,
        exec: j['exec'] as String?,
        args: (j['args'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        hasIcon: j['icon'] == true,
      );

  String get target {
    if (type == 'web') return url ?? '';
    if (type == 'native') return [exec, ...args].whereType<String>().join(' ').trim();
    return '';
  }

  String get kindLabel => switch (type) {
        'web' => 'Web app',
        'native' => 'App',
        _ => type,
      };
}

/// The coin/credit state shared by `GET_COIN_STATUS_RESPONSE`, `COIN_STATUS`
/// and `COIN_INSERTED`.
class CoinStatus {
  final int credits;
  final int remainingSeconds;
  final bool timeMode;
  final bool hardwareConnected;
  final bool freePlay;
  final bool coinSlotEnabled;
  final bool konamiCodeEnabled;
  final String insertMessage;
  final String infoMessage;

  const CoinStatus({
    this.credits = 0,
    this.remainingSeconds = 0,
    this.timeMode = false,
    this.hardwareConnected = false,
    this.freePlay = false,
    this.coinSlotEnabled = false,
    this.konamiCodeEnabled = false,
    this.insertMessage = 'INSERT COIN',
    this.infoMessage = '',
  });

  factory CoinStatus.fromJson(Map<String, dynamic> j) => CoinStatus(
        credits: (j['credits'] ?? 0) as int,
        remainingSeconds: (j['remainingSeconds'] ?? 0) as int,
        timeMode: j['timeMode'] == true,
        hardwareConnected: j['hardwareConnected'] == true,
        freePlay: j['freePlay'] == true,
        coinSlotEnabled: j['coinSlotEnabled'] == true,
        konamiCodeEnabled: j['konamiCodeEnabled'] == true,
        insertMessage: (j['insertMessage'] ?? 'INSERT COIN').toString(),
        infoMessage: (j['infoMessage'] ?? '').toString(),
      );

  /// Which screen the daemon would show for this state, replicating arcaderd's
  /// `post_game_screen`. Used to pick the initial screen before any
  /// `UPDATE_SCREEN` event arrives.
  String get derivedScreen {
    if (!coinSlotEnabled || freePlay) return 'SELECTION';
    final exhausted = timeMode ? remainingSeconds <= 0 : credits == 0;
    return exhausted ? 'COIN' : 'SELECTION';
  }
}

/// Decode a base64 cover/icon payload into an ImageProvider, or null if empty.
ImageProvider? decodeBase64Image(String? b64) {
  if (b64 == null || b64.isEmpty) return null;
  try {
    return MemoryImage(base64Decode(b64));
  } catch (_) {
    return null;
  }
}
