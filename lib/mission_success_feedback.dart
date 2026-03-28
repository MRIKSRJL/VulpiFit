import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:vibration/vibration.dart';

/// Retour audio + vibration après une validation de mission réussie.
/// Sur Android, utilise le moteur natif [Vibration] (souvent plus fiable que [HapticFeedback] seul).
/// Le MP3 est lu en [PlayerMode.mediaPlayer] avec contexte audio adapté.
abstract final class MissionSuccessFeedback {
  static const String _asset = 'assets/victory_fanfare.mp3';
  static const Duration _cutoff = Duration(milliseconds: 850);

  static AudioContext? _androidCtx() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    return AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
    );
  }

  static Future<void> _triggerVibration() async {
    if (kIsWeb) {
      HapticFeedback.mediumImpact();
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        if (await Vibration.hasVibrator()) {
          await Vibration.vibrate(duration: 42);
          return;
        }
      } catch (e) {
        debugPrint('Vibration: $e');
      }
    }
    HapticFeedback.mediumImpact();
  }

  /// À appeler depuis un callback UI (après succès API). Planifie vibration + son sur la frame suivante.
  static void schedulePlay(AudioPlayer player) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(play(player));
    });
  }

  static Future<void> play(AudioPlayer player) async {
    await _triggerVibration();

    try {
      final ctx = _androidCtx();
      await player.stop();
      await player.play(
        AssetSource(_asset),
        mode: PlayerMode.mediaPlayer,
        volume: 1.0,
        ctx: ctx,
      );
      unawaited(
        Future<void>.delayed(_cutoff, () async {
          try {
            await player.stop();
          } catch (_) {}
        }),
      );
    } catch (e, st) {
      debugPrint('MissionSuccessFeedback: $e\n$st');
    }
  }
}
