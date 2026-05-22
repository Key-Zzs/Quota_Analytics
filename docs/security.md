# Security

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
only. It still does not read cookies, tokens, storage, HTML, or network data.

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

Clear local data removes only those keys. It does not remove project files,
Flutter caches, emulator files, browser data, credentials, or any system
storage.

History is capped at 100 mock snapshots. Corrupted JSON is ignored or removed
for the affected app key so startup does not crash.

## Network

Stage 2 app code has no network data source. Mock refresh is a local delay and
value update only, followed by local persistence.

Stage 3 adds user-driven HTTPS WebView navigation for official-site login. It
does not add a quota network API, remote backend, telemetry SDK, advertising
SDK, crash reporting SDK, or automatic refresh job.

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

## Debug Raw Text Risk

Stage 2 debug text is mock-only. Stage 4 extracted text may contain account
identifiers or usage details even after redaction. The app displays and stores
only a bounded redacted preview, and never logs or uploads the raw page text.
Any future raw-text parser input must go through another review before it can be
persisted, exported, or uploaded.

## Device Testing

For real-device testing:

- Use a disposable debug build.
- Avoid granting unrelated device permissions.
- Keep logs local.
- Do not connect real account flows until the security boundary is reviewed.
- Prefer manual refresh before any foreground or background automation.
