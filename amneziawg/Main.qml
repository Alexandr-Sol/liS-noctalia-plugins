import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Services.UI

QtObject {
    id: root

    property var pluginApi: null
    readonly property var pluginSettings: pluginApi?.pluginSettings ?? ({})
    readonly property var toast: pluginSettings?.disableToastNotifications ? null : ToastService

    property bool isConnected: false
    property bool isLoading: false
    property string activeProfile: ""
    property string activeConfig: ""
    property var profiles: []
    property string homeDir: ""

    property var _homeDirProc: Process {
        command: ["sh", "-c", "echo $HOME"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                if (line.trim()) root.homeDir = line.trim()
            }
        }
    }

    // Scan directory for configs
    property var _scanProc: Process {
        command: ["pkexec", "ls", "/etc/amnezia/amneziawg/"]
        running: false
        stdout: SplitParser {
            onRead: (line) => {
                const files = line.trim().split(/\s+/).filter(f => f.endsWith(".conf"))
                const newList = []
                files.forEach(f => {
                    const name = f.replace(/\.conf$/, "")
                    newList.push({
                        name: name,
                        config: "/etc/amnezia/amneziawg/" + f
                    })
                })
                root.profiles = newList
            }
        }
    }

    // Monitoring interfaces
    property var _statusProc: Process {
        command: ["awg", "show", "interfaces"]
        running: false
        stdout: SplitParser {
            onRead: (line) => {
                const interfaces = line.trim().split(/\s+/).filter(i => i !== "")
                if (root.activeConfig) {
                    const iface = root.getInterfaceName(root.activeConfig)
                    root.isConnected = interfaces.includes(iface)
                } else {
                    root.isConnected = interfaces.length > 0
                    if (root.isConnected && !root.activeProfile) {
                        // Try to find matching profile
                        const iface = interfaces[0]
                        const found = root.profiles.find(p => p.name === iface)
                        if (found) {
                            root.activeProfile = found.name
                            root.activeConfig = found.config
                        } else {
                            root.activeProfile = iface
                        }
                    }
                }
            }
        }
    }

    property var _statusTimer: Timer {
        interval: 3000
        repeat: true
        running: true
        onTriggered: {
            _statusProc.running = true
        }
    }

    property var _upProc: Process {
        running: false
        onExited: (exitCode) => {
            Logger.i("AmneziaWG", "Up process exited with code: " + exitCode)
            root.isLoading = false
            if (exitCode === 0) {
                root.isConnected = true
                root.toast?.showNotice(root.t("toast.connected", { name: root.activeProfile }))
                if (root.pluginSettings?.autoStopZapret && root.isZapretActive)
                    root._zapretAutoStop()
            } else {
                root.toast?.showError(root.t("toast.connectionError", { name: root.activeProfile }))
                root.activeProfile = ""
                root.activeConfig = ""
            }
        }
    }

    property var _downProc: Process {
        running: false
        onExited: (exitCode) => {
            Logger.i("AmneziaWG", "Down process exited with code: " + exitCode)
            root.isLoading = false
            if (exitCode === 0) {
                root.isConnected = false
                root.toast?.showNotice(root.t("toast.disconnected"))
                if (root._zapretWasAutoStopped) {
                    root._zapretWasAutoStopped = false
                    root.zapretStart()
                }
                root.activeProfile = ""
                root.activeConfig = ""
            } else {
                root.toast?.showError(root.t("toast.disconnectionError"))
            }
        }
    }

    property bool isZapretActive: false
    property bool isZapretLoading: false
    property bool _zapretWasAutoStopped: false

    property var _zapretStatusProc: Process {
        command: ["systemctl", "is-active", "zapret"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                root.isZapretActive = line.trim() === "active"
            }
        }
    }

    property var _zapretStartProc: Process {
        running: false
        onExited: (exitCode) => {
            root.isZapretLoading = false
            if (exitCode === 0) {
                root.isZapretActive = true
                root.toast?.showNotice(root.t("toast.zapretStarted"))
            } else {
                root.toast?.showError(root.t("toast.zapretStartError"))
            }
        }
    }

    property var _zapretStopProc: Process {
        running: false
        onExited: (exitCode) => {
            root.isZapretLoading = false
            if (exitCode === 0) {
                root.isZapretActive = false
                root.toast?.showNotice(root.t("toast.zapretStopped"))
            } else {
                root.toast?.showError(root.t("toast.zapretStopError"))
            }
        }
    }

    function zapretStart() {
        if (isZapretLoading || isZapretActive) return
        isZapretLoading = true
        _zapretStartProc.command = ["systemctl", "start", "zapret"]
        _zapretStartProc.running = true
    }

    function _zapretAutoStop() {
        if (isZapretLoading || !isZapretActive) return
        _zapretWasAutoStopped = true
        isZapretLoading = true
        _zapretStopProc.command = ["systemctl", "stop", "zapret"]
        _zapretStopProc.running = true
    }

    function zapretStop() {
        if (isZapretLoading || !isZapretActive) return
        _zapretWasAutoStopped = false
        isZapretLoading = true
        _zapretStopProc.command = ["systemctl", "stop", "zapret"]
        _zapretStopProc.running = true
    }

    function resolveConfig(config) {
        if (config.startsWith("~/") && homeDir) {
            return homeDir + config.slice(1)
        }
        return config
    }

    function getInterfaceName(configPath) {
        const parts = configPath.split('/')
        const fileName = parts[parts.length - 1]
        return fileName.replace(/\.conf$/, '')
    }

    function connect(name, config) {
        if (isLoading || isConnected) return
        isLoading = true
        activeProfile = name
        activeConfig = resolveConfig(config)

        Logger.i("AmneziaWG", "Connecting with config: " + activeConfig)
        _upProc.command = ["pkexec", "awg-quick", "up", activeConfig]
        _upProc.running = true
    }

    function disconnect() {
        if (!isConnected || isLoading) return
        isLoading = true
        
        const configToUse = activeConfig || ("/etc/amnezia/amneziawg/" + activeProfile + ".conf")
        Logger.i("AmneziaWG", "Disconnecting: " + configToUse)
        _downProc.command = ["pkexec", "awg-quick", "down", configToUse]
        _downProc.running = true
    }

    function loadProfiles() {
        // Now using directory scanning
        _scanProc.running = true
    }

    function addProfile(name, config) {}
    function removeProfile(index) {}
    function _saveProfiles() {}

    function t(key, data) {
        return pluginApi?.tr(key, data) ?? key
    }

    Component.onCompleted: {
        loadProfiles()
        Logger.i("AmneziaWG", "Plugin started")
    }
}
