# Shell non-interactive strategy

**Context:** OpenCode's shell environment is non-interactive: it has no TTY/PTY, so commands that wait for input, launch a pager, or open an editor will hang until timeout. (Exception: interactive PTYs provided by `opencode-pty` or OpenCode's persistent terminals allow interactive programs; the rules below still apply to the default non-interactive `shell` tool.)

**Scope:** This file is a portable policy for headless agent environments. It is loaded by OpenCode as an instruction file. The rules apply to any comparable non-interactive shell, including OpenCode v2. OpenCode v2's `shell` tool runs a POSIX shell (fish and nu are rejected for the agent shell and remain terminal-only), so write POSIX-compatible commands.

## 1. Core rules

1. **No editors or pagers.** `vim`, `nano`, `less`, `more`, `man`, and similar TTY tools are banned.
2. **No interactive modes.** Avoid flags that open an interactive UI, such as `git add -p`, `git rebase -i`, or `bash -i`.
3. **Use command-specific non-interactive flags.** Prefer documented flags (`-y`, `--no-input`, `--no-edit`, `--no-pager`) over generic force.
4. **Fail fast on missing authorization.** When a command cannot run without a password or user choice, use a non-interactive fail-fast form or stop and report.
5. **Prefer OpenCode tools.** Use `Read`, `Write`, and `Edit` for file operations instead of shell text manipulation when they are available.
6. **Target a POSIX shell.** Write commands that run under any `/bin/sh`-compatible shell. Avoid shell-specific syntax such as fish `set`/`(cmd)` substitution, Nushell pipelines, or zsh-only globbing; do not rely on non-POSIX builtins.
7. **Quote defensively.** Wrap every variable expansion and filesystem path in double quotes (`"$var"`, `"$path"`) to prevent word splitting and globbing; single-quote literals that contain shell metacharacters. Never assume an unquoted token survives spaces, globs, or newlines.

### Portability and quoting

| Concern | Avoid | Prefer |
|---------|-------|--------|
| Shell-specific syntax | fish `set x 1`, `(cmd)`, nu pipelines | POSIX `x=1`, `$(cmd)` |
| Unquoted expansion | `cp $src $dst` | `cp "$src" "$dst"` |
| Unquoted paths | `rm $HOME/my dir/file` | `rm "$HOME/my dir/file"` |
| Literal metacharacters | `echo a|b` unquoted | `printf '%s\\n' 'a|b'` |

```bash
src="/path/with spaces/file.txt"
dst="/tmp/out.txt"
cp "$src" "$dst"
```

## 2. Handling prompts

When a command might prompt, choose one of these outcomes. Do not blanket-approve prompts with `yes | …` or heredocs.

### Authorized non-interactive flag

If the requested action is already authorized and the tool provides a non-interactive flag, use it.

```bash
apt-get install -y pkg
npm init -y
pip install --no-input pkg
```

### Fail-fast with non-interactive mode

If the requested action requires credentials or a user choice and the tool has a non-interactive mode that fails visibly, use it.

```bash
sudo -n command
ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 user@host
```

### Stop visibly

If the action is not authorized or no safe non-interactive form exists, stop and report that the operation needs user input, credentials, or a trusted host.

## 3. SSH and trust

For a new host that is explicitly trusted as a first contact, use `StrictHostKeyChecking=accept-new`. This accepts a previously unknown host key but refuses a changed host key.

```bash
ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 user@host
```

`StrictHostKeyChecking=no` is prohibited because it silently accepts changed host keys.

For file transfers, use the same SSH options:

```bash
scp -o BatchMode=yes -o StrictHostKeyChecking=accept-new file user@host:/path
```

## 4. Privileged commands

Use `sudo -n` to run a command only when it can succeed without a password. If the command requires a password, `sudo -n` exits with a non-zero status.

```bash
sudo -n systemctl status nginx
```

Do not pipe passwords to `sudo -S` or any other command.

## 5. Command reference

### Package managers

| Tool | Interactive (BAD) | Non-interactive (GOOD) |
|------|-------------------|------------------------|
| npm init | `npm init` | `npm init -y` |
| npm install | `npm install` (may need config) | `npm install` (non-interactive by default) |
| Yarn | `yarn install` | `yarn install --non-interactive` |
| PNPM | `pnpm install` | `pnpm install --reporter=silent` |
| Bun | `bun init` | `bun init -y` |
| Bun | `bun install` | `bun install` (non-interactive by default) |
| apt install | `apt-get install pkg` | `apt-get install -y pkg` |
| apt upgrade | `apt-get upgrade` | `apt-get upgrade -y` |
| pip install | `pip install pkg` | `pip install --no-input pkg` |
| Homebrew | `brew install pkg` | `HOMEBREW_NO_AUTO_UPDATE=1 brew install pkg` |

`npm install` is non-interactive by default. Use it directly; do not pass a blanket `--yes` or `--force` flag. `npm init -y` is the documented shorthand for `npm init --yes`.

### Git

