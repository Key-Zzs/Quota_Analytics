# Stage 5 Report: Quota Parser With Confidence Levels

## Goal

Stage 5 adds a local quota parser for the redacted visible text produced by
Stage 4. The parser converts likely usage text into a structured
`QuotaParseResult`, shows the result in the Web Login extraction panel, and can
create a local `QuotaSnapshot` preview.

## Parser Input Source

The parser input is only the current `ExtractedPageText.redactedTextPreview`
from Stage 4, or artificial text used by unit/widget tests. It does not read
from WebView directly and does not access raw unredacted page text.

## Security Boundary

Stage 5 does not access:

- Cookies or WebView cookies.
- Access tokens, refresh tokens, session tokens, or authorization headers.
- `localStorage`, `sessionStorage`, or `indexedDB`.
- Page HTML, DOM structure, scripts, CSS, network requests, or responses.
- Backend services, telemetry, analytics SDKs, crash reporting, or uploads.
- Automatic refresh, background refresh, timers, or polling loops.

All parsing happens in Dart on-device against already-redacted visible text.

## Supported Text Patterns

`RegexQuotaParser` conservatively supports common visible text shapes:

- Used/limit: `12 / 50`, `12 of 50`, `12 used of 50`, `Used 12 of 50`.
- Remaining/limit: `38 remaining`, `38 remaining of 50`,
  `Remaining 38`, `38 left`.
- Percentage: `76% remaining`, `24% used`.
- Reset text: `resets in 2 hours`, `resets in 5h`, `resets tomorrow`,
  `resets on Monday`, `reset at 3:00 PM`.
- Window labels: `5 hour`, `5-hour`, `5h`, `five hour`, `weekly`, `week`,
  `7 day`, `7-day`.
- Credits: `credits`, `remaining credits`, `credit balance`,
  `123 credits remaining`.
- Basic Chinese labels: `5小时`, `每周`, `剩余`, `已使用`, `重置`.

## Confidence Rules

- `high`: both 5-hour and weekly windows are detected, at least one window has
  structured usage/remaining values, and there are no conflicting candidates.
- `medium`: one recognized window has structured values, or credits are parsed
  without enough complete window information.
- `low`: only weak quota/usage/limit/remaining/reset signals are present and
  stable structured fields cannot be filled.
- `failed`: input is empty, has no visible lines, or has no meaningful quota
  signals.
- `notApplicable`: parser has not run or the user cleared the parser result.

## Conflict Handling

The parser splits text into normalized lines, finds 5-hour and weekly labels,
then searches nearby lines for numeric candidates. Candidates are scored by
proximity, keyword context, and pattern clarity. If multiple candidates disagree
for the same window, the parser keeps the nearest/best candidate, adds a
warning, and lowers confidence. It does not fabricate uncertain fields.

## Snapshot Mapping

`ParseResultToQuotaSnapshotMapper` maps only `high` and `medium` parse results
to a preview `QuotaSnapshot`. The mapped snapshot uses:

- `source: webViewManualExtraction`
- the parser confidence from `QuotaParseResult`
- `accountLabel: WebView Extracted Account`
- `capturedAt: result.parsedAt`
- no `nextSuggestedRefreshAt`
- a bounded evidence summary in `rawDebugText`, never the full parser input

`low` and `failed` results are shown in debug UI but are not saveable as
snapshots.

## UI Entry

The Web Login extraction panel now includes:

- `Parse Extracted Text`
- parser input length and parse status messages
- `ParseResultCard` with success, confidence, parser version, matched signals,
  warnings, errors, parsed windows, credits, and evidence labels
- `Save Parsed Snapshot`, enabled only for high/medium preview results
- confirmation copy: `This will save the parsed result as a local quota snapshot.`

The Debug page shows parser enabled status, automatic refresh disabled, last
parser input length, last confidence, parser version, warnings, and errors.

## Test Summary

Stage 5 adds unit and widget tests for:

- high confidence 5-hour + weekly parsing
- medium confidence weekly + credits parsing
- low confidence weak signals
- failed ordinary page text
- conflicting weekly candidates
- redacted marker samples
- basic Chinese quota text
- preprocessor normalization
- parse result to snapshot mapping
- parser controller parse/save behavior
- parse result and parsed window UI
- disabled parse/save button states

## Known Limitations

- The parser is regex-based and intentionally conservative.
- The app stores only the Stage 4 bounded redacted preview, so parsing may miss
  content beyond that preview.
- Absolute reset times such as `reset at 3:00 PM` are preserved as text unless
  they can be safely resolved.
- The parser may need new rules when visible usage page wording changes.
- Saved parsed snapshots are local previews and may be inaccurate.

## Next Stage

Stage 6 should implement a real manual refresh flow: user-triggered extraction,
parse, review, and save, with clear loading/success/error states and no
automatic or background refresh.

