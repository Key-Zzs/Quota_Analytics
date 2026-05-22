# Quota Data Sources

Stage 1 only ships `MockQuotaDataSource`.

Future sources are intentionally placeholders until their safety boundaries are
designed and reviewed:

- `WebViewQuotaDataSource`: possible in-app login container, not implemented.
- `OfficialApiQuotaDataSource`: possible official endpoint integration, not implemented.
- `BrowserExtensionQuotaDataSource`: possible browser-side companion, not implemented.
- `DesktopAgentQuotaDataSource`: possible desktop helper, not implemented.

No Stage 1 code reads browser cookies, tokens, passwords, OpenAI pages, ChatGPT
pages, Codex pages, or real usage.
