# Auth Feature

This feature implements the WebView login container.

Users can manually open the official website inside this app's WebView and sign
in there. The auth feature does not ask for, store, read, print, upload, or
parse passwords, cookies, tokens, page HTML, localStorage, or sessionStorage.
Stage 4 page text extraction lives in `features/extraction` and is limited to
user-triggered `document.body.innerText`.

The auth feature owns:

- `WebAuthConfig` for central URL configuration.
- `WebAuthStatus` for conservative navigation-derived status.
- `WebAuthRepository` for WebView navigation and clear-data actions.
- `WebViewAuthController` for testable UI state.
- `WebViewLoginPage` for the Material 3 login container UI.

This feature must remain separate from quota extraction and parser code.
