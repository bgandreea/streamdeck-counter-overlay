$ErrorActionPreference = "Stop"

$script:AppDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:ConfigPath = Join-Path $script:AppDir "counters.json"
$script:Port = 8787

function Get-DefaultConfig {
    return @{
        refreshMs = 500
        style = "versus"
        counters = @()
    }
}

function Read-Config {
    if (-not (Test-Path $script:ConfigPath)) {
        return (Get-DefaultConfig | ConvertTo-Json -Depth 6 | ConvertFrom-Json)
    }

    try {
        return (Get-Content $script:ConfigPath -Raw | ConvertFrom-Json)
    } catch {
        return (Get-DefaultConfig | ConvertTo-Json -Depth 6 | ConvertFrom-Json)
    }
}

function Get-CounterData {
    $config = Read-Config
    $items = @()

    foreach ($counter in $config.counters) {
        $value = ""
        $status = "ok"

        try {
            if (Test-Path $counter.file) {
                $value = [System.IO.File]::ReadAllText($counter.file).Trim()
            } else {
                $status = "missing"
            }
        } catch {
            $status = "error"
        }

        $items += [PSCustomObject]@{
            label  = [string]$counter.label
            value  = [string]$value
            status = [string]$status
            file   = [string]$counter.file
        }
    }

    return [PSCustomObject]@{
        updatedAt = [DateTime]::Now.ToString("HH:mm:ss.fff")
        refreshMs = if ($config.refreshMs) { [int]$config.refreshMs } else { 500 }
        style     = if ($config.style) { [string]$config.style } else { "versus" }
        items     = $items
    } | ConvertTo-Json -Depth 8
}

$html = @"
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>Live Counters</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
html, body {
  margin: 0;
  padding: 0;
  background: #00FF00;
  font-family: Arial, sans-serif;
  overflow: hidden;
  width: fit-content;
  height: fit-content;
}
body {
  display: inline-block;
}
.wrap {
  display: inline-flex;
  width: fit-content;
  height: fit-content;
  padding: 14px;
  box-sizing: border-box;
}
.wrap.vertical {
  flex-direction: column;
  align-items: flex-start;
  gap: 12px;
}
.wrap.horizontal {
  flex-direction: row;
  align-items: center;
  gap: 12px;
}
.counter {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 16px;
  border-radius: 18px;
  background: #5a5a63;
  box-shadow: none;
  white-space: nowrap;
}
.vertical .counter {
  min-width: 280px;
  justify-content: space-between;
}
.label {
  color: #ffffff;
  font-size: 22px;
  font-weight: 700;
  text-shadow: 0 2px 4px rgba(0,0,0,0.35);
}
.value {
  color: #ffffff;
  font-size: 28px;
  font-weight: 900;
  min-width: 24px;
  text-align: center;
  text-shadow: 0 2px 4px rgba(0,0,0,0.35);
}
.versus-card {
  display: flex;
  align-items: center;
  gap: 18px;
  padding: 12px 18px;
  border-radius: 20px;
  background: #5a5a63;
  box-shadow: none;
  white-space: nowrap;
}
.side {
  display: flex;
  align-items: center;
  gap: 12px;
}
.vs {
  color: #ffffff;
  font-size: 18px;
  font-weight: 900;
  padding: 4px 12px;
  border-radius: 999px;
  background: #6b6b74;
  text-transform: lowercase;
}
.missing .value, .error .value {
  opacity: 0.65;
}
</style>
</head>
<body>
<div class="wrap horizontal" id="wrap"></div>
<script>
let refreshTimer = null;

async function loadData() {
  const res = await fetch('/data?ts=' + Date.now(), {
    cache: 'no-store',
    headers: { 'Cache-Control': 'no-cache' }
  });

  const data = await res.json();
  const wrap = document.getElementById('wrap');
  const style = (data.style || 'horizontal').toLowerCase();

  wrap.className = 'wrap ' + style;
  wrap.innerHTML = '';

  if (style === 'versus' && data.items.length >= 2) {
    const left = data.items[0];
    const right = data.items[1];

    const card = document.createElement('div');
    card.className = 'versus-card';

    const leftSide = document.createElement('div');
    leftSide.className = 'side left ' + (left.status || 'ok');

    const leftLabel = document.createElement('div');
    leftLabel.className = 'label';
    leftLabel.textContent = left.label;

    const leftValue = document.createElement('div');
    leftValue.className = 'value';
    leftValue.textContent = left.value || '0';

    leftSide.appendChild(leftLabel);
    leftSide.appendChild(leftValue);

    const vs = document.createElement('div');
    vs.className = 'vs';
    vs.textContent = 'vs';

    const rightSide = document.createElement('div');
    rightSide.className = 'side right ' + (right.status || 'ok');

    const rightValue = document.createElement('div');
    rightValue.className = 'value';
    rightValue.textContent = right.value || '0';

    const rightLabel = document.createElement('div');
    rightLabel.className = 'label';
    rightLabel.textContent = right.label;

    rightSide.appendChild(rightValue);
    rightSide.appendChild(rightLabel);

    card.appendChild(leftSide);
    card.appendChild(vs);
    card.appendChild(rightSide);

    wrap.appendChild(card);
  } else {
    for (const item of data.items) {
      const row = document.createElement('div');
      row.className = 'counter ' + (item.status || 'ok');

      const label = document.createElement('div');
      label.className = 'label';
      label.textContent = item.label;

      const value = document.createElement('div');
      value.className = 'value';
      value.textContent = item.value || '0';

      row.appendChild(label);
      row.appendChild(value);
      wrap.appendChild(row);
    }
  }

  const nextRefresh = parseInt(data.refreshMs || 500, 10);
  if (refreshTimer) clearTimeout(refreshTimer);
  refreshTimer = setTimeout(loadData, nextRefresh);
}

loadData().catch(() => {
  setTimeout(loadData, 1000);
});
</script>
</body>
</html>
"@

$listener = New-Object System.Net.HttpListener
$prefix = "http://127.0.0.1:$($script:Port)/"
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
    Write-Host "Live counter server running at $prefix"
    Write-Host "Press Ctrl+C to stop."
} catch {
    Write-Host "Failed to start listener on $prefix"
    Write-Host $_.Exception.Message
    Read-Host "Press Enter to close"
    exit 1
}

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        $path = $request.Url.AbsolutePath.ToLowerInvariant()

        switch ($path) {
            "/" {
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
                $response.ContentType = "text/html; charset=utf-8"
                $response.Headers.Add("Cache-Control", "no-store, no-cache, must-revalidate")
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                $response.OutputStream.Close()
            }
            "/data" {
                $json = Get-CounterData
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                $response.ContentType = "application/json; charset=utf-8"
                $response.Headers.Add("Cache-Control", "no-store, no-cache, must-revalidate")
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                $response.OutputStream.Close()
            }
            default {
                $response.StatusCode = 404
                $buffer = [System.Text.Encoding]::UTF8.GetBytes("Not Found")
                $response.ContentType = "text/plain; charset=utf-8"
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                $response.OutputStream.Close()
            }
        }
    }
}
finally {
    if ($listener -and $listener.IsListening) {
        $listener.Stop()
    }
    $listener.Close()
}