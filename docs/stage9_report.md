# Stage 9 Report: Android Home Screen Widget - Data Export Layer

## Goal

Stage 9 prepares for an Android home screen widget by exporting a stable,
display-safe quota summary from the latest app-owned `QuotaSnapshot`.

This stage intentionally implements only the data export layer. It does not
implement an Android `AppWidgetProvider`, Kotlin widget UI, XML widget layout,
widget click actions, widget background refresh, iOS WidgetKit, or Wear OS
tiles.

## Why Export First

Android widgets should not depend on the app's internal parser, WebView, login
container, or full snapshot model. Stage 9 creates a small schema that future
native widget code can read without touching sensitive or complex app state.

Separating data export from widget UI keeps the security boundary reviewable:
the widget shell in Stage 10 can display already-exported fields, while the app
continues to own WebView/manual refresh behavior.

## WidgetSnapshotSummary Schema

`WidgetSnapshotSummary` is versioned with `schemaVersion: "1"` and currently
contains:

- `id`
- `fiveHourRemainingRatio`
- `fiveHourResetText`
- `fiveHourResetAt`
- `weeklyRemainingRatio`
- `weeklyResetText`
- `weeklyResetAt`
- `creditsRemaining`
- `lastUpdatedAt`
- `source`
- `parserConfidence`
- `isStale`
- `staleReason`
- `displayTitle`
- `displaySubtitle`
- `statusLabel`
- `errorLabel`
- `exportedAt`

Date/time fields are ISO 8601 strings in JSON. Enum-like values are stored as
strings, never enum indexes. Remaining ratios are clamped to `0.0..1.0` and may
be `null` when unavailable.

The summary deliberately excludes `accountLabel`, `rawDebugText`, extracted
page text, parser input, parser raw evidence, matched signal text, cookies,
tokens, browser storage, authorization headers, and URLs.

## Mapper

`QuotaSnapshotToWidgetSummaryMapper` maps:

- `fiveHourWindow.remainingRatio` to `fiveHourRemainingRatio`.
- `fiveHourWindow.resetAt` to `fiveHourResetAt`.
- `weeklyWindow.remainingRatio` to `weeklyRemainingRatio`.
- `weeklyWindow.resetAt` to `weeklyResetAt`.
- `creditsRemaining` directly when present.
- `capturedAt` to `lastUpdatedAt`.
- `source.storageKey` to `source`.
- `parserConfidence.storageKey` to `parserConfidence`.

Because `QuotaWindow` does not currently persist reset display text, reset text
is generated conservatively as `Reset time available` or `Reset time unknown`.

Staleness uses a simple 30-minute age threshold for Stage 9. A stale snapshot
gets `isStale: true`, `staleReason: stale_by_age`, and `statusLabel: STALE`.
Fresh data uses `fresh`. Low quota uses `LOW` when either window ratio is at or
below `0.25`; otherwise status is `OK` or `UNKNOWN`.

## Storage Strategy

Stage 9 uses the existing app-owned `JsonStorage` abstraction backed by
`shared_preferences`.

Keys:

- `widget.latest_summary_json`
- `widget.last_exported_at`
- `widget.export_status`
- `widget.last_export_error`

This keeps the schema stable and avoids introducing a database. Storage errors
return safe export metadata and do not fail the quota snapshot save path.

Current `shared_preferences` storage is convenient for Flutter-side tests and
Debug UI. Stage 10 should decide whether the native Kotlin widget can read this
data directly in the deployed Android preferences file or whether to mirror the
same JSON summary through a small platform bridge/native SharedPreferences key.
The schema and export service are intentionally independent of that choice.

## Export Triggers

`WidgetExportingQuotaRepository` wraps the active `QuotaRepository` and exports
after successful quota persistence operations:

- App startup load of a non-mock latest snapshot.
- Manual refresh save success.
- Quota page `Refresh usage page` save success because it reuses the manual
  refresh save path.
- Foreground auto refresh save success because it reuses the manual refresh
  save path.
