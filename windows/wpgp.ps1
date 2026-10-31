#!/usr/bin/env pwsh
# wpgp - a small interactive Windows PowerShell front end for GnuPG.
# Requires gpg (GnuPG) on PATH. Secret keys stay in GnuPG's local key store.

$ErrorActionPreference = 'Stop'
$script:AutoSign = $false
$script:Green = 'DarkGreen'
$script:Gpg = Get-Command gpg.exe, gpg -ErrorAction SilentlyContinue | Select-Object -First 1

function Write-Centered([string]$Text, [ConsoleColor]$Color = 'White') {
    $width = [Math]::Max(1, [Console]::WindowWidth)
    $padding = [Math]::Max(0, [int](($width - $Text.Length) / 2))
    Write-Host ((' ' * $padding) + $Text) -ForegroundColor $Color
}

function Show-Loading {
    Clear-Host
    $title = @'
██╗    ██╗██████╗  ██████╗ ██████╗
██║    ██║██╔══██╗██╔════╝ ██╔══██╗
██║ █╗ ██║██████╔╝██║  ███╗██████╔╝
██║███╗██║██╔═══╝ ██║   ██║██╔═══╝
╚███╔███╔╝██║     ╚██████╔╝██║
 ╚══╝╚══╝ ╚═╝      ╚═════╝ ╚═╝
'@
    $lines = @($title.TrimEnd("`r", "`n").Split("`n"))
    $subtitle = 'An open source PGP encryption tool for Windows PowerShell.'
    $insideWidth = [Math]::Max(($lines | ForEach-Object Length | Measure-Object -Maximum).Maximum, $subtitle.Length) + 4
    $border = '+' + ('-' * $insideWidth) + '+'
    Write-Centered $border $script:Green
    foreach ($line in $lines) {
        $left = [int](($insideWidth - $line.Length) / 2)
        $right = $insideWidth - $line.Length - $left
        Write-Host (' ' * [Math]::Max(0, [int](([Console]::WindowWidth - $insideWidth - 2) / 2))) -NoNewline
        Write-Host '|' -ForegroundColor $script:Green -NoNewline
        Write-Host ((' ' * $left) + $line + (' ' * $right)) -ForegroundColor White -NoNewline
        Write-Host '|' -ForegroundColor $script:Green
    }
    $italic = "`e[3m$subtitle`e[23m"
    $left = [int](($insideWidth - $subtitle.Length) / 2)
    $right = $insideWidth - $subtitle.Length - $left
    Write-Host (' ' * [Math]::Max(0, [int](([Console]::WindowWidth - $insideWidth - 2) / 2))) -NoNewline
    Write-Host '|' -ForegroundColor $script:Green -NoNewline
    Write-Host ((' ' * $left) + $italic + (' ' * $right)) -ForegroundColor White -NoNewline
    Write-Host '|' -ForegroundColor $script:Green
    Write-Centered $border $script:Green
    Start-Sleep -Milliseconds 1000
}

