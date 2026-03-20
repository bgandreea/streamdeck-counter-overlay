Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

$ErrorActionPreference = "Stop"

$script:AppDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:ConfigPath = Join-Path $script:AppDir "counters.json"
$script:ServerScriptPath = Join-Path $script:AppDir "server_runtime.ps1"
$script:Port = 8787
$script:ServerProcess = $null
$script:BrowserProcess = $null
$script:BrowserType = $null
$script:BrowserProfileDir = Join-Path $script:AppDir "overlay_browser_profile"

function Get-DefaultConfig {
    return @{
        refreshMs = 500
        style = "versus"
        counters = @()
    }
}

function Load-Config {
    if (Test-Path $script:ConfigPath) {
        try {
            return (Get-Content $script:ConfigPath -Raw | ConvertFrom-Json)
        } catch {
            [System.Windows.Forms.MessageBox]::Show(
                "Failed to read counters.json. A new config will be used.`n`n$($_.Exception.Message)",
                "Live Counters"
            ) | Out-Null
        }
    }

    return (Get-DefaultConfig | ConvertTo-Json -Depth 6 | ConvertFrom-Json)
}

function Save-Config {
    param(
        [System.Windows.Forms.ListView]$ListView,
        [System.Windows.Forms.ComboBox]$StyleCombo,
        [System.Windows.Forms.ComboBox]$RefreshCombo
    )

    $counters = @()
    foreach ($item in $ListView.Items) {
        $counters += [PSCustomObject]@{
            label = [string]$item.SubItems[0].Text
            file  = [string]$item.SubItems[1].Text
        }
    }

    $refresh = 500
    if ($RefreshCombo.SelectedItem) {
        $refresh = [int]$RefreshCombo.SelectedItem.ToString()
    }

    $style = "versus"
    if ($StyleCombo.SelectedItem) {
        $style = $StyleCombo.SelectedItem.ToString().ToLowerInvariant()
    }

    $config = [PSCustomObject]@{
        refreshMs = $refresh
        style     = $style
        counters  = $counters
    }

    $json = $config | ConvertTo-Json -Depth 8
    [System.IO.File]::WriteAllText($script:ConfigPath, $json, [System.Text.UTF8Encoding]::new($false))
}

function Get-BrowserInfo {
    $candidates = @(
        @{ Type = "edge";   Path = "$env:ProgramFiles(x86)\Microsoft\Edge\Application\msedge.exe" },
        @{ Type = "edge";   Path = "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe" },
        @{ Type = "edge";   Path = "$env:LocalAppData\Microsoft\Edge\Application\msedge.exe" },
        @{ Type = "chrome"; Path = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe" },
        @{ Type = "chrome"; Path = "$env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe" },
        @{ Type = "chrome"; Path = "$env:LocalAppData\Google\Chrome\Application\chrome.exe" }
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate.Path) {
            return $candidate
        }
    }

    return $null
}

function Stop-Overlay {
    if ($script:BrowserType -eq "edge") {
        try {
            Get-CimInstance Win32_Process |
                Where-Object {
                    $_.Name -ieq "msedge.exe" -and
                    $_.CommandLine -match [regex]::Escape($script:BrowserProfileDir)
                } |
                ForEach-Object {
                    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
                }
        } catch {}
    }
    elseif ($script:BrowserType -eq "chrome") {
        try {
            Get-CimInstance Win32_Process |
                Where-Object {
                    $_.Name -ieq "chrome.exe" -and
                    $_.CommandLine -match [regex]::Escape($script:BrowserProfileDir)
                } |
                ForEach-Object {
                    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
                }
        } catch {}
    }

    $script:BrowserProcess = $null
    $script:BrowserType = $null

    if ($script:ServerProcess) {
        try {
            if (-not $script:ServerProcess.HasExited) {
                Stop-Process -Id $script:ServerProcess.Id -Force -ErrorAction SilentlyContinue
                $script:ServerProcess.WaitForExit(2000) | Out-Null
            }
        } catch {}
    }

    $script:ServerProcess = $null
}

