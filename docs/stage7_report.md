# Stage 7 Report: Foreground Auto Refresh + WebView Layout Fix

## Goals

Stage 7 fixes the mobile WebView layout and adds user-controlled foreground
auto refresh. It stays within the Stage 6 safety boundary: current WebView page
only, `document.body.innerText` only, local redaction/parser/persistence only,
and no background execution.

## WebView Half-Screen Fix

Problem: on phones, the WebView could appear as only the upper portion of the
page or feel clipped. The previous page placed the WebView at the bottom of a
single `ListView` and gave it a fixed `360` or `460` pixel height. Large safety,
status, extraction, and manual refresh cards sat above it, so small screens had
poor constraints and the WebView did not own the main remaining height.

Possible causes considered:

- WebView inside an outer scroll view with fixed height.
- Status/debug panels competing with the WebView for vertical space.
- Buttons and safety text permanently occupying too much mobile height.
- Nested scrollables causing Flutter to scroll the shell rather than letting
  the WebView scroll its own page.
- Insets from app bars, navigation bars, and small device heights.

Actual changes:

- `WebViewLoginPage` now uses a `SafeArea` + `Stack` shell.
- The WebView is inside the keyed `Positioned.fill` region
  `webview-expanded-region`, so it visually fills the Web Login tab like a
  phone-screen viewport.
- Safety notice, WebView controls, and WebView status are compact translucent
  top overlays instead of height-taking layout rows.
- Manual refresh and extraction actions moved into a compact translucent bottom
  overlay with scrollable details.
- `WebViewAuthDataSource` keeps JavaScript enabled for the existing extraction
  flow and enables WebView zoom where supported.

Manual verification:

1. Open the app on a phone or emulator.
2. Go to `Web Login`.
3. Confirm the WebView container occupies the main visible area.
4. Tap `Open login page`.
5. Tap `Open usage page`.
6. Confirm the page itself scrolls inside the WebView.
7. Expand safety/status/details panels and confirm the WebView still returns to
   the main available height when panels are collapsed.

If the issue remains, next checks are Android WebView composition differences,
device-specific system insets, page viewport meta behavior on the official
site, and whether a specific Android System WebView version clips platform
views.

## URL Configuration

The URLs remain centralized through `WebConstants` / `WebAuthConfig`:

- Login: `https://chatgpt.com/auth/login`
- Usage: `https://chatgpt.com/codex/cloud/settings/analytics`

The WebView page still shows `Open login page` and `Open usage page`. The old
placeholder copy is not used. URL display continues to remove query strings and
fragments.

## Foreground Auto Refresh Design

Foreground auto refresh is an orchestration feature. It does not read WebView
content directly and does not own parser rules. It asks the Stage 6 manual
refresh controller to run the same safe pipeline against the current WebView
page when eligibility passes.

Main pieces:

- `AutoRefreshPolicy`: interval and failure cooldown calculations.
- `EvaluateAutoRefreshEligibility`: pure eligibility decision use case.
- `RunForegroundAutoRefresh`: invokes an `AutoRefreshRepository`.
- `ForegroundAutoRefreshRepository`: adapts `ManualRefreshController`.
- `ForegroundAutoRefreshController`: lifecycle, timer, status, and duplicate
  prevention.
- `AutoRefreshStatusCard`: Settings status display.

## Lifecycle Handling

The controller observes Flutter lifecycle changes:

- `resumed`: start a low-frequency foreground timer and perform one eligibility
  check.
- `paused`, `inactive`, `hidden`, or `detached`: stop the timer and do not
  refresh.
- dispose: stop the timer and unregister listeners/observer.

There is no WorkManager, boot receiver, foreground service, notification, cron,
launchd, or background task.

## Eligibility Rules

Auto refresh is eligible only when all of these are true:

- Auto refresh is enabled and interval is not `Off`.
- App lifecycle is `resumed`.
- A WebView has already been opened and attached.
- Current URL is HTTPS and allowlisted.
- The current page is not loading.
- No manual or auto refresh is already running.
- The selected interval has elapsed since the last auto refresh success.
- The failure cooldown is not active.

Skipped states are displayed as typed statuses such as `skipped: no WebView`,
`skipped: page loading`, `skipped: unsafe URL`, and
`skipped: interval not reached`.

## Save Policy

Auto refresh reuses `ManualRefreshPolicy`:

- High confidence can save automatically only when the user enables the existing
  high-confidence auto-save setting.
- Medium confidence creates a candidate and requires user confirmation.
- Low confidence and failed parses are not saved.
- Failed auto refresh enters cooldown to avoid tight retry loops.

## Safety Boundary

Stage 7 keeps the same content boundary:

- No cookie access.
- No token access.
- No `localStorage` or `sessionStorage` access.
- No `indexedDB` access.
- No HTML, script, CSS, request header, response, or network-hook extraction.
- No upload of page text, parser input, parser output, logs, or snapshots.
- No automatic login and no CAPTCHA/risk bypass.

The only page-content JavaScript remains:

```js
(() => document.body ? document.body.innerText : '')();
```

## Not Implemented

- No background refresh.
- No WorkManager.
- No notification flow.
- No boot receiver.
- No cookie/token/storage access.
- No HTML extraction.
- No network upload.

## Tests

Added or updated coverage for:

- Auto refresh interval and cooldown policy.
- Eligibility skip/eligible outcomes.
- Foreground controller lifecycle, timer stop, duplicate prevention, cooldown,
  success callback, and failed-result behavior.
- Settings persistence for auto refresh and high-confidence auto-save policy.
- Settings foreground-only UI.
- Debug Stage 7 status and safety rows.
- WebView login/usage buttons, no placeholder copy, collapsible safety notice,
  and WebView `Expanded` layout shell.

Final verification results:

- `flutter pub get`: passed.
- `flutter analyze`: passed with no issues.
- `flutter test`: passed.

`flutter devices` detected an Android 16 physical device and Chrome. No
interactive real-account WebView run was performed in this pass.

## Known Limits

Foreground auto refresh is in-memory for last auto attempt/success status; app
restart resets those display fields. The user must open the WebView and navigate
manually. The parser may still need updates if the official analytics page text
changes.

## Stage 8 Suggestion

Stage 8 can explore Android background refresh and notifications, but it needs a
separate security review because it changes lifecycle, scheduling, user
visibility, retry, and permission assumptions.
