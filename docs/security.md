# Security

## Stage 8.1 Reload-Before-Refresh Boundary

Stage 8.1 adds optional reload-before-refresh for manual refresh and
foreground auto refresh. Reload is foreground-only and uses the currently
visible WebView. It does not add background WebView refresh, hidden WebViews,
automatic login, or any new data source.

Manual refresh reload is on by default because a user tap usually means the
latest rendered official usage page is desired. Foreground auto reload is off
by default because automatic reloads can increase login, reliability, battery,
and rate-limit risk. Users must explicitly enable it.

Reload-before-refresh may do only this sequence:

1. Check that the current WebView exists.
2. Check that the current sanitized URL is HTTPS and allowlisted.
3. Reload the current foreground WebView page.
4. Wait for page finish with timeout.
5. Wait for a short settle delay.
6. Continue into the existing Stage 6 pipeline, which reads only
   `document.body.innerText`.

Stage 8.1 does not read or extract:

- `document.cookie`
- WebView cookies or system browser cookies
- `localStorage`
- `sessionStorage`
- `indexedDB`
- Access tokens, refresh tokens, session tokens, authorization headers, or
  network requests
- HTML, DOM structure, scripts, CSS, request headers, or network responses

Reload-before-refresh does not upload page text, parser input, parser output,
logs, snapshots, or reload metadata. URLs shown in UI or Debug remain sanitized
with query strings and fragments removed.

If the app leaves `resumed` foreground state while foreground auto reload is
waiting, reload-before-refresh is cancelled and extraction/parser work does not
continue. Android background tasks do not call the reload service, do not open
the usage page, and do not execute JavaScript.

The default reload constants are centralized in `ReloadBeforeRefreshPolicy`:

- Reload timeout: 15 seconds.
- Page settle delay: 800 ms.
- Reload cooldown: 30 seconds.
- Max consecutive reload failures: 3.

Reload can land on a login/auth page or trigger official-site loading issues.
In that case the result is reported as `loginRequired`, `timeout`, `failed`, or
another safe status, and extraction is skipped.

## Stage 8 Background Refresh And Notifications Boundary

Stage 8 adds Android WorkManager scheduling and local notifications. It does not
add real background web refresh. With no official API or background-safe data
source, background work is notify-only.

The background task may read only app-owned local data:

- Background refresh settings.
- Latest saved quota snapshot summary.
- Shallow manual refresh failure status and timestamps.
- Notification cooldown metadata.
- Last background run metadata.

The background snapshot loader deliberately replaces account labels with
`Local snapshot` and strips `rawDebugText`. The manual refresh metadata loader
reads only shallow status/timestamp fields and does not deserialize nested
extracted page text or parser output.

Stage 8 background work does not read or extract:

- WebView content.
- Hidden WebViews.
- `document.cookie`.
- WebView cookies.
- Browser cookies.
- `localStorage`.
- `sessionStorage`.
- `indexedDB`.
- Access tokens, refresh tokens, session tokens, authorization headers, or
  network requests.
- HTML, DOM structure, scripts, CSS, request headers, or network responses.
- Parser raw input or raw page text.

Stage 8 notification content is fixed and safe. Notifications do not include
account emails, full URLs, raw page text, parser input/output, tokens, stack
traces, or web-derived sensitive content. Notification taps open the app only;
they do not trigger background WebView refresh.

Android permission changes:

- `POST_NOTIFICATIONS` is declared so Android 13+ users can grant local
  notification permission.
- `RECEIVE_BOOT_COMPLETED` is declared for Android WorkManager rescheduling
  after reboot.
- `WAKE_LOCK` is declared for Android WorkManager/AndroidX Work runtime while it
  completes short local work.
- `flutter_local_notifications` would merge `VIBRATE`, but this app removes it
  because vibration is not required.
- `ACCESS_NETWORK_STATE` is removed because this stage does not use network
  constraints.
- `FOREGROUND_SERVICE` and `SCHEDULE_EXACT_ALARM` are not declared by the app.

Stage 8 does not use foreground services, exact alarms, dangerous permissions,
remote push, Firebase, analytics, advertising SDKs, crash reporting SDKs, or
remote configuration. WorkManager execution is best-effort and must not be used
to force hidden login or hidden scraping behavior.

## Stage 7 Foreground Auto Refresh Boundary

Stage 7 adds foreground-only automation. It does not add background refresh.
Auto refresh runs only while the Flutter lifecycle is `resumed`, the user has
enabled the setting, and the current already-open WebView page passes the same
Stage 6 safety checks.

When the app is `paused`, `inactive`, `hidden`, or `detached`, the foreground
timer is stopped and no refresh is attempted. Stage 7 does not use WorkManager,
foreground services, boot receivers, notifications, cron, launchd, or any
background keepalive.

Auto refresh still uses only the Stage 4/6 page content boundary:

```js
(() => document.body ? document.body.innerText : '')();
```

Stage 7 does not read or extract:

- `document.cookie`
- WebView cookies
- `localStorage`
- `sessionStorage`
- `indexedDB`
- Access tokens, refresh tokens, session tokens, authorization headers, or
  network requests.