function Start-Overlay {
    param(
        [System.Windows.Forms.ListView]$ListView,
        [System.Windows.Forms.ComboBox]$StyleCombo,
        [System.Windows.Forms.ComboBox]$RefreshCombo
    )

    if ($ListView.Items.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Add at least one .txt file first.", "Live Counters") | Out-Null
        return
    }

    if (-not (Test-Path $script:ServerScriptPath)) {
        [System.Windows.Forms.MessageBox]::Show(
            "server_runtime.ps1 was not found next to this app script.",
            "Live Counters"
        ) | Out-Null
        return
    }

    Save-Config -ListView $ListView -StyleCombo $StyleCombo -RefreshCombo $RefreshCombo
    Stop-Overlay

    try {
        $script:ServerProcess = Start-Process `
            -FilePath "powershell.exe" `
            -ArgumentList @(
                "-NoLogo",
                "-NoProfile",
                "-ExecutionPolicy", "RemoteSigned",
                "-File", $script:ServerScriptPath
            ) `
            -WorkingDirectory $script:AppDir `
            -PassThru
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Could not start server_runtime.ps1.`n`n$($_.Exception.Message)",
            "Live Counters"
        ) | Out-Null
        return
    }

    Start-Sleep -Milliseconds 1200

    $browserInfo = Get-BrowserInfo
    if (-not $browserInfo) {
        Stop-Overlay
        [System.Windows.Forms.MessageBox]::Show("Edge or Chrome was not found.", "Live Counters") | Out-Null
        return
    }

    $script:BrowserType = $browserInfo.Type

    if (-not (Test-Path $script:BrowserProfileDir)) {
        New-Item -ItemType Directory -Path $script:BrowserProfileDir | Out-Null
    }

    try {
        $script:BrowserProcess = Start-Process `
            -FilePath $browserInfo.Path `
            -ArgumentList @(
                "--user-data-dir=$script:BrowserProfileDir",
                "--new-window",
		"http://127.0.0.1:$($script:Port)/"
            ) `
            -WorkingDirectory $script:AppDir `
            -PassThru
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Could not open browser overlay.`n`n$($_.Exception.Message)",
            "Live Counters"
        ) | Out-Null
    }
}

