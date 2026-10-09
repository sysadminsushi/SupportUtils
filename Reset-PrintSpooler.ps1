<#
.SYNOPSIS
    Restarts the print spooler and clears stuck jobs.

.DESCRIPTION
    Stops the Print Spooler service, deletes queued job files in
    C:\Windows\System32\spool\PRINTERS, then starts the service again.
    Does not remove printers.

.EXAMPLE
    .\Reset-PrintSpooler.ps1

.NOTES
    Author:  sysadminsushi
    Version: 10.8.2026
    License: MIT License (see LICENSE file in repository)
    Requirements:
        - PowerShell 5.1 or later
        - Run elevated
#>

# Stops the spooler, deletes stuck job files, then starts it again
function Reset-PrintSpooler {
    Write-Host "Restarting print spooler and clearing stuck jobs..." -ForegroundColor Cyan

    Stop-Service -Name Spooler -Force
    Get-ChildItem "$env:SystemRoot\System32\spool\PRINTERS" -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue
    Start-Service -Name Spooler

    Get-Service Spooler
}

Reset-PrintSpooler