- Mock fallback startup snapshots are not exported, so clearing local data does
  not immediately repopulate widget data with demo data.

Background notify-only work does not read WebView or create new snapshots in
Stage 9. It does not trigger widget export.

## Clear Local Data

`clearLocalQuotaData` clears the widget summary through the wrapper repository.
The app-level clear-local-data flow also calls `WidgetExportController` clear
so the Debug UI reflects the cleared state immediately.

After clearing, the stored summary is absent and metadata records
`widget.export_status = cleared`.

## Debug UI

The Debug page now includes a `Widget Export` section with:

- Widget export enabled.
- Last widget export status.
- Last widget exported at.
- Last widget export error.
- Latest widget summary preview.
- Schema version.
- Stale status.
- Status label.
- Source.
- Parser confidence.
- `Export widget summary now`.
- `Clear widget summary`.
- Stage 9 note that no Android widget UI exists yet.

The Settings page local-data copy now includes widget summary export in the
clear description. A dedicated Settings widget section is deferred to a future
stage to avoid adding unnecessary settings complexity.

## Security Boundary

Widget export does not save:

- Raw page text.
- Redacted full page text.
- Parser input.
- Parser raw evidence text.
- Parser matched signal text.
- `document.body.innerText`.
- Cookies.
- Tokens.
- `localStorage` or `sessionStorage`.
- Authorization headers.
- Full URL query or fragment.
- Account email or account label.
- Sensitive debug logs.

Widget export does not call WebView, parser, login, extraction, network, or
background refresh APIs. It reads only an already-created `QuotaSnapshot` and
writes a reduced display summary.

## Tests

Added coverage for:

- `WidgetSnapshotSummary` JSON round trip, schema version, ISO 8601 dates,
  string enum-like fields, and null fields.
- `QuotaSnapshot -> WidgetSnapshotSummary` mapping, reset fields, credits,
  source/confidence strings, stale/fresh status, low quota status, and no raw
  debug/extracted/account text copying.
- Local widget summary datasource save/load/clear, corrupted JSON fallback, and
  metadata save/load.
- Widget summary repository export, safe failure result, clear, and missing
  summary state.
- Export triggers for manual refresh save, Quota page save path, foreground
  auto refresh save path, clear local data, and export failure isolation.
- Debug widget export section, status card, summary preview, and action
  buttons.

Verification during implementation:

- `flutter analyze`: passed.
- `flutter test test/features/widget_export test/widget/widget_export_status_card_test.dart`: passed.
- Full `flutter test`: passed.

## Manual Verification

Use an emulator or real Android device when available:

1. Open the app.
2. Complete one `Refresh usage page` or manual refresh.
3. Confirm the Quota dashboard updates.
4. Open Debug.
5. Scroll to `Widget Export`.
6. Confirm a latest widget summary exists.
7. Confirm the summary shows only remaining ratios, reset times, credits,
   last-updated time, source, confidence, and safe status labels.
8. Tap `Export widget summary now`.
9. Confirm `Last widget exported at` updates.
10. Tap `Clear widget summary`.
11. Confirm the widget summary preview shows no data.
12. Refresh again and confirm the summary regenerates.
13. Use `Clear local data` and confirm the widget summary is cleared.

No emulator/manual device run was performed during this coding pass unless
reported separately in the final verification notes.

## Known Limits

- No Android native widget shell exists yet.
- No Kotlin widget UI or XML widget layout exists yet.
- No widget click behavior exists yet.
- No widget background refresh exists yet.
- Stage 9 staleness uses a fixed 30-minute threshold rather than a user-visible
  widget setting.
- Native Kotlin direct reading of Flutter `shared_preferences` should be
  validated in Stage 10; if awkward, mirror the same JSON schema to an
  Android-native store through a platform bridge.

## Next Stage

Stage 10 should implement the Android native home screen widget shell that
reads only `WidgetSnapshotSummary` and opens the main app on tap.
