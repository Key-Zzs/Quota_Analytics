# Roadmap

## Stage 1: Architecture + Mock UI

Create a safe Flutter architecture, Android-first project, mock dashboard,
settings page, debug page, local tests, and documentation.

## Stage 2: Local Persistence

Persist mock snapshots and settings locally with an explicit data retention
policy. Keep data local.

## Stage 3: WebView Login Container

Design and implement a reviewed WebView container. Define cookie/session
storage, clear-session controls, and debug boundaries before coding.

## Stage 4: Usage Page Text Extraction

Extract usage page text inside the reviewed boundary. Avoid logging raw text by
default.

## Stage 5: Parser

Parse extracted usage text into the existing quota domain model. Track parser
confidence and failure reasons.

## Stage 6: Manual Refresh

Wire manual refresh to the real data source while keeping clear loading,
success, empty, and error states.

## Stage 7: Foreground Auto Refresh

Add foreground-only refresh while the app is open. Keep it user-controlled and
visible.

## Stage 8: Background Refresh / Notification

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
