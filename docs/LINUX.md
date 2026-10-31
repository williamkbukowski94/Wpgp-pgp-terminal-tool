# Linux / Bash version

The root-level `wpgp` executable is the original Bash front end for GnuPG. It requires Bash 4 or newer, GnuPG, and `nano` (or a compatible terminal editor through `EDITOR`/`VISUAL`).

Install for the current user:

```bash
./install.sh
```

The installer places the command in `~/.local/bin`. Add that directory to `PATH` if needed:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Use `wpgp` for the menu. `wpgp --help` lists command options. The Linux version's contact labels and GnuPG keyring behavior are documented in the source README history; the Windows version has its own [installation guide](INSTALL-WINDOWS.md).

