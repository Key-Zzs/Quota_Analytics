# Architecture

## Project Goal

Quota Analytics is an unofficial personal app for viewing quota-like usage
information. Stage 8 adds Android background task infrastructure and local
notifications while preserving the foreground-only WebView acquisition
boundary.

Stage 8 does not implement cookies, tokens, storage reads, HTML extraction,
backend calls, hidden WebView scraping, or true background web refresh. The
WebView login container, text extraction flow, parser, manual refresh
orchestration, foreground auto refresh orchestration, background local-check
orchestration, notifications, and quota persistence remain intentionally
separate.

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
- `features/auth`: WebView login container split into domain, data, and
  presentation layers.
- `features/extraction`: Stage 4 manual page text extraction, redaction, local
  redacted preview storage, controller state, and widgets.
- `features/parser`: Stage 5 local parser domain model, regex parser,
  confidence rules, result-to-snapshot mapper, controller state, and widgets.
- `features/refresh`: Stage 6 manual refresh orchestration, typed status/result
  model, save policy, persisted last result, use cases, controller, and widgets.
- `features/auto_refresh`: Stage 7 foreground lifecycle/timer orchestration,
  eligibility rules, status model, repository adapter, controller, and status
  widget. It reuses Stage 6 and does not read WebView JavaScript directly.
- `features/background_refresh`: Stage 8 Android WorkManager scheduling,
  background eligibility, local snapshot staleness/low-quota/failure checks,
  notify-only fallback, last-run metadata, and Settings/Debug UI. It does not
  depend on WebView.
- `features/notifications`: Stage 8 local notification rules, cooldown
  metadata, permission status, and local notification adapter. It does not
  depend on WebView.
- `platform_placeholders`: iOS, desktop, and watch migration notes.

## Quota Domain Model

The quota model is explicit and typed:

- `QuotaSnapshot`: one captured view of account label, source, confidence,
  windows, credits, timestamps, and debug text.
- `QuotaWindow`: one usage window such as `5-hour window` or `Weekly window`.
- `QuotaSource`: mock, `webViewManualExtraction`, plus future placeholders.
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
  Future<QuotaSnapshot> saveSnapshot(QuotaSnapshot snapshot);
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
`MockQuotaDataSource`. The legacy app-bar mock refresh still writes mock data to
latest snapshot storage and history. Stage 6 manual refresh uses `saveSnapshot`
after user confirmation, or after high-confidence auto-save if the user enables
that conservative setting.

## Persistence Layer

The persistence layer is intentionally small:

- `JsonStorage`: key/value string storage interface owned by `core/storage`.
- `SharedPreferencesStorage`: `shared_preferences` implementation of
  `JsonStorage`.
- `LocalStorageKeys`: the only local keys the app may write or clear.
- `LocalQuotaDataSource`: serializes/deserializes latest snapshot and history.
- `LocalSettingsDataSource`: serializes/deserializes app settings.
- `LocalExtractedTextDataSource`: serializes/deserializes the latest redacted
  extracted text preview.
- `LocalManualRefreshDataSource`: serializes/deserializes the latest manual
  refresh result without raw unredacted page text.

Current keys:

- `quota.latest_snapshot.v1`
- `quota.snapshot_history.v1`
- `settings.app_settings.v1`
- `extraction.last_page_text.v1`
- `refresh.last_manual_result.v1`
- `background_refresh.settings.v1`
- `background_refresh.last_result.v1`
- `notifications.metadata.v1`

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

The auth feature owns the WebView login container:

- `WebAuthConfig`: central URL configuration for the login page and Codex usage
  analytics page.
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

Stage 7 changes the WebView page layout shell. The WebView now sits in a keyed
`Expanded` main region (`webview-expanded-region`) with compact, collapsible
top safety/status controls and a compact bottom action panel. This keeps the
outer Flutter shell from constraining the WebView to a fixed small height on
phones; page scrolling remains inside the WebView.

## Extraction Feature

The extraction feature owns Stage 4 manual page text extraction:

- `ExtractedPageText`: structured result containing sanitized URL, title,
  redacted preview, redaction counts, source, safety status, timestamp, and
  optional safe error.
- `ExtractionSource`: currently only `webViewManual`.
- `ExtractionSafetyStatus`: `allowed`, `blockedNonHttps`,
  `blockedUnknownHost`, and `failed`.
- `PageTextExtractionRepository`: domain contract for attaching a current page
  reader, extracting, loading the last result, and clearing the local cache.
- `WebViewTextExtractionDataSource`: `webview_flutter` adapter that runs only
  the `document.body.innerText` JavaScript snippet after user action.
- `LocalExtractedTextDataSource`: app-owned local storage for the latest
  redacted preview only.
- `PageTextExtractionRepositoryImpl`: URL safety check, text redaction, result
  construction, and persistence orchestration.
- `PageTextExtractionController`: presentation state for extraction progress,
  messages, last result, and clear action.
