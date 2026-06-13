# Design Spec: Gemini Settings Persistence Fix

## Problem Statement
The "System Prompt" setting in `SettingsView.qml` uses `onEditingFinished` for saving, which only triggers when the `TextArea` loses focus. This is unreliable as users may close the settings view or switch windows without de-focusing the text area, leading to unsaved changes.

## Goals
- Ensure "System Prompt" changes are saved automatically and reliably.
- Provide a smooth user experience by debouncing saves while typing.
- Maintain consistency with existing `pluginApi` saving mechanisms.

## Proposed Changes

### 1. `SettingsView.qml`
Modify `/home/lis/.config/noctalia/plugins/gemini-panel/SettingsView.qml` to include:

#### Local State & Timer
- **Property:** `property string valueSystemPrompt`
  - Initialized from `pluginApi?.pluginSettings?.gemini?.appendSystemPrompt || ""`
- **Timer:** `saveTimer`
  - `interval: 500`
  - `repeat: false`
  - `onTriggered: root.saveSystemPromptNow()`
- **Function:** `saveSystemPromptNow()`
  - Calls `set("appendSystemPrompt", root.valueSystemPrompt)`

#### UI Component Update
- **TextArea:**
  - `text: root.valueSystemPrompt`
  - `onTextChanged:` Updates `root.valueSystemPrompt` and restarts `saveTimer` if the text has actually changed.
  - Remove `onEditingFinished`.

## Architecture & Data Flow
1. User types in `TextArea`.
2. `onTextChanged` triggers.
3. `root.valueSystemPrompt` is updated.
4. `saveTimer` is restarted (debouncing).
5. After 500ms of inactivity, `saveTimer` triggers `saveSystemPromptNow()`.
6. `saveSystemPromptNow()` calls `set()`, which updates `pluginApi.pluginSettings` and calls `pluginApi.saveSettings()`.

## Success Criteria
- Changes to the "System Prompt" are persisted after typing, without needing to lose focus.
- No performance issues from excessive saving (guaranteed by 500ms debounce).
- No data loss when closing the settings view immediately after typing.

## Testing Strategy
- Manual verification:
  1. Open Settings.
  2. Change "System Prompt".
  3. Close Settings (or switch view) without clicking elsewhere.
  4. Re-open Settings and verify the change persists.
