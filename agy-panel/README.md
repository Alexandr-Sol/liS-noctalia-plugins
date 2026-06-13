# Agy Panel

[English](README.md) | [Русский](README.ru.md)

---

A Noctalia Shell plugin that integrates Antigravity CLI (via `agy-bridge`) as a sidebar chat panel.

---

## Dependencies & Requirements

* `antigravity-cli` (provides the `agy` CLI)
* `wl-clipboard` (provides `wl-paste` and `wl-copy` for Wayland clipboard support)
* `python` (for running the bridge script)

## Features

- Scrollable chat with streaming responses (Flickable + Column — no scroll artifacts)
- Copy button on every message
- Paste from clipboard button
- Session continuity automatically managed by the CLI
- Sandbox and Auto-approval toggles
- Adaptive colors from the shell theme

## Commands

| Command | Description |
|---------|-------------|
| `/help` | Show available commands |
| `/clear` | Clear local chat history |
| `/new` | Start a new session |
| `/stop` | Stop current generation |
| `/copy` | Copy last assistant message |
| `/cwd <path>` | Set working directory |

## IPC

```sh
qs -c noctalia-shell ipc call plugin:agy-panel toggle
qs -c noctalia-shell ipc call plugin:agy-panel send "Hello"
qs -c noctalia-shell ipc call plugin:agy-panel newSession
```