function Add-CounterRow {
    param(
        [System.Windows.Forms.ListView]$ListView,
        [string]$LabelText,
        [string]$FilePath
    )

    $item = New-Object System.Windows.Forms.ListViewItem($LabelText)
    $null = $item.SubItems.Add($FilePath)
    $null = $ListView.Items.Add($item)
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Live Counters"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(760, 470)
$form.MinimumSize = New-Object System.Drawing.Size(760, 470)

$list = New-Object System.Windows.Forms.ListView
$list.Location = New-Object System.Drawing.Point(12, 12)
$list.Size = New-Object System.Drawing.Size(720, 280)
$list.View = [System.Windows.Forms.View]::Details
$list.FullRowSelect = $true
$list.GridLines = $true
$list.HideSelection = $false
$null = $list.Columns.Add("Label", 180)
$null = $list.Columns.Add("Text File", 520)

$addButton = New-Object System.Windows.Forms.Button
$addButton.Text = "Add"
$addButton.Location = New-Object System.Drawing.Point(12, 305)
$addButton.Size = New-Object System.Drawing.Size(100, 32)

$removeButton = New-Object System.Windows.Forms.Button
$removeButton.Text = "Remove"
$removeButton.Location = New-Object System.Drawing.Point(124, 305)
$removeButton.Size = New-Object System.Drawing.Size(100, 32)

$styleLabel = New-Object System.Windows.Forms.Label
$styleLabel.Text = "Style"
$styleLabel.Location = New-Object System.Drawing.Point(12, 355)
$styleLabel.AutoSize = $true

$styleCombo = New-Object System.Windows.Forms.ComboBox
$styleCombo.Location = New-Object System.Drawing.Point(12, 375)
$styleCombo.Size = New-Object System.Drawing.Size(180, 28)
$styleCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$null = $styleCombo.Items.AddRange(@("Vertical","Horizontal","Versus"))

$refreshLabel = New-Object System.Windows.Forms.Label
$refreshLabel.Text = "Refresh interval"
$refreshLabel.Location = New-Object System.Drawing.Point(220, 355)
$refreshLabel.AutoSize = $true

$refreshCombo = New-Object System.Windows.Forms.ComboBox
$refreshCombo.Location = New-Object System.Drawing.Point(220, 375)
$refreshCombo.Size = New-Object System.Drawing.Size(140, 28)
$refreshCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$null = $refreshCombo.Items.AddRange(@("250","500","1000","2000"))

$startButton = New-Object System.Windows.Forms.Button
$startButton.Text = "Start"
$startButton.Location = New-Object System.Drawing.Point(500, 365)
$startButton.Size = New-Object System.Drawing.Size(110, 38)

$stopButton = New-Object System.Windows.Forms.Button
$stopButton.Text = "Stop"
$stopButton.Location = New-Object System.Drawing.Point(622, 365)
$stopButton.Size = New-Object System.Drawing.Size(110, 38)

$form.Controls.AddRange(@(
    $list, $addButton, $removeButton, $styleLabel, $styleCombo,
    $refreshLabel, $refreshCombo, $startButton, $stopButton
))

$config = Load-Config
foreach ($counter in $config.counters) {
    Add-CounterRow -ListView $list -LabelText ([string]$counter.label) -FilePath ([string]$counter.file)
}

switch (($config.style | ForEach-Object { $_.ToString().ToLowerInvariant() })) {
    "vertical"   { $styleCombo.SelectedItem = "Vertical" }
    "horizontal" { $styleCombo.SelectedItem = "Horizontal" }
    default      { $styleCombo.SelectedItem = "Versus" }
}

$refreshCombo.SelectedItem = [string]($config.refreshMs)
if (-not $refreshCombo.SelectedItem) {
    $refreshCombo.SelectedItem = "500"
}

$addButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "Text files (*.txt)|*.txt|All files (*.*)|*.*"
    $dialog.Multiselect = $false

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        foreach ($existing in $list.Items) {
            if ($existing.SubItems[1].Text -ieq $dialog.FileName) {
                [System.Windows.Forms.MessageBox]::Show("That file is already added.", "Live Counters") | Out-Null
                return
            }
        }

        $defaultLabel = [System.IO.Path]::GetFileNameWithoutExtension($dialog.FileName)
        $label = [Microsoft.VisualBasic.Interaction]::InputBox(
            "Enter the label for this counter:",
            "Add Counter",
            $defaultLabel
        )

        if ([string]::IsNullOrWhiteSpace($label)) {
            return
        }

        Add-CounterRow -ListView $list -LabelText $label.Trim() -FilePath $dialog.FileName
        Save-Config -ListView $list -StyleCombo $styleCombo -RefreshCombo $refreshCombo
    }
})

$removeButton.Add_Click({
    if ($list.SelectedItems.Count -gt 0) {
        foreach ($selected in @($list.SelectedItems)) {
            $list.Items.Remove($selected)
        }

        Save-Config -ListView $list -StyleCombo $styleCombo -RefreshCombo $refreshCombo
    }
})

$styleCombo.Add_SelectedIndexChanged({
    Save-Config -ListView $list -StyleCombo $styleCombo -RefreshCombo $refreshCombo
})

$refreshCombo.Add_SelectedIndexChanged({
    Save-Config -ListView $list -StyleCombo $styleCombo -RefreshCombo $refreshCombo
})

$startButton.Add_Click({
    Start-Overlay -ListView $list -StyleCombo $styleCombo -RefreshCombo $refreshCombo
})

$stopButton.Add_Click({
    Stop-Overlay
})

$form.Add_FormClosing({
    Stop-Overlay
})

[void][System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::Run($form)
Stop-Overlay