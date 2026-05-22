# Architecture

## Project Goal

Quota Analytics is an unofficial personal app for viewing quota-like usage
information. Stage 3 keeps quota data mock-only while adding a WebView login
container for user-driven official-site login.

Stage 3 does not implement real usage reading, cookies, tokens, WebView
scraping, backend calls, quota parsing, or automatic refresh. The WebView login
container is intentionally separate from quota extraction.

## Layers

The app uses a feature-first Clean Architecture layout:

- `core`: shared constants, theme, time abstraction, formatting helpers, errors,
  logging, JSON storage abstraction, and serialization helpers.
- `features/quota/domain`: entities, repository contracts, and use cases.
- `features/quota/data`: mock data source, local data source, JSON models, and
  repository implementations.
- `features/quota/presentation`: controller, page, and widgets.
- `features/settings`: persisted settings domain, data, controller, and UI.
- `features/debug`: local debug view for mock state, WebView status, and safety
  notices.
- `features/auth`: Stage 3 WebView login container split into domain, data, and
  presentation layers.
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

## Auth Feature

The auth feature owns the Stage 3 login container:

- `WebAuthConfig`: central URL configuration for the login page and usage page
  placeholder.
- `WebAuthStatus`: conservative navigation-derived status values:
  `unknown`, `maybeLoggedIn`, `loggedOut`, `blocked`, and `error`.
- `WebAuthRepository`: repository contract for loading URLs, navigating the
  WebView, retrieving non-sensitive metadata, and clearing app WebView data.
- `WebViewAuthDataSource`: `webview_flutter` adapter. It loads HTTPS pages,
  denies WebView permission requests, reports navigation metadata, and clears
  WebView cache/local data where supported.
- `WebViewAuthController`: testable presentation state for sanitized current
  URL, page title, progress, last navigation time, last error, and auth status.
- `WebViewLoginPage`: Material 3 UI for safety notices, navigation controls,
  status, and the WebView container.

The auth feature does not expose cookies, tokens, page HTML, page body text,
localStorage, sessionStorage, or quota data to the quota feature.

## Why Login And Parser Are Separate

The login container is a security boundary, while the quota parser is a data
interpretation boundary. Stage 3 implements only the first boundary so users can
manually sign in without the app touching credentials. Stage 4 and Stage 5 must
go through separate review before any page text extraction or parser logic is
added. Keeping these concerns separate reduces the chance that navigation state
or WebView storage access becomes an implicit quota data source.

## Domain Independence

The domain layer does not import Flutter UI or `shared_preferences`. Repository
contracts expose typed entities and futures. This keeps the core quota/settings
model reusable for future local JSON files, SQLite/Drift, an official API
adapter, a reviewed WebView source, or desktop agents without changing widgets.

## Why Quota Data Is Still Mock Only

Mock-only scope keeps the early milestones safe and testable:

- User-driven WebView login only, with no app access to credentials.
- No cookie or token handling.
- No network parsing.
- No hidden background refresh.
- Fast local unit and widget tests.
- Clear UI and domain shape before security-sensitive integrations.
- Local persistence stores only mock quota data and user settings.

## Future Replacements

Future stages can add implementations behind the same repository contract:

- `WebViewQuotaDataSource`: a reviewed usage extraction source after Stage 4
  security review.
- `OfficialApiQuotaDataSource`: an official API integration if a stable API
  exists and is appropriate for this use case.
- `BrowserExtensionQuotaDataSource`: a browser-side companion that explicitly
  limits what text it sends to the app.
- `DesktopAgentQuotaDataSource`: a local desktop helper with audited process and
  credential boundaries.

Those sources should not change the quota UI contract.
