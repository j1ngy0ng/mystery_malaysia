# Mystery Malaysia — local Figma generator

This package creates a pixel-accurate, clickable Figma prototype from screenshots rendered directly by the current Flutter UI. It runs locally in Figma and makes no network or MCP calls.

## Run it

1. Open the Figma desktop app and create a blank **Design** file.
2. Open **Figma menu → Plugins → Development → Import plugin from manifest…**
3. Select this folder's `manifest.json`.
4. Run **Plugins → Development → Mystery Malaysia UI Generator**.
5. Wait for the “18 exact Flutter screens with working prototype links created” message.
6. Select the **Travel home** frame and click **Present** to test the flow.

The generator adds a new page rather than changing an existing page. Run it again whenever you want a fresh copy.

Optional local check: run `node verify.js` in this folder.

## What it creates

- Welcome, sign-in and registration
- Travel-focused home
- Mission constraints, generated picks, mystery preview and mission selection
- Mission history, active mission, clue and destination reveal
- Digital passport and AI travel diary
- Crew overview and shared mission lobby
- Notifications and profile

Each visual is the real Flutter render, locked to preserve exact appearance. Named transparent hotspot layers are placed above it and connected using native Figma prototype reactions. The hotspots can be resized or relinked in Figma's Prototype panel.

No remote Figma plugin, API token or paid quota is used.
