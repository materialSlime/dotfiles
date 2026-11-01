// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                     CYBERPUNK SDDM THEME                               ║
// ║  Color palette matched to Hyprland + Waybar + Hyprlock cyberpunk theme  ║
// ║                                                                        ║
// ║  LAYOUT: port of ~/.config/hypr/hyprlock.conf (center + bottom dock)   ║
// ║    Center      — big clock, date, user + password                      ║
// ║    Bottom dock — HOST panel (left), SYS.CTRL 2×2 grid (right)          ║
// ║    Every hyprlock widget is placed with hx()/hy() using the SAME       ║
// ║    position / halign / valign values, and font sizes go through pt()   ║
// ║    so they render at the same pixel size as hyprlock.                  ║
// ║    Change a value in hyprlock.conf → change the same number here.      ║
// ║                                                                        ║
// ║  Differences from hyprlock (a greeter has no session yet):             ║
// ║    - the media slot is the user's avatar + HOST info (hostname /       ║
// ║      kernel / OS); avatar.png = ~/.face.icon or the user's initial     ║
// ║    - LOGOUT's slot in the grid is the session selector                 ║
// ║                                                                        ║
// ║  PALETTE:                                                              ║
// ║    Colors: ~/.config/theme/palette -> theme.conf.user (config.c_<name>)║
// ║  INSTALL:  ~/.config/theme/build --sddm                                ║
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
    // Old 768p scale, only used by the SDDM-only decorations (particles, blade).
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
    readonly property color cSecondary:    config.c_secondary     || "#5EF6FF"   // Neon cyan
    readonly property color cAccent:       config.c_accent        || "#F3E900"   // clock / highlight
    readonly property color cPrimary:      config.c_primary       || "#F75049"   // alert red
    readonly property color cTertiary:     config.c_tertiary      || "#246DCE"   // deep blue
    readonly property color cText:         config.c_text          || "#CDD6F4"   // body text
    readonly property color cBg:           config.c_bg            || "#0E0E17"   // void black
    readonly property color cSecondaryDim: config.c_secondary_dim || "#25575F"

    function secondary(a) { return Qt.rgba(cSecondary.r, cSecondary.g, cSecondary.b, a) }
    function accent(a)    { return Qt.rgba(cAccent.r, cAccent.g, cAccent.b, a) }
    function primary(a)   { return Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, a) }
    function tertiary(a)  { return Qt.rgba(cTertiary.r, cTertiary.g, cTertiary.b, a) }
    function text(a)      { return Qt.rgba(cText.r, cText.g, cText.b, a) }

    // ═══════════════════════════════════════════════════════════════════════
    //   STATE
    // ═══════════════════════════════════════════════════════════════════════
    property bool isQuickshell: typeof sddm === "undefined" || sddm.hostName === undefined
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    // 12h clock like hyprlock's %I/%p. Qt's "hh" is only 12h when "AP" is in
    // the same format string, so format once and split.
    property var clockParts: Qt.formatTime(new Date(), "hh mm ss AP").split(" ")
    property string currentDate: Qt.formatDate(new Date(), "dddd  //  dd MMMM yyyy")
    property int currentUserIndex: 0
    property string authState: ""   // "", "check", "fail" — mirrors hyprlock

    // live from SDDM; test mode has none, so fall back to the name saved at install
    // login name of the selected user (avatar file name, initial)
    readonly property string selectedUser: (typeof userModel !== "undefined" && userModel.count > 0)
        ? (userModel.data(userModel.index(currentUserIndex, 0), Qt.UserRole + 1) || "") : ""

    // "Hyprland (uwsm-managed)" -> name "HYPRLAND", variant "UWSM"; "Hyprland" -> no variant.
    // The variant is shown as a small tag under the session name (like SAMURAI
    // under the username), so the grid keeps hyprlock's column widths.
    readonly property string sessionFull: (typeof sessionModel !== "undefined" && sessionModel.count > sessionIndex && sessionIndex >= 0 && sessionHelper.currentItem) ? sessionHelper.currentItem.sName : "Default"
    readonly property string sessionName: sessionFull.replace(/\s*\(.*\)\s*$/, "").toUpperCase()
    readonly property string sessionVariant: {
        var m = sessionFull.match(/\(([^)]*?)(-managed)?\)\s*$/)
        return m ? m[1].toUpperCase() : ""
    }

    readonly property string hostName: (!isQuickshell && sddm.hostName) ? sddm.hostName : (config.host_name || "localhost")

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
    //   BACKGROUND — bg.jpg, rendered by ~/.config/theme/sddm/background.py
    //   (hyprlock blurs a live screenshot; a greeter has none)
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

                color: Math.random() < 0.12 ? root.cSecondary : root.cPrimary
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

    // ── Top-left header ──   hyprlock: 80, -50  left/top
    Text {
        text: "┌── SYSTEM :: ENCRYPTED ──────────────────────"
        color: root.primary(0.5)
        font.family: root.fnMono
        font.pixelSize: root.pt(12)
        x: root.hx(width, 80, "left"); y: root.hy(height, -50, "top")
    }

    // ═══════════════════════════════════════════════════════════════════════
    //   CENTER — Clock, date, user + password   (hyprlock: halign = center)
    // ═══════════════════════════════════════════════════════════════════════

    // ── Clock ──   hyprlock: HH:MM centered, y 170
    // Rajdhani digits are proportional ("1" is much narrower than "8") and the
    // font has no tabular digits, so every digit gets a fixed slot as wide as
    // an "8" — the clock keeps one width all day. The middle digits are centered
    // in their slots; the first and last are placed by their own ink bounds so
    // they sit flush with the clock's edges (and the username / password row).
    // Seconds ride top-aligned after the minutes, AM/PM sits under them.
    TextMetrics {
        id: digitMetrics
        font.family: root.fn
        font.pixelSize: root.pt(160)
        font.bold: true
        text: "8"
    }

    // ink bounds of the two edge digits
    TextMetrics { id: firstInk; font: digitMetrics.font; text: root.clockParts[0].charAt(0) }
    TextMetrics { id: lastInk;  font: digitMetrics.font; text: root.clockParts[1].charAt(1) }

    component Digit: Text {
        width: digitMetrics.advanceWidth
        horizontalAlignment: Text.AlignHCenter
        font.family: root.fn
        font.pixelSize: root.pt(160)
        font.bold: true
    }

    Item {
        id: clockGroup
        readonly property real slot: digitMetrics.advanceWidth
        readonly property real hhmmWidth: 4 * slot + colonText.width     // HH:MM only
        width: secondsText.x + Math.max(secondsText.width, amPmText.width)
        height: hoursText.height
        x: root.hx(hhmmWidth, 0, "center"); y: root.hy(height, 170, "center")

        // hour tens: ink starts exactly at the left edge
        Text {
            id: hoursText
            text: root.clockParts[0].charAt(0); color: root.cAccent
            font: digitMetrics.font
            x: -firstInk.tightBoundingRect.x
        }
        Digit {
            id: hours2; text: root.clockParts[0].charAt(1); color: root.cAccent
            x: clockGroup.slot; anchors.baseline: hoursText.baseline
        }

        Text {
            id: colonText
            text: ":"
            color: root.primary(0.9)
            font.family: root.fn
            font.pixelSize: root.pt(130)
            font.bold: true
            x: 2 * clockGroup.slot
            anchors.baseline: hoursText.baseline
        }

        Digit {
            id: minutes1; text: root.clockParts[1].charAt(0); color: root.cSecondary
            x: 2 * clockGroup.slot + colonText.width; anchors.baseline: hoursText.baseline
        }
        // minute ones: ink ends exactly at the right edge
        Text {
            id: minutes2
            text: root.clockParts[1].charAt(1); color: root.cSecondary
            font: digitMetrics.font
            x: clockGroup.hhmmWidth - lastInk.tightBoundingRect.x - lastInk.tightBoundingRect.width
            anchors.baseline: hoursText.baseline
        }

        // rise 110px = Rajdhani digit height (137) - mono digit height (27)
        Text {
            id: secondsText
            text: root.clockParts[2]
            color: root.secondary(0.35)
            font.family: root.fnMono
            font.pixelSize: root.pt(28)
            x: clockGroup.hhmmWidth + root.pt(12) * 0.6   // one 12pt mono space after HH:MM
            anchors.baseline: hoursText.baseline
            anchors.baselineOffset: -110 * root.s
        }

        // hyprlock: same mono font/size as the seconds, primary 70%
        Text {
            id: amPmText
            text: root.clockParts[3]
            color: root.primary(0.7)
            font.family: root.fnMono
            font.pixelSize: root.pt(28)
            x: secondsText.x
            anchors.baseline: hoursText.baseline
        }
    }

    // ── Date ──   hyprlock: 0, 45  center/center
    Text {
        text: root.currentDate
        color: root.secondary(0.55)
        font.family: root.fn
        font.pixelSize: root.pt(20)
        font.bold: true
        x: root.hx(width, 0, "center"); y: root.hy(height, 45, "center")
    }

    // ── Separator ──   hyprlock: 0, 5  center/center
    Text {
        text: "──────────────────── ◆ ────────────────────"
        color: root.secondary(0.15)
        font.family: root.fnMono
        font.pixelSize: root.pt(10)
        x: root.hx(width, 0, "center"); y: root.hy(height, 5, "center")
    }

    // ── Username ──   ink starts at the clock's left edge (hyprlock: -223, -45)
    TextMetrics { id: userInk; font: userText.font; text: userText.text }
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
        color: userMouse.containsMouse ? root.cSecondary : root.primary(0.95)
        font.family: root.fn
        font.pixelSize: root.pt(28)
        font.bold: true
        x: clockGroup.x - userInk.tightBoundingRect.x; y: root.hy(height, -45, "center")

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

    // ── User role tag ──   centered under the username (hyprlock: -220, -78)
    Text {
        text: "SAMURAI"
        color: root.tertiary(0.5)
        font.family: root.fnMono
        font.pixelSize: root.pt(12)
        x: userText.x + (userText.width - width) / 2; y: root.hy(height, -78, "center")
    }

    // ── Input Field ──   24 px after the username, ends at the clock's right edge
    //    (hyprlock: size 419x55 at 39, -60 for the user "neo")
    Rectangle {
        id: inputContainer
        x: userText.x + userText.width + 24 * root.s
        width: clockGroup.x + clockGroup.hhmmWidth - x
        height: 55 * root.s
        y: root.hy(height, -60, "center")
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

        Rectangle {
            width: parent.width; height: 1
            color: root.cPrimary; opacity: 0.15
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            id: slashBlade
            height: 1.5 * sd
            y: (parent.height - height) / 2

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.6; color: root.cPrimary }
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
    //   BOTTOM DOCK — left: HOST panel · right: system controls
    // ═══════════════════════════════════════════════════════════════════════

    // ── Dock headers ──   hyprlock: 80, 215 left/bottom · -80, 215 right/bottom
    Text {
        text: "┌── HOST ─────────────────"
        color: root.secondary(0.35)
        font.family: root.fnMono
        font.pixelSize: root.pt(12)
        x: root.hx(width, 80, "left"); y: root.hy(height, 215, "bottom")
    }
    Text {
        text: "───────────────── SYS.CTRL ──┐"
        color: root.primary(0.4)
        font.family: root.fnMono
        font.pixelSize: root.pt(12)
        x: root.hx(width, -80, "right"); y: root.hy(height, 215, "bottom")
    }

    // ── Avatar ──   square 130×130 at 100, 60 left/bottom (hyprlock's media cover
    //    is 16:9 in the same spot). avatars/<user>.png is rendered by
    //    `build --sddm` from ~/.face.icon. Users without one get their initial.
    Item {
        width: 130 * root.s
        height: 130 * root.s
        x: root.hx(width, 100, "left"); y: root.hy(height, 60, "bottom")

        Rectangle {               // initial fallback
            anchors.fill: parent
            anchors.margins: 3 * root.s
            radius: 8 * root.s
            color: Qt.rgba(root.cBg.r, root.cBg.g, root.cBg.b, 0.9)
            visible: avatarImage.status !== Image.Ready
            Text {
                anchors.centerIn: parent
                text: (root.selectedUser || "?").charAt(0).toUpperCase()
                color: root.cPrimary
                style: Text.Outline; styleColor: root.primary(0.35)
                font.family: root.fnMono
                font.pixelSize: parent.height * 0.62
                font.bold: true
            }
        }
        Image {
            id: avatarImage
            anchors.fill: parent
            anchors.margins: 3 * root.s
            source: root.selectedUser ? "avatars/" + root.selectedUser + ".png" : ""
            fillMode: Image.PreserveAspectCrop
            smooth: true
            visible: status === Image.Ready
        }
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            radius: 10 * root.s
            border.width: 3 * root.s
            border.color: root.primary(0.5)
        }
    }

    // ── HOST lines ──   x 260 left/bottom (30 px after the square avatar), y 150 / 115 / 82
    Text {
        text: String.fromCodePoint(0xF0379) + "  " + root.hostName.toUpperCase()
        color: root.primary(0.95)
        font.family: root.fn
        font.pixelSize: root.pt(22)
        font.bold: true
        x: root.hx(width, 260, "left"); y: root.hy(height, 150, "bottom")
    }
    Text {
        text: "Linux " + (config.host_kernel || "")
        color: root.text(0.7)
        font.family: root.fn
        font.pixelSize: root.pt(16)
        font.bold: true
        x: root.hx(width, 260, "left"); y: root.hy(height, 115, "bottom")
    }
    Text {
        text: (config.host_os || "Linux").toUpperCase()
        color: root.primary(0.9)
        font.family: root.fnMono
        font.pixelSize: root.pt(13)
        font.letterSpacing: 8 * root.s
        x: root.hx(width, 260, "left"); y: root.hy(height, 82, "bottom")
    }

    // ── System controls: 2 × 2 grid, each column left-aligned ──   y 140 / 85, bottom
    //    column left edges at x = -410 / -241 from the screen's right side,
    //    the same edges as hyprlock (its widest items: REBOOT, SHUTDOWN)
    component Control: Text {
        id: ctl
        property real px: -241          // column's left edge, from the right side
        property real py: 85
        property color baseColor: root.primary(0.85)
        property color hoverColor: root.cSecondary
        signal activated()
        color: ctlMouse.containsMouse ? hoverColor : baseColor
        font.family: root.fn
        font.pixelSize: root.pt(18)
        font.bold: true
        x: root.width + px * root.s; y: root.hy(height, py, "bottom")
        MouseArea {
            id: ctlMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ctl.activated()
        }
    }

    Control {
        px: -410; py: 140
        text: "󰒲   SLEEP"
        onActivated: if (typeof sddm !== "undefined") sddm.suspend()
    }

    // Session selector — takes hyprlock's LOGOUT slot
    Control {
        id: sessionCtl
        px: -241; py: 140
        visible: !root.isQuickshell
        text: String.fromCodePoint(0xF0379) + "   " + root.sessionName
        baseColor: root.primary(0.85)
        hoverColor: root.cSecondary
        onActivated: {
            if (typeof sessionModel !== "undefined" && sessionModel.rowCount() > 0)
                root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount()
        }
    }

    // session variant tag, e.g. UWSM for "Hyprland (uwsm-managed)"
    Text {
        visible: sessionCtl.visible && root.sessionVariant !== ""
        text: root.sessionVariant
        color: root.tertiary(0.6)
        font.family: root.fnMono
        font.pixelSize: root.pt(10)
        font.letterSpacing: 2 * root.s
        x: sessionCtl.x + root.pt(18) * 1.55     // under the name, past the icon
        anchors.top: sessionCtl.bottom
        anchors.topMargin: -4 * root.s
    }

    Control {
        px: -410; py: 85
        text: "󰑓   REBOOT"
        baseColor: root.primary(0.85)
        hoverColor: root.cSecondary
        onActivated: if (typeof sddm !== "undefined") sddm.reboot()
    }

    Control {
        px: -241; py: 85
        text: "󰐥   SHUTDOWN"
        baseColor: root.primary(0.85)
        onActivated: if (typeof sddm !== "undefined") sddm.powerOff()
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
