# wpgp Windows installer

`wpgp-setup.exe` is a small Windows console installer. It checks for GnuPG and, if missing, asks whether to download the official Gpg4win installer and launch its interactive setup. If declined, it still installs wpgp and explains that PGP operations need GnuPG. It then downloads the PowerShell app from GitHub, installs it in the current user's `Documents\Codex\wpgp` folder, creates a `wpgp` command launcher, and adds the folder to the current user's PATH.

After setup, open Windows PowerShell and run `wpgp` from any directory. Gpg4win may request Windows administrator approval through UAC during its interactive installation.

The source is `WpgpInstaller.cs`. Build it on Windows with the .NET Framework compiler:

```powershell
$compiler = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
& $compiler /nologo /target:exe /out:wpgp-setup.exe WpgpInstaller.cs
```

The installer fetches `windows/wpgp.ps1` anonymously from the public GitHub repository. When GnuPG is missing, it asks for consent before downloading `gpg4win-latest.exe` from the official Gpg4win files site and launching the interactive setup; Windows may show a UAC prompt. If the user declines or Gpg4win setup fails, wpgp itself is still installed and the installer explains that PGP actions need GnuPG. Do not put a GitHub access token in the executable. The app download always uses the latest `main` version.

