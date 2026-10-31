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
    try {
        [Environment]::SetEnvironmentVariable('Path', ($pathEntries -join ';'), 'User')
    } catch {
        Write-Warning 'Windows blocked the per-user PATH update in this session.'
    }
}
$processEntries = @($env:Path -split ';' | Where-Object { $_ })
if (-not ($processEntries | Where-Object { $_.TrimEnd('\') -ieq $installDirectory.TrimEnd('\') })) {
    $env:Path = ($processEntries + $installDirectory) -join ';'
}

Write-Host "Installed wpgp to $installedScript" -ForegroundColor Green
if ([Environment]::GetEnvironmentVariable('Path', 'User') -split ';' | Where-Object { $_.TrimEnd('\') -ieq $installDirectory.TrimEnd('\') }) {
    Write-Host "Added $installDirectory to your user PATH. Run wpgp in a new PowerShell window." -ForegroundColor Cyan
} else {
    Write-Host "Add this folder to your user PATH to run wpgp by name: $installDirectory" -ForegroundColor Yellow
    Write-Host "Until then, run: & '$installedScript'" -ForegroundColor Cyan
}

