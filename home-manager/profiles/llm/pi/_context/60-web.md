# Web and browser

- Known static URL, PDF, video or GitHub repo → `fetch_content` (one request).
  Live DOM, login, JS rendering, clicks, screenshots → `agent_browser`; never for
  a static page `fetch_content` can already read.
- A `responseId` already exists → `get_search_content`, never a re-fetch.
- Finding URLs or open-web facts → `web_search` (2–4 varied queries in one call).
  Verifying one claim with citations → `source_check`.
