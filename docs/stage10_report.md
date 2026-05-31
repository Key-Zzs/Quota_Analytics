# Stage 10 Report: Android Home Screen Widget - Native Widget Shell

## Goal

Stage 10 adds the Android native home screen widget shell for the safe summary
export created in Stage 9. The widget displays exported quota summary data only;
it does not login, open WebView, read pages, run parser code, or access browser
storage.

## Android Widget Components

- `android/app/src/main/res/xml/quota_widget_info.xml`: AppWidgetProviderInfo
  with `@layout/quota_widget_small` as the initial layout, resize support,
  home-screen category, Android 12 target cells, and `updatePeriodMillis=0`.
- `android/app/src/main/res/layout/quota_widget_small.xml`: compact widget
  layout for title, 5-hour ratio, weekly ratio, last updated, and stale/status.
- `android/app/src/main/res/layout/quota_widget_medium.xml`: larger widget
  layout for 5-hour and weekly ratio/reset sections, optional credits,
  source/confidence, last updated, and stale/status.
- `android/app/src/main/kotlin/com/keyzzs/quota_analytics/widget/QuotaWidgetProvider.kt`:
  `AppWidgetProvider` entry point.
- `QuotaWidgetUpdater.kt`: chooses the small or medium layout, binds
  `RemoteViews`, and installs the tap-to-open pending intent.
- `QuotaWidgetSummaryReader.kt`: reads the latest safe JSON summary from
  Android SharedPreferences.
- `QuotaWidgetSummary.kt`: native model/parser with missing-field fallbacks and
  safe JSON normalization.
- `AndroidManifest.xml`: registers `.widget.QuotaWidgetProvider` as a receiver
  with `APPWIDGET_UPDATE` and `@xml/quota_widget_info`.

## Layout Behavior

Small widgets display:

- `Quota Analytics`
- `5h NN%`
- `Week NN%`
- `Updated HH:mm`
- `Stale`, `Low`, or `OK` when applicable

Medium widgets display:

- `Quota Analytics`
- 5-hour remaining ratio and reset time
- Weekly remaining ratio and reset time
- Optional credits remaining
- `High · Web` style source/confidence text
- Last updated and stale/status label

No widget layout displays used/limit counts, raw page text, account email,
tokens, cookies, full URLs, or parser input.

## Summary Read Strategy

Stage 9 still writes the Flutter app's local summary through
`LocalWidgetSummaryDataSource`. Stage 10 mirrors the same display-safe JSON into
Android-native SharedPreferences so Kotlin can read it without relying on
Flutter plugin internals:

- preferences name: `quota_widget_summary`
- key: `latest_summary_json`

The native writer parses and reserializes the incoming JSON through
`QuotaWidgetSummary`, which preserves only the expected display-safe fields.
If no JSON exists, the widget shows `No quota data` and `Open app to refresh`.
If JSON is corrupted, the reader returns an error state and the widget does not
crash.

## Flutter To Android Update Signal

`AndroidWidgetUpdateChannel` owns the platform bridge:

- `saveQuotaWidgetSummary`: stores display-safe summary JSON in native
  SharedPreferences.
- `clearQuotaWidgetSummary`: removes native summary JSON.
- `updateQuotaWidgets`: sends a signal only; it carries no summary or sensitive
  payload.
- `getQuotaWidgetStatus`: reports shell availability and installed widget
  count when Android can answer.

`WidgetSummaryRepositoryImpl` now performs best-effort native summary sync and
then sends an update signal after successful export. Clear summary also clears
native summary storage and updates widgets so installed widgets can return to
the no-data state. Platform channel failures do not fail local snapshot saving
or the Stage 9 summary export.

## Widget Tap

Tapping any widget surface opens `MainActivity` with extras:

- `open_route = "quota"`
- `source = "widget"`

Stage 10 does not add complex Flutter deep-link routing. The tap opens the app
only; it does not refresh a page, open WebView, execute JavaScript, or run the
parser.

## Debug Page

The Debug widget export card now shows:

- Android widget shell availability.
- Installed widget count when Android can report it.
- Last widget update signal timestamp.
- Last widget update status.
- Last widget update error.
- Latest safe summary preview.
- `Update Android widgets now`.
- `Export and update widget now`.
- `Clear widget summary`.
- Safety text that the widget reads display-safe summary only and does not
  login, parse pages, or access WebView.

## Security Boundary

The widget intentionally does not do any of the following:

- Open WebView.
- Login or auto-login.
- Execute JavaScript.
- Read `document.body.innerText`.
- Read HTML, DOM, scripts, CSS, request headers, or network responses.
- Run quota parser code.
- Read raw page text or parser input.
- Read cookies, tokens, `localStorage`, or `sessionStorage`.
- Access the network.
- Upload data.
- Add a background service, foreground service, exact alarm, or dangerous
  permission.

## Test And Build Results

Required commands run during Stage 10:

- `flutter pub get`: passed.
- `flutter analyze`: passed.
- `flutter test`: passed.
- `flutter build apk --debug`: passed, producing
  `build/app/outputs/flutter-apk/app-debug.apk`.

The first debug APK build encountered stale generated Android plugin artifacts
under `build/` with duplicate `* 2.class` files. `flutter clean` removed those
generated artifacts, `flutter pub get` regenerated tool metadata, and the debug
APK build then passed.

Android unit tests were not added because this Flutter app does not currently
have an Android/JUnit unit test harness configured. The native shell is covered
by Kotlin/XML compilation in the debug APK build, while parsing and update
signal behavior are covered by Flutter unit tests around the platform channel
and repository/controller pipeline.

Manual device verification was not run in this session because `flutter
devices` listed only Chrome as connected. `flutter emulators` listed an Android
AVD (`flutter_env_check_api_36_1`), but it was not launched during this build
verification pass.

## Manual Verification

Use an emulator or physical Android device:

1. Install the app.
2. Long-press the home screen and open Widgets.
3. Find `Quota Analytics`.
4. Add the widget to the home screen.
5. With no summary, confirm the widget shows `No quota data` and
   `Open app to refresh`.
6. Open the app.
7. Run `Refresh usage page` or Debug -> `Export and update widget now`.
8. Return to the home screen.
9. Confirm the widget shows 5-hour remaining ratio, weekly remaining ratio,
   reset time where available, and last updated time.
10. Tap the widget and confirm it opens the main app.
11. Use Debug -> `Clear widget summary`.
12. Tap `Update Android widgets now`.
13. Confirm the widget returns to no-data/error-safe display.
14. Confirm the widget never opens WebView, logs in, parses pages, or refreshes
   web content by itself.

## Known Limits

- Stage 10 widgets are display-only.
- The widget does not provide a refresh button.
- The widget does not implement full Flutter route handling for
  `open_route=quota`; the tap opens the app.
- Android launcher widget sizing varies by launcher, so small/medium selection
  uses the reported min-width option.
- Widget refresh depends on app export/update signals and normal AppWidget
  broadcasts; `updatePeriodMillis` is disabled.

## Next Stage

Stage 11 should add Android widget refresh integration that stays within the
same safety boundary: widget interactions may open the app or request an
app-visible safe flow, but must not perform hidden WebView, login, extraction,
parser, cookie/token/storage reads, or network scraping.
