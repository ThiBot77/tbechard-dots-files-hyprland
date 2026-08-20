/*
 * Greeter for the tbe-dots-files rice — laid out to mirror hyprlock.conf so
 * the login and lock screens read as one design.
 *
 * Import constraints, verified on this machine (Qt 5.15.19 / SDDM 0.21):
 *   - QtQuick 2.15 and QtQuick.Layouts ARE available.
 *   - QtQuick.Controls 2 and QtGraphicalEffects are NOT installed. Using them
 *     makes the whole document fail to load and SDDM silently falls back to
 *     its bundled theme, so everything here is built from plain QtQuick items
 *     and SddmComponents.
 *   - No runtime image effects means the circular avatar has to ship
 *     pre-masked (assets/avatar.png); only its ring is drawn here, so it
 *     still follows the accent colour.
 *
 * Validate changes with the real greeter, not the qt6 one:
 *   sddm-greeter --test-mode --theme /usr/share/sddm/themes/tbe
 */
import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: container
    width: 1920
    height: 1080
    color: config.background

    property int sessionIndex: sessionList.currentIndex
    property string errorText: ""

    TextConstants { id: textConstants }

    Connections {
        target: sddm

        function onLoginFailed() {
            passwordInput.text = ""
            container.errorText = textConstants.loginFailed
            passwordInput.forceActiveFocus()
        }

        function onLoginSucceeded() {
            container.errorText = ""
        }
    }

    // --- background ---------------------------------------------------------
    Image {
        anchors.fill: parent
        source: config.backgroundImage
        fillMode: Image.PreserveAspectCrop
        cache: true
    }

    // The jpg is already blurred and darkened; this only fine-tunes contrast
    // so the text stays legible on brighter wallpapers.
    Rectangle {
        anchors.fill: parent
        color: config.background
        opacity: 0.28
    }

    // --- centre stack -------------------------------------------------------
    Column {
        id: stack
        anchors.centerIn: parent
        spacing: 0

        Text {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            color: config.foreground
            font.family: config.font
            font.pixelSize: 108
            font.weight: Font.ExtraLight
            text: Qt.formatDateTime(new Date(), "HH:mm")

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clock.text = Qt.formatDateTime(new Date(), "HH:mm")
            }
        }

        // Locale forced to fr_FR: the greeter runs as the `sddm` user, whose
        // environment has no LANG, so Qt.locale() would render English here.
        Text {
            id: dateText
            anchors.horizontalCenter: parent.horizontalCenter
            color: config.foregroundDim
            font.family: config.font
            font.pixelSize: 14
            font.letterSpacing: 3.2
            font.capitalization: Font.AllUppercase
            text: new Date().toLocaleDateString(Qt.locale("fr_FR"), "dddd d MMMM")

            Timer {
                interval: 60000
                running: true
                repeat: true
                onTriggered: dateText.text =
                    new Date().toLocaleDateString(Qt.locale("fr_FR"), "dddd d MMMM")
            }
        }

        Item { width: 1; height: 56 }

        Item {
            id: avatarBox
            anchors.horizontalCenter: parent.horizontalCenter
            width: 150
            height: 150

            Image {
                anchors.fill: parent
                source: config.avatarImage
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: config.accent
            }
        }

        Item { width: 1; height: 16 }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: config.foreground
            font.family: config.font
            font.pixelSize: 18
            font.weight: Font.Medium
            text: config.fullName
        }

        Item { width: 1; height: 28 }

        // Hand-rolled instead of SddmComponents TextBox/PasswordBox: neither
        // has a placeholder, and both hardcode an 8px text inset that collides
        // with a pill radius. A plain TextInput gives padding and placeholder.
        Rectangle {
            id: userField
            anchors.horizontalCenter: parent.horizontalCenter
            width: 340
            height: 50
            radius: 25
            color: config.surface
            opacity: 0.94
            border.width: 1
            border.color: userInput.activeFocus ? config.accent : config.border

            Behavior on border.color { ColorAnimation { duration: 120 } }

            // Prefilled from userModel.lastUser, but editable: that value is
            // empty until someone has logged in through SDDM at least once,
            // and a read-only field would lock out a fresh install.
            TextInput {
                id: userInput
                anchors.fill: parent
                anchors.leftMargin: 22
                anchors.rightMargin: 22
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                color: config.foreground
                font.family: config.font
                font.pixelSize: 15
                selectionColor: config.accent
                selectedTextColor: config.background
                text: userModel.lastUser

                KeyNavigation.tab: passwordInput

                onTextChanged: container.errorText = ""

                Keys.onPressed: function (event) {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        passwordInput.forceActiveFocus()
                        event.accepted = true
                    }
                }
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 22
                anchors.verticalCenter: parent.verticalCenter
                text: "Identifiant"
                color: config.foregroundDim
                font.family: config.font
                font.pixelSize: 15
                visible: userInput.text === ""
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.IBeamCursor
                onClicked: userInput.forceActiveFocus()
            }
        }

        Item { width: 1; height: 12 }

        Rectangle {
            id: passwordField
            anchors.horizontalCenter: parent.horizontalCenter
            width: 340
            height: 50
            radius: 25
            color: config.surface
            opacity: 0.94
            border.width: 1
            border.color: passwordInput.activeFocus ? config.accent : config.border

            Behavior on border.color { ColorAnimation { duration: 120 } }

            TextInput {
                id: passwordInput
                anchors.fill: parent
                anchors.leftMargin: 22
                anchors.rightMargin: 22
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                color: config.foreground
                font.family: config.font
                font.pixelSize: 15
                selectionColor: config.accent
                selectedTextColor: config.background
                echoMode: TextInput.Password
                passwordCharacter: "\u25cf"
                passwordMaskDelay: 0

                KeyNavigation.backtab: userInput

                onTextChanged: container.errorText = ""

                Keys.onPressed: function (event) {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        sddm.login(userInput.text, passwordInput.text, container.sessionIndex)
                        event.accepted = true
                    }
                }
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 22
                anchors.verticalCenter: parent.verticalCenter
                text: "Mot de passe"
                color: config.foregroundDim
                font.family: config.font
                font.pixelSize: 15
                visible: passwordInput.text === ""
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.IBeamCursor
                onClicked: passwordInput.forceActiveFocus()
            }
        }

        Item { width: 1; height: 16 }

        // Fixed height so a login error or the caps-lock hint never shifts
        // the stack above it.
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 400
            height: 20

            Text {
                id: message
                anchors.centerIn: parent
                color: config.accent
                font.family: config.font
                font.pixelSize: 13
                text: container.errorText !== ""
                      ? container.errorText
                      : (keyboard.capsLock ? textConstants.capslockWarning : "")
            }
        }
    }

    // --- bottom bar ---------------------------------------------------------
    Item {
        id: sessionBox
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 48
        anchors.bottomMargin: 44
        width: 250
        height: 40

        Rectangle {
            id: sessionHeader
            anchors.fill: parent
            radius: 20
            color: config.surface
            opacity: 0.92
            border.width: 1
            border.color: sessionPopup.visible ? config.accent : config.border

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 44
                elide: Text.ElideRight
                color: config.foreground
                font.family: config.font
                font.pixelSize: 13
                text: sessionList.currentItem ? sessionList.currentItem.sessionName : ""
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                color: config.foregroundDim
                font.pixelSize: 9
                text: sessionPopup.visible ? "▲" : "▼"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: sessionPopup.visible = !sessionPopup.visible
            }
        }

        // Opens upward on purpose: anchored to the bottom of the screen, a
        // downward popup would render off-screen.
        Rectangle {
            id: sessionPopup
            visible: false
            z: 10
            anchors.bottom: sessionHeader.top
            anchors.bottomMargin: 8
            width: parent.width
            height: Math.min(sessionList.contentHeight + 8, 220)
            radius: 14
            color: config.surface
            border.width: 1
            border.color: config.border
            clip: true

            ListView {
                id: sessionList
                anchors.fill: parent
                anchors.margins: 4
                model: sessionModel
                currentIndex: sessionModel.lastIndex
                clip: true

                delegate: Rectangle {
                    property string sessionName: model.name
                    width: sessionList.width
                    height: 32
                    radius: 9
                    color: itemArea.containsMouse ? config.accent : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 24
                        elide: Text.ElideRight
                        text: model.name
                        color: itemArea.containsMouse ? config.background : config.foreground
                        font.family: config.font
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: itemArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            sessionList.currentIndex = index
                            sessionPopup.visible = false
                        }
                    }
                }
            }
        }
    }

    // Layout name and hostname are only populated by a real greeter session,
    // so every part hides itself when empty rather than leaving a stray
    // icon or separator floating in the bar.
    Row {
        id: statusRow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 52
        spacing: 10

        property string layoutName: {
            if (typeof keyboard === "undefined" || !keyboard.layouts)
                return ""
            var l = keyboard.layouts[keyboard.currentLayout]
            return l ? l.shortName : ""
        }
        property string host: sddm.hostName ? sddm.hostName : ""

        Text {
            visible: statusRow.layoutName !== ""
            color: config.foregroundDim
            font.family: config.iconFont
            font.pixelSize: 13
            text: "\uf11c"
        }

        Text {
            visible: statusRow.layoutName !== ""
            color: config.foregroundDim
            font.family: config.font
            font.pixelSize: 13
            font.letterSpacing: 1.6
            font.capitalization: Font.AllUppercase
            text: statusRow.layoutName
        }

        Text {
            visible: statusRow.layoutName !== "" && statusRow.host !== ""
            color: config.border
            font.pixelSize: 13
            text: "\u2022"
        }

        Text {
            visible: statusRow.host !== ""
            color: config.foregroundDim
            font.family: config.font
            font.pixelSize: 13
            text: statusRow.host
        }
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 48
        anchors.bottomMargin: 44
        spacing: 12

        Repeater {
            model: [
                { glyph: "", act: "suspend",  shown: sddm.canSuspend },
                { glyph: "", act: "reboot",   shown: sddm.canReboot },
                { glyph: "", act: "poweroff", shown: sddm.canPowerOff }
            ]

            delegate: Rectangle {
                visible: modelData.shown
                width: 40
                height: 40
                radius: 20
                color: powerArea.containsMouse ? config.accent : config.surface
                opacity: powerArea.containsMouse ? 1.0 : 0.92
                border.width: 1
                border.color: powerArea.containsMouse ? config.accent : config.border

                Text {
                    anchors.centerIn: parent
                    text: modelData.glyph
                    color: powerArea.containsMouse ? config.background : config.foregroundDim
                    font.family: config.iconFont
                    font.pixelSize: 15
                }

                MouseArea {
                    id: powerArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.act === "suspend")
                            sddm.suspend()
                        else if (modelData.act === "reboot")
                            sddm.reboot()
                        else
                            sddm.powerOff()
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        if (userInput.text === "")
            userInput.forceActiveFocus()
        else
            passwordInput.forceActiveFocus()
    }
}
