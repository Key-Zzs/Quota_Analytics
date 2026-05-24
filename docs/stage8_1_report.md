# Stage 8.1 Report: Reload-Before-Refresh

## Goal

Stage 8.1 adds a foreground-only reload step before quota extraction for:

- Manual Refresh.
- Foreground Auto Refresh.

Stage 7/8 read `document.body.innerText` from the currently rendered WebView
page. If the official analytics page had not updated its DOM, the app could
read stale text. Stage 8.1 lets the app reload the visible foreground WebView,
wait for page finish, wait for a short settle delay, and then run the existing
Stage 6 extraction/redaction/parser/save pipeline.

## Manual Refresh Design

Manual refresh has a persisted setting:

- `Reload page before manual refresh`
- Default: on

The default is on because a manual tap usually means the user expects the
latest official page content. If the setting is off, manual refresh keeps the
Stage 6 behavior and reads the current rendered page directly.

When enabled, manual refresh runs:

```text
Manual Refresh
  -> ReloadPageBeforeRefreshUseCase
  -> existing Stage 6 safety check
  -> document.body.innerText
  -> redaction
  -> local parser
  -> confidence policy
  -> local candidate/save
```

Reload failure, timeout, unsafe URL, page loading, cooldown, and login/auth
landing states stop the flow before extraction or parser work.

## Foreground Auto Refresh Design

Foreground auto refresh has a persisted setting:

- `Reload page before foreground auto refresh`
- Default: off

The default is off because automatic reloads can increase official-site login,
rate-limit, battery, and WebView reliability risk. Users must explicitly enable
it.

When enabled, foreground auto refresh runs:

```text
Foreground Auto Refresh
  -> interval/lifecycle eligibility
  -> ReloadPageBeforeRefreshUseCase
  -> existing Stage 6 manual refresh pipeline with manual reload disabled
```

The app must be in `AppLifecycleState.resumed`. If the app becomes paused,
inactive, hidden, or detached while reload is waiting, the reload is cancelled
and extraction/parser work does not continue.

## Reload Parameters

Reload parameters are centralized in `ReloadBeforeRefreshPolicy`:

- Reload timeout: 15 seconds.
- Page settle delay: 800 ms.
- Reload cooldown: 30 seconds.
- Max consecutive reload failures: 3.

These values are constants for Stage 8.1. They are exposed in Debug/UI text and
can become configurable later if needed.

## State Machine

`ReloadBeforeRefreshStatus` includes:

- `disabled`
- `idle`
- `checkingUrl`
- `blockedUnsafeUrl`
- `blockedNoWebView`
- `blockedPageLoading`
- `blockedAlreadyRefreshing`
- `blockedCooldown`
- `reloading`
- `waitingForPageFinished`
- `waitingForSettleDelay`
- `readyForExtraction`
- `loginRequired`
- `timeout`
- `cancelled`
- `failed`
- `completed`

`ReloadBeforeRefreshResult` records status, started/finished time, duration,
sanitized URL, safe warnings, and safe errors. It never stores cookies, tokens,
raw page text, parser input, parser output, HTML, request headers, or network
responses.

## Architecture

New Stage 8.1 pieces:

- `ReloadBeforeRefreshPolicy`
- `ReloadBeforeRefreshStatus`
- `ReloadBeforeRefreshResult`
- `WebViewReloadService`
- `WebViewAuthReloadService`
- `PageLoadWaiter`
- `ReloadCancellationToken`
- `ReloadPageBeforeRefreshUseCase`

`WebViewAuthController` now tracks current sanitized URL, page title, loading
progress, page-start/page-finish timestamps, last WebView resource error, last
reload status/duration/error, and reload cooldown.

## Background Boundary

Stage 8 background refresh remains notify-only.

Stage 8.1 does not add:

- Background WebView reload.
- Hidden WebView.
- Background page reads.
- Background JavaScript extraction.
- Cookie/token/storage access.
- Automatic login.
- Automatic usage-page opening.
- Network upload.

Android background tasks still read only app-owned local
snapshot/settings/metadata and notification cooldown state.

## Security Boundary

The only page content read after a successful foreground reload remains:

```js
(() => document.body ? document.body.innerText : '')();
```

Stage 8.1 does not read:

- `document.cookie`
- WebView cookies or browser cookies
- `localStorage`
- `sessionStorage`
- `indexedDB`
- Access tokens or refresh tokens
- Authorization headers
- Network requests or responses
- HTML, scripts, CSS, or full DOM

No page text, parser input, parser output, logs, snapshots, or reload metadata
is uploaded.

## UI

WebView container:

- Adds `Reload page before manual refresh`.
- Shows last reload status, duration, timeout hint, and safe error.
- Keeps Open login page, Open usage page, Reload, Manual Refresh, and Extract
  Page Text.

Settings:

- Adds `Reload page before foreground auto refresh`.
- States that it works only in foreground and not in Android background tasks.
- Warns that frequent reloads may be unreliable.

Debug:

- Shows both reload settings.
- Shows last reload status, started/finished time, duration, error, sanitized
  URL, cooldown, timeout, and settle delay.
- Reaffirms no background reload, no hidden WebView, no cookie/token/storage
  access, no HTML extraction, and no upload.

## Tests

Added and updated tests for:

- Reload policy defaults.
- Page load waiter completion, timeout, cancellation, and settle delay.
- Reload use case success, unsafe URL, no WebView, loading page, timeout,
  thrown reload, cancellation, cooldown, duplicate refresh, and login landing.
- Manual refresh integration with reload disabled/enabled, timeout,
  loginRequired, parser skip, success ordering, and reload summary.
- Foreground auto refresh disabled/enabled behavior, not-resumed skip,
  pause-cancel, timeout cooldown, and duplicate reload guard.
- Settings persistence for both reload settings and defaults.
- WebView, Settings, and Debug widget visibility.

Current verification:

- `flutter pub get`: passed.
- `flutter analyze`: passed.
- `flutter test`: passed.

## Manual Verification

Manual reload-before-refresh:

1. Open the app and go to Web Login.
2. Tap Open usage page.
3. Open WebView container controls.
4. Enable Reload page before manual refresh.
5. Tap Manual Refresh.
6. Confirm state progresses through checking URL, reloading, waiting for page
   finished, waiting for settle delay, extraction, and parsing.
7. Confirm the result updates or creates a candidate.
8. If reload lands on login/auth, confirm `loginRequired` is shown and parser
   does not run.

Foreground auto reload-before-refresh:

1. Open Settings.
2. Enable Foreground Auto Refresh.
3. Enable Reload page before foreground auto refresh.
4. Choose an interval, preferably 15+ minutes.
5. Keep the app foreground/resumed.
6. When eligible, confirm reload happens before extraction/parser.
7. Put the app in background during reload and confirm extraction/parser do not
   continue.
8. Confirm Debug says no background reload.

Regression:

1. Disable Reload page before manual refresh.
2. Manual Refresh should read the current rendered page directly.
3. Background refresh remains notify-only.
4. Notifications do not trigger background WebView access.

## Known Limits

- Reload can still land on a login/auth page if the official site invalidates
  the session.
- Official page content may update after `onPageFinished`; the settle delay
  reduces but cannot eliminate this timing risk.
- Foreground auto reload is intentionally off by default because frequent
  reloads may be unreliable.
- `flutter devices` found Chrome only and no Android emulator/physical device,
  so Android manual runtime verification was not performed in this pass.

## Next Stage

Stage 9 should add the Android home screen widget data export layer. It should
export only safe local snapshot summaries and continue to avoid WebView,
cookies, tokens, storage, HTML, page text, and uploads.
