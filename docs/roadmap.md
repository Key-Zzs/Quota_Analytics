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
open a usage placeholder, and clear this app's WebView data where supported.
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

Add foreground-only refresh while the app is open. Keep it user-controlled and
visible.

## Stage 8: Android Background Refresh And Notifications

Only after explicit review, add background refresh and notifications with
minimal scheduling, clear opt-in, and no hidden login behavior.

## Stage 9: iOS Adaptation

Adapt the app to iOS storage, credential, and background rules.

## Stage 10: Desktop / Wearable Clients

Port the architecture to desktop and wearable clients. Treat each platform's
storage, credentials, and background rules separately.

## Stage 11: Optional Official API Adapter

Add an official API adapter only if a stable API becomes available and is
appropriate for this use case.

## Status Checklist

- [x] Stage 1: Architecture + Mock UI
- [x] Stage 2: Local persistence
- [x] Stage 3: WebView login container
- [x] Stage 4: Usage page text extraction
- [x] Stage 5: Quota parser with confidence levels
- [x] Stage 6: Real manual refresh flow
- [ ] Stage 7: Foreground auto refresh
- [ ] Stage 8: Android background refresh and notifications
- [ ] Stage 9: iOS adaptation
- [ ] Stage 10: Desktop / wearable clients
- [ ] Stage 11: Optional official API adapter
