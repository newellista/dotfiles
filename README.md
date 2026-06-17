# dotfiles

Personal configuration for zsh, vim, tmux, git, and a few CLI / agent tools,
kept in one repo and linked into place. Secrets stay out of git; everything
else is reproducible on a new machine.

## How config reaches the tools

Three mechanisms are in play. Knowing which applies tells you how a file gets
to its tool — in all cases you **edit the copy here in the repo**.

| Mechanism | Applies to | How it works |
|---|---|---|
| **Home symlink** | top-level dotfiles (`.zshrc`, `.gitconfig`, `.tmux.conf`, …), `vim/`, `tmux/`, `.zsh/` | `init_dot_files.sh` links each to `~/.<name>` |
| **`XDG_CONFIG_HOME`** | `config/gh`, `config/ghostty`, `config/cursor` | `.zshrc` sets `XDG_CONFIG_HOME=$HOME/dotfiles/config`, so XDG-aware tools read straight from there — no symlink needed |
| **Agent skill dirs** | `skills/` | each skill is symlinked into `~/.claude/skills/` and/or `~/.cursor/skills/` |

## Bootstrap a new machine

1. **Clone with submodules** (vim/tmux plugins are submodules):
   ```sh
   git clone --recursive https://github.com/newellista/dotfiles.git ~/dotfiles
   # already cloned without --recursive?
   git -C ~/dotfiles submodule update --init --recursive
   ```
2. **Create the symlinks:**
   ```sh
   ~/dotfiles/init_dot_files.sh
   ```
   Links the top-level dotfiles, `vim/`/`tmux/`/`.zsh/`, and the shared agent
   skills (per `skills/targets.conf`), initializes plugin submodules, and reports
   any expected tools that are missing. Idempotent — safe to re-run; an existing
   real file is backed up to `<name>.bak` before being replaced.
3. **Install any tools** the previous step flagged as missing (oh-my-zsh,
   starship, fzf, ripgrep, asdf, tmux). In tmux, press `prefix + I` to install
   plugins via tpm.
4. **Recreate secrets** — see [Secrets](#secrets).
5. **Vim helptags:** open `vim`, run `:helptags ALL`.
6. **Re-authenticate tooling** (never stored in this repo): `gh auth login`, and
   re-auth any MCP servers from inside Claude Code (`/mcp`).

## Secrets

API keys and tokens never go in tracked files. They live in `~/.global.env`
(gitignored), which `.zshrc` sources at the end:

```sh
export SOME_API_KEY=...
```

`config/gh/hosts.yml` (which can hold a `gh` OAuth token after `gh auth login`)
is also gitignored. Auth that lives in the macOS Keychain (Claude Code login, etc.) is
re-established per machine, not synced.

## Skills (Claude Code / Cursor)

`skills/` is the single source of truth for agent skills shared between Claude
Code and Cursor — both use the same `SKILL.md` format, so one file serves both.
Each skill is symlinked into the tool's skill directory:

```sh
ln -sfn ~/dotfiles/skills/pr-summary ~/.claude/skills/pr-summary
ln -sfn ~/dotfiles/skills/pr-summary ~/.cursor/skills/pr-summary
```

`skills/targets.conf` declares which tools each skill links into;
`init_dot_files.sh` creates the links from it (use `ln -sfn` for any manual
one-off). Keep tool-specific skills (anything that hard-codes one tool's
mechanics) out of `skills/` — link those directly into the one tool instead.

## Vim / tmux plugins (git submodules)

Vim plugins use Vim 8's native package feature under `vim/pack/newellista/`.

Add a plugin:
```sh
git submodule add https://github.com/owner/foo.git vim/pack/newellista/start/foo
git commit -m "Add vim plugin foo"
```

Update all plugins (review before committing — submodule bumps show up as changes
in this repo):
```sh
git submodule foreach git pull origin master
git commit -am "Update plugins"
```

tmux plugins are managed by **tpm** (`tmux/plugins/tpm`, itself a submodule). The
other directories under `tmux/plugins/` are installed by tpm at runtime and are
gitignored.

## Gotchas

- **`XDG_CONFIG_HOME` is `dotfiles/config/`.** XDG-aware tools read *and write*
  there, so runtime state they drop (e.g. `config/configstore/`) is gitignored.
  Keeping it in a dedicated subdir rather than the repo root isolates those
  writes from the repo's own files.
- **Two gitignores.** Universal patterns live in `.gitignore_global` (wired up
  as `core.excludesfile`); repo-specific patterns stay in `.gitignore`. Don't
  move repo-specific patterns (`tmux/*`, `.tool-versions`, …) into the global
  file — they'd then hide matching files in every repo on the machine.

---
Vim package layout adapted from this [gist](https://gist.github.com/manasthakur/d4dc9a610884c60d944a4dd97f0b3560).
