# Car playback contract and regression checks

Both car forks carry the same `car_window_state.dart`,
`car_playback_intent.dart` and `car_recovery_budget.dart` contract. Keep these
files in sync when changing either fork; no runtime dependency on the other repo.

- Native window protocol version 1 uses logical pixels. `split` overrides
  contradictory fullscreen data. Unsupported versions or unknown states retain
  system bars. Flutter owns layout and consumes safe insets once.
- Only `resumed` can restore foreground playback. A user pause cancels automatic
  resume; focus gain alone cannot resume a closed/background foreground-only player.
- Recovery uses 1/2/4/8 second backoff with four attempts. Reopening a URL does not
  reset the budget. Twenty seconds of progress or an explicit user retry resets it.
  A 15-second no-progress watchdog covers streams that fail without an error event.
- Next/previous media buttons are debounced. Navigation MAY_DUCK requests leave
  playback and volume unchanged, including after the navigation request ends.
  Permanent focus loss (competing media) pauses and clears automatic resume;
  the user must explicitly play the video again. Exclusive temporary focus loss
  still pauses and can resume if playback remains eligible.

## Automated check

Run `dart tool/car_contract_test.dart` from the app directory. The car APK workflow
runs this check before building. It covers window classification, malformed input,
retry exhaustion/cancellation and combined playback-interruption states.

## Device regression matrix

1. Repeat host full/split transitions 20 times while playing: same player,
   centered picture, no system-bar oscillation; HVAC and keyboard insets applied once.
2. Pause manually, background and resume; playback stays paused.
3. Interrupt playback with navigation and a call; test independent navigation audio,
   focus gain while backgrounded, manual pause during interruption and media keys.
4. Disconnect networking during buffering, restore it, then repeat with an expired
   URL. Check bounded retries and correct status. Exit or change content during
   every await: old content must never restart.
5. Sleep for 30 seconds and resume; verify fresh live URLs / on-demand position.
6. Verify no network retry for local media, normal non-car mode, and repeated
   open/close cycles with no retained timers or media sessions.

Local validation uses the available standalone Dart SDK for syntax and contract
checks. Full Flutter/Android compilation runs in Actions. OEM focus forwarding,
HVAC behavior and actual sleep/resume require a physical vehicle head unit.

PiliPlus retains existing history/episode selection. Car progress is checkpointed
every five seconds and at interruption, respecting the history pause preference.
Explicit seek/history progress takes precedence over the local checkpoint.
The sidebar history button uses the existing `/history` route.

Navigation handling is based on the standard MAY_DUCK focus request, not app
package names. OEM navigation requesting exclusive/permanent focus cannot be
distinguished from other exclusive audio by this API; verify actual headrest
speaker routing on-device. Android requests use willPauseWhenDucked=true to
receive callbacks instead of framework attenuation, and deliberately ignore
MAY_DUCK in the car policy. Do not remove this flag or re-request focus on duck.
