# Stage 6 Report: Real Manual Refresh Flow

## Goal

Stage 6 connects the existing WebView visible-text extraction, redaction, quota
parser, confidence model, and local persistence into one user-triggered manual
refresh flow.

This stage is still conservative: it does not implement foreground automatic
refresh, background refresh, timers, cookie/token/storage reads, HTML
extraction, or network upload.

## Manual Refresh Pipeline

The Web Login page now exposes `Manual Refresh from Current Page`.

When the user taps it, the app runs:

1. Read current WebView presentation state: sanitized URL, title, loading
   status, and readiness.
2. Check the URL with the existing HTTPS allowlist policy.
3. Block immediately if the WebView is not ready, URL is empty/invalid,
   non-HTTPS, unknown-host, or still loading.
4. Call the Stage 4 extraction repository, which injects only
   `document.body.innerText`.
5. Redact text locally with `TextRedactor` and keep only the bounded redacted
   preview.
6. Parse the redacted visible text with the Stage 5 quota parser.
7. Map high/medium confidence parser results into a `QuotaSnapshot` candidate.
8. Apply `ManualRefreshPolicy`.
9. Save locally only after user confirmation, except high confidence can
   auto-save if the user enables that setting.
10. Update latest snapshot, history, home page, and Debug page.

## State Machine

`ManualRefreshStatus` is typed:

- `idle`
- `checkingPage`
- `extractingText`
- `redactingText`
- `parsing`
- `awaitingUserConfirmation`
- `saving`
- `saved`
- `blocked`
- `extractionFailed`
- `parseFailed`
- `lowConfidence`
- `failed`

`ManualRefreshResult` stores status, extraction safety status, parser
confidence, warnings/errors, snapshot candidate, redaction summary, timestamps,
duration, and last saved snapshot id. It does not store raw unredacted text.

## Save Policy

`ManualRefreshPolicy` defaults:

- `autoSaveHighConfidence = false`
- `requireConfirmationForMediumConfidence = true`
- `allowLowConfidenceSave = false`

Settings adds a persisted toggle for high-confidence auto-save. Medium
confidence remains confirmation-only. Low confidence remains blocked by default.

## Confidence Behavior

- High confidence: creates a candidate. Default behavior waits for the user to
  tap `Save Parsed Snapshot`; optional setting can auto-save.
- Medium confidence: creates a candidate and requires explicit confirmation.
- Low confidence: shows preview/status only and is not saved by default.
- Failed/not applicable: no candidate and no save.

## Safety Boundaries

Stage 6 preserves these boundaries:

- No cookie access.
- No token access.
- No `localStorage` or `sessionStorage` access.
- No `indexedDB` access.
- No HTML, script, CSS, DOM, request header, or network response extraction.
- No parser input/output upload.
- No backend, telemetry SDK, advertising SDK, or crash-reporting SDK.
- No automatic foreground refresh.
- No background refresh.
- No timers, WorkManager, cron, launchd, or polling loops.

The only page content extraction remains:

```js
(() => document.body ? document.body.innerText : '')();
```

## UI Changes

- Web Login page: added manual refresh button, status card, result card, and
  save confirmation.
- Home page: added `Go to Web Refresh` entry.
- Settings page: added manual refresh save policy controls/status.
- Debug page: added Stage 6 status, duration, safety, confidence, redaction
  summary, warnings/errors, saved id, and disabled auto/background refresh
  flags.

## Clear Local Data

Clear local data now removes:

- Latest quota snapshot.
- Quota history.
- Persisted settings.
- Last redacted extracted text preview.
- In-memory parser result.
- Last manual refresh result.

## Tests

Verified during implementation:

- `flutter pub get`
- `flutter analyze`
- `flutter test`

Added coverage for manual refresh status, policy decisions, persisted result
round-trip, success path, blocked URL path, extraction failure, parser failure,
low confidence, save use case, WebView entry, status/result widgets, Settings,
and Debug display.

## Known Limits

- The parser is heuristic and page wording can change.
- Unknown hosts are blocked by default; no explicit unknown-host confirmation UI
  is implemented yet.
- Emulator/manual WebView verification was not run in this pass.
- Stage 4 still stores only the latest bounded redacted preview for local debug.

## Next Stage

Stage 7 can add foreground-only automatic refresh while the app is open, but it
should remain visible, opt-in, easy to stop, and separate from the manual
refresh pipeline.