| Action | Interactive (BAD) | Non-interactive (GOOD) |
|--------|-------------------|------------------------|
| commit | `git commit` | `git commit -m "msg"` |
| merge | `git merge branch` | `git merge --no-edit branch` |
| pull | `git pull` | `git pull --no-edit` |
| rebase | `git rebase -i` | `git rebase` |
| add | `git add -p` | `git add <file>` or `git add .` |
| stash pop | `git stash pop` (conflicts) | `git stash pop` (handle conflicts manually) |
| log | `git log` (pager) | `git --no-pager log` |
| diff | `git diff` (pager) | `git --no-pager diff` |

Git may invoke an editor for `commit` without `-m` and for `merge` or `pull` when a merge message must be edited. Use `--no-edit` to keep the generated message, or supply `-m`. Use `--no-pager` (or `git --no-pager <command>`) to avoid `less` in non-interactive environments.

### File operations

| Tool | Notes |
|------|-------|
| rm | `rm file` does not prompt by default. `rm -i file` prompts. `rm -f file` suppresses errors and never prompts. Verify the target before running destructive commands. |
| cp | `cp -i a b` prompts before overwrite. Use `cp a b` if you accept the default, or `cp -f a b` if overwrite is intended. |
| mv | `mv -i a b` prompts before overwrite. Use `mv a b` if you accept the default, or `mv -f a b` if overwrite is intended. |
| unzip | `unzip -o file.zip` overwrites existing files without prompting. |
| tar | `tar xf file.tar` is usually non-interactive. |

### System and network

| Tool | Interactive (BAD) | Non-interactive (GOOD) |
|------|-------------------|------------------------|
| scp | `scp file host:` | `scp -o BatchMode=yes file host:` |
| curl | `curl url` | `curl -fsSL url` |
| wget | `wget url` | `wget -q url` |

### Docker

| Action | Interactive (BAD) | Non-interactive (GOOD) |
|--------|-------------------|------------------------|
| run | `docker run -it image` | `docker run image` |
| exec | `docker exec -it container bash` | `docker exec container cmd` |
| build | `docker build .` | `docker build --progress=plain .` |
| compose | `docker-compose up` | `docker-compose up -d` |

### REPLs

| Tool | Interactive (BAD) | Non-interactive (GOOD) |
|------|-------------------|------------------------|
| python | `python` | `python -c "code"` or `python script.py` |
| node | `node` | `node -e "code"` or `node script.js` |
| ipython | `ipython` | Never use; use `python -c` |

## 6. OpenCode specifics

- The `shell` tool is non-interactive: stdin is ignored, so commands cannot read prompts.
- Prefer the tool's own options over wrapping: set `workdir` instead of `cd`, `timeout` (milliseconds) for long commands, and `background` for dev servers or long-running processes.
- OpenCode v2 permissions use the `shell` action (not `bash`); scope rules by command string.
- These rules target the non-interactive `shell` tool. Interactive PTYs (opencode-pty, persistent terminals) can run interactive programs, but the banned/destructive guidance still applies.

## 7. Cross-platform notes

- **Windows:** the shell tool runs PowerShell with `-NonInteractive`. Prefer PowerShell-native non-interactive forms and set `$ProgressPreference = 'SilentlyContinue'` to avoid progress streams.
- **cmd.exe:** use `set VAR=value &&` prefixes and avoid interactive `pause`/`choice`.
- **Shell detection:** detect the active shell (Unix via `SHELL`, PowerShell via `PSModulePath`) rather than assuming bash; apply restrictive settings only in non-interactive contexts.

## 8. Optional per-command environment variables

These variables can be set for a single command when the tool does not provide a dedicated flag. They are not required and should not be set globally as an anti-hang technique.

| Variable | Value | Effect |
|----------|-------|--------|
| `GIT_TERMINAL_PROMPT` | `0` | Disable git HTTP password prompts |
| `DEBIAN_FRONTEND` | `noninteractive` | Suppress apt/dpkg UI prompts |
| `PIP_NO_INPUT` | `1` | Disable pip interactive prompts |
| `HOMEBREW_NO_AUTO_UPDATE` | `1` | Disable homebrew auto-update during install |

Example:

```bash
GIT_TERMINAL_PROMPT=0 git clone https://github.com/example/repo.git
```

## 9. Source references

- Git: [git-commit](https://git-scm.com/docs/git-commit), [git-merge](https://git-scm.com/docs/git-merge), [git-pull](https://git-scm.com/docs/git-pull), [git-rebase](https://git-scm.com/docs/git-rebase); `--no-edit`, `--no-pager`, `-m`.
- OpenSSH: [ssh_config(5)](https://man.openbsd.org/ssh_config) — `BatchMode`, `StrictHostKeyChecking`, `ConnectTimeout`.
- sudo: [sudo(8)](https://www.sudo.ws/docs/man/sudo.man/) — `-n` non-interactive mode.
- npm: [npm init](https://docs.npmjs.com/cli/v11/commands/npm-init) (`npm init -y`) and [npm install](https://docs.npmjs.com/cli/v11/commands/npm-install) (`npm install` has no `--yes`).
- rm: [POSIX rm](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/rm.html) — default is non-interactive; `-i` prompts; `-f` ignores errors and prompts.
- OpenCode: instructions are loaded from the `instructions[]` array in [opencode.json/opencode.jsonc](https://opencode.ai/docs/config/); see also [Rules](https://opencode.ai/docs/rules/).
