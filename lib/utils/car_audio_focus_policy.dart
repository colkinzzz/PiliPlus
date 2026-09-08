/// Standard Android focus changes. Navigation's MAY_DUCK is independent
/// of competing media's permanent focus loss; callbacks do not identify apps.
enum CarAudioFocusAction { ignore, pauseTemporarily, pauseUntilUserPlay, resume }

CarAudioFocusAction carAudioFocusAction(int focus) => switch (focus) {
  -3 => CarAudioFocusAction.ignore,
  -2 => CarAudioFocusAction.pauseTemporarily,
  -1 => CarAudioFocusAction.pauseUntilUserPlay,
  1 => CarAudioFocusAction.resume,
  _ => CarAudioFocusAction.ignore,
};
