import QtQuick
import QtQuick.Layouts
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

    // ── PipeWire volume (native, real-time) ──
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    // ── brightness ──
    // scroll changes are instant (parsed from brightnessctl output)
    // external changes polled every 2s
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

    // poll for external changes (brightness keys)
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

    // scroll: set + read back in one shot (instant)
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

    // ── power menu launcher ──
    function showPowerMenu() {
        Quickshell.execDetached([Quickshell.env("HOME") + "/dotfiles/scripts/powermenu"])
    }

    // ── network (XMLHttpRequest polls /tmp/niri_network) ──
    property string netIcon: String.fromCodePoint(0xF05AA)
    property string netStatus: "..."

    function updateNetwork() {
        let xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/niri_network")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                let line = xhr.responseText.trim().split("\n")[0]
                if (line.indexOf("wifi:") === 0) {
                    netIcon = String.fromCodePoint(0xF0928)
                    netStatus = line.substring(5)
                } else {
                    netIcon = String.fromCodePoint(0xF05AA)
                    netStatus = "Offline"
                }
            }
        }
        xhr.send()
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: updateNetwork()
    }

    function openNetwork() {
        Quickshell.execDetached(["nm-connection-editor"])
    }

    // ── bluetooth ──
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
        interval: 3000
        running: true
        repeat: true
        onTriggered: updateBluetooth()
    }

    // ── bar ──
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
                    spacing: 14

                    // ── left ──
                    Text {
                        text: "\u2630 Niri"
                        color: root.accent
                        font { family: "JetBrainsMono Nerd Font"; bold: true; pixelSize: 16 }
                    }
                    Rectangle {
                        implicitWidth: 1; implicitHeight: root.barH * 0.5
                        color: root.overlay1
                    }
                    Text {
                        text: bar.modelData.name
                        color: root.subtext; font.pixelSize: 15
                    }

                    Item { Layout.fillWidth: true }

                    // ── center ──
                    Text {
                        text: {
                            let h = new Date().getHours()
                            let e = h < 6  ? "\uD83C\uDF19"
                                  : h < 12 ? "\u2615"
                                  : h < 18 ? "\u2600"
                                  : h < 22 ? "\uD83C\uDF07"
                                  :          "\uD83C\uDF19"
                            return e + "  " + bar.dateNow
                        }
                        color: root.text; font.pixelSize: 15
                    }

                    Item { Layout.fillWidth: true }

                    // ── network ──
                    Item {
                        implicitWidth: netRow.width
                        implicitHeight: root.barH
                        visible: root.netStatus !== "..."
                        Row {
                            id: netRow
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            Text {
                                text: root.netIcon
                                color: root.netStatus === "Offline" ? root.subtext : root.green
                                font { family: "JetBrainsMono Nerd Font"; pixelSize: 16 }
                            }
                            Text {
                                text: root.netStatus
                                color: root.netStatus === "Offline" ? root.subtext : root.green
                                font.pixelSize: 13
                                visible: root.netStatus !== "Offline"
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

                    // ── bluetooth ──
                    Item {
                        implicitWidth: btRow.width
                        implicitHeight: root.barH
                        Row {
                            id: btRow
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            Text {
                                text: {
                                    let a = Bluetooth.defaultAdapter
                                    if (!a || !a.enabled) return String.fromCodePoint(0xF0A0B)
                                    if (root.btConnectedCount > 0) return String.fromCodePoint(0xF0A0E)
                                    return String.fromCodePoint(0xF0A0D)
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
                                        return root.btConnectedCount + ""
                                    return "On"
                                }
                                color: {
                                    let a = Bluetooth.defaultAdapter
                                    if (!a || !a.enabled) return root.subtext
                                    return root.accent
                                }
                                font.pixelSize: 13
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

                    // ── brightness ──
                    Item {
                        implicitWidth: brtRow.width
                        implicitHeight: root.barH
                        Row {
                            id: brtRow
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            Text {
                                text: String.fromCodePoint(0xF059C)
                                color: root.yellow
                                font { family: "JetBrainsMono Nerd Font"; pixelSize: 16 }
                            }
                            Text {
                                text: root.brtText
                                color: root.yellow
                                font.pixelSize: 14
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

                    // ── volume ──
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
                                    if (!s || !s.ready || !s.audio) return String.fromCodePoint(0xF0582)
                                    if (s.audio.muted || s.audio.volume <= 0)
                                        return String.fromCodePoint(0xF0582)
                                    if (s.audio.volume >= 0.66) return String.fromCodePoint(0xF057E)
                                    if (s.audio.volume >= 0.33) return String.fromCodePoint(0xF0580)
                                    return String.fromCodePoint(0xF057F)
                                }
                            }
                            Text {
                                color: {
                                    let s = Pipewire.defaultAudioSink
                                    if (s && s.audio && s.audio.muted) return root.red
                                    return root.teal
                                }
                                font.pixelSize: 14
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

                    // ── clock ──
                    Text {
                        text: bar.clockNow
                        color: root.lavender
                        font { family: "JetBrainsMono Nerd Font"; bold: true; pixelSize: 16 }
                    }

                    Rectangle {
                        implicitWidth: 1; implicitHeight: root.barH * 0.5
                        color: root.overlay1
                    }

                    // ── battery (UPower reports 0.0–1.0, multiply by 100) ──
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
                                    if (!d || !d.ready) return String.fromCodePoint(0xF0083)
                                    if (d.state === UPowerDeviceState.FullyCharged) return String.fromCodePoint(0xF008F)
                                    if (d.state === UPowerDeviceState.Charging) return String.fromCodePoint(0xF008F)
                                    let p = batteryItem.pct()
                                    if (p < 10) return String.fromCodePoint(0xF0079)
                                    if (p < 20) return String.fromCodePoint(0xF007B)
                                    if (p < 30) return String.fromCodePoint(0xF007C)
                                    if (p < 40) return String.fromCodePoint(0xF007D)
                                    if (p < 50) return String.fromCodePoint(0xF007E)
                                    if (p < 60) return String.fromCodePoint(0xF007F)
                                    if (p < 70) return String.fromCodePoint(0xF0080)
                                    if (p < 80) return String.fromCodePoint(0xF0081)
                                    if (p < 90) return String.fromCodePoint(0xF0082)
                                    return String.fromCodePoint(0xF0083)
                                }
                            }
                            Text {
                                id: batPct
                                font.pixelSize: 14
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

                    // ── power (rightmost) ──
                    Text {
                        text: String.fromCodePoint(0xF0425)
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
}
// We'll do this inline instead
