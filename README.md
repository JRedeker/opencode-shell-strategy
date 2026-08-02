# opencode-shell-strategy

OpenCode instructions for running shell commands safely in a non-interactive environment.

OpenCode's shell is non-interactive: it has no TTY/PTY, so commands that wait for input, launch a pager, or open an editor will hang until timeout. These instructions teach an agent to use command-specific non-interactive forms, fail fast when authorization is missing, and avoid unsafe patterns that bypass security controls.

The rules are written for OpenCode and apply to any comparable headless agent host.

## Installation

Add the remote instruction file to your OpenCode configuration:

```json
{
  "instructions": [
    "https://raw.githubusercontent.com/JRedeker/opencode-shell-strategy/trunk/shell_strategy.md"
  ]
}
```

Restart OpenCode. The rules load automatically at the start of each session.

A local clone is optional. If you want to edit or contribute, clone the repository and point your config at the local `shell_strategy.md` path instead.

## What it covers

### Safe non-interactive forms

| Tool | Avoid | Use |
|------|-------|-----|
| npm init | `npm init` | `npm init -y` |
| apt install | `apt-get install pkg` | `apt-get install -y pkg` |
| pip install | `pip install pkg` | `pip install --no-input pkg` |
| git commit | `git commit` | `git commit -m "msg"` |
| git merge | `git merge branch` | `git merge --no-edit branch` |
| git pull | `git pull` | `git pull --no-edit` |
| rm | `rm -i file` | `rm file` (no `-i`) |
| ssh first contact | `ssh host` | `ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 user@host` |

### Always-banned commands

These hang or break autonomy in a non-interactive shell:

- `vim`, `nano`, `vi`, `emacs` (editors)
- `less`, `more`, `man` (pagers)
- `git add -p`, `git rebase -i` (interactive git modes)
- `python`, `node`, `ipython`, `irb` without a script or `-c`/`-e` argument (REPLs)
- `bash -i`, `zsh -i` (interactive shells)

### Handling commands that must prompt

Do not use `yes | …` or heredocs to blanket-approve unknown prompts. If a command has no non-interactive flag, choose one of:

1. **Use a documented non-interactive flag.** Example: `apt-get install -y pkg`.
2. **Fail fast with a non-interactive mode.** Example: `sudo -n command` exits immediately if a password is required.
3. **Stop visibly.** Report that the operation needs credentials, user approval, or a trusted host, and do not proceed.

### SSH and new hosts

For an explicitly trusted first contact, use `StrictHostKeyChecking=accept-new` with a short timeout:

```bash
ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 user@host
```

If a host key changes, the command fails. Do not use `StrictHostKeyChecking=no`.

### Privileged commands

Use `sudo -n` to run a command only when it needs no password:

```bash
sudo -n systemctl status nginx
```

If the command requires a password, `sudo -n` fails immediately. Do not pipe passwords into `sudo -S`.

## License

MIT

## Release notes

### v1.1.0

- Safer guidance for commands that need authorization: prefer `sudo -n` so failures are visible instead of hanging, and do not pipe passwords into `sudo -S`.
- Safer SSH first-contact guidance: use `StrictHostKeyChecking=accept-new` with a short timeout and `BatchMode=yes` instead of disabling host-key checks.
- Added a dependency-free verification script (`test.sh verify`) so the rule set can be checked without installing extra tools.
- No new runtime dependencies were introduced.
