# Stage 3 Report: WebView Login Container

## Goal

Stage 3 implements a safe WebView login container. The user can manually open
the official website inside the app and sign in there. The app remains outside
the credential boundary and does not extract quota data.

## Implemented

- Added `webview_flutter` WebView support.
- Added an Official Web Login page.
- Added controls for:
  - Open login page.
  - Open usage page placeholder.
  - Reload.
  - Back.
  - Forward.
  - Clear WebView data.
- Added status display for sanitized current URL, page title, loading progress,
  last navigation time, last error, and conservative auth status.
- Added Stage 3 safety notice in the WebView page.
- Added Debug page Stage 3 status and safety flags.
- Added URL sanitization that removes query and fragment values.
- Added unit, controller, and widget tests for WebView safety logic.

## Package Choice

The project uses `webview_flutter` `^4.13.1`.

Reasons:

- It is the official Flutter community-maintained WebView plugin.
- It supports Android and iOS through maintained platform implementations.
- It exposes a modern controller/widget split that lets the app keep WebView
  logic outside testable presentation state.
- It avoids adding extra account, analytics, advertising, backend, or tracking
  SDKs.

## Android Permission

Added:

- `android.permission.INTERNET`

This is the minimal Android permission needed for HTTPS WebView navigation.

Not added:

- Camera.
- Microphone.
- Location.
- Contacts.
- External storage.
- Package install.
- System alert window.

The manifest does not enable cleartext traffic.

## URL Configuration

Central definitions live in `lib/core/constants/web_constants.dart`:

- `loginUrl`: `https://chatgpt.com/codex/cloud/settings/analytics`
- `usageUrlPlaceholder`: `https://chatgpt.com/#settings`

The usage URL is a placeholder for an official account/settings surface. A
future stage should confirm the exact usage route before extracting or parsing
anything.

## Auth Status Inference

Auth status is inferred only from navigation URL/title metadata:

- Login/auth-like URL or title: `loggedOut`.
- Non-login HTTPS page: `maybeLoggedIn`.
- Empty or missing navigation context: `unknown`.
- Non-HTTPS main-frame navigation: `blocked`.
- Invalid URL or WebView load error: `error`.

The UI explicitly states: "Login status is inferred from navigation only and
may be inaccurate."

## Safety Boundary

Stage 3 does not:

- Read, print, upload, or store cookies.
- Read, print, upload, or store access tokens, refresh tokens, or session
  tokens.
- Read system browser profiles or login state.
- Access Keychain, Credential Manager, password managers, `.env`, SSH keys,
  private keys, or certificates.
- Extract HTML, `document.body.innerText`, localStorage, or sessionStorage.
- Parse usage or quota values.
- Implement real quota refresh.
- Implement background refresh.
- Save user passwords.
- Imitate OpenAI, ChatGPT, or Codex official UI.
- Add analytics, ads, crash reporting, or a remote backend.

## Clear WebView Data

The Clear WebView Data button clears this app's WebView cache, local storage,
and WebView cookies where the platform supports those operations. It does not
read cookie values. It does not clear system browser data. It does not clear
mock quota snapshots, history, or settings.

## Tests

Baseline before Stage 3:

- `flutter pub get`: passed after allowing Flutter SDK cache access.
- `flutter analyze`: passed.
- `flutter test`: passed.

Final verification:

- `flutter pub get`: passed.
- `flutter analyze`: passed.
- `flutter test`: passed.

Widget tests use a fake injected WebView widget, while unit and controller tests
cover URL sanitization, status inference, error handling, and clear-data state.

## Emulator Verification

`flutter devices` found Android emulator `emulator-5554` and Chrome.
`flutter run -d emulator-5554` built, installed, launched, and reached the
Flutter run command prompt. The run session was then stopped.

## Known Risks

- Official login and account/settings URLs may change.
- Login pages can redirect through official auth infrastructure; status remains
  conservative and may be inaccurate.
- Platform support for clearing WebView local data can vary.
- WebView behavior should be checked on Android Emulator and real devices
  before Stage 4.

## Next Stage Recommendations

- Confirm the exact official usage page route before Stage 4.
- Keep page text extraction opt-in and separately reviewed.
- Treat extracted text as sensitive.
- Add explicit tests that raw page text is not logged or persisted by default.
- Add parser logic only after the extraction boundary is approved.
