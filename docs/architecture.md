# Architecture

## Project Goal

Quota Analytics is an unofficial personal app for viewing quota-like usage
information. Stage 1 is limited to architecture and mock UI for Android phones
and Android Emulator.

Stage 1 does not implement real GPT, ChatGPT, OpenAI, or Codex login, real usage
reading, cookies, tokens, WebView scraping, backend calls, or network data
sources.

## Layers

The app uses a feature-first Clean Architecture layout:

- `core`: shared constants, theme, time abstraction, formatting helpers, errors,
  and logging.
- `features/quota/domain`: entities, repository contracts, and use cases.
- `features/quota/data`: mock data source, model, and repository implementation.
- `features/quota/presentation`: controller, page, and widgets.
- `features/settings`: in-memory mock settings.
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
}
```

Stage 1 implements:

- `MockQuotaDataSource`
- `MockQuotaRepository`

The UI talks to `QuotaController`, which talks to use cases, which talk to the
repository contract. This keeps future data sources out of widget code.

## Why Stage 1 Is Mock Only

Mock-only scope keeps the first milestone safe and testable:

- No real account access.
- No cookie or token handling.
- No network parsing.
- No hidden background refresh.
- Fast local unit and widget tests.
- Clear UI and domain shape before security-sensitive integrations.

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
