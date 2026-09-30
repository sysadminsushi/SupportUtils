<#
.SYNOPSIS
    Copies a folder tree with Robocopy using the backup switches.

.DESCRIPTION
    Flags: /e /dcopy:t /copy:dat /r:1 /w:1 /tee /v
    and appends to a log file.

.NOTES
    Author:  sysadminsushi
    Version: 9.30.2026
#>

# Confirms the source folder exists before Robocopy runs
function Test-RobocopySource {
    param([Parameter(Mandatory)][string]$Source)
    if (-not (Test-Path -LiteralPath $Source)) {
        Write-Error "Source not found: $Source"
        return $false
    }
    return $true
}

# Runs Robocopy with the backup switches and appends the log
function Invoke-RobocopyBackup {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination,
        [Parameter(Mandatory)][string]$LogPath
    )

    $robocopyArgs = @(
        $Source
        $Destination
        "/e"
        "/dcopy:t"
        "/copy:dat"
        "/r:1"
        "/w:1"
        "/tee"
        "/v"
        "/log+:$LogPath"
    )

    Write-Output "Robocopy $Source -> $Destination"
    Write-Output "Log: $LogPath"
    & robocopy.exe @robocopyArgs
    return $LASTEXITCODE
}

# Entry point: validate source, copy, then treat Robocopy 0-7 as success
function Copy-WithRobocopy {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination,
        [string]$LogPath = "G:\backupLog.txt"
    )

    if (-not (Test-RobocopySource -Source $Source)) {
        exit 1
    }

    $exitCode = Invoke-RobocopyBackup -Source $Source -Destination $Destination -LogPath $LogPath

    if ($exitCode -ge 8) {
        Write-Error "Robocopy failed with exit code $exitCode"
        exit $exitCode
    }

    Write-Output "Robocopy finished. Exit code $exitCode"
    exit 0
}

Copy-WithRobocopy -Source "E:\Data\SQLbak\SQL_backup_1-19-2016" -Destination "G:\SQL_backup_1-19-2016" -LogPath "G:\backupLog.txt"