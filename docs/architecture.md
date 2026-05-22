# Architecture

## Project Goal

Quota Analytics is an unofficial personal app for viewing quota-like usage
information. Stage 2 is limited to mock data plus local persistence for Android
phones and Android Emulator.

Stage 2 does not implement real GPT, ChatGPT, OpenAI, or Codex login, real usage
reading, cookies, tokens, WebView scraping, backend calls, or network data
sources.

## Layers

The app uses a feature-first Clean Architecture layout:

- `core`: shared constants, theme, time abstraction, formatting helpers, errors,
  logging, JSON storage abstraction, and serialization helpers.
- `features/quota/domain`: entities, repository contracts, and use cases.
- `features/quota/data`: mock data source, local data source, JSON models, and
  repository implementations.
- `features/quota/presentation`: controller, page, and widgets.
- `features/settings`: persisted settings domain, data, controller, and UI.
- `features/debug`: local debug view for mock state and safety notices.
- `features/auth`: placeholder only.
- `platform_placeholders`: iOS, desktop, and watch migration notes.

## Quota Domain Model

The quota model is explicit and typed:

- `QuotaSnapshot`: one captured view of account label, source, confidence,
  windows, credits, timestamps, and debug text.
- `QuotaWindow`: one usage window such as `5-hour window` or `Weekly window`.
- `QuotaSource`: mock plus future placeholders.
- `ParserConfidence`: parser quality marker.
- `QuotaWindowStatus`: ok, warning, critical, or unknown.

`QuotaWindow.fromUsage` computes remaining count, remaining ratio, percentage,
and status from typed usage values.

## Data Source Abstraction

The domain depends on `QuotaRepository`:

```dart
abstract class QuotaRepository {
  Future<QuotaSnapshot> getLatestSnapshot();
  Future<QuotaSnapshot> refreshSnapshot();
  Future<List<QuotaSnapshot>> getHistory();
  Future<void> clearLocalQuotaData();
  Future<QuotaPersistenceStatus> getPersistenceStatus();
}
```

Stage 2 implements:

- `MockQuotaDataSource`
- `MockQuotaRepository`
- `LocalQuotaDataSource`
- `PersistentQuotaRepository`

The UI talks to `QuotaController`, which talks to use cases, which talk to the
repository contract. This keeps future data sources out of widget code.

`PersistentQuotaRepository` first attempts to load the latest snapshot from
`LocalQuotaDataSource`. If no valid local snapshot exists, it falls back to
`MockQuotaDataSource`. Manual refresh still comes from the mock source, then the
result is written to latest snapshot storage and snapshot history.

## Persistence Layer

The persistence layer is intentionally small:

- `JsonStorage`: key/value string storage interface owned by `core/storage`.
- `SharedPreferencesStorage`: `shared_preferences` implementation of
  `JsonStorage`.
- `LocalStorageKeys`: the only local keys the app may write or clear.
- `LocalQuotaDataSource`: serializes/deserializes latest snapshot and history.
- `LocalSettingsDataSource`: serializes/deserializes app settings.

Current keys:

- `quota.latest_snapshot.v1`
- `quota.snapshot_history.v1`
- `settings.app_settings.v1`

Snapshot history is newest-first and capped at 100 records.

## Settings Repository

Settings are modeled with:

- `RefreshInterval`
- `AppSettings`
- `SettingsRepository`
- `LocalSettingsRepository`
- `SettingsController`

The settings domain owns the concepts of automatic refresh and interval choice.
The data layer owns JSON encoding and `shared_preferences` access.

## Domain Independence

The domain layer does not import Flutter UI or `shared_preferences`. Repository
contracts expose typed entities and futures. This keeps the core quota/settings
model reusable for future local JSON files, SQLite/Drift, an official API
adapter, a reviewed WebView source, or desktop agents without changing widgets.

## Why Stage 2 Is Mock Only

Mock-only scope keeps the early milestones safe and testable:

- No real account access.
- No cookie or token handling.
- No network parsing.
- No hidden background refresh.
- Fast local unit and widget tests.
- Clear UI and domain shape before security-sensitive integrations.
- Local persistence stores only mock quota data and user settings.

## Future Replacements

Future stages can add implementations behind the same repository contract:

- `WebViewQuotaDataSource`: a reviewed login container with strict storage and
  debug boundaries.
- `OfficialApiQuotaDataSource`: an official API integration if a stable API
  exists and is appropriate for this use case.
- `BrowserExtensionQuotaDataSource`: a browser-side companion that explicitly
  limits what text it sends to the app.
- `DesktopAgentQuotaDataSource`: a local desktop helper with audited process and
  credential boundaries.

Those sources should not change the quota UI contract.
