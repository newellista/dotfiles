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
| **`XDG_CONFIG_HOME`** | `gh/`, `ghostty/`, `cursor/` | `.zshrc` sets `XDG_CONFIG_HOME=$HOME/dotfiles`, so XDG-aware tools read straight from here — no symlink needed |
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
   Links the top-level dotfiles plus `vim/` and `tmux/`. It does **not** yet link
   `.zsh/` or the `skills/` entries — do those manually for now (see Gotchas).
3. **Install the tools the configs expect:** oh-my-zsh, starship, fzf, ripgrep,
   asdf, tmux. In tmux, press `prefix + I` to install plugins via tpm.
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

`gh/hosts.yml` (which can hold a `gh` OAuth token after `gh auth login`) is also
gitignored. Auth that lives in the macOS Keychain (Claude Code login, etc.) is
re-established per machine, not synced.

## Skills (Claude Code / Cursor)

`skills/` is the single source of truth for agent skills shared between Claude
Code and Cursor — both use the same `SKILL.md` format, so one file serves both.
Each skill is symlinked into the tool's skill directory:

```sh
ln -sfn ~/dotfiles/skills/pr-summary ~/.claude/skills/pr-summary
ln -sfn ~/dotfiles/skills/pr-summary ~/.cursor/skills/pr-summary
```

Use `ln -sfn` (force, no-dereference) so the link can't accidentally nest inside
an existing directory. Keep tool-specific skills (anything that hard-codes one
tool's mechanics) out of `skills/`.

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

- **Global git excludes.** `core.excludesfile` currently points at this repo's
  `.gitignore` (via `~/.gitignore`), so repo-specific patterns here (`tmux/*`,
  `configstore/`, `gh/hosts.yml`) apply as ignores in *every* repo on the
  machine. Splitting a dedicated `.gitignore_global` out is on the TODO list.
- **`XDG_CONFIG_HOME` is the repo root.** XDG-aware tools therefore read *and
  write* here; runtime state they drop (e.g. `configstore/`) gets gitignored as
  it appears.

---
Vim package layout adapted from this [gist](https://gist.github.com/manasthakur/d4dc9a610884c60d944a4dd97f0b3560).
