/// Shared car playback retry contract, independent of Flutter.
class CarRecoveryBudget {
  int attempts = 0;
  int generation = 0;
  static const delays = [1, 2, 4, 8];

  Duration? nextDelay() {
    if (attempts >= delays.length) return null;
    return Duration(seconds: delays[attempts++]);
  }

  void cancel() {
    generation++;
  }

  void reset() {
    cancel();
    attempts = 0;
  }

  bool isCurrent(int ticket) => ticket == generation;
}
