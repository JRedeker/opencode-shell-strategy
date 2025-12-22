# opencode-shell-strategy

OpenCode instructions for non-interactive shell commands - prevents hangs from TTY-dependent operations.

## Problem

OpenCode's shell environment is strictly **non-interactive**. It lacks a TTY/PTY, meaning any command that waits for user input, confirmation, or launches a UI (editor/pager) will hang indefinitely and timeout.

Standard AI models often assume a human is watching the terminal or that they can use interactive tools like `nano`, `vim`, or answer "y/n" prompts. In OpenCode's headless environment, these actions cause the agent to hang.

## Solution

This plugin provides instructions that teach the LLM to:
- Always use non-interactive flags (e.g., `-y`, `--no-edit`)
- Bypass prompts using `yes |` or heredocs
- Avoid TTY-dependent tools (editors, pagers)
- Prefer OpenCode's native tools (`Read`/`Write`/`Edit`) over shell manipulation

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/JRedeker/opencode-shell-strategy.git ~/.config/opencode/plugin/shell-strategy
```

### 2. Add to OpenCode config

Add the instruction file to your `~/.config/opencode/opencode.json`:

```json
{
  "instructions": [
    "~/.config/opencode/plugin/shell-strategy/shell_strategy.md"
  ]
}
```

### 3. Restart OpenCode

The rules will be automatically loaded at the start of every session.

## What It Covers

### Package Managers
| Tool | Bad (hangs) | Good |
|------|-------------|------|
| npm | `npm init` | `npm init -y` |
| apt | `apt-get install pkg` | `apt-get install -y pkg` |
| pip | `pip install pkg` | `pip install --no-input pkg` |

### Git Operations
| Action | Bad (hangs) | Good |
|--------|-------------|------|
| Commit | `git commit` | `git commit -m "msg"` |
| Merge | `git merge branch` | `git merge --no-edit branch` |
| Add | `git add -p` | `git add .` |

### System Commands
| Tool | Bad (hangs) | Good |
|------|-------------|------|
| rm | `rm file` (prompts) | `rm -f file` |
| ssh | `ssh host` | `ssh -o BatchMode=yes host` |
| unzip | `unzip file.zip` | `unzip -o file.zip` |

### Banned Commands
These will always hang - never use them:
- `vim`, `nano`, `vi` (editors)
- `less`, `more`, `man` (pagers)
- `git add -p`, `git rebase -i` (interactive modes)
- `python` without `-c` flag (REPL)

## License

MIT
