# Quota Analytics

Quota Analytics is an unofficial cross-platform quota analytics app for tracking
usage limits, refresh windows, remaining quota, and quota status.

## Disclaimer

This is an unofficial independent project. It is not affiliated with, endorsed
by, or maintained by OpenAI, ChatGPT, or Codex.

Stage 8 adds Android background task infrastructure and local notifications,
but background work is safety-gated. Stage 8.1 adds optional foreground
reload-before-refresh for manual and foreground auto refresh. Stage 8.2 routes
the Quota page refresh action through the visible Usage page and manual refresh
pipeline instead of the mock refresh path. Without an official API or
background-safe data source, background mode uses notify-only behavior based on
the last saved local snapshot and refresh metadata. Real quota refresh still
requires foreground WebView visible-text extraction. The app still does not
read cookies, tokens, passwords, browser storage contents, local browser
profiles, credentials, HTML, or an official quota API.

## Current Status

Stage 8.2: Quota page Usage refresh is complete.

- Flutter Android-first implementation.
- Mock quota dashboard.
- Quota app-bar refresh opens the visible Usage page, refreshes from the current
  page, and saves high-confidence manual results for that tap.
- Last mock snapshot restore on startup.
- Bounded mock snapshot history.
- Persisted foreground auto-refresh and refresh interval settings.
- Official Web Login page using `webview_flutter`.
- Users can manually open the official login page inside the app WebView:
  `https://chatgpt.com/auth/login`.
- Users can manually open the Codex usage analytics page after login:
  `https://chatgpt.com/codex/cloud/settings/analytics`.
- Mobile WebView layout uses an expanded main region with compact controls.
- Users can manually extract visible text from the current WebView page.
- Extracted text is redacted before display and local storage.
- Users can manually parse the current redacted visible text.
- Users can manually refresh from the current WebView page in one flow.
- The Quota page refresh action reuses that manual refresh pipeline and no
  longer calls the app-bar mock refresh path.
- Manual refresh can optionally reload the current foreground WebView page
  before extraction. This is on by default because a user tap usually means the
  latest rendered official page is desired.
- Parser results include confidence, warnings, errors, matched signals, window
  fields, credits, and evidence labels.
- Parser results are local and may be inaccurate.
- Parsed snapshots require manual save and are marked with source and parser
  confidence.
- High-confidence manual refresh can auto-save only if the user enables the
  conservative setting; it is off by default.
- The Quota page refresh action uses a one-shot high-confidence auto-save
  override without changing the persisted setting.
- Foreground auto refresh is off by default, runs only while the app is
  resumed, uses the current already-open WebView page only, and reuses the
  manual refresh pipeline.
- Foreground auto refresh can optionally reload the current foreground WebView
  page before extraction. This is off by default because automatic page reloads
  can increase login, reliability, battery, and rate-limit risk.
- Android background refresh is safety-gated.
- Without an official API or background-safe datasource, background mode uses
  notify-only behavior.
- Background refresh remains notify-only and never uses hidden WebView
  scraping.
- Background checks read only app-owned local snapshot/settings/metadata.
- Local notifications can remind the user when saved quota data is stale, quota
  is low, or the last refresh failed.
- Notification cooldown metadata prevents repeated reminders.
- No hidden background WebView scraping.
- No hidden WebView.
- No background cookie/token/storage access.
- No background HTML or page text extraction.
- No cookie/token/storage access for reload-before-refresh.
- No HTML extraction.
- No data upload.
- WebView status shows sanitized URL, title, loading progress, navigation time,
  last error, and conservative auth status.
- The app still does not read cookie/token values.
- The app still does not read localStorage or sessionStorage.
- The app still does not extract HTML.
- The app still does not upload page text, parser input, parser output, logs, or
  snapshots.
- The app still does not run background WebView refresh.
- Settings page with explicit save and clear-local-data.
- Debug page with persistence diagnostics, WebView status, Stage 4 extraction,
  Stage 5 parser, Stage 6 manual refresh, Stage 7 foreground auto refresh, and
  Stage 8 background refresh/notification safety flags, plus Stage 8.1 reload
  status and Stage 8.2 Quota refresh behavior.
- Clean, feature-first layered architecture.

## Features

- Mock quota dashboard.
- 5-hour window mock display.
- Weekly window mock display.
- Credits mock display.
- Local mock fallback for development and first-run demo state.
- Quota page Usage refresh through the foreground manual refresh pipeline.
- Local latest snapshot persistence.
- Local history persistence, capped at 100 snapshots.
- Persisted refresh interval settings UI.
- WebView login container for manual official-site login.
- WebView controls for login page, usage page, reload, back, forward, and
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
- Optional reload-before-manual-refresh for the current foreground WebView.
- Optional reload-before-foreground-auto-refresh for the current foreground
  WebView only.
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