- `ExtractionStatusCard` and `ExtractedTextPreview`: WebView page UI for manual
  extraction, redacted preview, copy, and clear controls.

Shared security helpers live in `core/security`:

- `AllowedWebHosts`: conservative HTTPS host allowlist.
- `UrlSanitizer`: removes query and fragment values.
- `TextRedactor`: redacts emails, bearer tokens, suspected API keys,
  token-like strings, and secret/password/token key-value values.

## Parser Feature

The parser feature owns Stage 5 local interpretation of already-redacted visible
text:

- `QuotaParseResult`: parser success flag, confidence, windows, credits,
  matched signals, warnings, errors, parsed timestamp, and parser version.
- `ParsedQuotaWindow`: parsed 5-hour, weekly, or unknown window with optional
  used, limit, remaining, ratio, reset text/time, and evidence labels.
- `ParsedCredits`: optional credits remaining/total and local evidence text.
- `QuotaParser`: pure Dart contract with `parse(String text, {DateTime? now})`.
- `RegexQuotaParser`: conservative line/context regex parser for common
  used/limit, remaining, percentage, reset, window-label, credits, and basic
  Chinese patterns.
- `QuotaTextPreprocessor`: whitespace normalization and line splitting.
- `QuotaCandidateExtractor`: window label discovery for 5-hour and weekly
  contexts.
- `ParseResultToQuotaSnapshotMapper`: converts high/medium parse results into
  local `QuotaSnapshot` previews with `source: webViewManualExtraction`.
- `QuotaParserController`: presentation state for manual parse, preview, clear,
  and user-confirmed local save.
- `ParseResultCard` and `ParsedWindowCard`: debug UI for confidence, signals,
  warnings, errors, fields, credits, and evidence.

The parser does not depend on WebView and has no file, storage, cookie, token,
or network access. Its only app input is Stage 4 redacted visible text.

## Refresh Feature

The refresh feature owns Stage 6 manual orchestration:

- `ManualRefreshStatus`: typed state machine from `checkingPage` through
  extraction, redaction, parsing, confirmation, saving, saved, and failure
  states.
- `ManualRefreshResult`: status, extraction safety status, parser confidence,
  warnings/errors, candidate snapshot, redaction summary, duration, and saved
  snapshot id. It does not contain raw unredacted text.
- `ManualRefreshPolicy`: conservative save policy. High confidence can
  auto-save only if enabled; medium requires confirmation; low is blocked by
  default.
- `RefreshQuotaFromWebView`: checks current WebView page state and URL safety,
  calls the extraction repository, parses redacted text, maps high/medium
  results to a candidate snapshot, applies policy, and optionally auto-saves
  high confidence results.
- `SaveManualRefreshSnapshot`: validates policy and saves the candidate through
  `QuotaRepository.saveSnapshot`, which updates latest snapshot and history.
- `ManualRefreshRepository`: persists only the last manual refresh result for
  Debug/local state.
- `ManualRefreshController`: presentation state for the WebView page and Debug
  page.
- `ManualRefreshButton`, `ManualRefreshStatusCard`,
  `ManualRefreshResultCard`, and `SaveSnapshotConfirmation`: UI widgets for the
  user-triggered flow.

The refresh feature composes extraction, parser, and persistence. It does not
own WebView JavaScript, parser regexes, or direct `shared_preferences` access.

## Auto Refresh Feature

The auto refresh feature owns Stage 7 foreground orchestration:

- `AutoRefreshStatus`: typed disabled, idle, skipped, refreshing, success,
  failed, and cooldown statuses.
- `AutoRefreshState`: enabled flag, selected interval, last attempt/success,
  next eligible time, cooldown, last error, and in-progress flag.
- `AutoRefreshPolicy`: interval and failure cooldown calculations.
- `EvaluateAutoRefreshEligibility`: pure use case for foreground, WebView,
  URL, loading, interval, duplicate, and cooldown checks.
- `RunForegroundAutoRefresh`: use case that invokes an auto refresh repository.
- `ForegroundAutoRefreshRepository`: adapter that calls
  `ManualRefreshController.refreshFromCurrentPage`.
- `ForegroundAutoRefreshController`: `WidgetsBindingObserver` lifecycle bridge,
  foreground timer owner, duplicate guard, and status publisher.
- `AutoRefreshStatusCard`: Settings status display.

The controller starts its timer only when settings are enabled and lifecycle is
`resumed`. It stops on `paused`, `inactive`, `hidden`, `detached`, and dispose.
It never opens a WebView page, logs in, reads cookies/tokens/storage, reads
HTML, uploads data, or parses outside the Stage 6 manual refresh use case.

## Background Refresh Feature

The background refresh feature owns Stage 8 Android background orchestration:

- `BackgroundRefreshMode`: `disabled`, `notifyOnly`, and
  `backgroundSafeDataSourceOnly`.
- `BackgroundRefreshSettings`: mode, WorkManager check interval, stale-data
  threshold, notification settings, minimum run spacing, and update time.
