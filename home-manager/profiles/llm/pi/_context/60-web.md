# Web and browser

- Known static URL, PDF, video or GitHub repo → `extensions.fetch_content` (one
  request). Live DOM, login, JS rendering, clicks, screenshots →
  `extensions.agent_browser`; never for a static page
  `extensions.fetch_content` can already read.
- A `responseId` already exists → `extensions.get_search_content`, never a
  re-fetch.
- Finding URLs or open-web facts → `extensions.web_search` (2–4 varied queries in
  one call). Verifying one claim with citations → `extensions.source_check`.
