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

The process-scoped execution policy change lasts only for that PowerShell window. The installer needs no elevation for wpgp itself. It checks for GnuPG; if missing, it asks before downloading the official Gpg4win installer and launching its interactive setup. It installs the app to `Documents\Codex\wpgp`, creates a `wpgp.cmd` launcher that applies execution-policy bypass only to that wpgp child process, and adds the folder to your per-user `PATH`. It does not change the machine execution policy. Open a new PowerShell window and run `wpgp`.

```powershell
& "$env:USERPROFILE\Documents\Codex\wpgp\wpgp.ps1"
```

The launcher invokes Windows PowerShell with a process-only execution-policy bypass. GnuPG stores keys in your account's normal GnuPG home directory; wpgp does not create another key store.

## Use

- **Encrypt**: choose an existing recipient key, import one from a file, or paste an ASCII-armored public key. Enter a key email, ID, or fingerprint, then type a message or read it from a file. A line containing only `.` ends typed input. With auto-sign enabled, select your secret key when prompted. The armored result is saved and displayed for review.
- **Decrypt**: choose an encrypted file or paste an ASCII-armored message. GnuPG uses your secret key and may prompt for its passphrase. The plaintext appears in the terminal, saves by default to `Documents\Codex\wpgp\messages\decrypted-message.txt`, and asks you to confirm with `y` or `n` that you have read it.
- **Key pairs**: display public and secret key listings, or create a key pair. Key generation uses GnuPG defaults and may open pinentry.
- **Import public key**: choose filename search, direct path, or paste ASCII-armored key text. Imported keys enter your normal GnuPG keyring. The filename search checks the user profile, Desktop, and current directory recursively and shows matching paths.
- **Sign**: create a clear-signed message from typed text or a file using your secret key. The result saves by default to `Documents\Codex\wpgp\messages\signed-message.asc` and is shown for review.
- **Verify**: check a signed file or pasted message. Treat a valid signature as proof that the matching private key signed the data; independently verify the signer fingerprint to associate it with a person.
- **Export**: save an ASCII-armored copy of your public key to share.

The automatic-sign toggle is off at startup and lasts only for the current run. Option 6 toggles it and the menu shows its state. Type `exit` or `quit` at any wpgp prompt to cancel the current action and return to the menu; at the main menu either command quits. After an action, press Enter to return to the menu. Signing uses a secret/private key; recipients verify with the matching public key. Encryption uses the recipient public key and decryption requires its corresponding secret key.

## Registry wording

The app lists and imports keys in GnuPG's keyring. It does not inspect or edit the Windows Registry. The Windows Registry is unrelated to OpenPGP's public-key store.

## Uninstall

Remove the `Documents\Codex\wpgp` folder and remove that folder from your user `PATH`. This does not remove any GnuPG keys or messages.

## Troubleshooting

- **`gpg.exe` not found**: install Gpg4win, add its GnuPG `bin` folder to `PATH`, and restart PowerShell.
- **Scripts are disabled**: for a one-time install session, use `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`, then run the installer again. Follow your organization's policy on managed devices.
- **`wpgp` is not recognized**: open a new PowerShell window so it loads the updated `PATH`.
- **No key matches**: import the recipient's public key and confirm the email/fingerprint shown by `gpg --list-keys`.

## Security

Verify public-key fingerprints with their owners using another trusted channel. A key's presence in the keyring does not prove its identity. Protect secret keys and passphrases; losing a secret key can prevent decryption of older messages. Terminal scrollback may retain message text.

