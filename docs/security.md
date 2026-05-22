# Security

## Stage 1 Boundary

Stage 1 only uses local mock data. It does not access real GPT/Codex pages,
accounts, sessions, cookies, local storage, tokens, passwords, keychains,
browser profiles, or password managers.

## Sensitive Data

The app must not read, print, copy, upload, or store sensitive files or values,
including:

- SSH or GPG keys.
- Browser cookies, sessions, or local storage.
- ChatGPT, OpenAI, or Codex login state.
- API keys, tokens, credentials, private keys, or `.env` files.
- System keychain or credential manager records.

## Network

Stage 1 app code has no network data source. Mock refresh is an in-memory delay
and value update only.

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

No WebView login container exists in Stage 1.

## Debug Raw Text Risk

Stage 1 debug text is mock-only. In later parser stages, raw extracted text may
contain account identifiers or usage details. It must be opt-in, redacted where
possible, and never uploaded without explicit user action.

## Device Testing

For real-device testing:

- Use a disposable debug build.
- Avoid granting unrelated device permissions.
- Keep logs local.
- Do not connect real account flows until the security boundary is reviewed.
- Prefer manual refresh before any foreground or background automation.
