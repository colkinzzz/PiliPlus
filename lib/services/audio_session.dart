import 'dart:io' show Platform;
import 'package:PiliPlus/utils/car_audio_focus_policy.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:audio_session/audio_session.dart';
import 'package:PiliPlus/utils/storage_pref.dart';

class AudioSessionHandler {
  late AudioSession session;
  late final Future<void> _ready = initSession();
  PlPlayerController? _interruptedPlayer;
  PlPlayerController? _duckedPlayer;
  double? _volumeBeforeDuck;
  bool interrupted = false;
  bool _usingCarFocus = false;

  Future<void> _restoreDuck() async {
    final saved = _volumeBeforeDuck;
    final owner = _duckedPlayer;
    _volumeBeforeDuck = null;
    _duckedPlayer = null;
    if (saved != null && identical(owner, PlPlayerController.instance)) {
      final output = owner?.videoPlayerController;
      if (output != null && (output.state.volume - saved * 0.5).abs() < 0.01) {
        await output.setVolume(saved);
      }
    }
  }

  AudioSessionHandler() {
    _ready.catchError((Object _) {});
  }

  Future<bool> _activation = Future.value(false);
  Future<bool> setActive(bool active) {
    return _activation = _activation.then((_) => _applyActive(active));
  }

  Future<bool> _applyActive(bool active) async {
    try {
      await _ready;
      if (!active) await _restoreDuck();
      final useCarFocus = active ? Platform.isAndroid && Pref.carMode : _usingCarFocus;
      _usingCarFocus = useCarFocus;
      final bool granted;
      if (useCarFocus) {
        final manager = AndroidAudioManager();
        granted = active
            ? await manager.requestAudioFocus(AndroidAudioFocusRequest(
                gainType: AndroidAudioFocusGainType.gain,
                audioAttributes: const AndroidAudioAttributes(
                  usage: AndroidAudioUsage.media,
                  contentType: AndroidAudioContentType.music,
                ),
                // Prevent framework ducking. Raw MAY_DUCK remains distinct
                // from exclusive interruptions and is ignored by our policy.
                willPauseWhenDucked: true,
                onAudioFocusChanged: (focus) { _onCarFocus(focus.index); },
              ))
            : await manager.abandonAudioFocus();
      } else {
        granted = await session.setActive(active);
      }
      // Permanent focus loss may not emit an end event. An explicit new
      // successful request is also proof that the interruption has ended.
      if (active && granted) interrupted = false;
      return granted;
    } catch (_) {
      return false;
    }
  }

  void cancelResume() {
    _interruptedPlayer = null;
  }

  Future<void> _onCarFocus(int focus) async {
    if (!_usingCarFocus) return;
    final player = PlPlayerController.instance;
    switch (carAudioFocusAction(focus)) {
      case CarAudioFocusAction.ignore:
        // Headrest navigation owns its own output. Do not change volume,
        // playback intent, resume ownership or request audio focus here.
        return;
      case CarAudioFocusAction.pauseUntilUserPlay:
        _interruptedPlayer = null;
        interrupted = true;
        await player?.pause();
        return;
      case CarAudioFocusAction.pauseTemporarily:
        interrupted = true;
        if (player != null && player.carWantsPlayback) {
          _interruptedPlayer = player;
          await player.pause(isInterrupt: true);
        }
        return;
      case CarAudioFocusAction.resume:
        interrupted = false;
        final owner = _interruptedPlayer;
        _interruptedPlayer = null;
        if (owner != null && identical(owner, player) && owner.canCarResume) {
          await owner.play(systemResume: true);
        }
        return;
    }
  }

  Future<void> initSession() async {
    session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    session.interruptionEventStream.listen((event) async {
      if (_usingCarFocus) return;
      final player = PlPlayerController.instance;
      if (event.begin) {
        if (event.type == AudioInterruptionType.duck) {
          if (player?.videoPlayerController?.state.playing != true ||
              _volumeBeforeDuck != null)
            return;
          _duckedPlayer = player;
          _volumeBeforeDuck = player!.videoPlayerController!.state.volume;
          // Duck only this player's output, never the car's system volume.
          await player.videoPlayerController?.setVolume(
            _volumeBeforeDuck! * 0.5,
          );
        } else {
          interrupted = true;
          if (player != null && player.carWantsPlayback) {
            _interruptedPlayer = player;
            await player.pause(
              isInterrupt: event.type == AudioInterruptionType.pause,
            );
          }
        }
      } else if (event.type == AudioInterruptionType.duck) {
        await _restoreDuck();
      } else {
        interrupted = false;
        final owner = _interruptedPlayer;
        _interruptedPlayer = null;
        if (event.type == AudioInterruptionType.pause &&
            owner != null &&
            identical(owner, player) &&
            owner.canCarResume) {
          await owner.play(systemResume: true);
        }
      }
    });
    session.becomingNoisyEventStream.listen((_) {
      cancelResume();
      PlPlayerController.pauseIfExists();
    });
  }
}
