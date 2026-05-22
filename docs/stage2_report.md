# Stage 2 Report

## Goal

Stage 2 adds local persistence while staying in mock mode. The app can restore
the last mock `QuotaSnapshot`, keep bounded snapshot history, persist refresh
settings, and clear only its own local storage keys.

No WebView, real GPT/Codex/OpenAI login, cookie reading, token access, real
usage page parsing, backend, analytics SDK, crash reporting SDK, or background
daemon was added.

## Implemented

- Added `shared_preferences` as the only new runtime dependency.
- Added `JsonStorage` and `SharedPreferencesStorage` under `lib/core/storage`.
- Added stable JSON serialization for `QuotaSnapshot`, `QuotaWindow`,
  `AppSettings`, and enum values.
- Added `LocalQuotaDataSource` for latest snapshot and history persistence.
- Added `PersistentQuotaRepository`, which combines `MockQuotaDataSource` with
  local cache reads/writes.
- Added settings domain entities, repository contract, local data source, local
  repository, use cases, and controller.
- Updated the app shell to bootstrap persistent repositories by default.
- Updated the Quota page to show whether the current snapshot was loaded from
  local cache.
- Updated Settings with explicit save, persisted interval/auto-refresh state,
  and a clear-local-data entry.
- Updated Debug with persistence mode, storage backend, cache existence,
  history count, current settings, load/save timestamps, last persistence error,
  recent history, and clear-local-data.

## Storage Scheme

Storage backend: `shared_preferences`.

Keys owned by this app:

- `quota.latest_snapshot.v1`: latest mock `QuotaSnapshot` JSON object.
- `quota.snapshot_history.v1`: JSON list of mock `QuotaSnapshot` objects.
- `settings.app_settings.v1`: persisted `AppSettings` JSON object.

Snapshot history is stored newest-first and capped at 100 records.

## Serialization

- `DateTime` values are stored as ISO 8601 strings.
- Enums are stored as stable string keys via `enum.name`, never index values.
- Missing snapshot fields fall back to safe defaults.
- Corrupted latest snapshot data is ignored and removed.
- Corrupted history root data is ignored and removed.
- Corrupted history entries are skipped without crashing startup.
- Corrupted settings data falls back to defaults and removes the bad key.

## Startup Restore

On app startup, `PersistentQuotaRepository.getLatestSnapshot()` first tries
`LocalQuotaDataSource.loadLatestSnapshot()`.

- If a saved latest snapshot exists and parses, the dashboard shows it and marks
  `Loaded from local cache: true`.
- If no valid latest snapshot exists, the repository falls back to
  `MockQuotaDataSource.getLatestSnapshot()` and marks local-cache loading false.

Manual mock refresh still uses `MockQuotaDataSource`. After a successful refresh,
the snapshot is saved as the latest snapshot and inserted into history.

## Clear Local Data

The clear action is available from Settings and Debug and requires confirmation.
It removes only:

- `quota.latest_snapshot.v1`
- `quota.snapshot_history.v1`
- `settings.app_settings.v1`

It does not touch project files, Flutter caches, system files, browser data,
tokens, cookies, credentials, or any storage outside this app's owned keys.

After clearing, the dashboard reloads a fresh mock default snapshot, history is
empty, and settings return to defaults.

## Tests

Added coverage for:

- `QuotaSnapshot` JSON round-trip.
- `QuotaWindow` JSON round-trip.
- Enum string serialization for quota and settings enums.
- Local quota data source latest snapshot save/load.
- Local quota history append, max length 100, and clear.
- Corrupted local quota JSON handling.
- Settings repository defaults, save/load, clear, and corrupted JSON handling.
- Widget flows for local snapshot display, refresh timestamp update, settings
  interval update, debug history count, and clear local data.

Latest local verification in this stage:

- `flutter pub get`: passed.
- `flutter analyze`: passed.
- `flutter test`: passed with 27 tests.
- `flutter devices`: only Chrome was connected; no Android emulator or physical
  mobile device was available.

Emulator launch verification was not performed because no Android emulator or
physical mobile device was available during final validation.

## Known Issues

- Automatic refresh is only a persisted setting. No timer, background refresh,
  notification, daemon, cron, launchd, or system scheduler exists yet.
- The persisted data is still mock-only and must not be treated as real quota.
- Debug raw text is currently mock text. Future real parser work must treat raw
  extracted text as sensitive.

## Next Stage Suggestions

- Draft the WebView threat model before any login container work.
- Keep clear-session and clear-local-data boundaries separate in Stage 3.
- Decide whether raw extracted usage text should ever be persisted before Stage
  4 parser work begins.
