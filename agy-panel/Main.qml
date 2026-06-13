import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import "AgyLogic.js" as Logic

Item {
  id: root

  property var pluginApi: null

  // ----- Conversation state -----
  property var messages: []
  property bool isGenerating: false
  property string errorMessage: ""
  property bool isManuallyStopped: false
  property string currentAssistantBuffer: ""
  property bool sawPartialThisTurn: false

  // ----- Session / State flags -----
  property string conversationId: ""
  property string sessionWorkingDir: ""

  // ----- Input persistence -----
  property string inputText: ""
  property string pastedText: ""
  property var pastedImagePaths: []

  // ----- CLI health -----
  property bool binaryAvailable: false
  property bool binaryChecked: false
  readonly property string pluginDir: {
    var url = Qt.resolvedUrl(".").toString();
    if (url.indexOf("file://") === 0) {
      url = url.substring(7);
    }
    return url;
  }
  readonly property string resolvedBinaryPath: pluginDir + "agy-bridge"

  // ----- Cache paths -----
  readonly property string cacheDir: (typeof Settings !== 'undefined' && Settings.cacheDir)
      ? Settings.cacheDir + "plugins/agy-panel/" : ""
  readonly property string stateCachePath: cacheDir + "state.json"

  // ----- Settings accessors -----
  readonly property var agySettings: pluginApi?.pluginSettings?.agy || ({})
  readonly property string workingDir: agySettings.workingDir || ""

  Component.onCompleted: {
    Logger.i("AgyPanel", "Plugin initialized");
    ensureCacheDir();
    checkBinary();
  }

  Component.onDestruction: {
    root.performSaveState(true);
  }

  function ensureCacheDir() {
    if (cacheDir) { Quickshell.execDetached(["mkdir", "-p", cacheDir]); }
  }

  // ---------- Binary presence check ----------
  Process {
    id: checkLocalProcess
    command: ["test", "-x", root.resolvedBinaryPath]
    onExited: function (exitCode, exitStatus) {
      root.binaryAvailable = (exitCode === 0);
      root.binaryChecked = true;
      if (root.binaryAvailable) {
        Logger.i("AgyPanel", "Using local agy-bridge: " + root.resolvedBinaryPath);
      } else {
        Logger.w("AgyPanel", "Local agy-bridge at " + root.resolvedBinaryPath + " is not executable or not found.");
      }
    }
  }

  function checkBinary() {
    binaryChecked = false;
    checkLocalProcess.running = true;
  }

  // ---------- State persistence ----------
  FileView {
    id: stateCacheFile
    path: root.stateCachePath
    watchChanges: false
    onLoaded: loadStateFromCache()
    onLoadFailed: function (error) {
      if (error !== 2) { Logger.e("AgyPanel", "state load failed: " + error); }
    }
  }

  function loadStateFromCache() {
    var result = Logic.processLoadedState(stateCacheFile.text());
    if (!result || result.error) {
      if (result && result.error) { Logger.e("AgyPanel", "state parse: " + result.error); }
      root.conversationId = Logic.generateUUID();
      root.isGenerating = false;
      return;
    }
    root.messages = result.messages;
    root.inputText = result.inputText;
    root.conversationId = result.conversationId || Logic.generateUUID();
    root.sessionWorkingDir = result.sessionWorkingDir || "";
    root.isGenerating = false;
  }

  Timer {
    id: saveStateTimer
    interval: 500
    onTriggered: root.performSaveState(false)
  }
  property bool saveStateQueued: false

  function saveState() {
    saveStateQueued = true;
    saveStateTimer.restart();
  }

  function performSaveState(force) {
    if (!force && (!saveStateQueued || !cacheDir)) { return; }
    saveStateQueued = false;
    try {
      ensureCacheDir();
      var maxHistory = pluginApi?.pluginSettings?.maxHistoryLength || 200;
      var data = Logic.prepareStateForSave({
        messages: root.messages,
        inputText: root.inputText,
        conversationId: root.conversationId,
        sessionWorkingDir: root.sessionWorkingDir
      }, maxHistory);
      stateCacheFile.setText(data);
    } catch (e) {
      Logger.e("AgyPanel", "state save: " + e);
    }
  }

  // ---------- Message helpers ----------
  function pushMessage(entry) {
    var withMeta = Object.assign({
      id: Date.now().toString() + "-" + Math.random().toString(36).slice(2, 6),
      timestamp: Date.now()
    }, entry);
    root.messages = [...root.messages, withMeta];
    saveState();
    return withMeta;
  }

  function clearMessages() {
    root.messages = [];
    root.currentAssistantBuffer = "";
    performSaveState(true);
  }

  function _indexOfMessage(id) {
    for (var i = root.messages.length - 1; i >= 0; i--) {
      if (root.messages[i].id === id) return i;
    }
    return -1;
  }

  function _replaceMessageAt(i, updated) {
    root.messages = [...root.messages.slice(0, i), updated, ...root.messages.slice(i + 1)];
  }

  // Force active focus on chat view input
  signal forceInputFocus()

  function appendToStreaming(text) {
    if (!text) { return; }
    root.currentAssistantBuffer += text;
  }

  function finalizeStreaming() {
    var text = root.currentAssistantBuffer;
    root.currentAssistantBuffer = "";
    if (text && text.trim() !== "") {
      pushMessage({ role: "assistant", kind: "text", text: text });
    }
  }

  function newSession(customWorkingDir) {
    stopProcess();
    root.conversationId = Logic.generateUUID();
    root.messages = [];
    root.currentAssistantBuffer = "";
    root.errorMessage = "";
    root.sessionWorkingDir = customWorkingDir || "";
    performSaveState(true);
    showNotice(pluginApi?.tr("toast.newSessionStarted") || "Новая сессия Agy начата");
    root.forceInputFocus();
  }

  // ---------- Per-turn process ----------
  Process {
    id: agyProcess

    property string stderrBuffer: ""

    stdout: SplitParser {
      onRead: function (line) {
        root.appendToStreaming(line + "\n");
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        if (text && text.trim() !== "") {
          Logger.w("AgyPanel", "agy stderr: " + text);
          agyProcess.stderrBuffer = text;
        }
      }
    }

    property bool didStart: false
    onStarted: {
      didStart = true;
      startWatchdog.stop();
      Logger.i("AgyPanel", "agy process started (pid=" + agyProcess.processId + ")");
    }

    onExited: function (exitCode, exitStatus) {
      Logger.i("AgyPanel", "agy exited code=" + exitCode + " status=" + exitStatus);
      root.onProcessExited(exitCode);
    }
  }

  Timer {
    id: startWatchdog
    interval: 2000
    repeat: false
    onTriggered: {
      if (!agyProcess.didStart) {
        Logger.e("AgyPanel", "agy failed to start within 2s");
        root.isGenerating = false;
        root.errorMessage = "Agy failed to launch. Check bridge script path.";
        showError(root.errorMessage);
        if (agyProcess.running) { agyProcess.running = false; }
      }
    }
  }

  function stopProcess() {
    if (agyProcess.running) { agyProcess.running = false; }
  }

  onResolvedBinaryPathChanged: {
    // Keep it clean
  }

  function onProcessExited(exitCode) {
    var wasGenerating = root.isGenerating;
    if (root.isManuallyStopped) {
      root.isManuallyStopped = false;
      root.isGenerating = false;
      finalizeStreaming();
      return;
    }
    root.isGenerating = false;
    finalizeStreaming();
    if (wasGenerating && exitCode !== 0 && root.errorMessage === "") {
      var reason = agyProcess.stderrBuffer && agyProcess.stderrBuffer.trim() !== ""
        ? agyProcess.stderrBuffer.trim()
        : (pluginApi?.tr("errors.runFailed") || "Ошибка запуска Agy");
      root.errorMessage = reason;
    }
    agyProcess.stderrBuffer = "";
    root.saveState();
  }

  // ---------- Sending ----------
  function sendMessage(userText) {
    if (!userText || userText.trim() === "") { return; }
    if (!binaryAvailable) {
      root.errorMessage = pluginApi?.tr("errors.binaryMissing") || "Agy-bridge not found";
      showError(root.errorMessage);
      return;
    }
    if (root.isGenerating || agyProcess.running) {
      root.errorMessage = pluginApi?.tr("errors.busy") || "Agy is busy";
      return;
    }

    var text = userText.trim();
    pushMessage({ role: "user", kind: "text", text: text });

    root.isGenerating = true;
    root.isManuallyStopped = false;
    root.errorMessage = "";
    root.currentAssistantBuffer = "";
    agyProcess.stderrBuffer = "";

    if (!root.conversationId) {
      root.conversationId = Logic.generateUUID();
    }
    performSaveState(true);

    var home = Quickshell.env("HOME") || "";
    var isNewSession = true;
    for (var i = 0; i < root.messages.length; i++) {
      if (root.messages[i].role === "assistant") {
        isNewSession = false;
        break;
      }
    }

    var promptText = text;
    var defaultPrompt = (agySettings && agySettings.defaultPrompt) ? agySettings.defaultPrompt.trim() : "";
    if (isNewSession && defaultPrompt !== "") {
      promptText = defaultPrompt + "\n\n" + promptText;
    }

    var cmd = Logic.buildPerTurnCommand(agySettings, promptText, isNewSession, home);
    if (root.resolvedBinaryPath && cmd.args.length > 0) {
      cmd.args[0] = root.resolvedBinaryPath;
    }
    Logger.i("AgyPanel", "spawn: " + JSON.stringify(cmd.args));
    agyProcess.command = cmd.args;
    var effectiveCwd = "";
    if (root.sessionWorkingDir && root.sessionWorkingDir.trim() !== "") {
      effectiveCwd = Logic.expandHome(root.sessionWorkingDir, home);
    } else if (cmd.cwd && cmd.cwd.trim() !== "") {
      effectiveCwd = cmd.cwd;
    }

    if (effectiveCwd !== "") {
      agyProcess.workingDirectory = effectiveCwd;
    } else {
      agyProcess.workingDirectory = home || "/tmp";
    }
    agyProcess.didStart = false;
    agyProcess.running = true;
    startWatchdog.restart();
  }

  function stopGeneration() {
    if (!agyProcess.running) {
      root.isGenerating = false;
      finalizeStreaming();
      return;
    }
    root.isManuallyStopped = true;
    stopProcess();
    root.isGenerating = false;
    finalizeStreaming();
    showNotice(pluginApi?.tr("toast.stopped") || "Остановлено");
  }

  // ---------- Clipboard ----------
  function copyToClipboard(text) {
    if (typeof text !== "string" || text === "") { return; }
    const script = `if command -v wl-copy >/dev/null 2>&1; then printf %s "$1" | wl-copy; elif command -v xclip >/dev/null 2>&1; then printf %s "$1" | xclip -selection clipboard; fi`;
    Quickshell.execDetached(["sh", "-c", script, "--", text]);
    showNotice(pluginApi?.tr("toast.copied") || "Скопировано");
  }

  Process {
    id: pasteProcess
    command: [root.resolvedBinaryPath || "agy-bridge", "--paste"]
    stdout: StdioCollector {
      onStreamFinished: {
        if (text && text !== "") {
          root.pastedText = text;
        }
      }
    }
  }

  function pasteFromClipboard() {
    pasteProcess.running = true;
  }

  // Continue interactive CLI in default terminal
  function openTerminal() {
    var term = agySettings.terminalEmulator || "ghostty";
    var bin = "agy";
    var args = [bin, "--continue"];

    if (agySettings.sandbox) {
      args.unshift("--sandbox");
    }
    
    var home = Quickshell.env("HOME") || "";
    var cwd = (agySettings.workingDir) ? Logic.expandHome(agySettings.workingDir, home) : home;

    var cmd = [];
    if (term === "ghostty") {
      cmd = ["ghostty", "-e", ...args];
    } else if (term === "foot") {
      cmd = ["foot", ...args];
    } else if (term === "kitty") {
      cmd = ["kitty", "-e", ...args];
    } else {
      cmd = ["ghostty", "-e", ...args];
    }

    Logger.i("AgyPanel", "Opening terminal: " + JSON.stringify(cmd));
    Quickshell.execDetached(cmd, cwd);
  }

  // ---------- Slash commands ----------
  function handleSlashCommand(raw) {
    var p = Logic.parseSlashCommand(raw);
    if (!p.handled) { return false; }

    var cmd = "/" + p.command;
    var rest = p.args;

    switch (cmd) {
      case "/help":
        pushMessage({
          role: "assistant",
          kind: "text",
          text: [
            pluginApi?.tr("help.title") || "**Локальные команды**",
            pluginApi?.tr("help.helpCmd") || "- `/help` — этот список",
            pluginApi?.tr("help.clearCmd") || "- `/clear` — очистить историю чата",
            pluginApi?.tr("help.newCmd") || "- `/new` — начать новую сессию Agy",
            pluginApi?.tr("help.stopCmd") || "- `/stop` — остановить текущее выполнение",
            pluginApi?.tr("help.cwdCmd") || "- `/cwd <абсолютный-путь>` — установить рабочую директорию",
            pluginApi?.tr("help.copyCmd") || "- `/copy` — скопировать последнее сообщение ассистента"
          ].join("\n")
        });
        return true;

      case "/clear":
        clearMessages();
        showNotice(pluginApi?.tr("toast.historyCleared") || "История чата очищена");
        return true;

      case "/new":
        newSession(rest);
        return true;

      case "/stop":
        stopGeneration();
        return true;

      case "/cwd":
        if (!rest) {
          pushMessage({ role: "assistant", kind: "text",
            text: (pluginApi?.tr("cwd.current") || "Текущая cwd: ") + "`" + (root.sessionWorkingDir || agySettings.workingDir || (pluginApi?.tr("cwd.default") || "по умолчанию")) + "`" });
          return true;
        }
        root.sessionWorkingDir = rest;
        root.saveState();
        pushMessage({ role: "assistant", kind: "text", text: (pluginApi?.tr("cwd.updated") || "Рабочая директория установлена: ") + "`" + rest + "`." });
        return true;

      case "/copy":
        for (var i = messages.length - 1; i >= 0; i--) {
          var msg = messages[i];
          if (msg.role === "assistant" && msg.kind === "text" && msg.text) {
            copyToClipboard(msg.text);
            return true;
          }
        }
        showNotice(pluginApi?.tr("toast.noAssistantMessageToCopy") || "Нет сообщений ассистента для копирования");
        return true;

      default:
        return false;
    }
  }

  function setAgyField(key, value) {
    if (!pluginApi) { return; }
    if (!pluginApi.pluginSettings.agy) { pluginApi.pluginSettings.agy = {}; }
    pluginApi.pluginSettings.agy[key] = value;
    pluginApi.saveSettings();
    if (pluginApi.pluginSettingsChanged) pluginApi.pluginSettingsChanged();
  }

  function showNotice(text) {
    if (agySettings.enableNotifications !== false && typeof ToastService !== "undefined") {
      ToastService.showNotice(text);
    }
  }

  function showError(text) {
    if (agySettings.enableNotifications !== false && typeof ToastService !== "undefined") {
      ToastService.showError(text);
    }
  }

  // ---------- IPC ----------
  IpcHandler {
    target: "plugin:agy-panel"

    function toggle() {
      if (pluginApi) { pluginApi.withCurrentScreen(function (s) { pluginApi.togglePanel(s); }); }
    }
    function open() {
      if (pluginApi) { pluginApi.withCurrentScreen(function (s) { pluginApi.openPanel(s); }); }
    }
    function close() {
      if (pluginApi) { pluginApi.withCurrentScreen(function (s) { pluginApi.closePanel(s); }); }
    }
    function send(message: string) {
      if (!message || message.trim() === "") { return; }
      if (message[0] === "/") {
        if (root.handleSlashCommand(message.trim())) { return; }
      }
      root.sendMessage(message);
    }
    function stop() { root.stopGeneration(); }
    function clear() {
      root.clearMessages();
      showNotice(pluginApi?.tr("toast.historyCleared") || "История чата очищена");
    }
    function newSession() { root.newSession(); }
    function setWorkingDir(path: string) { root.setAgyField("workingDir", path || ""); }
    function copyLast() {
      for (var i = root.messages.length - 1; i >= 0; i--) {
        var msg = root.messages[i];
        if (msg.role === "assistant" && msg.kind === "text" && msg.text) {
          root.copyToClipboard(msg.text);
          return;
        }
      }
    }
  }
}
