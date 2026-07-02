import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A single, persistent client for the arcaderd Unix-domain socket.
///
/// Speaks the newline-delimited JSON protocol documented in
/// `Docs/src/content/docs/frontend.md`:
///   - Requests carry a `requestId`; the matching response echoes it, and is
///     delivered by completing the [request] future.
///   - Events have no `requestId` and are pushed onto [events].
///
/// Reconnects automatically and pings with `HELLO` so a dropped daemon is
/// noticed quickly. This is the *only* thing the modern frontend talks to — no
/// admin server, no HTTP, no filesystem catalog.
class ArcaderClient {
  /// Optional explicit socket path (used in tests). When null, the path is
  /// derived from `$XDG_RUNTIME_DIR/arcaderd.sock`.
  final String? socketPathOverride;

  ArcaderClient({this.socketPathOverride});

  Socket? _socket;
  final List<int> _buffer = [];
  int _reqCounter = 0;
  final Map<String, Completer<Map<String, dynamic>>> _pending = {};
  final _events = StreamController<Map<String, dynamic>>.broadcast();
  final _connection = StreamController<bool>.broadcast();
  Timer? _ping;
  Timer? _reconnect;
  bool _closed = false;

  /// Unsolicited daemon events (`UPDATE_SCREEN`, `COIN_STATUS`, `GAMES_UPDATED`,
  /// `APPS_UPDATED`, `OVERLAY_*`, `TIMER_*`, ...).
  Stream<Map<String, dynamic>> get events => _events.stream;

  /// `true`/`false` as the socket connects and drops.
  Stream<bool> get connection => _connection.stream;

  bool get isConnected => _socket != null;

  static String? socketPath() {
    final explicit = Platform.environment['ARCADER_SOCKET'];
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final rt = Platform.environment['XDG_RUNTIME_DIR'];
    if (rt == null || rt.isEmpty) return null;
    return '$rt/arcaderd.sock';
  }

  Future<void> start() async {
    _closed = false;
    await _connect();
  }

  Future<void> _connect() async {
    final path = socketPathOverride ?? socketPath();
    if (path == null) {
      _scheduleReconnect();
      return;
    }
    try {
      final s = await Socket.connect(
        InternetAddress(path, type: InternetAddressType.unix),
        0,
      );
      _socket = s;
      _connection.add(true);
      s.listen(
        _onData,
        onError: (_) => _onDisconnect(),
        onDone: _onDisconnect,
        cancelOnError: true,
      );
      _startPing();
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onData(List<int> data) {
    _buffer.addAll(data);
    while (true) {
      final nl = _buffer.indexOf(10); // '\n'
      if (nl < 0) break;
      final line = utf8.decode(_buffer.sublist(0, nl), allowMalformed: true);
      _buffer.removeRange(0, nl + 1);
      if (line.trim().isEmpty) continue;
      try {
        final obj = jsonDecode(line);
        if (obj is Map<String, dynamic>) _dispatch(obj);
      } catch (_) {
        // ignore malformed lines
      }
    }
  }

  void _dispatch(Map<String, dynamic> obj) {
    final reqId = obj['requestId'];
    if (reqId is String) {
      final c = _pending.remove(reqId);
      if (c != null && !c.isCompleted) c.complete(obj);
      return;
    }
    // No requestId -> it's an event.
    if (obj['type'] != null) _events.add(obj);
  }

  /// Send a request and await its response. Rejects on timeout/disconnect.
  Future<Map<String, dynamic>> request(String type,
      [Map<String, dynamic>? data]) {
    final s = _socket;
    final id = 'req_${++_reqCounter}';
    final completer = Completer<Map<String, dynamic>>();
    if (s == null) {
      completer.completeError('not connected');
      return completer.future;
    }
    _pending[id] = completer;
    s.write('${jsonEncode({
          'type': type,
          'requestId': id,
          'data': data ?? {},
        })}\n');
    Timer(const Duration(seconds: 8), () {
      final c = _pending.remove(id);
      if (c != null && !c.isCompleted) c.completeError('timeout');
    });
    return completer.future;
  }

  /// Fire-and-forget message (no `requestId`, no response) — e.g. `RESUME_GAME`.
  void send(String type, [Map<String, dynamic>? data]) {
    _socket?.write('${jsonEncode({'type': type, 'data': data ?? {}})}\n');
  }

  void _startPing() {
    _ping?.cancel();
    _ping = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        await request('HELLO');
      } catch (_) {
        _onDisconnect();
      }
    });
  }

  void _onDisconnect() {
    if (_socket == null) return;
    _ping?.cancel();
    try {
      _socket?.destroy();
    } catch (_) {}
    _socket = null;
    _connection.add(false);
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError('disconnected');
    }
    _pending.clear();
    _buffer.clear();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_closed) return;
    _reconnect?.cancel();
    _reconnect = Timer(const Duration(seconds: 2), _connect);
  }

  void dispose() {
    _closed = true;
    _ping?.cancel();
    _reconnect?.cancel();
    _socket?.destroy();
    _events.close();
    _connection.close();
  }
}
