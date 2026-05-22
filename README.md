# Quota Analytics

Quota Analytics is an unofficial cross-platform quota analytics app for tracking
usage limits, refresh windows, remaining quota, and quota status.

## Disclaimer

This is an unofficial independent project. It is not affiliated with, endorsed
by, or maintained by OpenAI, ChatGPT, or Codex.

Stage 4 adds manual visible page text extraction from the current in-app
WebView page. Extraction happens only after the user taps the button, reads only
`document.body.innerText`, redacts the result locally, and stores only a bounded
redacted preview for debugging. The app still does not read real quota data,
cookies, tokens, passwords, browser storage contents, local browser profiles,
or credentials, and does not provide an official quota API.

## Current Status

Stage 4: manual page text extraction is complete.

- Flutter Android-first implementation.
- Mock quota dashboard.
- Mock manual refresh.
- Last mock snapshot restore on startup.
- Bounded mock snapshot history.
- Persisted auto-refresh and refresh interval settings.
- Official Web Login page using `webview_flutter`.
- Users can manually open the official login page inside the app WebView.
- Usage page placeholder entry exists for future confirmation.
- Users can manually extract visible text from the current WebView page.
- Extracted text is redacted before display and local storage.
- WebView status shows sanitized URL, title, loading progress, navigation time,
  last error, and conservative auth status.
- The app still does not read real quota data.
- The app still does not read cookie/token values.
- The app still does not read localStorage or sessionStorage.
- The app still does not extract HTML.
- The app still does not parse the Usage page.
- Settings page with explicit save and clear-local-data.
- Debug page with persistence diagnostics, WebView status, and Stage 4 safety
  flags.
- Clean, feature-first layered architecture.

## Features

- Mock quota dashboard.
- 5-hour window mock display.
- Weekly window mock display.
- Credits mock display.
- Manual mock refresh.
- Local latest snapshot persistence.
- Local history persistence, capped at 100 snapshots.
- Persisted refresh interval settings UI.
- WebView login container for manual official-site login.
- WebView controls for login page, usage placeholder, reload, back, forward, and
  app WebView data clearing.
- Sanitized WebView URL display that hides query and fragment values.
- Manual WebView visible text extraction with HTTPS and host allowlist checks.
- Redaction for emails, bearer tokens, suspected API keys, token-like strings,
  and secret/password/token key-value values.
- Local cache for the most recent redacted extracted preview only.
- Debug information page with storage diagnostics.
- Clear local data with confirmation.
- Light and dark Material 3 themes.
- Unit and widget tests for persistence, WebView safety, extraction redaction,
  URL safety, and Stage 4 UI.

## Architecture

The app is built with Flutter and organized with a feature-first layered
architecture:

- `domain`: typed entities, repository contracts, and use cases.
- `data`: mock data source, models, and repository implementation.
- `presentation`: controllers, pages, and widgets.

The quota feature depends on a `QuotaRepository` abstraction. Stage 2 ships a
`MockQuotaDataSource`, `LocalQuotaDataSource`, and `PersistentQuotaRepository`;
the UI talks through use cases and controllers rather than directly reading data
sources or `shared_preferences`.

The auth feature owns the WebView login container through
`WebAuthConfig`, `WebAuthRepository`, `WebViewAuthController`, and the
`WebViewLoginPage`. It is intentionally separate from the quota data source and
parser pipeline so login navigation cannot accidentally become quota
extraction.

The extraction feature owns the Stage 4 manual text extraction flow through
`PageTextExtractionRepository`, `WebViewTextExtractionDataSource`,
`LocalExtractedTextDataSource`, `TextRedactor`, and
`PageTextExtractionController`. It reads only `document.body.innerText` after a
user action and never reads cookies, tokens, storage, HTML, request headers, or
network responses.

Future source placeholders include:

- `WebViewQuotaDataSource` for a future reviewed usage extraction stage.
- `OfficialApiQuotaDataSource` if a stable official quota API becomes available.
- `DesktopAgentQuotaDataSource` for local desktop helpers.
- Browser extension integration.
- Wearable clients.

More detail is available in [docs/architecture.md](docs/architecture.md),
[docs/security.md](docs/security.md), [docs/roadmap.md](docs/roadmap.md), and
[docs/stage1_report.md](docs/stage1_report.md). The Stage 2 implementation is
summarized in [docs/stage2_report.md](docs/stage2_report.md), Stage 3 is
summarized in [docs/stage3_report.md](docs/stage3_report.md), and Stage 4 is
summarized in [docs/stage4_report.md](docs/stage4_report.md).

## Project Structure

```text
.
├── android/
│   ├── app/
│   ├── build.gradle.kts
│   ├── gradle.properties
│   └── settings.gradle.kts
├── docs/
│   ├── architecture.md
│   ├── roadmap.md
│   ├── security.md
│   ├── stage1_report.md
│   ├── stage2_report.md
│   ├── stage3_report.md
│   └── stage4_report.md
├── lib/
│   ├── app.dart
│   ├── core/
│   ├── features/
│   │   ├── auth/
│   │   ├── debug/
│   │   ├── extraction/
│   │   ├── quota/
│   │   └── settings/
│   ├── main.dart
│   └── platform_placeholders/
├── test/
│   ├── features/
│   └── widget/
├── analysis_options.yaml
├── pubspec.lock
├── pubspec.yaml
├── LICENSE
└── README.md
```

## Getting Started

This project was prepared with Flutter 3.38.10 stable and Dart 3.10.9.

Install dependencies:

```sh
flutter pub get
```

Run static analysis:

```sh
flutter analyze
```

Run tests:

```sh
flutter test
```

Run the app:

```sh
flutter run
```

## Development Notes

- Stage 4 WebView network access is limited to user-driven official-site
  navigation inside the app WebView.
- Stage 4 uses mock quota data only and persists mock quota data/settings plus
  the last redacted extracted text preview.
- Do not add quota extraction or parsing without a new security review.
- Do not store credentials.

## Roadmap

- [x] Stage 1: Architecture + Mock UI
- [x] Stage 2: Local persistence for snapshots and settings
- [x] Stage 3: WebView login container
- [x] Stage 4: Usage page text extraction
- [ ] Stage 5: Quota parser with confidence levels
- [ ] Stage 6: Real manual refresh flow
- [ ] Stage 7: Foreground auto refresh
- [ ] Stage 8: Android background refresh and notifications
- [ ] Stage 9: iOS adaptation
- [ ] Stage 10: Desktop / wearable clients
- [ ] Stage 11: Optional official API adapter if a stable API becomes available

## Security And Privacy

- No password storage.
- No cookie reading or upload.
- No token scraping.
- No localStorage or sessionStorage reading.
- No WebView HTML extraction.
- Manual WebView text extraction reads only `document.body.innerText`.
- Extracted text remains local and only a redacted preview is saved.
- No real quota parser or refresh in Stage 4.
- No analytics SDK by default.
- Debug extracted text should be treated as sensitive even after redaction.

See [docs/security.md](docs/security.md) for the Stage 4 security boundary.

## License

MIT. See [LICENSE](LICENSE).
