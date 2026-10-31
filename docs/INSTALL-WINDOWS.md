# Windows installation and use

## Requirements

- Windows PowerShell 5.1 or PowerShell 7 or newer.
- GnuPG (`gpg.exe`). Gpg4win is a Windows distribution that includes GnuPG.
- Git, if installing from a repository clone.

Confirm GnuPG is available before starting:

```powershell
gpg --version
```

If PowerShell cannot find `gpg`, install Gpg4win and ensure its `bin` directory is on `PATH`, then open a new terminal.

## Install from a clone

```powershell
git clone https://github.com/williamkbukowski94/Wpgp-pgp-terminal-tool.git
Set-Location .\Wpgp-pgp-terminal-tool
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\install-windows.ps1
```

The process-scoped execution policy change lasts only for that PowerShell window. The installer needs no elevation. It copies `windows\wpgp.ps1` to your Documents PowerShell scripts folder and adds a marked `wpgp` function to `$PROFILE.CurrentUserAllHosts`. Open a new PowerShell window to use `wpgp`, or load the profile in the current window with:

```powershell
. $PROFILE.CurrentUserAllHosts
wpgp
```

The launcher invokes the script directly. GnuPG stores its keys in your account's normal GnuPG home directory; wpgp does not make another key store.

## Use

- **Encrypt**: import or otherwise obtain the recipient public key first. Enter the recipient key's email, key ID, or full fingerprint, then enter message lines. A line containing only `.` ends input. With auto-sign enabled, select your own secret key when prompted.
- **Decrypt**: provide a path to an encrypted message file. GnuPG uses your secret key and may prompt for its passphrase.
- **Key pairs**: display public and secret key listings, or create a key pair. Key generation uses GnuPG defaults and may open pinentry.
- **Import public key**: choose filename search, direct path, or paste ASCII-armored key text. Imported keys enter your normal GnuPG keyring. The filename search checks the user profile, Desktop, and current directory recursively and shows matching paths.
- **Sign**: create a clear-signed text message using your secret key.
- **Verify**: check a signed message file. Treat a valid signature as proof that the matching private key signed the data; independently verify the signer fingerprint to associate it with a person.
- **Export**: save an ASCII-armored copy of your public key to share.

The automatic-sign toggle is off at startup and lasts only for the current run. Signing always uses a secret/private key; recipients need the matching public key to verify. Encryption uses a recipient public key and decryption requires its corresponding secret key.

## Registry wording

The app lists and imports keys in GnuPG's keyring. It does not inspect or edit the Windows Registry. The Windows Registry is unrelated to OpenPGP's public-key store.

## Uninstall

Remove `wpgp.ps1` from the PowerShell scripts folder shown during install and remove the section between `# >>> wpgp launcher >>>` and `# <<< wpgp launcher <<<` from `$PROFILE.CurrentUserAllHosts`. This does not remove any GnuPG keys or messages.

## Troubleshooting

- **`gpg.exe` not found**: install Gpg4win, add its GnuPG `bin` folder to `PATH`, and restart PowerShell.
- **Scripts are disabled**: for a one-time install session, use `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`, then run the installer again. Follow your organization's policy on managed devices.
- **`wpgp` is not recognized**: open a new PowerShell window or dot-source the current-user profile as shown above.
- **No key matches**: import the recipient's public key and confirm the email/fingerprint shown by `gpg --list-keys`.

## Security

Verify public-key fingerprints with their owners using another trusted channel. A key's presence in the keyring does not prove its identity. Protect secret keys and passphrases; losing a secret key can prevent decryption of older messages. Terminal scrollback may retain message text.