function Pause-Menu { Write-Host ''; [void](Read-Host 'Press Enter to return to the menu') }
function Require-Gpg {
    if (-not $script:Gpg) { throw 'GnuPG was not found. Install Gpg4win (gpg) and make sure gpg.exe is on PATH.' }
}
function Invoke-Gpg([string[]]$Arguments) {
    Require-Gpg
    & $script:Gpg.Source @Arguments
    if ($LASTEXITCODE -ne 0) { throw "GnuPG returned exit code $LASTEXITCODE." }
}
function Get-KeyId([string]$Prompt) {
    $id = Read-Host $Prompt
    if ([string]::IsNullOrWhiteSpace($id)) { throw 'A key ID, fingerprint, or email address is required.' }
    return $id
}
function Get-MessageText {
    Write-Host 'Enter the message. Finish with a line containing only .'
    $lines = [System.Collections.Generic.List[string]]::new()
    while ($true) {
        $line = Read-Host
        if ($line -eq '.') { break }
        $lines.Add($line)
    }
    return ($lines -join [Environment]::NewLine)
}
function Save-Message([string]$Text, [string]$SuggestedName) {
    $path = Read-Host "Output file [$SuggestedName]"
    if ([string]::IsNullOrWhiteSpace($path)) { $path = Join-Path (Get-Location) $SuggestedName }
    [IO.File]::WriteAllText($path, $Text, [Text.UTF8Encoding]::new($false))
    Write-Host "Saved: $path" -ForegroundColor Green
}
function Protect-Message {
    $recipient = Get-KeyId 'Recipient public key (email, key ID, or fingerprint)'
    $text = Get-MessageText
    $inputFile = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString() + '.txt')
    $outputFile = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString() + '.asc')
    try {
        [IO.File]::WriteAllText($inputFile, $text, [Text.UTF8Encoding]::new($false))
        $args = @('--yes', '--armor', '--output', $outputFile, '--encrypt', '--recipient', $recipient)
        if ($script:AutoSign) {
            $signer = Get-KeyId 'Signing key (your secret key email, key ID, or fingerprint)'
            $args = @('--yes', '--armor', '--output', $outputFile, '--sign', '--encrypt', '--recipient', $recipient, '--local-user', $signer)
        }
        $args += $inputFile
        Invoke-Gpg $args
        Save-Message ([IO.File]::ReadAllText($outputFile)) 'message.asc'
    } finally { Remove-Item $inputFile, $outputFile -Force -ErrorAction SilentlyContinue }
}
function Unprotect-Message {
    $path = Read-Host 'Encrypted .asc/.pgp file path'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw 'Input file not found.' }
    $outputFile = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString() + '.txt')
    try {
        Invoke-Gpg @('--yes', '--output', $outputFile, '--decrypt', $path)
        Save-Message ([IO.File]::ReadAllText($outputFile)) 'decrypted-message.txt'
    } finally { Remove-Item $outputFile -Force -ErrorAction SilentlyContinue }
}
function Show-Keys {
    Write-Host "`nYour public and secret keys:" -ForegroundColor Cyan
    Invoke-Gpg @('--list-keys', '--keyid-format', 'long')
    Write-Host "`nSecret keys (needed to decrypt and sign):" -ForegroundColor Cyan
    Invoke-Gpg @('--list-secret-keys', '--keyid-format', 'long')
}
function New-KeyPair {
    $name = Read-Host 'Name for the key'
    $email = Read-Host 'Email address'
    if (-not $name -or -not $email) { throw 'Name and email are required.' }
    $uid = "$name <$email>"
    Invoke-Gpg @('--quick-generate-key', $uid, 'default', 'default')
}
function Export-PublicKey {
    $id = Get-KeyId 'Your key ID, fingerprint, or email'
    $out = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString() + '.asc')
    try {
        Invoke-Gpg @('--armor', '--output', $out, '--export', $id)
        if ((Get-Item $out).Length -eq 0) { throw 'No matching public key was exported.' }
        Save-Message ([IO.File]::ReadAllText($out)) 'public-key.asc'
    } finally { Remove-Item $out -Force -ErrorAction SilentlyContinue }
}
function Find-KeyFile {
    $name = Read-Host 'Key filename to search for (for example recipient.asc)'
    if (-not $name) { throw 'Enter a filename.' }
    $roots = @([Environment]::GetFolderPath('UserProfile'), [Environment]::GetFolderPath('Desktop'), (Get-Location).Path) | Select-Object -Unique
    $matches = foreach ($root in $roots) {
        if (Test-Path -LiteralPath $root) {
            Get-ChildItem -LiteralPath $root -File -Recurse -Filter $name -ErrorAction SilentlyContinue
        }
    }
    $matches = @($matches | Sort-Object FullName -Unique)
    if (-not $matches.Count) { throw "No file named '$name' found in your profile, Desktop, or current directory." }
    for ($i = 0; $i -lt $matches.Count; $i++) { Write-Host "[$($i + 1)] $($matches[$i].FullName)" }
    $choice = Read-Host 'Choose a file number'
    $index = 0
    if (-not [int]::TryParse($choice, [ref]$index) -or $index -lt 1 -or $index -gt $matches.Count) { throw 'Invalid file selection.' }
    return $matches[$index - 1].FullName
}
function Import-KeyFile([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw 'Key file not found.' }
    Invoke-Gpg @('--import', $Path)
}
function Add-Key {
    Write-Host '[1] Find a key text file by filename  [2] Enter file path  [3] Paste key text'
    switch (Read-Host 'Choose source') {
        '1' { $path = Find-KeyFile; Import-KeyFile $path }
        '2' { $path = Read-Host 'Key file path'; Import-KeyFile $path }
        '3' {
            Write-Host 'Paste the complete ASCII-armored key; finish with a line containing only .'
            $lines = [System.Collections.Generic.List[string]]::new()
            while (($line = Read-Host) -ne '.') { $lines.Add($line) }
            $temp = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString() + '.asc')
            try { [IO.File]::WriteAllLines($temp, $lines); Import-KeyFile $temp } finally { Remove-Item $temp -Force -ErrorAction SilentlyContinue }
        }
        default { throw 'Choose 1, 2, or 3.' }
    }
}
function Sign-Message {
    $id = Get-KeyId 'Your signing key (secret key email, key ID, or fingerprint)'
    $text = Get-MessageText
    $in = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString() + '.txt')
    $out = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString() + '.asc')
    try {
        [IO.File]::WriteAllText($in, $text, [Text.UTF8Encoding]::new($false))
        Invoke-Gpg @('--yes', '--armor', '--output', $out, '--clearsign', '--local-user', $id, $in)
        Save-Message ([IO.File]::ReadAllText($out)) 'signed-message.asc'
    } finally { Remove-Item $in, $out -Force -ErrorAction SilentlyContinue }
}
function Verify-Message {
    $path = Read-Host 'Signed message file path'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw 'Input file not found.' }
    Invoke-Gpg @('--verify', $path)
}
function Run-Action([scriptblock]$Action) {
    try { & $Action }
    catch { Write-Host "`nError: $($_.Exception.Message)" -ForegroundColor Red }
    Pause-Menu
}
function Show-Menu {
    while ($true) {
        Clear-Host
        Write-Host '╔══════════════════════════════════════════════════╗' -ForegroundColor $script:Green
        Write-Host '║                    wpgp                          ║' -ForegroundColor White
        Write-Host '╚══════════════════════════════════════════════════╝' -ForegroundColor $script:Green
        Write-Host 'Encrypt recipient-bound messages; decrypt with your secret key.'
        Write-Host 'Import public keys before encrypting. Create a key pair to decrypt or sign.'
        Write-Host 'Sign with your secret key; recipients verify using your public key.'
        Write-Host 'Key files can be imported by path, filename search, or pasted ASCII armor.'
        Write-Host ''
        Write-Host '[1] Encrypt a message'
        Write-Host '[2] Decrypt a message'
        Write-Host '[3] Show current key pairs'
        Write-Host '[4] Check GnuPG keyring / import a public key'
        Write-Host '[5] Make a new key pair'
        Write-Host "[6] Automatic signing: $(if ($script:AutoSign) { 'ON' } else { 'OFF' }) (toggle)"
        Write-Host '[7] Sign a message'
        Write-Host '[8] Verify a signature'
        Write-Host '[9] Export your public key'
        Write-Host '[0] Exit'
        Write-Host "`nGnuPG: $(if ($script:Gpg) { 'available' } else { 'not found' }) | Automatic signing is off by default."
        Write-Host 'written by WB for all open source use' -ForegroundColor DarkCyan
        switch (Read-Host "`nSelect an option") {
            '1' { Run-Action { Protect-Message } }
            '2' { Run-Action { Unprotect-Message } }
            '3' { Run-Action { Show-Keys } }
            '4' { Run-Action { Require-Gpg; Invoke-Gpg @('--list-keys', '--keyid-format', 'long'); Add-Key } }
            '5' { Run-Action { New-KeyPair } }
            '6' { $script:AutoSign = -not $script:AutoSign }
            '7' { Run-Action { Sign-Message } }
            '8' { Run-Action { Verify-Message } }
            '9' { Run-Action { Export-PublicKey } }
            '0' { return }
            default { Write-Host 'Choose a listed option.' -ForegroundColor Yellow; Start-Sleep -Milliseconds 700 }
        }
    }
}

Show-Loading
Show-Menu

