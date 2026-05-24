# Stage 8 Report: Android Background Refresh And Notifications

## Stage 8 Goal

Stage 8 adds Android background task infrastructure, safety-gated background
refresh eligibility rules, notify-only fallback behavior, and local
notifications. It does not add a hidden WebView crawler, background login,
cookie/token/storage access, or any remote backend.

## Background Refresh Feasibility Audit

1. Current official API data source: none. The project has no stable official
   Codex usage API adapter.
2. Current browser extension or desktop agent data source: none. Existing
   desktop/browser-extension entries are placeholders only.
3. Safe Android background WebView refresh: not supported by this stage.
   Android background execution should not run a hidden Flutter WebView for
   logged-in ChatGPT/Codex pages.
4. Safe Android background visible-text extraction: not available. The current
   real quota path depends on foreground WebView `document.body.innerText`
   extraction after the user has opened the page. Running that in the
   background would risk session, cookie, token, storage, anti-abuse, and user
   intent boundaries.
5. Safe fallback: background checks read only app-owned local settings,
   app-owned latest quota snapshot summary, app-owned refresh failure metadata,
   notification metadata, and the last background run result. If data is stale,
   quota is low, or the last refresh failed, the app sends a local reminder to
   open the app and refresh in the foreground.
6. Background task responsibilities:
   - Evaluate `BackgroundRefreshEligibility`.
   - Detect stale saved snapshots.
   - Detect low saved 5-hour, weekly, or credits quota.
   - Detect the last foreground/manual refresh failure from shallow metadata.
   - Send safe local notifications with cooldowns.
   - Save last background run metadata.
   - Schedule or cancel Android WorkManager tasks.
   - Preserve a future adapter slot for official API, desktop agent, or browser
     extension sync data sources.
7. Background task non-responsibilities:
   - Do not open ChatGPT/Codex pages.
   - Do not create hidden WebViews.
   - Do not inject JavaScript.
   - Do not read `document.cookie`, WebView cookies, `localStorage`,
     `sessionStorage`, `indexedDB`, access tokens, refresh tokens,
     authorization headers, HTML, DOM, or page text.
   - Do not read parser raw input or raw extracted page text.
   - Do not upload logs, snapshots, parser input/output, or page text.

## Current Conclusion

Current real quota data comes from foreground WebView visible text extraction.
Because there is no official API or background-safe data source, Stage 8
implements notify-only background behavior by default. A
`backgroundSafeDataSourceOnly` mode exists for future official API, desktop
agent, or browser extension sync, but today it downgrades to notify-only and
records a warning instead of using WebView.

## BackgroundRefreshMode

- `disabled`: no WorkManager task and no background reminders.
- `notifyOnly`: WorkManager may run a local check. It reads app-owned snapshot,
  settings, refresh failure metadata, notification cooldown metadata, and last
  background run metadata. It sends local notifications when rules match.
- `backgroundSafeDataSourceOnly`: reserved for a future official API, desktop
  agent, or browser extension sync. With no current safe datasource, it falls
  back to notify-only and records a warning.

## Notify-Only Strategy

The current Stage 8 implementation checks only saved local state:

- Latest saved `QuotaSnapshot` summary with `accountLabel` replaced by
  `Local snapshot` and `rawDebugText` stripped.
- Background refresh settings.
- Shallow manual-refresh status/timestamps for failure reminders.
- Notification metadata keyed by notification type.
- Last background run result.

No parser raw input, extracted page text, HTML, cookies, tokens, WebView
storage, or browser profile data are read by the background check.

## Future Background-Safe Datasource Slot

The repository exposes `hasBackgroundSafeDataSource()`. It currently returns
false through a no-op adapter. A future official API, trusted desktop agent, or
browser extension sync can implement this boundary without making
`background_refresh` depend on WebView.

## WorkManager Configuration

Stage 8 uses `workmanager` for Android periodic task registration. The task name
is `quota_background_refresh_check`, and the unique periodic work name is
`quota_background_refresh_periodic`.

The task input data is limited to a non-sensitive purpose string:
`local_snapshot_notification_check`. No quota text, URL query values, cookies,
tokens, parser input, or page content are passed to WorkManager.

Android does not guarantee exact periodic timing. WorkManager may batch or delay
tasks based on battery, app standby, Doze, OEM policy, and system load.

## Notification Configuration

Stage 8 uses `flutter_local_notifications` for local notifications. Supported
notification types are:

- `staleData`
- `lowFiveHourQuota`
- `lowWeeklyQuota`
- `lowCredits`
- `refreshFailed`
- `backgroundRefreshUnavailable`

Notification bodies are fixed safe strings. They do not include account email,
full URLs, raw page text, parser input, token-like values, stack traces, or
web-derived sensitive content. Each notification type has its own cooldown,
defaulting to one hour.

Notification taps use normal app launch behavior and safe payload labels such
as `quota` or `web_login`. A tap never triggers background WebView refresh.

The Android app module enables core library desugaring and adds
`com.android.tools:desugar_jdk_libs:2.1.4`, which is required by
`flutter_local_notifications` 21.x. This is a build-time compatibility setting
and does not grant sensitive runtime access.

