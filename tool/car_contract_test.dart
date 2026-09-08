import '../lib/utils/car_audio_focus_policy.dart';
import '../lib/utils/car_playback_intent.dart';
import '../lib/utils/car_window_state.dart';
import '../lib/utils/car_recovery_budget.dart';

void check(bool value, String message) {
  if (!value) throw StateError(message);
}

void main() {
  for (final raw in [null, 'unexpected', 'split']) {
    final state = CarWindowState.fromMap({'hostWindowState': raw});
    check(!state.canUseImmersive, 'Unknown/split must preserve system bars');
  }
  check(!CarWindowState.unsupported().canUseImmersive, 'Unsupported');
  check(
    CarWindowState.fromMap({'hostWindowState': 'full'}).canUseImmersive,
    'Full',
  );
  check(
    CarWindowState.fromMap({'isInMultiWindowMode': true}).hostWindowState ==
        'split',
    'Multiwindow fallback',
  );
  check(
    !CarWindowState.fromMap({
      'hostWindowState': 'full',
      'isInMultiWindowMode': true,
    }).canUseImmersive,
    'Split overrides contradictory full',
  );
  check(
    !CarWindowState.fromMap({
      'schemaVersion': 9,
      'hostWindowState': 'full',
    }).canUseImmersive,
    'Unknown schema is conservative',
  );
  final malformed = CarWindowState.fromMap({
    'width': 'bad',
    'height': double.nan,
    'insetBottom': -10,
    'hostWindowState': 42,
  });
  check(
    malformed.width == 0 && malformed.height == 0 && malformed.insetBottom == 0,
    'Malformed dimensions',
  );
  check(!malformed.canUseImmersive, 'Malformed state');
  final budget = CarRecoveryBudget();
  final ticket = budget.generation;
  for (final seconds in [1, 2, 4, 8]) {
    check(budget.nextDelay()?.inSeconds == seconds, 'Backoff sequence');
  }
  check(budget.nextDelay() == null, 'Retry limit');
  budget.cancel();
  check(!budget.isCurrent(ticket), 'Cancelled request cannot resume');
  check(budget.nextDelay() == null, 'Cancel must not reset retry budget');
  budget.reset();
  check(budget.nextDelay()?.inSeconds == 1, 'Explicit retry resets budget');
  check(carAudioFocusAction(-3) == CarAudioFocusAction.ignore,
      'Navigation must not pause, duck, or acquire focus again');
  check(carAudioFocusAction(-1) == CarAudioFocusAction.pauseUntilUserPlay,
      'Competing music must pause without automatic restart');
  check(carAudioFocusAction(-2) == CarAudioFocusAction.pauseTemporarily,
      'Exclusive temporary interruption still pauses');
  check(carAudioFocusAction(1) == CarAudioFocusAction.resume, 'Focus gain');
  check(carAudioFocusAction(99) == CarAudioFocusAction.ignore, 'Unknown focus');
  final intent = CarPlaybackIntent();
  check(intent.canResume(), 'Initially eligible');
  intent.interrupted = true;
  check(!intent.canResume(), 'Focus loss blocks playback');
  intent.inBackground = true;
  intent.interrupted = false;
  check(!intent.canResume(), 'Focus gain alone must not resume in background');
  intent.inBackground = false;
  check(intent.canResume(), 'Resume after temporary interruption');
  intent.interrupted = true;
  intent.wantsPlayback = false;
  intent.interrupted = false;
  check(!intent.canResume(), 'Manual pause during navigation remains paused');
  intent.wantsPlayback = true;
  intent.inBackground = true;
  check(
    intent.canResume(allowBackground: true),
    'Explicit background playback',
  );
  intent.closed = true;
  check(
    !intent.canResume(allowBackground: true),
    'Closed player never resumes',
  );
  final competingMedia = CarPlaybackIntent();
  // Apply the same permanent-loss effect as both adapters, then simulate gain.
  if (carAudioFocusAction(-1) == CarAudioFocusAction.pauseUntilUserPlay) {
    competingMedia.wantsPlayback = false;
  }
  competingMedia.interrupted = false;
  check(!competingMedia.canResume(), 'Music stopped: video must wait for user');
  print('Car window, playback intent, audio focus and recovery contracts passed');
}
