# Security

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

If Stage 4 introduces page text extraction, it needs a new security review
before any raw page text is displayed, logged, persisted, parsed, or exported.

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
enabled because modern official login pages require it, but the app does not
register JavaScript channels and does not call `runJavaScript` to read page
content. Web content permission requests are denied by the app, and Android only
adds the normal `INTERNET` permission required for HTTPS WebView navigation.

## Debug Raw Text Risk

Stage 2 debug text is mock-only. In later parser stages, raw extracted text may
contain account identifiers or usage details. Treat raw text as sensitive before
deciding whether it can be logged, displayed, persisted, or cleared. It must be
opt-in, redacted where possible, and never uploaded without explicit user
action.

## Device Testing

For real-device testing:

- Use a disposable debug build.
- Avoid granting unrelated device permissions.
- Keep logs local.
- Do not connect real account flows until the security boundary is reviewed.
- Prefer manual refresh before any foreground or background automation.