- HTML, DOM structure, scripts, CSS, request headers, or network responses.

Auto refresh does not open pages automatically and does not log in
automatically. The user must already have opened the WebView and navigated to an
allowed HTTPS page. The feature reuses `ManualRefreshPolicy`: high confidence
can auto-save only if the user enables that setting, medium confidence remains a
candidate requiring confirmation, and low/failed results are not saved.

Automatic saving carries stale/incorrect parser risk if the official page text
changes. Keeping high-confidence auto-save off by default limits that risk.
Medium and low confidence results must not silently overwrite the latest
snapshot.

## Stage 6 Manual Refresh Boundary

Stage 6 adds a real user-triggered manual refresh flow. The flow composes the
existing WebView visible-text extraction, local redaction, local parser,
confidence policy, and local snapshot persistence.

The user can tap `Manual Refresh from Current Page`. Stage 7 may also trigger
the same pipeline from a foreground-only timer when explicitly enabled. The app
does not refresh on app startup, page load, navigation events, background jobs,
WorkManager, cron, launchd, or hidden polling.

Stage 6 still reads only:

```js
(() => document.body ? document.body.innerText : '')();
```

Stage 6 does not read or extract:

- `document.cookie`
- WebView cookies
- `localStorage`
- `sessionStorage`
- `indexedDB`
- Access tokens, refresh tokens, session tokens, authorization headers, or
  network requests.
- HTML, DOM structure, scripts, CSS, request headers, or network responses.

Unredacted text is allowed only as a short-lived local variable inside the
extraction call. It is immediately redacted, is not sent to UI, is not logged,
is not persisted, and is not uploaded.

Manual refresh can save only a parsed `QuotaSnapshot` candidate. The saved
snapshot uses `source: webViewManualExtraction`, stores parser confidence, and
stores parser evidence/matched-signal summaries rather than raw page text. Low
confidence results are not saved by default.

The Stage 6 local result key is `refresh.last_manual_result.v1`; it stores
status, safety status, confidence, redaction summary, warnings/errors, duration,
candidate metadata, and saved snapshot id. It does not store raw unredacted page
text.

## Stage 5 Parser Boundary

Stage 5 adds a local parser that reads only Stage 4 redacted visible text
(`ExtractedPageText.redactedTextPreview`) or artificial test/mock samples. It
does not read WebView state directly and does not access raw unredacted page
text.

Stage 5 does not read or extract:

- `document.cookie`
- WebView cookies
- `localStorage`
- `sessionStorage`
- `indexedDB`
- Access tokens, refresh tokens, session tokens, or authorization headers
- Page HTML, DOM structure, scripts, CSS, request headers, network requests, or
  network responses

The parser input and output stay local. They are not uploaded to a backend,
analytics SDK, advertising SDK, crash reporter, or model service.

Parser results can be inaccurate because visible usage page wording may change.
The UI must display `ParserConfidence`, warnings, and errors. Low-confidence
results must not be automatically saved as real quota data; Stage 5 enables
manual save only for high/medium parsed snapshot previews.

## Stage 4 Page Text Extraction Boundary

Stage 4 adds user-triggered page text extraction for local debugging only. The
only page content the app is allowed to read is:

```js
(() => document.body ? document.body.innerText : '')();
```

The user must tap `Extract Page Text` from the Web Login page. The app does not
extract on page load, app startup, timers, loops, background jobs, or navigation
events.

Stage 4 does not read or extract:

- `document.cookie`
- `localStorage`
- `sessionStorage`
- `indexedDB`
- Access tokens, refresh tokens, session tokens, or authorization headers.
- Page HTML, scripts, CSS, DOM structure, request headers, network requests, or
  network responses.
- Browser/system cookies, browser profiles, Keychain, Credential Manager, or
  password manager data.

Before extraction, the current URL must be present, HTTPS, and on the conservative
allowlist: `chatgpt.com`, `chat.openai.com`, `openai.com`, or
`platform.openai.com`. Query strings and fragments are removed before the URL is
shown or persisted. Unknown hosts and non-HTTPS pages are blocked by default.

The extracted text is immediately redacted in memory before display or local
storage. Redaction covers:

- Email addresses -> `[REDACTED_EMAIL]`
- Bearer tokens -> `Bearer [REDACTED_TOKEN]`
- `sk-`-prefixed suspected API keys -> `[REDACTED_API_KEY]`
- Long token-like strings -> `[REDACTED_TOKEN]`
- Values near `session`, `access`, `refresh`, `token`, `secret`, and `password`
  labels -> `[REDACTED_SECRET]`

The debug preview is capped at 2000 characters. Stage 4 saves only the most
recent redacted preview under the app-owned key
`extraction.last_page_text.v1`; it never saves the raw unredacted page text.
Clear local data removes this extracted preview along with mock quota and
settings data.

Redacted debug previews can still contain account or usage context. Treat them
as local sensitive debugging data, do not upload them, and avoid using real
account pages for automated tests.

## Stage 3 WebView Boundary

