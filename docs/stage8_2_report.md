# Stage 8.2 Report: Quota Page Usage Refresh

## Goal

Stage 8.2 removes the Quota page app-bar refresh shortcut that previously
called the mock quota refresh path and could update the dashboard to
`Mock GPT Account`.

The Quota page refresh action now uses the real foreground refresh path:

```text
Quota page refresh tap
  -> show the Web Login tab so the WebView is visible
  -> open the Codex usage analytics page
  -> wait for page finish and settle delay
  -> run ManualRefreshController.refreshFromCurrentPage
  -> auto-save only high-confidence results for this tap
  -> update the Quota dashboard from the saved snapshot
  -> let foreground auto refresh recalculate next eligible refresh time
```

## Behavior

- The Quota app-bar action is now labelled `Refresh usage page`.
- It no longer calls `QuotaController.refresh()` or
  `QuotaRepository.refreshSnapshot()` from the app bar.
- It switches to the visible WebView tab before navigation, preserving the
  Stage 8.1 foreground-visible WebView boundary.
- It opens `https://chatgpt.com/codex/cloud/settings/analytics`.
- It waits for the page to finish loading with the same timeout and settle
  values used by manual reload-before-refresh.
- It then extracts from the current page through the existing manual refresh
  pipeline.
- It applies a one-shot policy override:
  `autoSaveHighConfidence: true`.
- Medium-confidence results still require confirmation.
- Low-confidence and failed results are not saved.

The regular WebView container Manual Refresh button keeps using the user's
persisted manual refresh policy.

## Refresh Time Propagation

Successful high-confidence saves update all connected refresh state:

- `ManualRefreshController.lastResult` records the manual refresh status,
  started time, finished time, duration, parser confidence, and saved snapshot
  id.
- `QuotaController.applySavedSnapshot` updates the dashboard snapshot, refresh
  result label, refresh duration, persistence status, and history.
- `ForegroundAutoRefreshController` already listens to
  `ManualRefreshController`; the saved manual result resets `lastAttemptAt`,
  `lastSuccessAt`, clears cooldown/error state, and recalculates
  `nextEligibleAt`.
- The Quota metadata card shows the saved snapshot's `capturedAt` and
  `nextSuggestedRefreshAt` from the parser mapping.

If the Usage page loads but parsing does not produce a high-confidence saved
snapshot, the Quota controller records a completed refresh without replacing
the current dashboard snapshot.

## Safety Boundary

Stage 8.2 does not add:

- Background WebView work.
- Hidden WebView scraping.
- Automatic background usage-page opening.
- Cookie, token, localStorage, sessionStorage, or IndexedDB reads.
- HTML, DOM, network request, or response extraction.
- Upload of page text, parser input/output, snapshots, logs, or diagnostics.

The only page content read remains the Stage 4/6 bounded visible text
extraction:

```js
(() => document.body ? document.body.innerText : '')();
```

## UI Notes

- The Quota empty state now points users to Web Refresh instead of offering a
  mock snapshot refresh.
- The Stage notice now reports Stage 8.2 behavior.
- The legacy mock datasource remains available as a local fallback for
  development and initial demo data, but the Quota page refresh action no
  longer uses it.

## Tests

Updated and added coverage for:

- Quota home UI no longer exposing the `Refresh mock quota` tooltip.
- Quota home UI exposing `Refresh usage page`.
- One-shot high-confidence policy override saving a manual refresh result.

Current verification:

- `dart format`: passed.
- `flutter test test/features/refresh/manual_refresh_reload_integration_test.dart test/widget/quota_home_page_test.dart`: passed.
- `flutter test`: passed.
- `flutter analyze`: passed.

## Manual Verification

1. Open the app.
2. Log in through Web Login if needed.
3. Return to Quota.
4. Tap the app-bar refresh button.
5. Confirm the app switches to Web Login and opens the Usage page visibly.
6. Confirm a high-confidence parse saves locally without changing the persisted
   manual refresh setting.
7. Confirm Quota shows the saved snapshot after the refresh completes.
8. Confirm Debug and Settings foreground auto refresh status show refreshed
   last success and next eligible refresh time.

## Known Limits

- The user must still be logged in to the official site inside the app WebView.
- If the official site redirects to login/auth, parsing will fail or produce no
  saved snapshot.
- Official page content can still change after load; Stage 8.2 waits for page
  finish plus settle delay, but it cannot guarantee official DOM freshness.
