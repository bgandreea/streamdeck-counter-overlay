# Stream Counter Companion

A lightweight local overlay manager for Stream Deck counters that write their values to .txt files.

This tool turns one or more text-based counters into a local browser overlay that can be captured in streaming software like TikTok LIVE Studio.

## FEATURES

- Add and remove .txt counter files from a simple Windows GUI
- Assign a custom label to each counter
- Choose between Vertical, Horizontal, or Versus layouts
- Pick a refresh interval:
  - 250 ms
  - 500 ms
  - 1000 ms
  - 2000 ms
- Opens the overlay in a browser window
- Uses a chroma-key friendly green background (```#00FF00```)
- Keeps the actual counter cards grey
- Local-only workflow
- No blur effects

## USE CASE

This project is meant to work with Stream Deck counters that write their values to .txt files, such as plugins like Multi Stream Counter.

**Example workflow:**

1. A Stream Deck button updates a .txt file
2. This app reads that file locally
3. The value appears in a browser overlay
4. Your streaming software captures that browser window

This is especially useful in streaming software that does not support reading text files directly.

## QUICK START

1. Put these files in the same folder:
   - LiveCountersApp.ps1
   - server_runtime.ps1
   - start_live_counters.bat

2. Run:
   start_live_counters.bat

3. In the app:
   - click Add
   - select one or more .txt files
   - enter the label for each counter
   - choose a layout style
   - choose a refresh interval
   - click Start

4. Capture the opened browser window in your streaming software.

## OVERLAY STYLES

### Vertical
Displays counters stacked on top of each other.

```text
Streamer   3
Chat       1
Wins       5
Loses      2
```

### Horizontal
Displays counters side by side.

```text
Streamer 3   Chat 1   Wins 5   Loses 2
```

### Versus
Displays the first two counters in a versus layout.

```text
Streamer 3   vs   1 Chat
```

This is useful for head-to-head counters, battles, polls, or score comparisons.

## CHROMA KEY BACKGROUND

The overlay page uses a solid green background:
```
#00FF00
```

This makes it easier to chroma key in software like TikTok LIVE Studio.
Only the outer page background is green.
The actual counter cards remain grey.

## REQUIREMENTS

- Windows
- PowerShell
- Microsoft Edge or Google Chrome
- One or more .txt files containing counter values

## PROJECT FILES

```text
Multi Stream Counter Companion
├─ LiveCountersApp.ps1
├─ server_runtime.ps1
├─ start_live_counters.bat
└─ counters.json


LiveCountersApp.ps1 - The main GUI app.

server_runtime.ps1 - The local server that reads .txt files and serves the overlay page.

start_live_counters.bat - A simple launcher for the app.

counters.json - The saved config file created and updated automatically by the app.

```

## HOW TO USE

1. Add counters - Click Add, choose a .txt file, and enter the label you want to show in the overlay.

2. Remove counters - Select a counter in the list and click Remove.

3. Choose a layout - Pick one of:

   - Vertical
   - Horizontal
   - Versus

4. Choose refresh interval - Available options:
   - 250 ms
   - 500 ms
   - 1000 ms
   - 2000 ms

5. Start the overlay - Click Start to:

   - save the current config
   - start the local server
   - open the overlay in a browser window

6. Stop the overlay - Click Stop to close:
   - the overlay browser window
   - the local server process

Closing the app window should also stop everything it launched.

## COUNTER FILE FORMAT

Each counter file should contain a simple value, for example:
```text
3
```

or

```text
12
```

The app reads the file contents as text and displays them live.

## TROUBLESHOOTING

### PowerShell says script execution is disabled

If you get an error like: ```running scripts is disabled on this system```

try launching with:

```text
powershell -STA -NoProfile -ExecutionPolicy RemoteSigned -File ".\LiveCountersApp.ps1"
```

Or set it for the current user:

```text
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

### The overlay does not update

Check these things:
 - the .txt file path is correct
 - the file actually changes when the Stream Deck counter updates
 - the selected file in the app matches the file being updated
 - server_runtime.ps1 is in the same folder as the app

### The overlay window is not detected by streaming software

Some streaming apps may not detect browser app windows reliably.

If that happens:
 - try capturing a normal browser window
 - or use display capture and crop it manually

### Stop does not close everything

If browser windows stay open, the issue is usually how that browser instance was launched and detected. The current setup is designed to close only the overlay browser instance and the server process started by the app.

## WHY THIS EXISTS

Some streaming software, especially outside the OBS ecosystem, does not support text-file overlays directly.

This tool fills that gap by turning .txt counters into a local browser overlay that can still be captured and chroma keyed.

## NOTES

- This project is local-only
- It does not upload your data anywhere
- It is designed to stay lightweight
- It works best with small text-based counter files