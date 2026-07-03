import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/character_select_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const PataApp());
}

class PataApp extends StatelessWidget {
  const PataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pata Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1a0533),
      ),
      home: const TitleScreen(),
    );
  }
}

class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PATAPONY\nROZRABIAJĄ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.1,
                shadows: [
                  Shadow(blurRadius: 20, color: Color(0xFF6a0dad)),
                  Shadow(blurRadius: 40, color: Color(0xFF6a0dad)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Platformowa przygoda jednookich stworków',
              style: TextStyle(fontSize: 16, color: Colors.white54),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6a0dad),
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CharacterSelectScreen()),
                );
              },
              child: const Text('GRAJ', style: TextStyle(fontSize: 28, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
