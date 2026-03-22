# Stream Counter Companion

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Platform](https://img.shields.io/badge/Platform-Windows-0078D6?logo=windows&logoColor=white)

A small Windows app that turns Stream Deck counters (values written to `.txt` files) into a **local browser overlay** you can capture in streaming software such as TikTok LIVE Studio.

---

## Table of contents

- [Features](#features)
- [Why use this](#why-use-this)
- [Quick start](#quick-start)
- [Requirements](#requirements)
- [Project layout](#project-layout)
- [Usage](#usage)
- [Overlay layouts](#overlay-layouts)
- [Chroma key background](#chroma-key-background)
- [Counter file format](#counter-file-format)
- [Troubleshooting](#troubleshooting)
- [Privacy](#privacy)
- [License](#license)

---

## Features

- Add and remove `.txt` counter files from a simple Windows GUI
- Custom label per counter
- Layouts: **Vertical**, **Horizontal**, or **Versus**
- Refresh interval: 250 ms, 500 ms, 1000 ms, or 2000 ms
- Opens the overlay in a browser window
- Chroma-key friendly green page background (`#00FF00`); counter cards stay grey
- **Local-only** workflow — no blur effects, no cloud upload

## Why use this

Many streaming apps (especially outside the OBS ecosystem) cannot read text files as overlays. This project bridges that gap:

1. A Stream Deck button or plugin (e.g. **Multi Stream Counter**) updates a `.txt` file
2. This app reads that file on disk
3. The value appears in a browser overlay
4. Your streaming software captures that window

Useful when your software does not support text-file overlays natively.

## Quick start

1. Keep these files in the same folder:

   | File | Role |
   |------|------|
   | `LiveCountersApp.ps1` | Main GUI |
   | `server_runtime.ps1` | Local server + overlay |
   | `start_live_counters.bat` | Launcher |

2. Run `start_live_counters.bat`.

3. In the app: **Add** → pick one or more `.txt` files → set labels → choose layout and refresh interval → **Start**.

4. Capture the opened browser window in your streaming software.

## Requirements

- Windows
- PowerShell
- Microsoft Edge or Google Chrome
- One or more `.txt` files containing counter values

## Project layout

```
streamdeck-counter-overlay/
├── LiveCountersApp.ps1      # Main GUI application
├── server_runtime.ps1       # Local server; reads .txt files and serves the overlay
├── start_live_counters.bat  # Launcher
└── counters.json            # Saved config (created/updated by the app)
```

## Usage

| Step | What to do |
|------|------------|
| Add counters | **Add** → choose a `.txt` file → enter the label shown in the overlay |
| Remove | Select a counter in the list → **Remove** |
| Layout | Choose **Vertical**, **Horizontal**, or **Versus** |
| Refresh | Pick 250 ms, 500 ms, 1000 ms, or 2000 ms |
| Start | **Start** saves config, starts the local server, opens the overlay in the browser |
| Stop | **Stop** closes the overlay browser window and the server process |

Closing the app window should also stop everything the app started.

## Overlay layouts

### Vertical

Counters stacked:

```text
Streamer   3
Chat       1
Wins       5
Loses      2
```

### Horizontal

Counters in a row:

```text
Streamer 3   Chat 1   Wins 5   Loses 2
```

### Versus

First two counters in a head-to-head layout (battles, polls, scores):

```text
Streamer 3   vs   1 Chat
```

## Chroma key background

The overlay page uses solid green `#00FF00` so you can key it out in TikTok LIVE Studio and similar tools. Only the **page** background is green; the counter cards remain grey.

## Counter file format

Each file should contain a simple value, for example:

```text
3
```

or

```text
12
```

The app reads the file as text and displays it live.

## Troubleshooting

### PowerShell: scripts are disabled

If you see an error like “running scripts is disabled on this system”, run:

```powershell
powershell -STA -NoProfile -ExecutionPolicy RemoteSigned -File ".\LiveCountersApp.ps1"
```

Or allow scripts for your user:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

### Overlay does not update

- Confirm the `.txt` path is correct and the file changes when the Stream Deck updates it
- Ensure the file selected in the app matches the one being written
- Ensure `server_runtime.ps1` sits in the same folder as the app

### Streaming software does not see the overlay window

Some apps detect browser windows inconsistently. Try capturing a normal browser window, or use display capture and crop.

### Stop does not close everything

If browser windows stay open, detection of that browser instance can vary. The app is intended to close the overlay browser instance and the server process it started.

## Privacy

- Runs **locally**; nothing is uploaded by design
- Suited for small, text-based counter files

## License

This project is licensed under the [MIT License](LICENSE).

Copyright (c) 2026 Andreea Baboi
