<#
.SYNOPSIS
    Fixes yellow/warm page tint in Edge and Chrome after a Windows update.
.DESCRIPTION
    Bounces display adapters, creates sRGB launch shortcuts for Edge and Chrome,
    and opens Color Management so the monitor can be set to sRGB IEC61966-2.1.
.NOTES
    Author:  sysadminsushi
    Version: 9.30.2026
#>

# Temporarily disable then re-enable each GPU/display adapter.
# Chromium reloads the color space after the bounce; yellow tint often
# disappears immediately. Effect can come back after a reboot.
function Reset-DisplayAdapters {
    Write-Host "Resetting display adapters..." -ForegroundColor Cyan
    $devs = Get-PnpDevice -Class Display | Where-Object { $_.Status -eq 'OK' }
    if (-not $devs) { Write-Warning "No display adapters found."; return }

    foreach ($d in $devs) {
        Write-Host "  Disabling $($d.FriendlyName)"
        Disable-PnpDevice -InstanceId $d.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
    }
    Start-Sleep -Seconds 2
    foreach ($d in $devs) {
        Write-Host "  Enabling $($d.FriendlyName)"
        Enable-PnpDevice -InstanceId $d.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
    }
    Write-Host "Done. Leave Edge/Chrome open if they already were; the yellow tint should drop." -ForegroundColor Green
}

# Opens Color Management and points you at the built-in sRGB profile.
# Set it as the monitor default so Edge/Chrome stop using a broken HDR/ICC profile.
function Set-DisplayProfileToSrgb {
    $srgb = "$env:SystemRoot\System32\spool\drivers\color\sRGB Color Space Profile.icm"
    if (Test-Path $srgb) {
        Write-Host "sRGB profile is here: $srgb" -ForegroundColor Green
    } else {
        Write-Warning "Could not find the built-in sRGB profile."
    }

    Write-Host ""
    Write-Host "Color Management will open. Do this for EACH monitor:" -ForegroundColor Yellow
    Write-Host "  1. Devices tab -> pick the monitor"
    Write-Host "  2. Check 'Use my settings for this device'"
    Write-Host "  3. Add -> sRGB Color Space Profile.icm"
    Write-Host "  4. Select it -> Set as Default Profile"
    Write-Host "  5. Close and reopen Edge and Chrome"
    Start-Process colorcpl.exe
}

# Creates Desktop shortcuts for Edge and Chrome that launch with --force-color-profile=srgb.
function New-SrgbBrowserShortcuts {
    $desktop = [Environment]::GetFolderPath('Desktop')
    $ws = New-Object -ComObject WScript.Shell

    $edgePaths = @(
        "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
    )
    $edge = $edgePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($edge) {
        $lnk = $ws.CreateShortcut((Join-Path $desktop 'Edge sRGB.lnk'))
        $lnk.TargetPath = $edge
        $lnk.Arguments  = '--force-color-profile=srgb'
        $lnk.WorkingDirectory = Split-Path $edge
        $lnk.Save()
        Write-Host "Created: $desktop\Edge sRGB.lnk" -ForegroundColor Green
    } else {
        Write-Warning "Edge not found."
    }

    $chromePaths = @(
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
    )
    $chrome = $chromePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($chrome) {
        $lnk = $ws.CreateShortcut((Join-Path $desktop 'Chrome sRGB.lnk'))
        $lnk.TargetPath = $chrome
        $lnk.Arguments  = '--force-color-profile=srgb'
        $lnk.WorkingDirectory = Split-Path $chrome
        $lnk.Save()
        Write-Host "Created: $desktop\Chrome sRGB.lnk" -ForegroundColor Green
    } else {
        Write-Host "Chrome not installed; skipped." -ForegroundColor DarkGray
    }

    Write-Host "Use those shortcuts (or pin them). Close other Edge/Chrome windows first." -ForegroundColor Yellow
}

# Runs all three fixes: GPU bounce, sRGB shortcuts, then Color Management.
function Repair-YellowBrowserTint {
    Reset-DisplayAdapters
    New-SrgbBrowserShortcuts
    Set-DisplayProfileToSrgb
}

Repair-YellowBrowserTint