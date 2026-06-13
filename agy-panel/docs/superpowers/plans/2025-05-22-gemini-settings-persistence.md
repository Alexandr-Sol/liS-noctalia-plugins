# Gemini Settings Persistence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the unreliable "System Prompt" setting persistence by implementing a debounced auto-save mechanism in `SettingsView.qml`.

**Architecture:** Introduce a local property for current state, a 500ms debounce timer for saves, and update the UI to bind to this local state while triggering the timer on changes.

**Tech Stack:** QML (Qt Quick), Quickshell Plugin API.

---

### Task 1: Add Local State and Timer to `SettingsView.qml`

**Files:**
- Modify: `/home/lis/.config/noctalia/plugins/gemini-panel/SettingsView.qml`

- [ ] **Step 1: Add `valueSystemPrompt` property and `saveTimer`**

Add these to the root `Item` of `SettingsView.qml`.

```qml
// Inside root Item
property string valueSystemPrompt: pluginApi?.pluginSettings?.gemini?.appendSystemPrompt || ""

Timer {
    id: saveTimer
    interval: 500
    repeat: false
    onTriggered: root.saveSystemPromptNow()
}

function saveSystemPromptNow() {
    set("appendSystemPrompt", root.valueSystemPrompt);
}
```

- [ ] **Step 2: Commit changes**

```bash
git add /home/lis/.config/noctalia/plugins/gemini-panel/SettingsView.qml
git commit -m "feat: add local state and save timer for system prompt"
```

---

### Task 2: Update `TextArea` to use Local State and Debounce

**Files:**
- Modify: `/home/lis/.config/noctalia/plugins/gemini-panel/SettingsView.qml`

- [ ] **Step 1: Update `TextArea` bindings**

Find the `TextArea` inside the "Системный промпт" section and update it.

```qml
// Replace existing TextArea content
TextArea {
    anchors.fill: parent
    anchors.margins: Style.marginS
    text: root.valueSystemPrompt // Bind to local property
    color: Color.mOnSurface
    font.pointSize: Style.fontSizeS
    wrapMode: TextArea.Wrap
    onTextChanged: {
        if (text !== root.valueSystemPrompt) {
            root.valueSystemPrompt = text;
            saveTimer.restart();
        }
    }
    // onEditingFinished: set("appendSystemPrompt", text) // REMOVE THIS
    background: null
}
```

- [ ] **Step 2: Commit changes**

```bash
git add /home/lis/.config/noctalia/plugins/gemini-panel/SettingsView.qml
git commit -m "feat: update TextArea to use debounced saving"
```

---

### Task 3: Verification

- [ ] **Step 1: Manual verification**

1. Open the Gemini settings panel.
2. Type a new system prompt in the text area.
3. Wait for ~1 second (to ensure timer triggers).
4. Close the settings panel or switch to another view without clicking away from the text area.
5. Re-open the settings panel and verify the text is persisted.

- [ ] **Step 2: Cleanup (Optional)**
Remove the design and plan docs if no longer needed (or keep them as documentation).
