# Changelog

Internal, human-readable record of what shipped in each Rounds release.
Loosely follows [Keep a Changelog](https://keepachangelog.com/); the git
history (and Jira, for ticketed work) is the source of truth for detail.

## [1.1.0] — submitted 2026-09-16

A visual refresh plus fixes learned from live-testing 1.0. **No paywall, no
History/Calendar/Health/Share** — that work (RO-11, RO-13, RO-14, RO-15,
RO-23) went through a full build-and-test pass on `develop` first and was
deliberately set aside to ship the UI + fixes as a free update on their own.
It isn't lost: that line is preserved on `archive/develop-pre-1.1-reset` for
whenever the paywall gets rebuilt — with a better sense, from this round of
testing, of what's actually worth gating.

`develop` and `release/1.1.0` were reset to branch from `1190168` (1.0.0 +
the UI re-skin) rather than from the abandoned paid line — so version
history jumps 1.0.0 → 1.1.0 on purpose; 2.0.0 stays reserved for whenever
the paid line ships for real.

### Changed
- Adopted the UIWorkouts "Ambient Dark" design refresh on the timer screen —
  `WKTimerDial`, phase-tinted ambient backgrounds, the round-tally pill, the
  segmented progress track.
- "Dim other audio during cues" now only ducks your music for the moment a
  bell or clap actually sounds, instead of for the whole workout.
- Bell volume and the finish buzz tuned down.

### Added
- **Silent workout** setting — vibration-only cues, no bell or clap.
- A 5-second "Get ready" countdown before the first bell.
- Stop now confirms first ("Stop this workout?"), pausing the timer while
  the alert is up.
- A phone call or other audio interruption now pauses the workout; it stays
  paused until you tap Resume.

## [1.0.0] — approved 2026-09-03

Initial App Store release. Round / rest timer, Non-Stop mode, bundled
presets, background audio with lock-screen bells, light/dark appearance.
