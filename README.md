# Wpgp

Wpgp is a Bash front end for GnuPG. GnuPG performs all OpenPGP key, encryption, signature, and decryption operations; Wpgp provides an interactive terminal flow.

## Requirements

- Bash 4 or newer
- GnuPG (`gpg`)
- `nano` (or set `EDITOR`/`VISUAL` to another terminal editor) for paste/type mode

## Install for your user

Clone and install in one command (private repository access is required):

```bash
git clone https://github.com/williamkbukowski94/Wpgp-pgp-terminal-tool.git && cd Wpgp-pgp-terminal-tool && ./install.sh
```

If `~/.local/bin` is not already on your `PATH`, add this line to `~/.bashrc`, then open a new terminal:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Run `wpgp`. Do not use `sudo`: Wpgp should use your account's GnuPG keyring and agent.

## Use

- `wpgp` opens the menu.
- `wpgp encrypt` starts encryption with filename selection.
- `wpgp encrypt --manual` opens the editor for the public key and message.
- `wpgp decrypt` starts decryption with filename selection.
- `wpgp decrypt --manual` opens the editor for the encrypted message.
- `wpgp --help` shows command usage.
- `R` in the main menu imports a recipient public key and saves a contact label.
- Type `menu` and press Enter at any Wpgp text prompt to cancel the current action and return to the main menu.

Filename lookup searches recursively under your home folder. To restrict searches to particular folders, set `WPGP_SEARCH_DIRS` to a colon-separated list before starting Wpgp. For example:

```bash
WPGP_SEARCH_DIRS="$HOME/Documents/keys:$HOME/Documents/messages" wpgp
```

When there are duplicate filenames, Wpgp displays the matching paths and asks you to choose. Key files may be ASCII-armored `.asc` files or text files containing an ASCII-armored public key; no conversion is needed. A key that Wpgp imports is added to your regular GnuPG keyring.

## Key and signature behavior

- **Encrypt** displays public-key identities in a numbered list; select one by number. Press `R` at the menu to import a recipient key and associate a contact label. Imported keys are kept in your GnuPG keyring; labels are stored under `~/.config/wpgp/recipients.tsv`.
- **Decrypt** uses your regular GnuPG keyring. GnuPG reports signature status and signer identity when the message is signed. Verify the signer's full fingerprint independently before trusting that identity.
- **Display my keys** lists public keys and secret-key metadata. It does not print private key material.
- **Make a new key pair** adds a new pair and preserves existing keys. Existing private keys may be needed to decrypt old messages; back them up securely before removing them through GnuPG.

GnuPG may open its own passphrase prompt during signing, decryption, or key generation. Keep your private key protected by a strong passphrase. Wpgp uses permission-restricted temporary files and removes them when it exits, but terminal scrollback can retain displayed message contents. Saved output files are created with owner-only permissions and are not overwritten when the chosen filename already exists.

## Appearance

Wpgp uses ANSI green, red, and white styling in interactive terminals. The terminal controls its background color; set the terminal background to black for the intended look. Set `NO_COLOR=1` to disable styling.

The short opening animation shows a yellow-eyed tuxedo cat blinking beside a butterfly. Screens use a heavy double-line frame and the bold title “WPGP - Cryptographic Tool” on a black terminal background. Success messages use a green checkmark and “Completed!”; the author credit is `wb`.
