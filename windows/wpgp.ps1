#!/usr/bin/env pwsh
# wpgp - a small interactive Windows PowerShell front end for GnuPG.
# Requires gpg (GnuPG) on PATH. Secret keys stay in GnuPG's local key store.

$ErrorActionPreference = 'Stop'
$script:AutoSign = $false
$script:ExitRequested = $false
$script:Green = 'DarkGreen'
$script:Gpg = Get-Command gpg.exe, gpg -ErrorAction SilentlyContinue | Select-Object -First 1

class WpgpReturnToMenuException : System.Exception { }

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

function Read-Wpgp([string]$Prompt = '', [switch]$MainMenu) {
    if ($Prompt) { Write-Host $Prompt }
    Write-Host '% ' -NoNewline -ForegroundColor DarkCyan
    $answer = [Console]::ReadLine()
    if ($answer -match '^(?i:exit|quit)$') {
        if ($MainMenu) { $script:ExitRequested = $true; return $null }
        throw [WpgpReturnToMenuException]::new()
    }
    return $answer
}
function Pause-Menu { Write-Host ''; [void](Read-Wpgp 'Press Enter to return to the menu (or type exit)') }
function Require-Gpg {
    if (-not $script:Gpg) { throw 'GnuPG was not found. Install Gpg4win (gpg) and make sure gpg.exe is on PATH.' }
}
function Invoke-Gpg([string[]]$Arguments) {
    Require-Gpg
    & $script:Gpg.Source @Arguments
    if ($LASTEXITCODE -ne 0) { throw "GnuPG returned exit code $LASTEXITCODE." }
}
function Get-KeyId([string]$Prompt) {
    $id = Read-Wpgp $Prompt
    if ([string]::IsNullOrWhiteSpace($id)) { throw 'A key ID, fingerprint, or email address is required.' }
    return $id
}
function Read-PastedText([string]$Instruction) {
    Write-Host $Instruction
    $lines = [System.Collections.Generic.List[string]]::new()
    while ($true) {
        $line = Read-Wpgp
        if ($line -eq '.') { break }
        $lines.Add($line)
    }
    return ($lines -join [Environment]::NewLine)
}
function Get-MessageText {
    Write-Host '[1] Type a message  [2] Read message text from a file'
    $source = Read-Wpgp 'Choose message source'
    if ($source -eq '2') {
        $path = Read-TextFilePath 'Message text file'
        return [IO.File]::ReadAllText($path)
    }
    if ($source -ne '1') { throw 'Choose 1 or 2.' }
    Write-Host 'Enter the message. Finish with a line containing only .'
    $lines = [System.Collections.Generic.List[string]]::new()
    while ($true) {
        $line = Read-Wpgp
        if ($line -eq '.') { break }
        $lines.Add($line)
    }
    return ($lines -join [Environment]::NewLine)
}
function Show-ResultAndConfirm([string]$Caption, [string]$Text) {
    Write-Host "`n$Caption" -ForegroundColor Cyan
    Write-Host $Text
    do {
        $answer = Read-Wpgp 'Have you read the message? [y/n]'
        if ($answer -notmatch '^(?i:y|yes|n|no)$') { Write-Host 'Enter y or n.' -ForegroundColor Yellow }
    } while ($answer -notmatch '^(?i:y|yes|n|no)$')
    if ($answer -match '^(?i:n|no)$') { Write-Host 'Message remains available on screen above.' -ForegroundColor Yellow }
}
function Read-TextFilePath([string]$Description) {
    Write-Host '[1] Enter the full path  [2] Search by filename'
    switch (Read-Wpgp "$Description source") {
        '1' { $path = Read-Wpgp "$Description path" }
        '2' { $path = Find-KeyFile }
        default { throw 'Choose 1 or 2.' }
    }
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw 'File not found.' }
    return $path
}
function Save-Message([string]$Text, [string]$SuggestedName) {
    $outputDirectory = Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Documents\Codex\wpgp\messages'
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    $defaultPath = Join-Path $outputDirectory $SuggestedName
    $path = Read-Wpgp "Output file [$defaultPath]"
    if ([string]::IsNullOrWhiteSpace($path)) { $path = $defaultPath }
    try { [IO.File]::WriteAllText($path, $Text, [Text.UTF8Encoding]::new($false)) }
    catch { throw "Could not write '$path'. Choose a folder where your account has write access. $($_.Exception.Message)" }
    Write-Host "Saved: $path" -ForegroundColor Green
}
function Protect-Message {
    $recipient = Get-RecipientKey
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
        $armored = [IO.File]::ReadAllText($outputFile)
        Save-Message $armored 'message.asc'
        Show-ResultAndConfirm 'Generated encrypted message:' $armored
    } finally { Remove-Item $inputFile, $outputFile -Force -ErrorAction SilentlyContinue }
}
function Unprotect-Message {
    Write-Host '[1] Read encrypted message from a file  [2] Paste ASCII-armored message'
    $source = Read-Wpgp 'Choose encrypted message source'
    $outputFile = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString() + '.txt')
    $inputFile = $null
    $deleteInput = $false
    try {
        if ($source -eq '1') { $inputFile = Read-TextFilePath 'Encrypted message' }
        elseif ($source -eq '2') {
            $inputFile = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString() + '.asc')
            $armor = Read-PastedText 'Paste the complete encrypted message; finish with a line containing only .'
            [IO.File]::WriteAllText($inputFile, $armor, [Text.UTF8Encoding]::new($false))
            $deleteInput = $true
        } else { throw 'Choose 1 or 2.' }
        Invoke-Gpg @('--yes', '--output', $outputFile, '--decrypt', $inputFile)
        $plain = [IO.File]::ReadAllText($outputFile)
        Save-Message $plain 'decrypted-message.txt'
        Show-ResultAndConfirm 'Decrypted message:' $plain
    } finally { Remove-Item $outputFile -Force -ErrorAction SilentlyContinue; if ($deleteInput) { Remove-Item $inputFile -Force -ErrorAction SilentlyContinue } }
}
function Show-Keys {
    Write-Host "`nYour public and secret keys:" -ForegroundColor Cyan
    Invoke-Gpg @('--list-keys', '--keyid-format', 'long')
    Write-Host "`nSecret keys (needed to decrypt and sign):" -ForegroundColor Cyan
    Invoke-Gpg @('--list-secret-keys', '--keyid-format', 'long')
}
function New-KeyPair {
    $name = Read-Wpgp 'Name for the key'
    $email = Read-Wpgp 'Email address'
    if (-not $name -or -not $email) { throw 'Name and email are required.' }
    $uid = "$name <$email>"
    Invoke-Gpg @('--quick-generate-key', $uid, 'default', 'default')
}
function Export-PublicKey {
    Write-Host 'Your keys in the GnuPG keyring:'
    Invoke-Gpg @('--list-keys', '--keyid-format', 'long')
    $id = Get-KeyId 'Your key ID, fingerprint, or email'
    $out = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString() + '.asc')
    try {
        Invoke-Gpg @('--armor', '--output', $out, '--export', $id)
        if ((Get-Item $out).Length -eq 0) { throw 'No matching public key was exported.' }
        Save-Message ([IO.File]::ReadAllText($out)) 'public-key.asc'
    } finally { Remove-Item $out -Force -ErrorAction SilentlyContinue }
}
function Find-KeyFile {
    $name = Read-Wpgp 'Key filename to search for (for example recipient.asc)'
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
    $choice = Read-Wpgp 'Choose a file number'
    $index = 0
    if (-not [int]::TryParse($choice, [ref]$index) -or $index -lt 1 -or $index -gt $matches.Count) { throw 'Invalid file selection.' }
    return $matches[$index - 1].FullName
}
function Import-KeyFile([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw 'Key file not found.' }
    Invoke-Gpg @('--import', $Path)
}
function Get-RecipientKey {
    Write-Host '[1] Select a key already in your GnuPG keyring'
    Write-Host '[2] Read and import a public key text file'
    Write-Host '[3] Paste and import a public key'
    switch (Read-Wpgp 'Choose recipient key source') {
        '1' {
            Invoke-Gpg @('--list-keys', '--keyid-format', 'long')
            return Get-KeyId 'Recipient email, key ID, or fingerprint'
        }
        '2' {
            $path = Read-TextFilePath 'Recipient public key/info file'
            Import-KeyFile $path
            Invoke-Gpg @('--list-keys', '--keyid-format', 'long')
            return Get-KeyId 'Imported recipient email, key ID, or fingerprint'
        }
        '3' {
            $armor = Read-PastedText 'Paste the public key and any text-file notes; finish with a line containing only .'
            $temp = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString() + '.asc')
            try {
                [IO.File]::WriteAllText($temp, $armor, [Text.UTF8Encoding]::new($false))
                Import-KeyFile $temp
            } finally { Remove-Item $temp -Force -ErrorAction SilentlyContinue }
            Invoke-Gpg @('--list-keys', '--keyid-format', 'long')
            return Get-KeyId 'Imported recipient email, key ID, or fingerprint'
        }
        default { throw 'Choose 1, 2, or 3.' }
    }
}
function Add-Key {
    Write-Host '[1] Find a key text file by filename  [2] Enter file path  [3] Paste key text'
    switch (Read-Wpgp 'Choose source') {
        '1' { $path = Find-KeyFile; Import-KeyFile $path }
        '2' { $path = Read-Wpgp 'Key file path'; Import-KeyFile $path }
        '3' {
            $text = Read-PastedText 'Paste the public key and any associated notes; finish with a line containing only .'
            $temp = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString() + '.asc')
            try { [IO.File]::WriteAllText($temp, $text, [Text.UTF8Encoding]::new($false)); Import-KeyFile $temp } finally { Remove-Item $temp -Force -ErrorAction SilentlyContinue }
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
        $signed = [IO.File]::ReadAllText($out)
        Save-Message $signed 'signed-message.asc'
        Show-ResultAndConfirm 'Generated signed message:' $signed
    } finally { Remove-Item $in, $out -Force -ErrorAction SilentlyContinue }
}
function Verify-Message {
    Write-Host '[1] Read signed message from a file  [2] Paste signed message'
    $source = Read-Wpgp 'Choose signed message source'
    $path = $null
    $temp = $null
    try {
        if ($source -eq '1') { $path = Read-TextFilePath 'Signed message' }
        elseif ($source -eq '2') {
            $temp = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString() + '.asc')
            $text = Read-PastedText 'Paste the complete signed message; finish with a line containing only .'
            [IO.File]::WriteAllText($temp, $text, [Text.UTF8Encoding]::new($false))
            $path = $temp
        } else { throw 'Choose 1 or 2.' }
        Invoke-Gpg @('--verify', $path)
    } finally { if ($temp) { Remove-Item $temp -Force -ErrorAction SilentlyContinue } }
}
function Run-Action([scriptblock]$Action) {
    $returnRequested = $false
    Clear-Host
    try { & $Action }
    catch [WpgpReturnToMenuException] { $returnRequested = $true }
    catch { Write-Host "`nError: $($_.Exception.Message)" -ForegroundColor Red }
    if (-not $returnRequested) {
        try { Pause-Menu } catch [WpgpReturnToMenuException] { }
    }
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
        $gpgStatus = if ($script:Gpg) { 'available' } else { 'not found; run setup and approve Gpg4win' }
        Write-Host "`nGnuPG: $gpgStatus | Automatic signing: $(if ($script:AutoSign) { 'ON' } else { 'OFF' })"
        Write-Host 'written by WB for all open source use' -ForegroundColor DarkCyan
        $choice = Read-Wpgp "`nSelect an option (or type exit/quit to close)" -MainMenu
        if ($script:ExitRequested) { return }
        switch ($choice) {
            '1' { Run-Action { Protect-Message } }
            '2' { Run-Action { Unprotect-Message } }
            '3' { Run-Action { Show-Keys } }
            '4' { Run-Action { Require-Gpg; Invoke-Gpg @('--list-keys', '--keyid-format', 'long'); Add-Key } }
            '5' { Run-Action { New-KeyPair } }
            '6' {
                $script:AutoSign = -not $script:AutoSign
                Write-Host "Automatic signing is now $(if ($script:AutoSign) { 'ON' } else { 'OFF' })." -ForegroundColor Cyan
                Start-Sleep -Milliseconds 700
            }
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


