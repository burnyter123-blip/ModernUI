import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'arcaderd.dart';
import 'coin_screen.dart';
import 'home_screen.dart';
import 'loading_screen.dart';
import 'overlay_menu.dart';
import 'store.dart';
import 'sounds.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  final client = ArcaderClient();
  final store = AppStore(client);
  client.start();
  runApp(ModernFrontend(store: store));
}

class ModernFrontend extends StatelessWidget {
  final AppStore store;
  const ModernFrontend({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arcader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'ConsoleSans',
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: Root(store: store),
    );
  }
}

/// Chooses the visible screen from the daemon-driven `screen` state and layers
/// the pause overlay on top when the daemon opens it.
class Root extends StatefulWidget {
  final AppStore store;
  const Root({super.key, required this.store});

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => Sounds.I.startMusic());
    // Pause the home theme while a game/app is in the foreground, resume on
    // return — mirrors the daemon's screen lifecycle.
    widget.store.addListener(_onScreen);
  }

  String _lastScreen = 'SELECTION';
  void _onScreen() {
    final s = widget.store.screen;
    if (s == _lastScreen) return;
    _lastScreen = s;
    if (s == 'LOADING') {
      Sounds.I.pauseMusic();
    } else {
      Sounds.I.resumeMusic();
    }
  }

  @override
  void dispose() {
    widget.store.removeListener(_onScreen);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        if (!widget.store.connected) {
          return const _WaitingForDaemon();
        }

        final Widget screen = switch (widget.store.screen) {
          'COIN' => CoinScreen(coin: widget.store.coin),
          'LOADING' => const LoadingScreen(),
          _ => HomeScreen(store: widget.store),
        };

        return Stack(
          children: [
            Positioned.fill(child: screen),
            if (widget.store.overlayOpen)
              Positioned.fill(child: OverlayMenu(store: widget.store)),
          ],
        );
      },
    );
  }
}

class _WaitingForDaemon extends StatelessWidget {
  const _WaitingForDaemon();
  @override
  Widget build(BuildContext context) {
    final hasRuntime = ArcaderClient.socketPath() != null;
    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation(glowBlue),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              hasRuntime
                  ? 'Connecting to arcaderd…'
                  : 'XDG_RUNTIME_DIR not set — cannot reach arcaderd',
              style: const TextStyle(
                  color: ink, fontWeight: FontWeight.w700, fontSize: 34),
            ),
          ],
        ),
      ),
    );
  }
}
