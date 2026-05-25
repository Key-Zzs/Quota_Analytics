# Roadmap

## Stage 1: Architecture + Mock UI

Create a safe Flutter architecture, Android-first project, mock dashboard,
settings page, debug page, local tests, and documentation.

## Stage 2: Local Persistence

Persist mock snapshots and settings locally with an explicit data retention
policy. Keep data local.

## Stage 3: WebView Login Container

Implemented a reviewed WebView login container. Users can manually open the
official website, inspect sanitized navigation state, reload, go back/forward,
open the Codex usage analytics page, and clear this app's WebView data where
supported.
The app does not read cookies, tokens, HTML, page text, or quota values.

## Stage 4: Usage Page Text Extraction

Implemented manual, user-triggered visible page text extraction from the current
WebView page. The app reads only `document.body.innerText`, blocks empty,
non-HTTPS, and unknown-host URLs, redacts extracted text locally, and stores
only the latest bounded redacted preview for debugging.

## Stage 5: Quota Parser With Confidence Levels

Implemented a local parser for Stage 4 redacted visible text. The parser
produces `QuotaParseResult`, confidence, warnings/errors, parsed windows,
optional credits, and high/medium `QuotaSnapshot` previews that can be saved
only after explicit user confirmation.

## Stage 6: Real Manual Refresh Flow

Implemented a real user-triggered manual refresh flow from the current WebView
page. The app checks page safety, extracts only visible text, redacts locally,
parses locally, creates high/medium confidence snapshot candidates, and saves
only after policy allows it. No automatic or background refresh is included.

## Stage 7: Foreground Auto Refresh

Implemented foreground-only refresh while the app is open and resumed. It is
off by default, uses the current already-open WebView page only, reuses the
Stage 6 manual refresh pipeline, and adds a mobile WebView layout fix.

## Stage 8: Android Background Refresh And Notifications

Implemented Android background task infrastructure, background refresh
eligibility, notify-only fallback, local notifications, cooldown metadata, and
Debug/Settings controls. Without an official API or background-safe datasource,
background mode sends reminders only and never opens a hidden WebView.

## Stage 8.1: Reload-Before-Refresh For Manual And Foreground Refresh

Implemented optional foreground reload-before-refresh. Manual refresh can
reload the current visible WebView page before extraction, and foreground auto
refresh can do the same only while the app is resumed. Background refresh
remains notify-only and does not call WebView reload, hidden WebViews, or
JavaScript extraction.

## Stage 8.2: Quota Page Usage Refresh

Replaced the Quota page mock refresh shortcut with a foreground Usage page
refresh flow. The app now opens the visible Usage WebView, refreshes from the
current page through the manual refresh pipeline, saves high-confidence results
for that tap, updates the Quota dashboard, and lets foreground auto refresh
recalculate the next eligible refresh time.

## Stage 9: Android Home Screen Widget - Data Export Layer

Export safe local snapshot summaries for Android widgets without WebView,
cookie, token, storage, HTML, or page text access.

## Stage 10: Android Home Screen Widget - Native Widget Shell

Create the native Android widget shell that displays exported local data.

## Stage 11: Android Widget Refresh Integration

Connect widget refresh actions to safe app-owned data export and foreground app
entry points.

## Stage 12: iOS Adaptation Feasibility

Assess iOS storage, credential, WebView, notification, widget, and background
rules before implementation.

## Stage 13: Desktop Client / Tray Adaptation

Assess desktop tray/client adaptation and local datasource boundaries.

## Stage 14: Wearable Adaptation

Assess wearable display and sync constraints.

## Stage 15: Data Source Abstraction Upgrade

Add an official API adapter only if a stable API becomes available and is
appropriate for this use case.

## Status Checklist

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
