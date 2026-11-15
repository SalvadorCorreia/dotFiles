import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#282c42"

    readonly property real sx: width / 1920.0
    readonly property real sy: height / 1080.0
    readonly property real colCenterX: (width / 2.0) - (480.0 * sx)
    readonly property real centerY: height / 2.0

    property int sessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property string currentUser: (userModel && userModel.lastUser) ? userModel.lastUser : "salvador"
    property bool loginError: false

    function formatTime12(d) {
        var h = d.getHours() % 12
        if (h === 0) h = 12
        var hh = (h < 10 ? "0" : "") + h
        var mm = (d.getMinutes() < 10 ? "0" : "") + d.getMinutes()
        return hh + ":" + mm
    }

    function formatDate(d) {
        return d.toLocaleDateString(Qt.locale("en_US"), "dddd, MMMM dd")
    }

    function doLogin() {
        loginError = false
        sddm.login(currentUser, passwordInput.text, sessionIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            passwordInput.text = ""
            root.loginError = true
            passwordInput.forceActiveFocus()
        }
        function onLoginSucceeded() {
            root.loginError = false
        }
    }

    // BACKGROUND (matches hyprlock wallpaper5.jpg + brightness/contrast feel)
    Image {
        anchors.fill: parent
        source: config.background || "background.jpg"
        fillMode: Image.PreserveAspectCrop
        smooth: true
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.16
    }

    Timer {
        id: clockTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var now = new Date()
            timeLabel.text = root.formatTime12(now)
            dateLabel.text = root.formatDate(now)
        }
    }

    // GREETINGS (position = -480, 320 | font_size = 72)
    Text {
        id: greetingLabel
        text: "Welcome!"
        color: Qt.rgba(216/255, 222/255, 233/255, 0.75)
        font.family: "FreeSans"
        font.pixelSize: Math.round(72 * root.sy)
        font.bold: true
        x: root.colCenterX - width / 2
        y: root.centerY - (320 * root.sy) - height / 2
    }

    // Time (position = -480, 210 | font_size = 52)
    Text {
        id: timeLabel
        text: root.formatTime12(new Date())
        color: Qt.rgba(216/255, 222/255, 233/255, 0.75)
        font.family: "FreeSans"
        font.pixelSize: Math.round(52 * root.sy)
        font.bold: true
        x: root.colCenterX - width / 2
        y: root.centerY - (210 * root.sy) - height / 2
    }

    // Day-Month-Date (position = -480, 130 | font_size = 24)
    Text {
        id: dateLabel
        text: root.formatDate(new Date())
        color: Qt.rgba(216/255, 222/255, 233/255, 0.75)
        font.family: "FreeSans"
        font.pixelSize: Math.round(24 * root.sy)
        font.bold: true
        x: root.colCenterX - width / 2
        y: root.centerY - (130 * root.sy) - height / 2
    }

    // USER-BOX + USER (position = -480, -90 | size = 380, 65 | font_size = 20)
    Rectangle {
        id: userBox
        width: Math.round(380 * root.sx)
        height: Math.round(65 * root.sy)
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.10)
        x: root.colCenterX - width / 2
        y: root.centerY + (90 * root.sy) - height / 2

        Text {
            anchors.centerIn: parent
            text: "    " + root.currentUser
            color: Qt.rgba(216/255, 222/255, 233/255, 0.80)
            font.family: "FreeSans"
            font.pixelSize: Math.round(20 * root.sy)
            font.bold: true
        }
    }

    // INPUT FIELD (position = -480, -185 | size = 380, 65)
    Rectangle {
        id: inputBox
        width: Math.round(380 * root.sx)
        height: Math.round(65 * root.sy)
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.10)
        border.width: root.loginError ? 2 : 0
        border.color: Qt.rgba(235/255, 111/255, 146/255, 0.85)
        x: root.colCenterX - width / 2
        y: root.centerY + (185 * root.sy) - height / 2

        Text {
            id: placeholderLabel
            anchors.centerIn: parent
            visible: passwordInput.text.length === 0
            text: root.loginError ? "🔒  Wrong Password" : "🔒  Enter Pass"
            color: root.loginError ? "#ccff6b6b" : "#99ffffff"
            font.family: "FreeSans"
            font.pixelSize: Math.round(18 * root.sy)
            font.bold: true
            font.italic: true
        }

        TextInput {
            id: passwordInput
            anchors.fill: parent
            anchors.leftMargin: Math.round(28 * root.sx)
            anchors.rightMargin: Math.round(28 * root.sx)
            verticalAlignment: TextInput.AlignVCenter
            horizontalAlignment: TextInput.AlignHCenter
            echoMode: TextInput.Password
            passwordCharacter: "●"
            color: Qt.rgba(200/255, 200/255, 200/255, 1.0)
            font.family: "FreeSans"
            font.pixelSize: Math.round(18 * root.sy)
            font.bold: true
             font.letterSpacing: 4
            focus: true
            clip: true

            onTextChanged: {
                if (text.length > 0 && root.loginError) {
                    root.loginError = false
                }
            }

            Keys.onReturnPressed: root.doLogin()
            Keys.onEnterPressed: root.doLogin()
        }

        MouseArea {
            anchors.fill: parent
            onClicked: passwordInput.forceActiveFocus()
        }
    }

    // CRUCIAL SDDM CONTROLS: Session Switcher + Power Buttons (bottom of the same column)
    Column {
        id: controlsColumn
        spacing: Math.round(12 * root.sy)
        x: root.colCenterX - width / 2
        y: root.height - height - Math.round(40 * root.sy)

        // Session Selector Pill (click to cycle session)
        ListView {
            id: sessionList
            visible: false
            width: 1
            height: 1
            model: sessionModel
            currentIndex: root.sessionIndex
            delegate: Item {
                width: 1
                height: 1
                property string sessionName: model.name || ""
            }
        }

        Rectangle {
            id: sessionPill
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.max(Math.round(180 * root.sx), sessionText.implicitWidth + Math.round(36 * root.sx))
            height: Math.round(36 * root.sy)
            radius: height / 2
            color: sessionMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.10)

            Text {
                id: sessionText
                anchors.centerIn: parent
                text: "   Session: " + ((sessionList.currentItem && sessionList.currentItem.sessionName) ? sessionList.currentItem.sessionName : "Hyprland")
                color: Qt.rgba(216/255, 222/255, 233/255, 0.80)
                font.family: "FreeSans"
                font.pixelSize: Math.round(14 * root.sy)
                font.bold: true
            }

            MouseArea {
                id: sessionMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (sessionList.count > 0) {
                        root.sessionIndex = (root.sessionIndex + 1) % sessionList.count
                    }
                    passwordInput.forceActiveFocus()
                }
            }
        }

        // Power Action Pills: Suspend | Reboot | Shut Down
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.round(12 * root.sx)

            // Suspend
            Rectangle {
                width: Math.round(118 * root.sx)
                height: Math.round(40 * root.sy)
                radius: height / 2
                color: suspendMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.10)

                Text {
                    anchors.centerIn: parent
                    text: "󰤄  Suspend"
                    color: Qt.rgba(216/255, 222/255, 233/255, 0.80)
                    font.family: "FreeSans"
                    font.pixelSize: Math.round(14 * root.sy)
                    font.bold: true
                }

                MouseArea {
                    id: suspendMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sddm.suspend()
                }
            }

            // Reboot
            Rectangle {
                width: Math.round(118 * root.sx)
                height: Math.round(40 * root.sy)
                radius: height / 2
                color: rebootMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.10)

                Text {
                    anchors.centerIn: parent
                    text: "󰜉  Reboot"
                    color: Qt.rgba(216/255, 222/255, 233/255, 0.80)
                    font.family: "FreeSans"
                    font.pixelSize: Math.round(14 * root.sy)
                    font.bold: true
                }

                MouseArea {
                    id: rebootMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sddm.reboot()
                }
            }

            // Shut Down
            Rectangle {
                width: Math.round(118 * root.sx)
                height: Math.round(40 * root.sy)
                radius: height / 2
                color: powerMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.10)

                Text {
                    anchors.centerIn: parent
                    text: "  Power Off"
                    color: Qt.rgba(216/255, 222/255, 233/255, 0.80)
                    font.family: "FreeSans"
                    font.pixelSize: Math.round(14 * root.sy)
                    font.bold: true
                }

                MouseArea {
                    id: powerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sddm.powerOff()
                }
            }
        }
    }

    Component.onCompleted: {
        passwordInput.forceActiveFocus()
    }
}
