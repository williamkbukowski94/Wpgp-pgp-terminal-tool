[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$sourceScript = Join-Path $PSScriptRoot 'windows\wpgp.ps1'
if (-not (Test-Path -LiteralPath $sourceScript -PathType Leaf)) {
    throw "Cannot find windows\wpgp.ps1 beside this installer. Run it from the repository checkout."
}

$installDirectory = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Scripts'
$installedScript = Join-Path $installDirectory 'wpgp.ps1'
$profilePath = $PROFILE.CurrentUserAllHosts
$beginMarker = '# >>> wpgp launcher >>>'
$endMarker = '# <<< wpgp launcher <<<'
$launcher = @"
$beginMarker
function wpgp {
    & '$($installedScript.Replace("'", "''"))' @args
}
$endMarker
"@

New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null
Copy-Item -LiteralPath $sourceScript -Destination $installedScript -Force

$profileDirectory = Split-Path -Parent $profilePath
New-Item -ItemType Directory -Path $profileDirectory -Force | Out-Null
$profileText = if (Test-Path -LiteralPath $profilePath) { Get-Content -LiteralPath $profilePath -Raw } else { '' }
$escapedBegin = [regex]::Escape($beginMarker)
$escapedEnd = [regex]::Escape($endMarker)
$blockPattern = "(?ms)^$escapedBegin\r?\n.*?^$escapedEnd(?:\r?\n)?"
if ($profileText -match $blockPattern) {
    $profileText = [regex]::Replace($profileText, $blockPattern, '')
}
$profileText = $profileText.TrimEnd() + [Environment]::NewLine + $launcher + [Environment]::NewLine
Set-Content -LiteralPath $profilePath -Value $profileText -Encoding utf8

Write-Host "Installed wpgp to $installedScript" -ForegroundColor Green
Write-Host "Added the wpgp launcher to $profilePath" -ForegroundColor Green
Write-Host 'Open a new PowerShell window and run: wpgp' -ForegroundColor Cyan

