# Shell Non-Interactive Strategy (Global)

**Context:** Opencode's shell environment is strictly **non-interactive**. It lacks a TTY/PTY, meaning any command that waits for user input, confirmation, or launches a UI (editor/pager) will hang indefinitely and timeout.

**Goal:** Achieve parity with Claude's shell capabilities by internalized knowledge of non-interactive flags.

## 1. Core Mandates
1.  **Assume `CI=true`**: Act as if running in a headless CI/CD pipeline.
2.  **No Editors/Pagers**: `vim`, `nano`, `less`, `more`, `man`, `git log` (without config) are BANNED.
3.  **Force & Yes**: Always preemptively supply "yes" or "force" flags.
4.  **Use Tools**: Prefer `Read`/`Write`/`Edit` tools over shell manipulation (`sed`, `echo`, `cat`).

## 2. Command Reference

### Package Managers
| Tool | Interactive (BAD) | Non-Interactive (GOOD) |
|------|-------------------|------------------------|
| **NPM** | `npm init` | `npm init -y` |
| **NPM** | `npm install` | `npm install --yes` |
| **APT** | `apt-get install pkg` | `apt-get install -y pkg` |
| **PIP** | `pip install pkg` | `pip install --no-input pkg` |
| **Python** | `python` | `python -c "code"` |

### Git Operations
| Action | Interactive (BAD) | Non-Interactive (GOOD) |
|--------|-------------------|------------------------|
| **Commit** | `git commit` | `git commit -m "msg"` |
| **Merge** | `git merge branch` | `git merge --no-edit branch` |
| **Pull** | `git pull` | `git pull --no-edit` |
| **Add** | `git add -p` | `git add .` |

### System & Files
| Tool | Interactive (BAD) | Non-Interactive (GOOD) |
|------|-------------------|------------------------|
| **RM** | `rm file` | `rm -f file` |
| **CP** | `cp a b` | `cp -f a b` |
| **Unzip**| `unzip file.zip` | `unzip -o file.zip` |
| **SSH** | `ssh host` | `ssh -o BatchMode=yes host` |

## 3. Handling Prompts
If a flag doesn't exist, use pipes or Heredocs.

**The "Yes" Pipe:**
```bash
yes | ./install_script.sh
```

**Heredoc Input:**
```bash
./configure.sh <<EOF
option1
option2
EOF
```
