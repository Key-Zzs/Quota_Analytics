# Stage 4 Report: Usage Page Text Extraction

## Goal

Stage 4 implements manual, safe, local page text extraction from the current
WebView page. This is only for future Stage 5 parser development and debugging.
It does not parse quota values and does not refresh real quota data.

## Implemented

- Added `Extract Page Text` on the Web Login page.
- Added an extraction status card with last extraction status, sanitized URL,
  length summary, redaction counts, redacted preview, copy-redacted-preview, and
  clear-preview controls.
- Added Debug page Stage 4 diagnostics.
- Added local storage for the most recent redacted preview only.
- Added clear-local-data coverage for extracted text cache.
- Added unit and widget tests for security utilities, model serialization,
  controller states, WebView page UI, extraction card UI, and Debug page status.

## Allowed Extraction

The only allowed page content extraction is:

```js
(() => document.body ? document.body.innerText : '')();
```

Extraction runs only after the user taps the button. The app does not extract
on page load, app startup, navigation events, timers, loops, or background jobs.

## Explicitly Forbidden

Stage 4 does not read or extract:

- Cookies or `document.cookie`
- Access tokens, refresh tokens, session tokens, authorization headers, or
  credential values
- `localStorage`
- `sessionStorage`
- `indexedDB`
- HTML, scripts, CSS, DOM structure, or `document.body.innerHTML`
- Network requests, request headers, or network responses
- Browser/system cookies, browser profiles, Keychain, Credential Manager, or
  password manager data

No extracted text is uploaded, and no backend, analytics SDK, advertising SDK,
or crash reporting SDK was added.

## URL Safety

Before extraction, the current WebView URL is checked:

- Empty or invalid URL -> blocked as `failed`
- Non-HTTPS URL -> blocked as `blockedNonHttps`
- Unknown host -> blocked as `blockedUnknownHost`
- Allowlisted HTTPS host -> `allowed`

The conservative allowlist is:

- `chatgpt.com`
- `chat.openai.com`
- `openai.com`
- `platform.openai.com`

Displayed and persisted URLs are sanitized by removing query and fragment
values.

## Redaction Strategy

Extracted text is redacted in memory before display or storage. The redactor
covers:

- Email addresses -> `[REDACTED_EMAIL]`
- Bearer tokens -> `Bearer [REDACTED_TOKEN]`
- `sk-`-prefixed suspected API keys -> `[REDACTED_API_KEY]`
- Long token-like strings -> `[REDACTED_TOKEN]`
- Values near `session`, `access`, `refresh`, `token`, `secret`, and `password`
  labels -> `[REDACTED_SECRET]`

The result includes `originalLength`, `redactedLength`, redaction counts, and
`truncated`.

## Local Storage

Stage 4 saves only the latest redacted preview under the app-owned key:

- `extraction.last_page_text.v1`

The app does not save raw unredacted page text. The debug/persisted preview is
capped at 2000 characters. The code keeps a 10000-character constant available
as the upper bound for any future reviewed redacted full-text storage, but this
stage does not persist full text.

Clear local data removes the extracted text cache along with mock quota and
settings data.

## UI Entry

Open `Web Login`, navigate manually, then tap `Extract Page Text`.

The Web Login page states:

- Stage 4 extracts only visible page text after you tap the button.
- No cookies, tokens, localStorage, sessionStorage, or HTML are accessed.
- Quota parsing is not implemented in this stage.
- Extracted text is redacted and kept local for debugging.
- This project is unofficial and not affiliated with OpenAI, ChatGPT, or Codex.

## Test Results

Baseline before implementation:

- `flutter pub get` passed.
- `flutter analyze` passed.
- `flutter test` passed.

After implementation:

- `flutter pub get` passed.
- `flutter analyze` passed.
- `flutter test` passed.

Flutter commands required access to the Flutter SDK cache outside the workspace.
No emulator verification was performed in this stage.

## Known Risks

- Redaction is defensive but cannot guarantee every possible secret format is
  removed.
- Redacted previews can still include account or usage context.
- Host allowlisting reduces accidental extraction but does not imply official
  support.
- Stage 4 does not validate real account usage page layouts.

## Next Stage

Stage 5 should implement a quota parser with confidence levels using the
structured `ExtractedPageText` output. Parser work should remain separate from
WebView credentials, cookies, storage, HTML, network data, and background jobs.