## Android Permissions

New explicit app permission:

- `POST_NOTIFICATIONS`: required on Android 13+ to show local notifications.
- `RECEIVE_BOOT_COMPLETED`: used by Android WorkManager scheduling so periodic
  local checks can be rescheduled by the system after a device reboot.
- `WAKE_LOCK`: used by Android WorkManager/AndroidX Work runtime to complete
  short scheduled local work. The app does not use it to keep a foreground
  service alive.

Plugin merge handling:

- `flutter_local_notifications` declares `VIBRATE`; this app removes it with
  `tools:node="remove"` because Stage 8 does not need vibration.
- `ACCESS_NETWORK_STATE` is removed with `tools:node="remove"` because Stage 8
  local background checks do not use network constraints.

Not added:

- `FOREGROUND_SERVICE`
- `SCHEDULE_EXACT_ALARM`
- Camera, microphone, location, contacts, external storage, install packages,
  or system overlay permissions.

The added permissions do not grant access to WebView, cookies, tokens,
localStorage, sessionStorage, HTML, browser data, or page text, and they are not
used for webpage reading.

## Xiaomi And HyperOS Limits

Xiaomi/HyperOS and other OEM Android builds may delay or block background work
and notification delivery. Users may need to allow notifications, autostart, and
background running in system settings. The app does not use dangerous
permissions, foreground services, exact alarms, or keepalive tricks to force
execution. Background checks are best-effort and not guaranteed to run on time.

## Safety Boundary

Confirmed Stage 8 boundaries:

- No background WebView scraping.
- No hidden WebView.
- No background login.
- No cookie access.
- No token access.
- No `localStorage`, `sessionStorage`, or `indexedDB` access.
- No HTML extraction.
- No page text extraction in background.
- No parser raw text access in background.
- No network upload.
- No remote backend.
- No analytics, ads, crash reporting, or remote configuration SDK.

## Settings And Debug UI

Settings now includes an Android Background Refresh section with:

- Mode selector.
- Check interval selector.
- Local notification switch.
- Stale data threshold.
- Low 5-hour quota threshold.
- Low weekly quota threshold.
- Refresh failure reminder switch.
- Notification permission status and request button.
- Safety copy explaining the notify-only fallback.

Debug now includes:

- Last background run status.
- Last background run timestamps.
- Notification count.
- Background-safe datasource availability.
- Safety lines for no hidden WebView extraction and no background
  cookie/token/storage/page text/HTML access.
- `Run background check now`, which executes the same safe local check logic.
- Notification cooldown state by type.

## Tests

Added unit/widget coverage for:

- `BackgroundRefreshSettings` defaults, serialization, interval storage keys,
  and JSON round trip.
- `EvaluateBackgroundRefreshEligibility` disabled, notify-only, no safe
  datasource fallback, cooldown, denied notification permission, and missing
  snapshot behavior.
- `RunBackgroundRefreshCheck` stale snapshot, low 5-hour quota, low weekly
  quota, refresh failure, no-action, denied permission, and no-safe-datasource
  notify-only behavior.
- Safety behavior that strips `rawDebugText` and avoids nested manual refresh
  extracted/parser text in background metadata reads.
- `NotificationSettings`, notification thresholds, notification rule
  evaluation, cooldown, safe content, and fake notification repository send
  behavior.
- Settings and Debug widget visibility for Stage 8 controls and safety status.

## Verification Results

Baseline before Stage 8 changes:

- `flutter pub get`: passed after allowing Flutter SDK cache access.
- `flutter analyze`: passed.
- `flutter test`: passed.

After Stage 8 changes, `flutter pub add workmanager flutter_local_notifications`
completed successfully and updated `pubspec.yaml`/`pubspec.lock`.

Final `dart format`, `flutter analyze`, and `flutter test` could not be rerun in
this sandbox after the escalation reviewer rejected further SDK-cache access
requests with an account usage-limit message. The commands were not worked
around. They should be rerun locally once SDK-cache access is available:

```sh
flutter pub get
flutter analyze
flutter test
```

## Manual Verification Steps

1. Open the app.
2. Go to Settings -> Android Background Refresh.
3. Select `Notify only`.
4. Select a background check interval.
5. Enable local notifications.
6. Request and grant notification permission.
7. Set a stale data threshold or low quota threshold.
8. Wait for local data to become stale, or use Debug -> Run background check
   now.
9. Confirm a notification appears.
10. Tap the notification and confirm the app opens.
11. Confirm no background WebView opens.
12. Confirm no cookies, tokens, storage, HTML, or page text are accessed.
13. Confirm Debug shows the last background run and notification cooldown
    state.

## Known Limits

- No official API or background-safe datasource exists yet.
- Notify-only mode cannot produce a new quota snapshot.
- WorkManager timing is best-effort.
- OEM Android builds may throttle background work and notifications.
- Notification taps currently rely on normal app launch/safe payload labels;
  deeper in-app routing can be expanded later.

## Next Stage

Stage 9 should add the Android home screen widget data export layer. It should
reuse the same safe local snapshot summary boundary and must not add widget-side
WebView, cookie, token, storage, HTML, or page text access.
