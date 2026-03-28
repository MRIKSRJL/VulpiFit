import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_screen.dart';
import 'dashboard_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('Audio global: $e\n$st');
    }
  }

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e, st) {
    debugPrint('Firebase init: $e\n$st');
  }

  try {
    await initializeDateFormatting('fr_FR', null);
  } catch (e, st) {
    debugPrint('Date formatting init: $e\n$st');
  }

  runApp(const VulpiFitApp());
}

class VulpiFitApp extends StatelessWidget {
  const VulpiFitApp({super.key});

  // 🕵️‍♂️ VÉRIFICATION SILENCIEUSE : A-t-on un token enregistré dans le téléphone ?
  Future<bool> _checkIfLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false; // En cas de doute, on dit qu'on n'est pas connecté
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VulpiFit',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00FFD1),
          onPrimary: const Color(0xFF0A0E17),
          secondary: const Color(0xFFFF2D95),
          onSecondary: Colors.white,
          surface: const Color(0xFF12182A),
          onSurface: Colors.white,
          error: const Color(0xFFFF5252),
        ),
        scaffoldBackgroundColor: const Color(0xFF060814),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F1628),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E2740),
          contentTextStyle: const TextStyle(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF12182A),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: const Color(0xFF00FFD1).withValues(alpha: 0.35)),
          ),
        ),
      ),
      // 🚦 L'AIGUILLEUR : Décide quelle page afficher au démarrage
      home: FutureBuilder<bool>(
        future: _checkIfLoggedIn(),
        builder: (context, snapshot) {
          // 1. Pendant qu'on cherche dans la mémoire (ça prend quelques millisecondes)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF060814),
              body: Center(child: CircularProgressIndicator(color: Color(0xFF00FFD1))),
            );
          }
          
          // 2. Si on a trouvé un token (l'utilisateur est déjà connecté)
          if (snapshot.data == true) {
            return const DashboardScreen();
          } 
          // 3. Sinon (nouvel utilisateur ou compte supprimé)
          else {
            return const AuthScreen();
          }
        },
      ),
    );
  }
}
