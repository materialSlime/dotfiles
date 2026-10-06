// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                     CYBERPUNK SDDM THEME                               ║
// ║  Color palette matched to Hyprland + Waybar + Hyprlock cyberpunk theme  ║
// ║                                                                        ║
// ║  LAYOUT: 1:1 port of ~/.config/hypr/hyprlock.conf                      ║
// ║    Every hyprlock widget is placed with place() using the SAME         ║
// ║    position / halign / valign values, and font sizes go through pt()   ║
// ║    so they render at the same pixel size as hyprlock.                  ║
// ║    Change a value in hyprlock.conf → change the same number here.      ║
// ║                                                                        ║
// ║  PALETTE:                                                              ║
// ║    Colors: ~/.config/theme/palette -> theme.conf.user (config.c_<name>)║
// ╚══════════════════════════════════════════════════════════════════════════╝

import QtQuick
import QtQuick.Window
import Qt.labs.folderlistmodel
import SddmComponents 2.0

Rectangle {
    // Wayland Cursor Fix
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        z: -1
    }

    id: root
    width: Screen.width
    height: Screen.height
    color: cBg

    // Scale factor — hyprlock coordinates are pixels on a 1080p monitor,
    // so 1080 is the reference (s = 1 on the 1920x1080 display).
    readonly property real s: height / 1080
    // Old 768p scale, only used by the SDDM-only decorations (HUDs, blade).
    readonly property real sd: height / 768

    // hyprlock font_size is in points rendered at 96 DPI → px = pt * 4/3
    function pt(v) { return v * 4 / 3 * s }

    // hyprlock positioning: origin bottom-left, +y is up.
    //   halign left/center/right, valign top/center/bottom
    function hx(w, px, halign) {
        if (halign === "right")  return width - w + px * s
        if (halign === "center") return (width - w) / 2 + px * s
        return px * s
    }
    function hy(h, py, valign) {
        if (valign === "top")    return -py * s
        if (valign === "bottom") return height - h - py * s
        return (height - h) / 2 - py * s
    }

    // ═══════════════════════════════════════════════════════════════════════
    //   CYBERPUNK COLOR PALETTE — from ~/.config/theme/palette via theme.conf.user
    // ═══════════════════════════════════════════════════════════════════════
    readonly property color cSecondary:    config.c_secondary     || "#5EF6FF"   // Neon cyan — primary accent
    readonly property color cAccent:  config.c_accent   || "#F3E900"   // accent — highlight/clock
    readonly property color cPrimary:     config.c_primary      || "#F75049"   // Alert red — warnings/borders
    readonly property color cTertiary:    config.c_tertiary     || "#246DCE"   // Deep blue — secondary/subtle
    readonly property color cBg:      config.c_bg       || "#0E0E17"   // Deep void black
    readonly property color cSecondaryDim:   config.c_secondary_dim || "#25575F"   // Dimmed foreground

    function secondary(a)   { return Qt.rgba(cSecondary.r, cSecondary.g, cSecondary.b, a) }
    function accent(a) { return Qt.rgba(cAccent.r, cAccent.g, cAccent.b, a) }
    function primary(a)    { return Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, a) }
    function tertiary(a)   { return Qt.rgba(cTertiary.r, cTertiary.g, cTertiary.b, a) }

    // ═══════════════════════════════════════════════════════════════════════
    //   STATE
    // ═══════════════════════════════════════════════════════════════════════
    property bool isQuickshell: typeof sddm === "undefined" || sddm.hostName === undefined
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    // 12h clock like hyprlock's %I/%p. Qt's "hh" is only 12h when "AP" is in
    // the same format string, so format once and split.
    property var clockParts: Qt.formatTime(new Date(), "hh mm ss AP").split(" ")
    property string currentDate:    Qt.formatDate(new Date(), "dddd  //  dd MMMM yyyy")
    property int currentUserIndex: 0
    property string authState: ""   // "", "check", "fail" — mirrors hyprlock

    TextConstants { id: textConstants }

    // ═══════════════════════════════════════════════════════════════════════
    //   FONTS
    // ═══════════════════════════════════════════════════════════════════════
    FolderListModel {
        id: fontFolder
        folder: Qt.resolvedUrl("font")
        nameFilters: ["*.ttf", "*.otf"]
    }
    FontLoader {
        id: customFont
        source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : ""
    }
    readonly property string fn: customFont.name.length > 0 ? customFont.name : "Rajdhani"
    readonly property string fnMono: "JetBrainsMono Nerd Font Mono"

    // ═══════════════════════════════════════════════════════════════════════
    //   TIMERS
    // ═══════════════════════════════════════════════════════════════════════
    Timer {
        interval: 300; running: true
        onTriggered: pwInput.forceActiveFocus()
    }

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            var now = new Date()
            root.clockParts  = Qt.formatTime(now, "hh mm ss AP").split(" ")
            root.currentDate = Qt.formatDate(now, "dddd  //  dd MMMM yyyy")
        }
    }

    // hyprlock fail_timeout = 2000
    Timer {
        id: failTimer
        interval: 2000
        onTriggered: root.authState = ""
    }

    // ═══════════════════════════════════════════════════════════════════════
    //   HELPERS
    // ═══════════════════════════════════════════════════════════════════════
    ListView {
        id: sessionHelper
        model: typeof sessionModel !== "undefined" ? sessionModel : null
        currentIndex: root.sessionIndex
        visible: true; width: 1; height: 1; opacity: 0; z: -100
        delegate: Item { property string sName: model.name || "" }
    }

    // ═══════════════════════════════════════════════════════════════════════
    //   BACKGROUND
    //   (hyprlock blurs a live screenshot; SDDM has none, so it keeps bg.jpg)
    // ═══════════════════════════════════════════════════════════════════════
    Image {
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        mipmap: true
    }

    // ═══════════════════════════════════════════════════════════════════════
    //   FLOATING PARTICLES — cyan embers rising (SDDM only)
    // ═══════════════════════════════════════════════════════════════════════
    Item {
        anchors.fill: parent
        opacity: 0.6

        Repeater {
            model: 30
            Rectangle {
                id: particle
                property real startY: 0
                property real dur: 12000
                property real maxOp: 0.3

                color: Math.random() < 0.15 ? root.cAccent : root.cSecondary
                width: 2 * root.sd
                height: 2 * root.sd
                radius: width / 2
                opacity: 0

                Component.onCompleted: {
                    x = Math.random() * root.width
                    startY = root.height * 0.4 + Math.random() * root.height * 0.6
                    dur = 14000 + Math.random() * 14000
                    maxOp = Math.random() * 0.45 + 0.1
                    var sz = (Math.random() * 2.5 + 0.5) * root.sd
                    width = sz; height = sz; radius = sz / 2

                    particleYAnim.from = startY
                    particleYAnim.to   = startY - root.height * 0.85
                    particleYAnim.duration = dur
                    particleOpIn.to       = maxOp
                    particleOpIn.duration  = dur * 0.25
                    particleOpOut.duration = dur * 0.75
                    particleAnim.start()
                }

                ParallelAnimation {
                    id: particleAnim
                    loops: Animation.Infinite
                    NumberAnimation {
                        id: particleYAnim
                        target: particle; property: "y"
                    }
                    SequentialAnimation {
                        NumberAnimation {
                            id: particleOpIn
                            target: particle; property: "opacity"; from: 0
                        }
                        NumberAnimation {
                            id: particleOpOut
                            target: particle; property: "opacity"; to: 0
                        }
                        PauseAnimation { duration: Math.random() * 2500 }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    //   LEFT COLUMN — Clock, Date, User, Input   (hyprlock: halign = left)
    // ═══════════════════════════════════════════════════════════════════════

    // ── Decorative top accent ──   hyprlock: 80, -50  left/top
    Text {
        text: "┌── SYSTEM :: ENCRYPTED ──────────────────────"
        color: root.primary(0.5)
        font.family: root.fnMono
        font.pixelSize: root.pt(12)
        x: root.hx(width, 80, "left"); y: root.hy(height, -50, "top")
    }

    // ── Clock ──   hyprlock: 80, 240  left/center
    // HH:MM flow in one row (Rajdhani digits are proportional), seconds sit
    // top-aligned after the minutes and AM/PM sits on the baseline under them.
    Item {
        id: clockGroup
        width: amPmText.x + Math.max(secondsText.width, amPmText.width)
        height: hoursText.height
        x: root.hx(width, 80, "left"); y: root.hy(height, 240, "center")

        Text {
            id: hoursText
            text: root.clockParts[0]
            color: root.cAccent
            font.family: root.fn
            font.pixelSize: root.pt(160)
            font.bold: true
        }

        Text {
            id: colonText
            text: ":"
            color: root.primary(0.9)
            font.family: root.fn
            font.pixelSize: root.pt(130)
            font.bold: true
            anchors.left: hoursText.right
            anchors.baseline: hoursText.baseline
        }

        Text {
            id: minutesText
            text: root.clockParts[1]
            color: root.cSecondary
            font.family: root.fn
            font.pixelSize: root.pt(160)
            font.bold: true
            anchors.left: colonText.right
            anchors.baseline: hoursText.baseline
        }

        // rise 110px = Rajdhani digit height (137) - mono digit height (27)
        Text {
            id: secondsText
            text: root.clockParts[2]
            color: root.secondary(0.35)
            font.family: root.fnMono
            font.pixelSize: root.pt(28)
            anchors.left: minutesText.right
            anchors.leftMargin: root.pt(12) * 0.6   // one 12pt mono space
            anchors.baseline: hoursText.baseline
            anchors.baselineOffset: -110 * root.s
        }

        Text {
            id: amPmText
            text: root.clockParts[3]
            color: root.primary(0.7)
            font.family: root.fn
            font.pixelSize: root.pt(18)
            font.bold: true
            x: secondsText.x
            anchors.baseline: hoursText.baseline
        }
    }

    // ── Date ──   hyprlock: 100, 95  left/center
    Text {
        text: root.currentDate
        color: root.secondary(0.5)
        font.family: root.fn
        font.pixelSize: root.pt(20)
        font.bold: true
        x: root.hx(width, 100, "left"); y: root.hy(height, 95, "center")
    }

    // ── Separator ──   hyprlock: 90, 65  left/center
    Text {
        text: "─────────────────────────────────────"
        color: root.secondary(0.12)
        font.family: root.fnMono
        font.pixelSize: root.pt(10)
        x: root.hx(width, 90, "left"); y: root.hy(height, 65, "center")
    }

    // ── Username ──   hyprlock: 100, -10  left/center
    Text {
        id: userText
        text: {
            if (typeof userModel !== "undefined" && userModel.count > 0) {
                var realName = userModel.data(userModel.index(root.currentUserIndex, 0), Qt.UserRole + 2)
                var name = userModel.data(userModel.index(root.currentUserIndex, 0), Qt.UserRole + 1)
                return name || realName || "user"
            }
            return "user"
        }
        color: userMouse.containsMouse ? root.cAccent : root.secondary(0.9)
        font.family: root.fn
        font.pixelSize: root.pt(28)
        font.bold: true
        x: root.hx(width, 100, "left"); y: root.hy(height, -10, "center")

        MouseArea {
            id: userMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: (typeof userModel !== "undefined" && userModel.count > 1)
                         ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (typeof userModel !== "undefined" && userModel.count > 1)
                    root.currentUserIndex = (root.currentUserIndex + 1) % userModel.count
            }
        }
    }

    // ── User role tag ──   hyprlock: 100, -42  left/center
    Text {
        text: "SAMURAI"
        color: root.tertiary(0.5)
        font.family: root.fnMono
        font.pixelSize: root.pt(12)
        x: root.hx(width, 100, "left"); y: root.hy(height, -42, "center")
    }

    // ── Input Field ──   hyprlock: size 400x55, 100, -110  left/center
    Rectangle {
        id: inputContainer
        width: 400 * root.s
        height: 55 * root.s
        x: root.hx(width, 100, "left"); y: root.hy(height, -110, "center")
        radius: 3 * root.s
        color: Qt.rgba(cBg.r, cBg.g, cBg.b, 0.85)
        border.width: 2 * root.s
        border.color: root.authState === "fail"  ? root.cPrimary
                    : root.authState === "check" ? root.accent(0.8)
                    : keyboard.capsLock          ? root.cAccent
                    : root.primary(0.8)
        Behavior on border.color { ColorAnimation { duration: 150 } }

        // hyprlock placeholder/fail text: font_size = field height / 4
        Text {
            text: root.authState === "fail" ? "✘ ACCESS_DENIED" : "▸ ACCESS_REQUIRED"
            opacity: pwInput.text.length === 0 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutSine } }
            color: root.cPrimary
            font.family: root.fn
            font.pixelSize: root.pt(Math.floor(55 / 4))
            font.italic: true
            font.bold: true
            anchors.centerIn: parent
        }

        // Dots — dots_size 0.25, dots_spacing 0.25, dots_center true
        Row {
            id: dotsRow
            readonly property real dot: 55 * 0.25 * root.s
            anchors.centerIn: parent
            spacing: dot * 0.25
            Repeater {
                model: pwInput.text.length
                Rectangle {
                    width: dotsRow.dot; height: dotsRow.dot
                    radius: width / 2
                    color: root.cSecondary
                }
            }
        }

        // Real input — invisible, the dots above render it
        TextInput {
            id: pwInput
            anchors.fill: parent
            color: "transparent"
            selectionColor: "transparent"
            selectedTextColor: "transparent"
            echoMode: TextInput.Password
            cursorVisible: false
            cursorDelegate: Item { width: 0; height: 0 }

            MouseArea {
                anchors.fill: parent
                onClicked: pwInput.forceActiveFocus()
            }

            onTextEdited: if (root.authState === "fail") root.authState = ""
            Keys.onReturnPressed: doLogin()
            Keys.onEnterPressed:  doLogin()
            onTextChanged: {
                if (text.length > 0) slashAnim.restart()
            }
        }
    }

    // ── Left panel bottom accent ──   hyprlock: 80, -180  left/center
    Text {
        text: "└────────────────────────────────────────────"
        color: root.secondary(0.15)
        font.family: root.fnMono
        font.pixelSize: root.pt(12)
        x: root.hx(width, 80, "left"); y: root.hy(height, -180, "center")
    }

    // ═══════════════════════════════════════════════════════════════════════
    //   BLADE SLASH ACCENT — triggers on keypress (SDDM only)
    // ═══════════════════════════════════════════════════════════════════════
    Item {
        anchors.top: parent.top
        anchors.topMargin: 55 * sd
        anchors.right: parent.right
        anchors.rightMargin: 80 * sd
        width: 180 * sd
        height: 12 * sd
        clip: true

        // Base line
        Rectangle {
            width: parent.width; height: 1
            color: root.cSecondaryDim; opacity: 0.15
            anchors.verticalCenter: parent.verticalCenter
        }

        // Animated blade
        Rectangle {
            id: slashBlade
            height: 1.5 * sd
            y: (parent.height - height) / 2

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.6; color: root.cSecondary }
                GradientStop { position: 1.0; color: "#FFFFFF" }
            }

            SequentialAnimation {
                id: slashAnim
                running: false

                ParallelAnimation {
                    NumberAnimation {
                        target: slashBlade; property: "x"
                        from: 180 * root.sd; to: 0
                        duration: 180; easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: slashBlade; property: "width"
                        from: 0; to: 180 * root.sd
                        duration: 180; easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: slashBlade; property: "opacity"
                        from: 0.0; to: 1.0; duration: 50
                    }
                }

                ParallelAnimation {
                    NumberAnimation {
                        target: slashBlade; property: "x"
                        to: 180 * root.sd
                        duration: 1500; easing.type: Easing.OutSine
                    }
                    NumberAnimation {
                        target: slashBlade; property: "width"
                        to: 0
                        duration: 1500; easing.type: Easing.OutSine
                    }
                    NumberAnimation {
                        target: slashBlade; property: "opacity"
                        to: 0.0; duration: 1000
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    //   RIGHT COLUMN — System Controls   (hyprlock: halign = right)
    // ═══════════════════════════════════════════════════════════════════════

    // ── Panel header ──   hyprlock: -80, 0
    Text {
        text: "── SYS.CTRL ──┐"
        color: root.primary(0.4)
        font.family: root.fnMono
        font.pixelSize: root.pt(12)
        x: root.hx(width, -80, "right"); y: root.hy(height, 0, "center")
    }

    // Control label: Rajdhani Bold 18pt, right-aligned at x = -100
    component Control: Text {
        id: ctl
        property real py: 0
        property color baseColor: root.secondary(0.8)
        property color hoverColor: root.cAccent
        signal activated()
        color: ctlMouse.containsMouse ? hoverColor : baseColor
        font.family: root.fn
        font.pixelSize: root.pt(18)
        font.bold: true
        x: root.hx(width, -100, "right"); y: root.hy(height, py, "center")
        MouseArea {
            id: ctlMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ctl.activated()
        }
    }

    // ┊ separator at x = -80
    component Divider: Text {
        property real py: 0
        text: "┊"
        color: root.secondary(0.12)
        font.family: root.fnMono
        font.pixelSize: root.pt(12)
        x: root.hx(width, -80, "right"); y: root.hy(height, py, "center")
    }

    // ── Suspend ──   hyprlock: -100, -50
    Control {
        py: -50
        text: "󰒲   SLEEP"
        onActivated: if (typeof sddm !== "undefined") sddm.suspend()
    }
    Divider { py: -80 }

    // ── Session ──   takes hyprlock's LOGOUT slot: -100, -110
    Control {
        py: -110
        visible: !root.isQuickshell
        text: String.fromCodePoint(0xF0379) + "   " + ((typeof sessionModel !== "undefined" && sessionModel.count > root.sessionIndex && root.sessionIndex >= 0 && sessionHelper.currentItem) ? sessionHelper.currentItem.sName : "Default").replace(/\s*\(.*\)/, "").toUpperCase()
        baseColor: root.accent(0.8)
        hoverColor: root.cSecondary
        onActivated: {
            if (typeof sessionModel !== "undefined" && sessionModel.rowCount() > 0)
                root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount()
        }
    }
    Divider { py: -140 }

    // ── Reboot ──   hyprlock: -100, -170
    Control {
        py: -170
        text: "󰑓   REBOOT"
        baseColor: root.accent(0.8)
        hoverColor: root.cSecondary
        onActivated: if (typeof sddm !== "undefined") sddm.reboot()
    }
    Divider { py: -200 }

    // ── Shutdown ──   hyprlock: -100, -230
    Control {
        py: -230
        text: "󰐥   SHUTDOWN"
        baseColor: root.primary(0.9)
        onActivated: if (typeof sddm !== "undefined") sddm.powerOff()
    }

    // ── Panel bottom accent ──   hyprlock: -80, -275
    Text {
        text: "──────────────┘"
        color: root.secondary(0.15)
        font.family: root.fnMono
        font.pixelSize: root.pt(12)
        x: root.hx(width, -80, "right"); y: root.hy(height, -275, "center")
    }

    // ═══════════════════════════════════════════════════════════════════════
    //   BOTTOM-RIGHT — HUD Interface (SDDM only)
    // ═══════════════════════════════════════════════════════════════════════
    Item {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40 * sd
        anchors.right: parent.right
        anchors.rightMargin: 50 * sd
        width: 240 * sd
        height: 90 * sd

        Column {
            anchors.right: parent.right
            spacing: 6 * sd

            // Equalizer bars
            Row {
                spacing: 3 * sd
                height: 16 * sd
                anchors.right: parent.right
                Repeater {
                    model: 7
                    Item {
                        width: 4 * root.sd
                        height: 16 * root.sd
                        Rectangle {
                            width: 4 * root.sd
                            anchors.bottom: parent.bottom
                            color: root.cSecondary
                            SequentialAnimation on height {
                                loops: Animation.Infinite
                                NumberAnimation {
                                    to: 3 * root.sd
                                    duration: 180 + index * 70
                                    easing.type: Easing.InOutSine
                                }
                                NumberAnimation {
                                    to: 14 * root.sd
                                    duration: 180 + index * 70
                                    easing.type: Easing.InOutSine
                                }
                            }
                        }
                    }
                }
            }

            // Separator line
            Rectangle {
                width: 200 * sd; height: 1
                color: root.cSecondary; opacity: 0.3
                anchors.right: parent.right
            }

            // Firmware text
            Text {
                text: "FIRMWARE VER 2.4.11"
                color: root.cSecondaryDim
                font.family: root.fnMono
                font.pixelSize: 9 * sd
                font.letterSpacing: 2
                anchors.right: parent.right
            }

            // Unauthorized access warning
            Text {
                text: "UNAUTHORIZED ACCESS PROHIBITED"
                color: root.cPrimary
                font.family: root.fnMono
                font.pixelSize: 9 * sd
                font.letterSpacing: 1
                anchors.right: parent.right
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.25; duration: 900 }
                    NumberAnimation { to: 0.75; duration: 900 }
                }
            }

            // Barcode decoration
            Row {
                spacing: 2 * sd
                anchors.right: parent.right
                Repeater {
                    model: 24
                    Rectangle {
                        width:  (index % 4 === 0 ? 3 * root.sd : (index % 5 === 0 ? 4 * root.sd : 1.5 * root.sd))
                        height: (index % 3 === 0 ? 20 * root.sd : 14 * root.sd)
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.cSecondaryDim
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    //   BOTTOM CENTER — Data Feed Ticker   hyprlock: 0, 8  center/bottom
    // ═══════════════════════════════════════════════════════════════════════
    Text {
        text: "▸ CYBERSPACE.NET.STATUS :: ALL.SYSTEMS.NOMINAL :: UPLINK.ACTIVE"
        color: root.tertiary(0.35)
        font.family: root.fnMono
        font.pixelSize: root.pt(11)
        x: root.hx(width, 0, "center"); y: root.hy(height, 8, "bottom")
    }

    // ═══════════════════════════════════════════════════════════════════════
    //   CORNER DECORATIONS — hyprlock: ±40, -30 top / ±40, 10 bottom
    // ═══════════════════════════════════════════════════════════════════════
    component Corner: Text {
        color: root.primary(0.25)
        font.family: root.fnMono
        font.pixelSize: root.pt(16)
    }
    Corner { text: "┌─"; x: root.hx(width,  40, "left");  y: root.hy(height, -30, "top") }
    Corner { text: "─┐"; x: root.hx(width, -40, "right"); y: root.hy(height, -30, "top") }
    Corner { text: "└─"; color: root.secondary(0.2); x: root.hx(width,  40, "left");  y: root.hy(height, 10, "bottom") }
    Corner { text: "─┘"; color: root.secondary(0.2); x: root.hx(width, -40, "right"); y: root.hy(height, 10, "bottom") }

    // ═══════════════════════════════════════════════════════════════════════
    //   FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════
    function doLogin() {
        if (pwInput.text !== "") {
            var uname = ""
            if (typeof userModel !== "undefined") {
                uname = userModel.data(userModel.index(root.currentUserIndex, 0), Qt.UserRole + 1)
            }
            root.authState = "check"
            if (typeof sddm !== "undefined") sddm.login(uname, pwInput.text, root.sessionIndex)
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    //   CONNECTIONS
    // ═══════════════════════════════════════════════════════════════════════
    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginFailed() {
            root.authState = "fail"
            failTimer.restart()
            pwInput.text = ""
            pwInput.forceActiveFocus()
        }
    }

    Component.onCompleted: {
        keyboard.numLock = true
        if (typeof userModel !== "undefined" && userModel.lastIndex >= 0)
            root.currentUserIndex = userModel.lastIndex
        pwInput.forceActiveFocus()
    }
}
