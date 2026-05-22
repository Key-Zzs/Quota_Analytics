# Security

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

Development commands such as `flutter doctor`, `flutter pub get`, and Android
Gradle builds may perform normal toolchain checks or dependency resolution, but
the app itself does not call external usage services.

## Future WebView Boundary

A future WebView stage must be treated as security-sensitive. Before it is
implemented, define:

- What storage the WebView can use.
- Whether cookies persist.
- Whether debug text can contain account details.
- How users clear local session data.
- What data may leave the WebView boundary.
- What logs are allowed.

No WebView login container exists in Stage 2.

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
