\# Multi Stream Counter Companion



A lightweight local overlay manager for Stream Deck counters that write their values to `.txt` files.



This tool turns one or more text-based counters into a local browser overlay that can be captured in streaming software like TikTok LIVE Studio.



\## Features



\- Add and remove `.txt` counter files from a simple Windows GUI

\- Assign a custom label to each counter

\- Choose between \*\*Vertical\*\*, \*\*Horizontal\*\*, or \*\*Versus\*\* layouts

\- Pick a refresh interval:

&#x20; - `250 ms`

&#x20; - `500 ms`

&#x20; - `1000 ms`

&#x20; - `2000 ms`

\- Opens the overlay in a browser window

\- Uses a chroma-key friendly green background (`#00FF00`)

\- Keeps the actual counter cards grey

\- Local-only workflow

\- No blur effects



\## Use case



This project is meant to work with Stream Deck counters that write their values to `.txt` files, such as plugins like \*\*Multi Stream Counter\*\*.



Example workflow:



1\. A Stream Deck button updates a `.txt` file

2\. This app reads that file locally

3\. The value appears in a browser overlay

4\. Your streaming software captures that browser window



This is especially useful in streaming software that does \*\*not\*\* support reading text files directly.



\## Quick start



1\. Put these files in the same folder:

&#x20;  - `LiveCountersApp.ps1`

&#x20;  - `server\_runtime.ps1`

&#x20;  - `start\_live\_counters.bat`



2\. Run:



&#x20;  ```text

&#x20;  start\_live\_counters.bat

&#x20;  ```



3\. In the app:

&#x20;  - click \*\*Add\*\*

&#x20;  - select one or more `.txt` files

&#x20;  - enter the label for each counter

&#x20;  - choose a layout style

&#x20;  - choose a refresh interval

&#x20;  - click \*\*Start\*\*



4\. Capture the opened browser window in your streaming software.



\## Overlay styles



\### Vertical



Displays counters stacked on top of each other.



Example:



```text

Streamer   3

Chat       1

Wins       5

Loses      2

```



\### Horizontal



Displays counters side by side.



Example:



```text

Streamer 3   Chat 1   Wins 5   Loses 2

```



\### Versus



Displays the first two counters in a versus layout.



Example:



```text

Streamer 3   vs   1 Chat

```



This is useful for head-to-head counters, battles, polls, or score comparisons.



\## Chroma key background



The overlay page uses a solid green background:



```text

\#00FF00

```



This makes it easier to chroma key in software like TikTok LIVE Studio.



Only the outer page background is green.  

The actual counter cards remain grey.



\## Requirements



\- Windows

\- PowerShell

\- Microsoft Edge or Google Chrome

\- One or more `.txt` files containing counter values



\## Project files



```text

Multi Stream Counter Companion/

├─ LiveCountersApp.ps1

├─ server\_runtime.ps1

├─ start\_live\_counters.bat

└─ counters.json

```



\### `LiveCountersApp.ps1`

The main GUI app.



\### `server\_runtime.ps1`

The local server that reads `.txt` files and serves the overlay page.



\### `start\_live\_counters.bat`

A simple launcher for the app.



\### `counters.json`

The saved config file created and updated automatically by the app.



\## How to use



\### 1. Add counters .txt files after they have been created by the StreanDeck plugin



Click \*\*Add\*\*, choose a `.txt` file, and enter the label you want to show in the overlay.



Example labels:



\- Streamer

\- Chat

\- Wins

\- Loses



\### 2. Remove counters



Select a counter in the list and click \*\*Remove\*\*.



\### 3. Choose a layout



Pick one of:



\- \*\*Vertical\*\*

\- \*\*Horizontal\*\*

\- \*\*Versus\*\*



\### 4. Choose refresh interval



Available options:



\- `250 ms`

\- `500 ms`

\- `1000 ms`

\- `2000 ms`



Recommended default:



\- `1000 ms`



\### 5. Start the overlay



Click \*\*Start\*\* to:



\- save the current config

\- start the local server

\- open the overlay in a browser window



\### 6. Stop the overlay



Click \*\*Stop\*\* to close:



\- the overlay browser window

\- the local server process



Closing the app window should also stop everything it launched.



\## Counter file format



Each counter file should contain a simple value, for example:



```text

3

```



or



```text

12

```



The app reads the file contents as text and displays them live.



\## Example setup



Example counter files:



```text

F:\\files\\live\_counters\\streamer.txt

F:\\files\\live\_counters\\chat.txt

F:\\files\\live\_counters\\wins.txt

F:\\files\\live\_counters\\loses.txt

```



Example labels:



\- Streamer

\- Chat

\- Wins

\- Loses



\## Example `counters.json`



```json

{

&#x20; "refreshMs": 500,

&#x20; "style": "horizontal",

&#x20; "counters": \[

&#x20;   {

&#x20;     "label": "Streamer",

&#x20;     "file": "F:\\\\files\\\\live\_counters\\\\streamer.txt"

&#x20;   },

&#x20;   {

&#x20;     "label": "Chat",

&#x20;     "file": "F:\\\\files\\\\live\_counters\\\\chat.txt"

&#x20;   },

&#x20;   {

&#x20;     "label": "Wins",

&#x20;     "file": "F:\\\\files\\\\live\_counters\\\\wins.txt"

&#x20;   },

&#x20;   {

&#x20;     "label": "Loses",

&#x20;     "file": "F:\\\\files\\\\live\_counters\\\\loses.txt"

&#x20;   }

&#x20; ]

}

```



\## Troubleshooting



\### PowerShell says script execution is disabled



If you get an error like:



```text

running scripts is disabled on this system

```



try launching with:



```bat

powershell -STA -NoProfile -ExecutionPolicy RemoteSigned -File ".\\LiveCountersApp.ps1"

```



Or set it for the <CurrentUser> - replace with yours:



```powershell

Set-ExecutionPolicy -Scope <CurrentUser> RemoteSigned

```



\### The overlay does not update



Check these things:



\- the `.txt` file path is correct

\- the file actually changes when the Stream Deck counter updates

\- the selected file in the app matches the file being updated

\- `server\_runtime.ps1` is in the same folder as the app



\### The overlay window is not detected by streaming software



Some streaming apps may not detect browser app windows reliably.



If that happens:



\- try capturing a normal browser window

\- or use display capture and crop it manually



\### Stop does not close everything



If browser windows stay open, the issue is usually how that browser instance was launched and detected. The current setup is designed to close only the overlay browser instance and the server process started by the app.



\## Why this exists



Some streaming software, especially outside the OBS ecosystem, does not support text-file overlays directly.



This tool fills that gap by turning `.txt` counters into a local browser overlay that can still be captured and chroma keyed.



\## Notes



\- This project is local-only

\- It does not upload your data anywhere

\- It is designed to stay lightweight

\- It works best with small text-based counter files

