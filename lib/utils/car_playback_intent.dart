/// Playback intent survives temporary interruptions, never a manual pause.
class CarPlaybackIntent {
  bool wantsPlayback = true;
  bool inBackground = false;
  bool interrupted = false;
  bool closed = false;

  bool canResume({bool allowBackground = false}) =>
      !closed &&
      wantsPlayback &&
      !interrupted &&
      (!inBackground || allowBackground);
}
