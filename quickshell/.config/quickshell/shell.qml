import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.UPower

ShellRoot {
    id: root

    readonly property color bg: "#181825"
    readonly property color surface: "#1e1e2e"
    readonly property color overlay1: "#313244"
    readonly property color text: "#cdd6f4"
    readonly property color subtext: "#a6adc8"
    readonly property color accent: "#89b4fa"
    readonly property color green: "#a6e3a1"
    readonly property color yellow: "#f9e2af"
    readonly property color red: "#f38ba8"
    readonly property color lavender: "#b4befe"
    readonly property color teal: "#94e2d5"

    readonly property int barH: 34

    Component.onCompleted: {
        print("Quickshell bar loaded — " + Quickshell.env("HOME") + "/dotfiles/wallpapers")
    }

    // ── PipeWire volume ──
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    // ── Niri Workspaces & Window Title IPC ──
    property int activeWs: 1
    property string activeTitle: "Desktop"
    property string activeAppId: ""

    Process {
        id: niriInfoPoll
        command: [Quickshell.env("HOME") + "/dotfiles/scripts/niri-workspace-info"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = text.trim()
                if (!txt) return
                let wsMatch = txt.match(/ws_idx=(\d+)/)
                let titleMatch = txt.match(/title="([^"]*)"/)
                let appMatch = txt.match(/app_id="([^"]*)"/)
                if (wsMatch) root.activeWs = parseInt(wsMatch[1])
                if (titleMatch) root.activeTitle = titleMatch[1] || "Desktop"
                if (appMatch) root.activeAppId = appMatch[1] || ""
            }
        }
        onExited: niriTimer.start()
    }

    Timer {
        id: niriTimer
        interval: 300
        repeat: false
        onTriggered: { if (!niriInfoPoll.running) niriInfoPoll.running = true }
    }

    // ── Brightness ──
    property string brtText: "—%"
    property real brightnessMax: 1

    Process {
        id: backlightDiscovery
        command: ["sh", "-c",
            "b=$(ls /sys/class/backlight/*/brightness 2>/dev/null | head -1); " +
            "[ -n \"$b\" ] && echo \"$b\" && cat \"${b%brightness}max_brightness\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n")
                if (lines.length >= 2) {
                    let max = parseInt(lines[1])
                    if (!isNaN(max) && max > 0) {
                        brightnessMax = max
                        brtPoller.start()
                    }
                }
            }
        }
    }

    Process {
        id: brtPoll
        command: ["brightnessctl", "-m"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = text.trim().split(",")
                if (parts.length >= 4) brtText = parts[3]
            }
        }
        onExited: brtPoller.start()
    }

    Timer {
        id: brtPoller
        interval: 500
        repeat: false
        onTriggered: { if (!brtPoll.running) brtPoll.running = true }
    }

    property var brtQueue: []
    Process {
        id: brtSet
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = text.trim().split(",")
                if (parts.length >= 4) brtText = parts[3]
            }
        }
        onExited: {
            if (brtQueue.length > 0) {
                command = brtQueue.shift()
                running = true
            }
        }
    }

    function adjustBrightness(up) {
        let cmd = ["brightnessctl", "-m", "set", up ? "5%+" : "5%-"]
        if (!brtSet.running) {
            brtSet.command = cmd
            brtSet.running = true
        } else {
            brtQueue.push(cmd)
        }
    }

    // ── Power menu launcher ──
    function showPowerMenu() {
        Quickshell.execDetached([Quickshell.env("HOME") + "/dotfiles/scripts/powermenu"])
    }

    // ── Network stats polling ──
    property string netIcon: "󰤨"
    property string netStatus: "Checking..."
    property string netType: "wifi"

    Process {
        id: netPoll
        command: [Quickshell.env("HOME") + "/dotfiles/scripts/network-stats"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = text.trim()
                let typeMatch = txt.match(/type=([^\s]+)/)
                let nameMatch = txt.match(/name="([^"]*)"/)
                let iconMatch = txt.match(/icon="([^"]*)"/)
                if (typeMatch) root.netType = typeMatch[1]
                if (nameMatch) root.netStatus = nameMatch[1]
                if (iconMatch) root.netIcon = iconMatch[1]
            }
        }
        onExited: netTimer.start()
    }

    Timer {
        id: netTimer
        interval: 2000
        repeat: false
        onTriggered: { if (!netPoll.running) netPoll.running = true }
    }

    function openNetwork() {
        Quickshell.execDetached(["nm-connection-editor"])
    }

    // ── Bluetooth status ──
    property int btConnectedCount: 0
    property string btConnectedName: ""

    function updateBluetooth() {
        let a = Bluetooth.defaultAdapter
        if (!a || !a.enabled) {
            btConnectedCount = 0
            btConnectedName = ""
            return
        }
        let devs = a.devices
        let count = 0
        let firstName = ""
        if (devs) {
            for (let i = 0; i < 50; i++) {
                let d = devs[i]
                if (!d) break
                if (d.connected) {
                    if (count === 0) firstName = d.name || d.deviceName || d.address
                    count++
                }
            }
        }
        btConnectedCount = count
        btConnectedName = firstName
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: updateBluetooth()
    }

    // ── System stats polling ──
    property var stats: ({ cpu_temp: 0, cpu_usage: 0, gpu_temp: 0, gpu_junction: 0, gpu_mem: 0, gpu_busy: 0, gpu_power: 0, cpu_fan: 0, gpu_fan: 0, fan_max: 0, ambient: 0, nvme: 0, mem_used: 0, mem_total: 0 })
    property bool statsOpen: false
    property bool calendarOpen: false

    function tempColor(t) {
        if (t >= 90) return root.red
        if (t >= 75) return root.yellow
        return root.green
    }

    Process {
        id: statsPoll
        command: [Quickshell.env("HOME") + "/dotfiles/scripts/system-stats"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let s = {}
                let pairs = text.trim().split(" ")
                for (let i = 0; i < pairs.length; i++) {
                    let kv = pairs[i].split("=")
                    if (kv.length === 2) s[kv[0]] = parseFloat(kv[1])
                }
                root.stats = s
            }
        }
        onExited: statsTimer.start()
    }

    Timer {
        id: statsTimer
        interval: 1000
        repeat: false
        onTriggered: { if (!statsPoll.running) statsPoll.running = true }
    }

    // ── Calendar date state ──
    property date calDate: new Date()

    // ── Bar window ──
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property ShellScreen modelData
            screen: modelData
            anchors.top: true; anchors.left: true; anchors.right: true
            exclusiveZone: root.barH
            implicitHeight: root.barH
            color: "transparent"
            WlrLayershell.namespace: "niri-bar"

            property string clockNow: Qt.formatDateTime(new Date(), "hh:mm")
            property string dateNow:  Qt.formatDateTime(new Date(), "ddd MMM d")
            Timer { interval: 1000; running: true; repeat: true; onTriggered: {
                bar.clockNow = Qt.formatDateTime(new Date(), "hh:mm")
                bar.dateNow  = Qt.formatDateTime(new Date(), "ddd MMM d")
            }}

            Rectangle {
                anchors.fill: parent
                color: root.bg
                border { color: root.overlay1; width: 1 }

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 10; rightMargin: 10
                    }
                    spacing: 12

                    // ── LEFT: Workspace & Window Title Context ──
                    Rectangle {
                        implicitWidth: wsRow.width + 12
                        implicitHeight: root.barH - 8
                        color: root.surface
                        radius: 6
                        border { color: root.accent; width: 1 }

                        Row {
                            id: wsRow
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "󰍹 " + root.activeWs
                                color: root.accent
                                font { family: "JetBrainsMono Nerd Font"; bold: true; pixelSize: 14 }
                            }
                        }
                    }

                    Rectangle {
                        implicitWidth: 1; implicitHeight: root.barH * 0.5
                        color: root.overlay1
                    }

                    // Focused Window Title
                    Text {
                        text: root.activeTitle ? (root.activeTitle.length > 35 ? root.activeTitle.substring(0, 35) + "…" : root.activeTitle) : "Desktop"
                        color: root.text
                        font { family: "JetBrainsMono Nerd Font"; pixelSize: 14 }
                        elide: Text.ElideRight
                        Layout.maximumWidth: 350
                    }

                    Item { Layout.fillWidth: true }

                    // ── CENTER: Date, Greeting & Calendar Trigger ──
                    Item {
                        implicitWidth: dateRow.width + 16
                        implicitHeight: root.barH - 6

                        Rectangle {
                            anchors.fill: parent
                            color: root.calendarOpen ? root.overlay1 : "transparent"
                            radius: 6
                        }

                        Row {
                            id: dateRow
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: {
                                    let h = new Date().getHours()
                                    let e = h < 6  ? "🌙"
                                          : h < 12 ? "☕"
                                          : h < 18 ? "☀️"
                                          : h < 22 ? "🌆"
                                          :          "🌙"
                                    return e + "  " + bar.dateNow
                                }
                                color: root.text
                                font { family: "JetBrainsMono Nerd Font"; bold: true; pixelSize: 14 }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.calendarOpen = !root.calendarOpen
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // ── RIGHT: Network ──
                    Item {
                        implicitWidth: netRow.width
                        implicitHeight: root.barH
                        Row {
                            id: netRow
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 5
                            Text {
                                text: root.netIcon
                                color: root.netType === "offline" ? root.subtext : root.green
                                font { family: "JetBrainsMono Nerd Font"; pixelSize: 16 }
                            }
                            Text {
                                text: root.netStatus
                                color: root.netType === "offline" ? root.subtext : root.green
                                font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: openNetwork()
                        }
                    }

                    Rectangle {
                        implicitWidth: 1; implicitHeight: root.barH * 0.5
                        color: root.overlay1
                    }

                    // ── Bluetooth ──
                    Item {
                        implicitWidth: btRow.width
                        implicitHeight: root.barH
                        Row {
                            id: btRow
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 5
                            Text {
                                text: {
                                    let a = Bluetooth.defaultAdapter
                                    if (!a || !a.enabled) return "󰂲"  // NF Bluetooth Off
                                    if (root.btConnectedCount > 0) return "󰂱" // NF Bluetooth Connected
                                    return "󰂯" // NF Bluetooth On
                                }
                                color: {
                                    let a = Bluetooth.defaultAdapter
                                    if (!a || !a.enabled) return root.subtext
                                    return root.accent
                                }
                                font { family: "JetBrainsMono Nerd Font"; pixelSize: 16 }
                            }
                            Text {
                                text: {
                                    let a = Bluetooth.defaultAdapter
                                    if (!a || !a.enabled) return "Off"
                                    if (root.btConnectedCount === 1 && root.btConnectedName)
                                        return root.btConnectedName
                                    if (root.btConnectedCount > 1)
                                        return root.btConnectedCount + " devices"
                                    return "On"
                                }
                                color: {
                                    let a = Bluetooth.defaultAdapter
                                    if (!a || !a.enabled) return root.subtext
                                    return root.accent
                                }
                                font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.LeftButton) {
                                    let a = Bluetooth.defaultAdapter
                                    if (a) a.enabled = !a.enabled
                                } else if (mouse.button === Qt.RightButton) {
                                    Quickshell.execDetached(["blueman-manager"])
                                }
                            }
                        }
                    }

                    Rectangle {
                        implicitWidth: 1; implicitHeight: root.barH * 0.5
                        color: root.overlay1
                    }

                    // ── System Stats ──
                    Item {
                        implicitWidth: statsRow.width
                        implicitHeight: root.barH
                        Row {
                            id: statsRow
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6
                            Text {
                                text: "󰔏"
                                color: root.tempColor(Math.max(root.stats.cpu_temp, root.stats.gpu_temp))
                                font { family: "JetBrainsMono Nerd Font"; pixelSize: 16 }
                            }
                            Text {
                                text: root.stats.cpu_temp + "°"
                                color: root.tempColor(root.stats.cpu_temp)
                                font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
                            }
                            Text {
                                text: root.stats.gpu_temp + "°"
                                color: root.tempColor(root.stats.gpu_temp)
                                font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
                            }
                            Text {
                                text: "󰈐"
                                color: root.teal
                                font { family: "JetBrainsMono Nerd Font"; pixelSize: 15 }
                            }
                            Text {
                                text: {
                                    let f = Math.max(root.stats.cpu_fan, root.stats.gpu_fan)
                                    return f > 0 ? (f >= 1000 ? (f / 1000).toFixed(1) + "k" : f + "") : "off"
                                }
                                color: root.teal
                                font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.LeftButton)
                                    root.statsOpen = !root.statsOpen
                                else if (mouse.button === Qt.RightButton)
                                    Quickshell.execDetached([Quickshell.env("HOME") + "/dotfiles/scripts/toggle-gpu-fan"])
                            }
                        }
                    }

                    Rectangle {
                        implicitWidth: 1; implicitHeight: root.barH * 0.5
                        color: root.overlay1
                    }

                    // ── Brightness ──
                    Item {
                        implicitWidth: brtRow.width
                        implicitHeight: root.barH
                        Row {
                            id: brtRow
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            Text {
                                text: "󰃠"
                                color: root.yellow
                                font { family: "JetBrainsMono Nerd Font"; pixelSize: 16 }
                            }
                            Text {
                                text: root.brtText
                                color: root.yellow
                                font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onWheel: (wheel) => {
                                if (wheel.angleDelta.y > 0) adjustBrightness(true)
                                else if (wheel.angleDelta.y < 0) adjustBrightness(false)
                            }
                        }
                    }

                    Rectangle {
                        implicitWidth: 1; implicitHeight: root.barH * 0.5
                        color: root.overlay1
                    }

                    // ── Volume ──
                    Item {
                        implicitWidth: volRow.width
                        implicitHeight: root.barH
                        Row {
                            id: volRow
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            Text {
                                color: root.teal
                                font { family: "JetBrainsMono Nerd Font"; pixelSize: 16 }
                                text: {
                                    let s = Pipewire.defaultAudioSink
                                    if (!s || !s.ready || !s.audio) return "󰝟"
                                    if (s.audio.muted || s.audio.volume <= 0) return "󰝟"
                                    if (s.audio.volume >= 0.66) return "󰕾"
                                    if (s.audio.volume >= 0.33) return "󰖀"
                                    return "󰕿"
                                }
                            }
                            Text {
                                color: {
                                    let s = Pipewire.defaultAudioSink
                                    if (s && s.audio && s.audio.muted) return root.red
                                    return root.teal
                                }
                                font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
                                text: {
                                    let s = Pipewire.defaultAudioSink
                                    if (!s || !s.ready || !s.audio) return "—%"
                                    if (s.audio.muted) return "muted"
                                    let v = s.audio.volume
                                    return Math.round(v * 100) + "%"
                                }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.LeftButton)
                                    Quickshell.execDetached(["pavucontrol"])
                                else if (mouse.button === Qt.MiddleButton) {
                                    let s = Pipewire.defaultAudioSink
                                    if (s && s.audio) s.audio.muted = !s.audio.muted
                                }
                            }
                            onWheel: (wheel) => {
                                let s = Pipewire.defaultAudioSink
                                if (!s || !s.audio) return
                                let d = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                                s.audio.volume = Math.max(0, Math.min(1.5, s.audio.volume + d))
                            }
                        }
                    }

                    Rectangle {
                        implicitWidth: 1; implicitHeight: root.barH * 0.5
                        color: root.overlay1
                    }

                    // ── Clock ──
                    Text {
                        text: bar.clockNow
                        color: root.lavender
                        font { family: "JetBrainsMono Nerd Font"; bold: true; pixelSize: 15 }
                    }

                    Rectangle {
                        implicitWidth: 1; implicitHeight: root.barH * 0.5
                        color: root.overlay1
                    }

                    // ── Battery ──
                    Item {
                        id: batteryItem
                        implicitWidth: batRow.width
                        implicitHeight: root.barH
                        visible: UPower.displayDevice && UPower.displayDevice.isPresent

                        function pct() {
                            let d = UPower.displayDevice
                            return d && d.ready ? d.percentage * 100 : 0
                        }

                        Row {
                            id: batRow
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            Text {
                                id: batIcon
                                font { family: "JetBrainsMono Nerd Font"; pixelSize: 16 }
                                color: {
                                    let d = UPower.displayDevice
                                    if (!d || !d.ready) return root.subtext
                                    if (d.state === UPowerDeviceState.FullyCharged) return root.green
                                    if (d.state === UPowerDeviceState.Charging) return root.green
                                    let p = batteryItem.pct()
                                    if (p <= 10) return root.red
                                    if (p <= 20) return root.yellow
                                    return root.text
                                }
                                text: {
                                    let d = UPower.displayDevice
                                    if (!d || !d.ready) return "󰁹"
                                    if (d.state === UPowerDeviceState.FullyCharged) return "󰂄"
                                    if (d.state === UPowerDeviceState.Charging) return "󰂄"
                                    let p = batteryItem.pct()
                                    if (p < 10) return "󰂎"
                                    if (p < 20) return "󰁺"
                                    if (p < 30) return "󰁻"
                                    if (p < 40) return "󰁼"
                                    if (p < 50) return "󰁽"
                                    if (p < 60) return "󰁾"
                                    if (p < 70) return "󰁿"
                                    if (p < 80) return "󰂀"
                                    if (p < 90) return "󰂁"
                                    return "󰁹"
                                }
                            }
                            Text {
                                id: batPct
                                font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
                                color: batIcon.color
                                text: {
                                    let d = UPower.displayDevice
                                    if (!d || !d.ready) return "—%"
                                    return Math.round(batteryItem.pct()) + "%"
                                }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                Quickshell.execDetached(["foot", "-e", "bash", "-c", "upower -i /org/freedesktop/UPower/devices/battery_BAT0; read -p 'Press enter to close...'"])
                            }
                        }
                    }

                    Rectangle {
                        implicitWidth: 1; implicitHeight: root.barH * 0.5
                        color: root.overlay1
                    }

                    // ── Power Button ──
                    Text {
                        text: "󰐥"
                        color: root.red
                        font { family: "JetBrainsMono Nerd Font"; bold: true; pixelSize: 18 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: showPowerMenu()
                        }
                    }
                }
            }
        }
    }

    // ── CALENDAR FLYOUT PANEL ──
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: calPanel
            required property ShellScreen modelData
            screen: modelData
            visible: root.calendarOpen
            anchors.top: true
            anchors.horizontalCenter: true
            margins.top: root.barH + 6
            exclusiveZone: 0
            implicitWidth: 340
            implicitHeight: calCol.implicitHeight + 24
            color: "transparent"
            WlrLayershell.namespace: "niri-calendar"

            Rectangle {
                anchors.fill: parent
                color: root.bg
                radius: 12
                border { color: root.overlay1; width: 1 }

                ColumnLayout {
                    id: calCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                    spacing: 10

                    // Month & Year Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: Qt.formatDateTime(root.calDate, "MMMM yyyy")
                            color: root.accent
                            font { family: "JetBrainsMono Nerd Font"; bold: true; pixelSize: 16 }
                        }
                        Item { Layout.fillWidth: true }
                        
                        // Previous Month
                        Rectangle {
                            implicitWidth: 26; implicitHeight: 26; radius: 6
                            color: root.surface
                            Text { anchors.centerIn: parent; text: "‹"; color: root.text; font.pixelSize: 16 }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    let d = new Date(root.calDate)
                                    d.setMonth(d.getMonth() - 1)
                                    root.calDate = d
                                }
                            }
                        }

                        // Today Reset
                        Rectangle {
                            implicitWidth: 44; implicitHeight: 26; radius: 6
                            color: root.surface
                            Text { anchors.centerIn: parent; text: "Today"; color: root.teal; font.pixelSize: 12 }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.calDate = new Date()
                            }
                        }

                        // Next Month
                        Rectangle {
                            implicitWidth: 26; implicitHeight: 26; radius: 6
                            color: root.surface
                            Text { anchors.centerIn: parent; text: "›"; color: root.text; font.pixelSize: 16 }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    let d = new Date(root.calDate)
                                    d.setMonth(d.getMonth() + 1)
                                    root.calDate = d
                                }
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: root.overlay1 }

                    // Days of week header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Repeater {
                            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                            Text {
                                text: modelData
                                color: root.subtext
                                font { family: "JetBrainsMono Nerd Font"; bold: true; pixelSize: 13 }
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                            }
                        }
                    }

                    // Month Calendar Grid (7x6 days)
                    GridLayout {
                        id: dayGrid
                        columns: 7
                        rowSpacing: 4; columnSpacing: 4
                        Layout.fillWidth: true

                        Repeater {
                            model: 42 // 6 weeks * 7 days

                            delegate: Rectangle {
                                implicitWidth: 38; implicitHeight: 32
                                radius: 6
                                Layout.alignment: Qt.AlignHCenter

                                property date dayDate: {
                                    let y = root.calDate.getFullYear()
                                    let m = root.calDate.getMonth()
                                    let firstDay = new Date(y, m, 1).getDay()
                                    // shift so Monday is 0, Sunday is 6
                                    let offset = (firstDay + 6) % 7
                                    return new Date(y, m, index - offset + 1)
                                }

                                property bool isCurrentMonth: dayDate.getMonth() === root.calDate.getMonth()
                                property bool isToday: {
                                    let now = new Date()
                                    return dayDate.getDate() === now.getDate() &&
                                           dayDate.getMonth() === now.getMonth() &&
                                           dayDate.getFullYear() === now.getFullYear()
                                }

                                color: isToday ? root.accent : (isCurrentMonth ? root.surface : "transparent")

                                Text {
                                    anchors.centerIn: parent
                                    text: dayDate.getDate()
                                    color: isToday ? root.bg : (isCurrentMonth ? root.text : root.overlay1)
                                    font { family: "JetBrainsMono Nerd Font"; bold: isToday; pixelSize: 13 }
                                }
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: root.overlay1 }

                    // Google Calendar & Calendar App Action Buttons
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 32
                            radius: 6
                            color: root.surface
                            border { color: root.accent; width: 1 }

                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: "󰃭"; color: root.accent; font { family: "JetBrainsMono Nerd Font"; pixelSize: 14 } }
                                Text { text: "Google Calendar"; color: root.text; font.pixelSize: 12 }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.calendarOpen = false
                                    Quickshell.execDetached(["xdg-open", "https://calendar.google.com"])
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 32
                            radius: 6
                            color: root.surface
                            border { color: root.overlay1; width: 1 }

                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: "󰸉"; color: root.teal; font { family: "JetBrainsMono Nerd Font"; pixelSize: 14 } }
                                Text { text: "Calendar App"; color: root.text; font.pixelSize: 12 }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.calendarOpen = false
                                    Quickshell.execDetached(["sh", "-c", "gnome-calendar || korganizer || xdg-open https://calendar.google.com"])
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── SYSTEM STATS FLYOUT PANEL ──
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: statsPanel
            required property ShellScreen modelData
            screen: modelData
            visible: root.statsOpen
            anchors.top: true
            anchors.right: true
            margins.top: root.barH + 6
            margins.right: 8
            exclusiveZone: 0
            implicitWidth: 320
            implicitHeight: statsCol.implicitHeight + 24
            color: "transparent"
            WlrLayershell.namespace: "niri-stats"

            component StatRow: RowLayout {
                property string label: ""
                property string value: ""
                property color valueColor: root.text
                property real ratio: 0
                spacing: 8
                Layout.fillWidth: true
                Text {
                    text: label
                    color: root.subtext
                    font.pixelSize: 13
                    Layout.preferredWidth: 100
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 5
                    radius: 3
                    color: root.overlay1
                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, ratio))
                        height: parent.height
                        radius: 3
                        color: valueColor
                    }
                }
                Text {
                    text: value
                    color: valueColor
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 120
                }
            }

            Rectangle {
                anchors.fill: parent
                color: root.bg
                radius: 10
                border { color: root.overlay1; width: 1 }

                ColumnLayout {
                    id: statsCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                    spacing: 7

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Text {
                            text: "󰔏  System Stats"
                            color: root.accent
                            font { family: "JetBrainsMono Nerd Font"; bold: true; pixelSize: 14 }
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle { width: 7; height: 7; radius: 4; color: root.green }
                        Text { text: "live"; color: root.green; font.pixelSize: 12 }
                    }

                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: root.overlay1 }

                    StatRow { label: "CPU temp";     value: root.stats.cpu_temp + "°C";  valueColor: root.tempColor(root.stats.cpu_temp);     ratio: root.stats.cpu_temp / 100 }
                    StatRow { label: "CPU usage";    value: root.stats.cpu_usage + "%"; valueColor: root.accent;                           ratio: root.stats.cpu_usage / 100 }
                    StatRow { label: "GPU edge";     value: root.stats.gpu_temp + "°C";  valueColor: root.tempColor(root.stats.gpu_temp);     ratio: root.stats.gpu_temp / 100 }
                    StatRow { label: "GPU junction"; value: root.stats.gpu_junction + "°C"; valueColor: root.tempColor(root.stats.gpu_junction); ratio: root.stats.gpu_junction / 110 }
                    StatRow { label: "GPU memory";   value: root.stats.gpu_mem + "°C";   valueColor: root.tempColor(root.stats.gpu_mem);      ratio: root.stats.gpu_mem / 120 }
                    StatRow { label: "GPU busy";     value: root.stats.gpu_busy + "%";  valueColor: root.lavender;                          ratio: root.stats.gpu_busy / 100 }
                    StatRow { label: "GPU power";    value: root.stats.gpu_power + " W"; valueColor: root.yellow;                            ratio: root.stats.gpu_power / 80 }

                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: root.overlay1 }

                    StatRow { label: "CPU fan"; value: root.stats.cpu_fan + " RPM"; valueColor: root.teal; ratio: root.stats.fan_max > 0 ? root.stats.cpu_fan / root.stats.fan_max : 0 }
                    StatRow { label: "GPU fan"; value: root.stats.gpu_fan + " RPM"; valueColor: root.teal; ratio: root.stats.fan_max > 0 ? root.stats.gpu_max : 0 }

                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: root.overlay1 }

                    StatRow { label: "Ambient"; value: root.stats.ambient + "°C"; valueColor: root.subtext; ratio: root.stats.ambient / 60 }
                    StatRow { label: "NVMe";    value: root.stats.nvme + "°C";    valueColor: root.tempColor(root.stats.nvme); ratio: root.stats.nvme / 90 }
                    StatRow { label: "RAM";     value: root.stats.mem_used.toFixed(1) + " / " + root.stats.mem_total.toFixed(1) + " GiB"; valueColor: root.accent; ratio: root.stats.mem_total > 0 ? root.stats.mem_used / root.stats.mem_total : 0 }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.statsOpen = false
            }
        }
    }
}