Stage 3 adds a WebView login container so the user can manually open the
official website and sign in inside this app's WebView. The app provides the
container and navigation controls only.

Stage 3 does not:

- Store passwords.
- Read cookies, session cookies, access tokens, refresh tokens, or session
  tokens.
- Read system browser data from Chrome, Safari, Edge, or other browsers.
- Access Keychain, Credential Manager, password managers, `.env` files, SSH
  keys, private keys, or certificates.
- Extract page HTML, `document.body.innerText`, localStorage, or sessionStorage.
- Parse usage or quota values.
- Run background refresh.
- Upload WebView content.

The WebView status UI may display non-sensitive metadata:

- Sanitized current URL.
- Page title.
- Loading progress.
- Last navigation time.
- Last WebView error.
- Conservative auth status inferred from navigation only.

Displayed and logged URLs must hide query and fragment values. For example,
`https://example.com/path?token=secret#fragment` is shown as
`https://example.com/path`.

Clear WebView Data clears only this app's WebView cache, WebView local storage,
and WebView cookies where the platform supports those operations. It does not
clear system browser data and does not remove this app's saved mock quota
snapshots, history, or settings.

Stage 4 extends this boundary with manual `document.body.innerText` extraction
only. Stage 5 adds a parser for the redacted extraction result only. It still
does not read cookies, tokens, storage, HTML, or network data.

## Stage 2 Boundary

Stage 2 only uses local mock data and local settings. It does not access real
GPT/Codex pages, accounts, sessions, cookies, browser local storage, tokens,
passwords, keychains, browser profiles, or password managers.

The app persists only:

- Mock quota snapshots.
- Mock quota snapshot history.
- Refresh setting choices.
- Debug/development persistence status derived from those app-owned values.

It does not persist passwords, API keys, cookies, tokens, session identifiers,
browser storage, or raw real account usage text.

## Sensitive Data

The app must not read, print, copy, upload, or store sensitive files or values,
including:

- SSH or GPG keys.
- Browser cookies, sessions, or local storage.
- ChatGPT, OpenAI, or Codex login state.
- API keys, tokens, credentials, private keys, or `.env` files.
- System keychain or credential manager records.

## Local Persistence

Stage 2 uses `shared_preferences` through a small `JsonStorage` abstraction.
The only keys the app owns are:

- `quota.latest_snapshot.v1`
- `quota.snapshot_history.v1`
- `settings.app_settings.v1`
- `extraction.last_page_text.v1`
- `refresh.last_manual_result.v1`

Clear local data removes only those keys. It does not remove project files,
Flutter caches, emulator files, browser data, credentials, or any system
storage.

History is capped at 100 quota snapshots. Stage 5 parsed snapshots, if the user
explicitly saves them, use the same local latest/history keys and include source
and parser confidence. Corrupted JSON is ignored or removed for the affected app
key so startup does not crash.

## Network

Stage 2 app code has no network data source. Mock refresh is a local delay and
value update only, followed by local persistence.

Stage 3 adds user-driven HTTPS WebView navigation for official-site login. It
does not add a quota network API, remote backend, telemetry SDK, advertising
SDK, crash reporting SDK, or automatic refresh job.

Stage 5 parsing, Stage 6 manual refresh, and Stage 7 foreground auto refresh are
local Dart code only. They do not add network upload, backend sync, telemetry,
or background refresh.

Development commands such as `flutter doctor`, `flutter pub get`, and Android
Gradle builds may perform normal toolchain checks or dependency resolution, but
the app itself does not call external usage services.

## WebView Implementation Notes

Stage 3 uses `webview_flutter` for the embedded WebView. JavaScript execution is
enabled because modern official login pages require it. Stage 4 uses
`runJavaScriptReturningResult` only for the `document.body.innerText` snippet
listed above. The app does not register JavaScript channels and does not read
cookies, storage, HTML, request headers, or network responses. Web content
permission requests are denied by the app, and Android only adds the normal
`INTERNET` permission required for HTTPS WebView navigation.
Stage 6 reuses the same extraction boundary and adds local orchestration only.
Stage 7 reuses that orchestration from the foreground lifecycle only. The
WebView layout fix changes Flutter widget constraints and does not broaden page
content access.

## Debug Raw Text Risk

Stage 2 debug text is mock-only. Stage 4 extracted text may contain account
identifiers or usage details even after redaction. The app displays and stores
only a bounded redacted preview, and never logs or uploads the raw page text.
Stage 5 parser input is that bounded redacted preview only. Parsed snapshots
store an evidence summary, not the full parser input. Any future raw-text parser
input must go through another review before it can be persisted, exported, or
uploaded.
Stage 6 manual refresh results store redaction summaries and parser evidence
only; they do not store raw page text. Stage 7 auto refresh status stores
attempt/success times, cooldown/error state, and typed status only.

## Device Testing

For real-device testing:

- Use a disposable debug build.
- Avoid granting unrelated device permissions.
- Keep logs local.
- Do not connect real account flows until the security boundary is reviewed.
- Prefer manual refresh before enabling foreground automation.
- Do not test background automation in Stage 7; it is not implemented.