- `BackgroundRefreshEligibility`: pure Dart result for allowed, notify-only,
  disabled, no-safe-datasource, cooldown, system constraint, and failed cases.
- `EvaluateBackgroundRefreshEligibility`: pure rule evaluator for settings,
  local state, datasource availability, notification permission status, and
  cooldown.
- `RunBackgroundRefreshCheck`: safe local check use case. It reads app-owned
  snapshot/settings/metadata only and calls notification rules.
- `LocalBackgroundRefreshDataSource`: app-owned storage adapter. It strips
  `rawDebugText`, replaces account labels, and reads shallow manual refresh
  failure metadata only.
- `WorkmanagerBackgroundTaskDataSource`: thin WorkManager schedule/cancel
  wrapper. It passes only a non-sensitive purpose string to tasks.
- `BackgroundTaskDispatcher`: Android background isolate entry point that
  rebuilds only storage, background refresh, and notification dependencies.
- `BackgroundRefreshSettingsController`,
  `BackgroundRefreshSettingsSection`, and `BackgroundRefreshStatusCard`:
  Settings/Debug UI.

`background_refresh` intentionally does not import auth, extraction, parser, or
WebView data sources. It cannot open pages, inject JavaScript, read cookies,
read browser storage, read HTML, or read page text.

`backgroundSafeDataSourceOnly` is an architectural placeholder. It is reserved
for a future official API, desktop agent, or browser extension sync adapter. The
current no-op adapter reports unavailable, causing the use case to downgrade to
notify-only.

## Notifications Feature

The notifications feature owns Stage 8 local notification behavior:

- `QuotaNotificationType`: stale data, low 5-hour quota, low weekly quota, low
  credits, refresh failed, and background refresh unavailable.
- `NotificationSettings`: local notification toggle, thresholds, refresh
  failure reminder flag, and cooldown duration.
- `NotificationCandidate`: fixed safe title/body/payload values.
- `NotificationMetadata`: per-type `lastSentAt` cooldown tracking.
- `EvaluateNotificationRules`: pure Dart rule evaluator for stale, low quota,
  failure, unavailable datasource, and cooldown cases.
- `LocalNotificationDataSource`: thin `flutter_local_notifications` adapter.
- `LocalNotificationRepository`: permission, send, and metadata persistence.

Notifications do not contain account email, full URL, raw page text, parser raw
input/output, tokens, stack traces, or web-derived sensitive content. They are
local reminders only and never trigger hidden background web refresh.

## Why Manual Refresh And Auto Refresh Are Separate

Manual refresh is a user-intent boundary: the user opens a page, taps a clear
button, reviews the result, and confirms save unless policy allows
high-confidence auto-save. Foreground auto refresh is a scheduling boundary: it
adds lifecycle, interval, retry, and user-awareness rules while deliberately
reusing the same Stage 6 pipeline. Keeping the features separate prevents the
timer from owning WebView JavaScript, parser regexes, or persistence details.

## Why Extraction And Parser Are Separate

Extraction is a controlled acquisition boundary; parsing is a data
interpretation boundary. Stage 4 only acquires bounded, redacted visible text
for local debugging. Stage 5 parses that structured `ExtractedPageText` output
without gaining access to cookies, tokens, WebView storage, HTML, network
responses, or background execution.

## Why Login And Parser Are Separate

The login container is a security boundary, while the quota parser is a data
interpretation boundary. The WebView login feature lets users manually sign in
without the app touching credentials. Stage 4 adds a separate reviewed
innerText-only extraction boundary, and Stage 5 must remain a separate parser
boundary. Keeping these concerns separate reduces the chance that navigation
state or WebView storage access becomes an implicit quota data source.

## Domain Independence

The domain layer does not import Flutter UI or `shared_preferences`. Repository
contracts expose typed entities and futures. This keeps the core quota/settings
model reusable for future local JSON files, SQLite/Drift, an official API
adapter, a reviewed WebView source, or desktop agents without changing widgets.

## Why Background Refresh Is Notify-Only

Stage 8 adds scheduling and notifications, but real web acquisition remains
foreground-only:

- User-driven WebView login only, with no app access to credentials.
- User-triggered visible text extraction only, with no cookie or token handling.
- Local parser only for redacted visible text.
- User-reviewed save policy for medium confidence parsed snapshots.
- Low-frequency foreground timer only when the app is resumed.
- Background checks read only app-owned snapshot/settings/metadata.
- Background-safe datasource mode downgrades to notify-only until a real safe
  adapter exists.
- No network parsing or uploads.
- No hidden background WebView refresh.
- Fast local unit and widget tests.
- Clear UI and domain shape before security-sensitive integrations.
- Local persistence stores mock quota data, user settings, the latest redacted
  extracted text preview, the last manual refresh result, background settings,
  notification metadata, last background result, and policy-approved parsed
  snapshot previews.

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
