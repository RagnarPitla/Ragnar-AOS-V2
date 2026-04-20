# Dashboard Theme Engine

> Runtime-switchable themes for the RAOS Mission Control dashboard.

## Overview

The dashboard supports multiple visual themes loaded from JSON files. Themes are stored in `dashboard/themes/`, served via API, and applied client-side through CSS custom properties. Theme selection persists in `localStorage`.

## Theme File Format

```json
{
  "name": "Dark",
  "colors": {
    "primary": "#bb86fc",
    "secondary": "#03dac6",
    "bg": "#121212",
    "text": "#e1e1e1",
    "accent": "#bb86fc",
    "success": "#03dac6",
    "warning": "#ffb74d",
    "error": "#cf6679"
  },
  "fonts": {
    "heading": "'JetBrains Mono', monospace",
    "body": "-apple-system, BlinkMacSystemFont, sans-serif"
  },
  "logo_text": "RAOS V3 — Dark Mode"
}
```

## API Endpoints

| Endpoint              | Method | Description                    |
|-----------------------|--------|--------------------------------|
| `/api/themes`         | GET    | List all available themes      |
| `/api/theme`          | GET    | Get default (first) theme      |
| `/api/theme?name=Dark`| GET    | Get theme by name              |

## Adding a Custom Theme

1. Create `dashboard/themes/mytheme.json` with the format above
2. Restart the dashboard server (or it picks up on next `/api/themes` call)
3. Select from the dropdown in the dashboard header

## Backward Compatibility

If `dashboard/themes/` is empty or missing, the server returns a hardcoded default theme matching the original V2 dark color scheme. No theme files required for basic operation.

## File Structure

```
dashboard/
  server.py          # serves /api/themes and /api/theme endpoints
  index.html          # loads theme on init, has theme switcher dropdown
  themes/
    default.json      # default cyan/dark theme
    dark.json         # material dark purple theme
```
