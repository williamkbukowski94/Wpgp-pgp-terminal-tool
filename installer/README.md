# wpgp Windows installer

`wpgp-setup.exe` is a small Windows console installer. It downloads the PowerShell app from the wpgp GitHub repository, installs it in the current user's `Documents\Codex\wpgp` folder, creates a `wpgp` command launcher, and adds the folder to the current user's PATH. It needs no administrator privileges.

After setup, open Windows PowerShell and run `wpgp` from any directory. GnuPG (provided by Gpg4win) must also be installed for encryption, decryption, key, and signature operations.

The source is `WpgpInstaller.cs`. Build it on Windows with the .NET Framework compiler:

```powershell
$compiler = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
& $compiler /nologo /target:exe /out:wpgp-setup.exe WpgpInstaller.cs
```

The installer fetches `windows/wpgp.ps1` anonymously from the public GitHub repository. Do not put a GitHub access token in the executable. For a new build after changing the PowerShell app, rebuild the installer to refresh the embedded download URL only if the repository or file path changes; the current installer always downloads the latest `main` version.

