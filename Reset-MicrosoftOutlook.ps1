<#
.SYNOPSIS
    Performs a hard reset of classic Outlook and New Outlook (Olk).

.DESCRIPTION
    Stops Outlook.exe and olk.exe, clears classic and New Outlook cache,
    and removes Office 16.0 Outlook profiles under HKCU so the next
    launch is a new profile. Signatures are left in place.

.NOTES
    Author:  sysadminsushi
    Version: 9.29.2026
#>
function Reset-MicrosoftOutlook {
    Get-Process -Name Outlook, olk -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    $cachePaths = @(
        (Join-Path $env:LOCALAPPDATA "Microsoft\Outlook"),
        (Join-Path $env:LOCALAPPDATA "Microsoft\Olk")
    )
    foreach ($cachePath in $cachePaths) {
        if (Test-Path $cachePath) {
            Remove-Item -Path (Join-Path $cachePath "*") -Recurse -Force -ErrorAction SilentlyContinue
            Write-Output "Cleared: $cachePath"
        }
    }

    $roamingOutlookPath = Join-Path $env:APPDATA "Microsoft\Outlook"
    if (Test-Path $roamingOutlookPath) {
        Get-ChildItem $roamingOutlookPath -Force |
            Where-Object { $_.Name -ne "Signatures" } |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Output "Cleared roaming Outlook data (Signatures kept): $roamingOutlookPath"
    }

    $profilesRootPath = "HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles"
    if (Test-Path $profilesRootPath) {
        Remove-Item -Path $profilesRootPath -Recurse -Force
        Write-Output "Removed: $profilesRootPath"
    }
    New-Item -Path $profilesRootPath -Force | Out-Null
    Write-Output "Recreated empty Profiles key."
}

Reset-MicrosoftOutlook
