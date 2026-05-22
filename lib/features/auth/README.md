# Auth Feature

Stage 3 implements a WebView login container only.

Users can manually open the official website inside this app's WebView and sign
in there. The app does not ask for, store, read, print, upload, or parse
passwords, cookies, tokens, page HTML, page body text, localStorage, or
sessionStorage.

The auth feature owns:

- `WebAuthConfig` for central URL configuration.
- `WebAuthStatus` for conservative navigation-derived status.
- `WebAuthRepository` for WebView navigation and clear-data actions.
- `WebViewAuthController` for testable UI state.
- `WebViewLoginPage` for the Material 3 login container UI.

This feature must remain separate from quota extraction and parser code.