The auto refresh feature owns the Stage 7 foreground lifecycle and timer
orchestration through `AutoRefreshPolicy`,
`EvaluateAutoRefreshEligibility`, `RunForegroundAutoRefresh`,
`ForegroundAutoRefreshController`, and `AutoRefreshStatusCard`. It reuses the
manual refresh pipeline and does not read WebView JavaScript directly.

The background refresh feature owns the Stage 8 Android WorkManager
infrastructure, `BackgroundRefreshEligibility`, notify-only local snapshot
checks, last background run metadata, and Settings/Debug controls. It does not
depend on WebView, extraction, parser, cookies, tokens, browser storage, HTML,
or page text.

The notifications feature owns local notification settings, safe fixed
notification content, per-type cooldown metadata, notification permission
status, and the `flutter_local_notifications` adapter.

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
summarized in [docs/stage5_report.md](docs/stage5_report.md), Stage 6 is
summarized in [docs/stage6_report.md](docs/stage6_report.md), and Stage 7 is
summarized in [docs/stage7_report.md](docs/stage7_report.md). Stage 8 is
summarized in [docs/stage8_report.md](docs/stage8_report.md). Stage 8.1 is
summarized in [docs/stage8_1_report.md](docs/stage8_1_report.md). Stage 8.2 is
summarized in [docs/stage8_2_report.md](docs/stage8_2_report.md).

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
│   ├── stage6_report.md
│   ├── stage7_report.md
│   ├── stage8_report.md
│   ├── stage8_1_report.md
│   └── stage8_2_report.md
├── lib/
│   ├── app.dart
│   ├── core/
│   ├── features/
│   │   ├── auth/
│   │   ├── auto_refresh/
│   │   ├── background_refresh/
│   │   ├── debug/
│   │   ├── extraction/
│   │   ├── notifications/
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

- Stage 8 background work is notify-only unless a future background-safe data
  source is added.
- Stage 8.1 reload-before-refresh is foreground only. It reloads only the
  visible, current WebView page before the existing `document.body.innerText`
  extraction pipeline.
- Stage 8.2 Quota refresh is user-triggered, foreground-only, and uses the
  visible Usage page before the same manual extraction pipeline.
- Stage 7 WebView network access is limited to user-driven official-site
  navigation inside the app WebView.
- Stage 8 persists mock quota data/settings, the last redacted extracted text
  preview, the last manual refresh result, background settings, notification
  metadata, the last background result, and policy-approved parsed snapshots.
- Do not add real background web refresh, hidden WebViews, credential reads, or
  network upload without a new security review.
- Do not store credentials.

## Roadmap

- [x] Stage 1: Architecture + Mock UI
- [x] Stage 2: Local persistence for snapshots and settings
- [x] Stage 3: WebView login container
- [x] Stage 4: Usage page text extraction
- [x] Stage 5: Quota parser with confidence levels
- [x] Stage 6: Real manual refresh flow
- [x] Stage 7: Foreground auto refresh + WebView layout fix
- [x] Stage 8: Android background refresh and notifications
- [x] Stage 8.1: Reload-before-refresh for manual and foreground refresh
- [x] Stage 8.2: Quota page usage refresh
- [ ] Stage 9: Android home screen widget - data export layer
- [ ] Stage 10: Android home screen widget - native widget shell
- [ ] Stage 11: Android widget refresh integration
- [ ] Stage 12: iOS adaptation feasibility
- [ ] Stage 13: Desktop client / tray adaptation
- [ ] Stage 14: Wearable adaptation
- [ ] Stage 15: Data source abstraction upgrade

## Security And Privacy

- No password storage.
- No cookie reading or upload.
- No token scraping.
- No localStorage or sessionStorage reading.
- No WebView HTML extraction.
- Manual WebView text extraction reads only `document.body.innerText`.
- Android background work does not access WebView, cookies, tokens,
  localStorage, sessionStorage, HTML, or page text.
- Extracted text remains local and only a redacted preview is saved.
- Parser works on redacted visible text only.
- Parser results are local and may be inaccurate.
- Low-confidence parser results are not saveable as snapshots.
- Manual refresh requires a user tap.
- Foreground auto refresh is opt-in and foreground-only.
- Background WorkManager checks are notify-only and safety-gated.
- No background WebView refresh.
- No analytics SDK by default.
- Debug extracted text should be treated as sensitive even after redaction.

See [docs/security.md](docs/security.md) for the Stage 8 security boundary.

## License

MIT. See [LICENSE](LICENSE).
