# Shell Non-Interactive Strategy Plugin

This Opencode plugin provides a set of rules and strategies to empower AI agents (specifically Gemini and other models less familiar with headless environments) to operate effectively in non-interactive shells.

## Purpose

Standard AI models often assume a human is watching the terminal or that they can use interactive tools like `nano`, `vim`, or answer "y/n" prompts. In a headless agentic environment (like Opencode), these actions cause the agent to hang and time out.

This plugin "patches" the agent's knowledge base with explicit instructions to:
- Always use non-interactive flags (e.g., `-y`, `--no-edit`).
- Bypass prompts using `yes |` or Heredocs.
- Avoid TTY-dependent tools (editors, pagers).

## Installation

1.  Clone this repository to your local machine:
    ```bash
    git clone https://github.com/your-username/shell-non-interactive-strategy.git ~/dev/oc-plugins/shell-non-interactive-strategy
    ```

2.  Add the rule file to your Opencode configuration (`~/.config/opencode/opencode.json`):

    ```json
    {
      "instructions": [
        "~/.config/opencode/rules.yaml",
        "~/dev/oc-plugins/shell-non-interactive-strategy/shell_strategy.md"
      ]
    }
    ```

## Usage

Once installed, the agent will automatically ingest these rules at the start of every session. You don't need to do anything else. The agent will seemingly "know" how to handle `npm init`, `git commit`, and other common blockers without getting stuck.
