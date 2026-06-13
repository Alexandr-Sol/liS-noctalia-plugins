.pragma library

// AgyLogic.js — helpers for Agy CLI (`agy-bridge`) integration.
// Pure functions. No QML/Qt dependencies.

// Build argv for a per-turn `agy-bridge -p "<prompt>"` invocation.
function buildPerTurnCommand(settings, prompt, newSession, homeDir) {
  var bin = (settings && settings.binary) ? settings.binary : "agy-bridge";
  
  var args = [bin, "-p", prompt];

  if (newSession) {
    args.push("--new");
  }

  if (settings) {
    if (settings.sandbox) {
      args.push("--sandbox");
    }

    if (settings.dangerouslySkipPermissions) {
      args.push("--dangerously-skip-permissions");
    }
  }

  return {
    args: args,
    cwd: (settings && settings.workingDir) ? expandHome(settings.workingDir, homeDir) : ""
  };
}

function expandHome(path, home) {
  if (!path) { return path; }
  var s = String(path).trim();
  if (!home) { return s; }
  if (s === "~") { return home; }
  if (s.indexOf("~/") === 0) { return home + s.substring(1); }
  return s;
}

// Slash command parser — returns { action: string, args: string, handled: bool }
function parseSlashCommand(raw) {
  if (!raw || raw[0] !== "/") { return { handled: false }; }
  var parts = raw.trim().split(/\s+/);
  var cmd = parts[0].toLowerCase();
  var rest = parts.slice(1).join(" ");

  var known = ["/help", "/clear", "/new", "/stop", "/cwd", "/copy"];
  if (known.indexOf(cmd) === -1) { return { handled: false }; }

  return {
    handled: true,
    command: cmd.substring(1),
    args: rest
  };
}

// State persistence helpers.
function processLoadedState(content) {
  if (!content || String(content).trim() === "") { return null; }
  try {
    var c = JSON.parse(content);
    return {
      messages: c.messages || [],
      inputText: c.inputText || "",
      filteredTexts: c.filteredTexts || [],
      conversationId: c.conversationId || "",
      sessionWorkingDir: c.sessionWorkingDir || ""
    };
  } catch (err) {
    return { error: err.toString() };
  }
}

// Prepare the state for save - saves up to maxHistory messages.
function prepareStateForSave(state, maxHistory) {
  var max = maxHistory && maxHistory > 0 ? maxHistory : 200;
  var msgs = (state.messages || []).slice(-max);
  return JSON.stringify({
    messages: msgs,
    inputText: state.inputText || "",
    filteredTexts: state.filteredTexts || [],
    conversationId: state.conversationId || "",
    sessionWorkingDir: state.sessionWorkingDir || "",
    timestamp: Math.floor(Date.now() / 1000)
  }, null, 2);
}

function generateUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    var r = Math.random() * 16 | 0, v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

function extractPath(text) {
  if (!text) return "";
  var trimmed = text.trim();
  if (trimmed.indexOf("\n") !== -1) return "";
  
  var pathPattern = /^(\/|~\/|\.\/|\.\.\/)[^<>:"|?*]+$/;
  if (pathPattern.test(trimmed)) {
    return trimmed;
  }
  return "";
}
