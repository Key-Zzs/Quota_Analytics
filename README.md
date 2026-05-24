# Quota Analytics

Quota Analytics is an unofficial cross-platform quota analytics app for tracking
usage limits, refresh windows, remaining quota, and quota status.

## Disclaimer

This is an unofficial independent project. It is not affiliated with, endorsed
by, or maintained by OpenAI, ChatGPT, or Codex.

Stage 6 connects the user-triggered WebView visible-text extraction, local
redaction, local parser, confidence policy, and local snapshot persistence into
a real manual refresh flow. Extraction still reads only
`document.body.innerText`; parsing and save policy remain local. The app still
does not read cookies, tokens, passwords, browser storage contents, local
browser profiles, credentials, HTML, or an official quota API.

## Current Status

Stage 6: manual WebView refresh flow is complete.

- Flutter Android-first implementation.
- Mock quota dashboard.
- Legacy mock refresh remains available from the app bar.
- Last mock snapshot restore on startup.
- Bounded mock snapshot history.
- Persisted auto-refresh and refresh interval settings.
- Official Web Login page using `webview_flutter`.
- Users can manually open the official login page inside the app WebView.
- Usage page placeholder entry exists for future confirmation.
- Users can manually extract visible text from the current WebView page.
- Extracted text is redacted before display and local storage.
- Users can manually parse the current redacted visible text.
- Users can manually refresh from the current WebView page in one flow.
- Parser results include confidence, warnings, errors, matched signals, window
  fields, credits, and evidence labels.
- Parser results are local and may be inaccurate.
- Parsed snapshots require manual save and are marked with source and parser
  confidence.
- High-confidence manual refresh can auto-save only if the user enables the
  conservative setting; it is off by default.
- WebView status shows sanitized URL, title, loading progress, navigation time,
  last error, and conservative auth status.
- The app still does not read cookie/token values.
- The app still does not read localStorage or sessionStorage.
- The app still does not extract HTML.
- The app still does not upload parser input or output.
- The app still does not run automatic or background refresh.
- Settings page with explicit save and clear-local-data.
- Debug page with persistence diagnostics, WebView status, Stage 4 extraction,
  Stage 5 parser, and Stage 6 manual refresh safety flags.
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
- Local quota parser for redacted visible text.
- Parse result UI with confidence, warnings, errors, windows, credits, and
  evidence labels.
- Manual refresh flow from the current WebView page.
- Manual refresh policy for high/medium/low confidence saves.
- Optional user-confirmed save for high/medium parsed snapshots.
- Debug information page with storage diagnostics.
- Clear local data with confirmation.
- Light and dark Material 3 themes.
- Unit and widget tests for persistence, WebView safety, extraction redaction,
  URL safety, parser behavior, parser mapping, parser controller state, and UI.

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

The parser feature owns the Stage 5 local parser through `QuotaParseResult`,
`RegexQuotaParser`, `QuotaParserController`, `ParseResultCard`, and
`ParseResultToQuotaSnapshotMapper`. It consumes only redacted visible text and
can map high/medium parse results to `QuotaSnapshot` previews with
`source: webViewManualExtraction`.

The refresh feature owns the Stage 6 manual orchestration through
`ManualRefreshStatus`, `ManualRefreshResult`, `ManualRefreshPolicy`,
`RefreshQuotaFromWebView`, `SaveManualRefreshSnapshot`,
`ManualRefreshController`, and the manual refresh widgets. It composes
extraction, parser, and persistence without adding cookie/token/storage/HTML
access or background execution.

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
summarized in [docs/stage3_report.md](docs/stage3_report.md), Stage 4 is
summarized in [docs/stage4_report.md](docs/stage4_report.md), Stage 5 is
summarized in [docs/stage5_report.md](docs/stage5_report.md), and Stage 6 is
summarized in [docs/stage6_report.md](docs/stage6_report.md).

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
│   ├── stage4_report.md
│   ├── stage5_report.md
│   └── stage6_report.md
├── lib/
│   ├── app.dart
│   ├── core/
│   ├── features/
│   │   ├── auth/
│   │   ├── debug/
│   │   ├── extraction/
│   │   ├── quota/
│   │   ├── parser/
│   │   ├── refresh/
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

- Stage 6 WebView network access is limited to user-driven official-site
  navigation inside the app WebView.
- Stage 6 persists mock quota data/settings, the last redacted extracted text
  preview, the last manual refresh result, and policy-approved parsed
  snapshots.
- Do not add automatic refresh, background refresh, storage reads, or network
  upload without a new security review.
- Do not store credentials.

## Roadmap

- [x] Stage 1: Architecture + Mock UI
- [x] Stage 2: Local persistence for snapshots and settings
- [x] Stage 3: WebView login container
- [x] Stage 4: Usage page text extraction
- [x] Stage 5: Quota parser with confidence levels
- [x] Stage 6: Real manual refresh flow
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
- Parser works on redacted visible text only.
- Parser results are local and may be inaccurate.
- Low-confidence parser results are not saveable as snapshots.
- Manual refresh requires a user tap.
- No automatic or background refresh.
- No analytics SDK by default.
- Debug extracted text should be treated as sensitive even after redaction.

See [docs/security.md](docs/security.md) for the Stage 6 security boundary.

## License

MIT. See [LICENSE](LICENSE).
