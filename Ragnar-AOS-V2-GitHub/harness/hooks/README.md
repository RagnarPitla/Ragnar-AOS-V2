# Hooks — Claude Code Only

The shell scripts in this folder (`pre-tool-use.sh`, `post-tool-use.sh`, `stop.sh`, `user-prompt-submit.sh`) are **Claude Code hook scripts**. They rely on Claude Code's PreToolUse/PostToolUse/Stop/UserPromptSubmit hook system, which GitHub Copilot CLI does not support.

If you are using GitHub Copilot CLI, these scripts are inert. See [HOOKS-DEGRADED.md](../../HOOKS-DEGRADED.md) for what's lost and the manual alternatives.

If you are using Claude Code, register these hooks via `harness/settings.json.fragment` merged into `~/.claude/settings.json`.
