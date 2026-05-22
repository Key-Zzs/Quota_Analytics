# Quota Analytics

Quota Analytics is an unofficial cross-platform quota analytics app for tracking
usage limits, refresh windows, remaining quota, and quota status.

## Disclaimer

This is an unofficial independent project. It is not affiliated with, endorsed
by, or maintained by OpenAI, ChatGPT, or Codex.

Stage 2 uses mock data plus local persistence only. The app does not access real
GPT, ChatGPT, OpenAI, or Codex accounts, does not read cookies, tokens,
passwords, browser storage, or credentials, and does not provide an official
quota API.

## Current Status

Stage 2: Local persistence is complete.

- Flutter Android-first implementation.
- Mock quota dashboard.
- Mock manual refresh.
- Last mock snapshot restore on startup.
- Bounded mock snapshot history.
- Persisted auto-refresh and refresh interval settings.
- Settings page with explicit save and clear-local-data.
- Debug page with persistence diagnostics and recent history.
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
- Debug information page with storage diagnostics.
- Clear local data with confirmation.
- Light and dark Material 3 themes.
- Unit and widget tests for the Stage 2 mock persistence flow.

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

Future source placeholders include:

- `WebViewQuotaDataSource` for a reviewed login container.
- `OfficialApiQuotaDataSource` if a stable official quota API becomes available.
- `DesktopAgentQuotaDataSource` for local desktop helpers.
- Browser extension integration.
- Wearable clients.

More detail is available in [docs/architecture.md](docs/architecture.md),
[docs/security.md](docs/security.md), [docs/roadmap.md](docs/roadmap.md), and
[docs/stage1_report.md](docs/stage1_report.md). The Stage 2 implementation is
summarized in [docs/stage2_report.md](docs/stage2_report.md).

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
│   └── stage2_report.md
├── lib/
│   ├── app.dart
│   ├── core/
│   ├── features/
│   │   ├── auth/
│   │   ├── debug/
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

- Stage 2 app code does not use network access except dependency fetching by
  developer tooling.
- Stage 2 uses mock data only and persists only mock quota data/settings.
- Do not add real account login before a security review.
- Do not store credentials.

## Roadmap

- [x] Stage 1: Architecture + Mock UI
- [x] Stage 2: Local persistence for snapshots and settings
- [ ] Stage 3: WebView login container
- [ ] Stage 4: Usage page text extraction
- [ ] Stage 5: Quota parser with confidence levels
- [ ] Stage 6: Real manual refresh flow
- [ ] Stage 7: Foreground auto refresh
- [ ] Stage 8: Android background refresh and notifications
- [ ] Stage 9: iOS adaptation
- [ ] Stage 10: Desktop / wearable clients
- [ ] Stage 11: Optional official API adapter if a stable API becomes available

## Security And Privacy

- No password storage.
- No cookie upload.
- No token scraping.
- No analytics SDK by default.
- Debug raw text should be treated as sensitive in future real-data stages.

See [docs/security.md](docs/security.md) for the Stage 2 security boundary.

## License

MIT. See [LICENSE](LICENSE).
