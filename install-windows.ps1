[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$sourceScript = Join-Path $PSScriptRoot 'windows\wpgp.ps1'
if (-not (Test-Path -LiteralPath $sourceScript -PathType Leaf)) {
    throw "Cannot find windows\wpgp.ps1 beside this installer. Run it from the repository checkout."
}

$installDirectory = Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Documents\Codex\wpgp'
$installedScript = Join-Path $installDirectory 'wpgp.ps1'
$launcherPath = Join-Path $installDirectory 'wpgp.cmd'
$engine = Get-Command pwsh.exe -ErrorAction SilentlyContinue
if (-not $engine) { $engine = Get-Command powershell.exe -ErrorAction SilentlyContinue }
if (-not $engine) { throw 'Neither pwsh.exe nor powershell.exe was found.' }

New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null
Copy-Item -LiteralPath $sourceScript -Destination $installedScript -Force
[IO.File]::WriteAllText($launcherPath, "@echo off`r`n`"$($engine.Source)`" -NoLogo -NoProfile -ExecutionPolicy Bypass -File `"%~dp0wpgp.ps1`" %*`r`n", [Text.Encoding]::ASCII)

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$pathEntries = @($userPath -split ';' | Where-Object { $_ })
if (-not ($pathEntries | Where-Object { $_.TrimEnd('\') -ieq $installDirectory.TrimEnd('\') })) {
    $pathEntries += $installDirectory
    [Environment]::SetEnvironmentVariable('Path', ($pathEntries -join ';'), 'User')
}
$processEntries = @($env:Path -split ';' | Where-Object { $_ })
if (-not ($processEntries | Where-Object { $_.TrimEnd('\') -ieq $installDirectory.TrimEnd('\') })) {
    $env:Path = ($processEntries + $installDirectory) -join ';'
}

Write-Host "Installed wpgp to $installedScript" -ForegroundColor Green
Write-Host "Added $installDirectory to your user PATH" -ForegroundColor Green
Write-Host 'Run wpgp in this window or any new PowerShell window.' -ForegroundColor Cyan

