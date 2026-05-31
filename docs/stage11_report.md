# Stage 11 Report: Android Widget Refresh Integration

## Goal

Stage 11 connects the Android home screen widget to app-owned quota summary
changes and safe foreground entry points. Widget refresh updates the widget view
or opens the app; it does not refresh webpages in the background.

## Widget Update Trigger Matrix

| Trigger | Export summary | Android update signal | WebView/parser work |
| --- | --- | --- | --- |
| App startup with local latest snapshot | Yes | Yes, `appStartup` | No |
| Quota page Refresh usage page save | Yes | Yes, `snapshotSaved` | Foreground visible flow only |
| Manual refresh save | Yes | Yes, `snapshotSaved` | Foreground visible flow only |
| Foreground auto refresh save | Yes | Yes, `snapshotSaved` | Foreground resumed only |
| Background notify-only check | Yes, metadata/stale refresh | Best effort, `backgroundNotifyOnlyCheck` | No |
| Debug export and update | Yes | Yes, `debugExport` | No |
| Debug update Android widgets now | No | Yes, `debugUpdate` | No |
| Clear widget summary | Clear | Yes, `clearWidgetSummary` | No |
| Clear local data | Clear | Yes, `clearData` | No |
| AppWidgetProvider.onUpdate/onEnabled | No | Full RemoteViews update | No |
| Safe custom provider update action | No | Full RemoteViews update | No |

## Flutter To Android Update Channel

The MethodChannel is `quota_analytics/widget`.

- `saveQuotaWidgetSummary`: stores normalized display-safe summary JSON in
  Android-native SharedPreferences.
- `clearQuotaWidgetSummary`: removes the native summary.
- `updateQuotaWidgets`: sends only `reason` and `timestamp`.
- `getQuotaWidgetStatus`: returns shell availability and installed widget count.
- `consumeWidgetLaunchAction`: lets Flutter consume pending safe widget click
  extras.

The channel does not transfer raw page text, parser input, cookies, tokens,
browser storage, account email, or full URLs.

## AppWidgetManager Strategy

`QuotaWidgetUpdater.updateAll` reads installed ids from `AppWidgetManager`,
builds full `RemoteViews` for each widget, and calls `updateAppWidget`. No
partial update is used. No installed widgets is a safe no-op.

`QuotaWidgetProvider` now handles `onUpdate`, `onEnabled`,
`onAppWidgetOptionsChanged`, and a safe custom update action. It never opens
WebView, parses pages, logs in, or reads sensitive storage.

## Click Behavior

Main widget area:

- Opens `MainActivity`.
- Extras: `source=widget`, `target=quota`, `action=openQuota`.
- Flutter routes to the Quota tab.

Refresh area:

- Opens `MainActivity`.
- Extras: `source=widget`, `target=refreshUsagePage`,
  `action=openRefreshFlow`.
- Flutter routes to the Quota tab and shows: "Opened from widget. Tap Refresh
  usage page to update."
- No background webpage refresh is triggered.

## Display States

Fresh:

- Shows remaining ratios, reset time, updated time, source, confidence, and OK
  or LOW badge.

Stale:

- Keeps safe quota values visible when available.
- Shows `Stale` badge and `Open app to refresh` copy.
- Kotlin re-evaluates age with a conservative 30-minute threshold when
  RemoteViews are rebuilt.

No data:

- Shows `No quota data` and `Open app to refresh`.

Error:

- Shows a safe error label only.
- No stack traces or sensitive details are rendered.

## Native Storage Compatibility

Flutter writes the Stage 9 summary to app local storage and mirrors the same
display-safe JSON into Android SharedPreferences:

- preferences: `quota_widget_summary`
- key: `latest_summary_json`

Kotlin reads this native mirror first. It also has a display-safe compatibility
fallback for the Flutter SharedPreferences key `flutter.widget.latest_summary_json`
so background notify-only metadata updates remain readable if the native mirror
is not present.

## Debug And Settings Updates

Debug Widget Export now shows:

- Android shell availability and installed widget count.
- Last update signal timestamp, reason, status, and safe error.
- Last widget click source and target.
- Update, export-and-update, and clear-and-update controls.
- Safety copy that widget refresh updates the view only and does not refresh web
  pages in background.

Settings includes an Android Widget note explaining update and refresh-entry
behavior.

## Validation

Baseline before Stage 11 changes:

- `flutter pub get`: passed.
- `flutter analyze`: passed.
- `flutter test`: passed.
- `flutter build apk --debug`: passed.

Post-change validation:

- `git diff --check`: passed.
- `flutter analyze`: blocked in this environment after the Flutter SDK cache
  write was denied by sandboxing and the required escalation was rejected by the
  approval layer due to current usage limits.
- `flutter test`: not rerun after the same Flutter SDK cache escalation block.
- `flutter build apk --debug`: not rerun after the same Flutter SDK cache
  escalation block.

## Manual Verification Steps

1. Install the debug APK on an Android device or emulator.
2. Add the Quota Analytics widget to the home screen.
3. With no summary, confirm `No quota data` and `Open app to refresh`.
4. Open the app and run Refresh usage page from the visible foreground UI.
5. Return home and confirm the widget updates without being re-added.
6. Tap the widget main area and confirm the app opens the Quota page.
7. Tap the widget refresh area and confirm the app opens the refresh entry with
   the visible prompt.
8. Confirm no hidden WebView, login, parser, or background webpage refresh runs.
9. Clear widget summary and confirm the widget returns to no data.
10. Run a notify-only background check or stale local check and confirm widget
    stale/status metadata updates when rebuilt.
11. Restart the app and confirm the widget can still read the latest summary.

## Known Limitations

- Widget stale threshold is conservative and currently fixed at 30 minutes in
  native display code.
- Background WorkManager can update display-safe Flutter summary metadata; full
  immediate native widget redraw is best-effort and depends on the available
  foreground/native update path.
- No iOS WidgetKit implementation exists in this stage.

## Next Stage

Stage 12 should assess iOS adaptation feasibility, including app group storage,
WidgetKit timeline policies, foreground-only refresh boundaries, and whether
the same display-safe summary contract can be reused.
