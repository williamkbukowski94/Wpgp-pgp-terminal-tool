# wpgp

**wpgp** is a small terminal interface for GnuPG (GPG), built for people who know OpenPGP and want common tasks without memorizing command options. The repository contains the original Bash program for Linux and a Windows PowerShell version.

GnuPG performs all cryptographic operations. wpgp does not implement encryption itself and does not transmit messages or keys.

## Features

- Encrypt text to a recipient's imported public key; optionally sign while encrypting.
- Decrypt messages with a matching secret key.
- Generate and list public and secret keys.
- Import a public key from a file path, filename search, or pasted ASCII-armored text; export your public key.
- Create a clear-signed message and verify a signed message.
- Toggle automatic signing (off by default).

Signing requires your **secret/private key**. Recipients verify with your public key. Encryption uses the recipient's public key; decryption uses your matching secret key. Never share a secret key or passphrase.

## Windows PowerShell

### Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- GnuPG, available as `gpg.exe` on `PATH` (Gpg4win provides GnuPG)

### Install

Clone this repository, then run the installer from a PowerShell window:

```powershell
git clone https://github.com/williamkbukowski94/Wpgp-pgp-terminal-tool.git
cd Wpgp-pgp-terminal-tool
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\install-windows.ps1
```

The installer checks for GnuPG. If it is missing, it asks before downloading the official Gpg4win installer and opening its interactive setup. It installs wpgp into `Documents\Codex\wpgp`, creates a `wpgp.cmd` launcher, configures the current-user PATH, and applies execution-policy bypass only to the wpgp child process. Open a new PowerShell window and run:

```powershell
wpgp
```

The installer does not need administrator rights for wpgp itself. Gpg4win may request approval through Windows UAC. If Gpg4win installation is declined, wpgp is still installed but PGP operations remain unavailable until GnuPG is installed. To uninstall, remove `Documents\Codex\wpgp` and its user PATH entry.

### Windows menu

| Option | Action |
| --- | --- |
| 1 | Encrypt typed or file-based text for a recipient. Choose a key from your keyring, import a key file, or paste a key. |
| 2 | Decrypt an encrypted file or pasted armored message. The plaintext is shown in the terminal. |
| 3 | List public and secret key metadata in your GnuPG keyring. |
| 4 | Show the keyring and import a recipient public key from a filename search, path, or pasted armor. |
| 5 | Generate a key pair using GnuPG's standard defaults. |
| 6 | Toggle automatic signing; starts off each time wpgp launches and its state appears in the menu. |
| 7 | Clear-sign typed or file-based text with your secret key. |
| 8 | Verify a signed file or pasted message. |
| 9 | Export your public key to an ASCII-armored file. |

Messages and keys can be typed/pasted or read from a file where applicable. Multi-line text entry ends with a single period (`.`) on a line by itself. Generated encrypted/signed output and decrypted plaintext are shown in the terminal; confirm with `y` or `n` that you have read it. Type `exit` or `quit` at any wpgp prompt to return to the menu; at the main menu these commands quit. Choose option 6 and press Enter to toggle automatic signing. Filename search checks your user profile, Desktop, and current directory and shows full paths. The “keyring” is GnuPG's local key store, not the Windows Registry.

For more installation, security, and troubleshooting details, see [Windows installation](docs/INSTALL-WINDOWS.md).

## Linux / Bash

The existing `wpgp` Bash program and `install.sh` remain available. They require Bash 4+, GnuPG, and a terminal editor (`nano` by default). See the original [Linux usage and installation notes](docs/LINUX.md).

## Security notes

- GnuPG owns the key store, key generation, encryption, signing, verification, and decryption.
- Verify a public key's full fingerprint with its owner through a separate trusted channel before relying on it.
- wpgp does not establish key trust or certify identities for you.
- Protect and back up your secret keys. A lost secret key may make old encrypted messages unrecoverable.
- Message text is entered in the terminal and may remain in terminal scrollback. Avoid shared or recorded sessions.
- Decryption and key generation may invoke GnuPG's pinentry/passphrase prompt.

## Credits

Written by WB for all open source use.

