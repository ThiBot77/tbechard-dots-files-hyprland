/*
 * Greeter for the tbe-dots-files rice.
 *
 * Modelled on the themes SDDM ships (maldives/elarun): versioned imports and
 * SddmComponents widgets only. QtQuick.Controls / QtQuick.Layouts are NOT
 * available to the greeter — using them silently fails and SDDM falls back to
 * its default theme.
 */
import QtQuick 2.0
import SddmComponents 2.0

Rectangle {
    id: container
    width: 1920
    height: 1080
    color: config.background

    property int sessionIndex: sessionBox.index

    TextConstants { id: textConstants }

    Connections {
        target: sddm

        function onLoginFailed() {
            password.text = ""
            errorMessage.text = textConstants.loginFailed
            password.forceActiveFocus()
        }

        function onLoginSucceeded() {
            errorMessage.text = ""
        }
    }

    // --- centre: horloge, date, utilisateur, mot de passe -------------------
    Column {
        id: mainColumn
        anchors.centerIn: parent
        spacing: 14

        Text {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            color: config.foreground
            font.family: config.font
            font.pixelSize: 88
            font.bold: true
            text: Qt.formatDateTime(new Date(), "HH:mm")

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clock.text = Qt.formatDateTime(new Date(), "HH:mm")
            }
        }

        Text {
            id: dateText
            anchors.horizontalCenter: parent.horizontalCenter
            color: config.foregroundDim
            font.family: config.font
            font.pixelSize: 20
            text: new Date().toLocaleDateString(Qt.locale(), "dddd d MMMM")
            bottomPadding: 24
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 320
            horizontalAlignment: Text.AlignLeft
            color: config.foregroundDim
            font.family: config.font
            font.pixelSize: 13
            text: textConstants.userName
        }

        // Editable on purpose: userModel.lastUser is empty on a machine that
        // has never logged in, and a read-only label would leave no way to
        // type a username. The shipped themes do the same.
        TextBox {
            id: userName
            anchors.horizontalCenter: parent.horizontalCenter
            width: 320
            height: 46
            radius: 12
            text: userModel.lastUser
            color: config.surface
            borderColor: config.border
            focusColor: config.accent
            hoverColor: config.accent
            textColor: config.foreground
            font.family: config.font
            font.pixelSize: 16

            KeyNavigation.tab: password

            Keys.onPressed: function (event) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    password.forceActiveFocus()
                    event.accepted = true
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 320
            horizontalAlignment: Text.AlignLeft
            color: config.foregroundDim
            font.family: config.font
            font.pixelSize: 13
            text: textConstants.password
            topPadding: 6
        }

        PasswordBox {
            id: password
            anchors.horizontalCenter: parent.horizontalCenter
            width: 320
            height: 46
            radius: 12
            color: config.surface
            borderColor: config.border
            focusColor: config.accent
            hoverColor: config.accent
            textColor: config.foreground
            font.family: config.font
            font.pixelSize: 16

            KeyNavigation.backtab: userName

            Keys.onPressed: function (event) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    sddm.login(userName.text, password.text, sessionIndex)
                    event.accepted = true
                }
            }
        }

        Text {
            id: errorMessage
            anchors.horizontalCenter: parent.horizontalCenter
            height: 20
            color: config.accent
            font.family: config.font
            font.pixelSize: 14
            text: ""
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 320
            horizontalAlignment: Text.AlignLeft
            color: config.foregroundDim
            font.family: config.font
            font.pixelSize: 13
            text: textConstants.session
        }

        // Kept in the centre column, not down with the power buttons:
        // SddmComponents.ComboBox anchors its dropdown to its own bottom edge
        // with no way to flip it, so near the screen edge the list opened
        // off-screen and the sessions were unreachable.
        ComboBox {
            id: sessionBox
            anchors.horizontalCenter: parent.horizontalCenter
            width: 320
            height: 40
            model: sessionModel
            index: sessionModel.lastIndex
            color: config.surface
            textColor: config.foreground
            borderColor: config.border
            focusColor: config.accent
            hoverColor: config.accent
            menuColor: config.surface
            // Without this the arrow box renders as a white block.
            arrowColor: config.surface
            font.family: config.font
            font.pixelSize: 14
        }
    }

    // --- bas: alimentation --------------------------------------------------
    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 32
        spacing: 20

        // Hand-rolled instead of SddmComponents.Button: that one exposes no
        // radius, so its corners can't be rounded.
        Component {
            id: powerButton

            Rectangle {
                property string label: ""
                property var action: function () {}

                width: buttonText.implicitWidth + 32
                height: 36
                radius: 10
                color: buttonArea.containsMouse ? config.accent : config.surface
                border.width: 1
                border.color: config.border

                Text {
                    id: buttonText
                    anchors.centerIn: parent
                    text: parent.label
                    color: buttonArea.containsMouse ? config.background : config.foreground
                    font.family: config.font
                    font.pixelSize: 14
                }

                MouseArea {
                    id: buttonArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: parent.action()
                }
            }
        }

        Loader {
            sourceComponent: powerButton
            onLoaded: {
                item.label = "Redémarrer"
                item.action = function () { sddm.reboot() }
            }
        }

        Loader {
            sourceComponent: powerButton
            onLoaded: {
                item.label = "Éteindre"
                item.action = function () { sddm.powerOff() }
            }
        }
    }

    Component.onCompleted: {
        if (userName.text === "")
            userName.forceActiveFocus()
        else
            password.forceActiveFocus()
    }
}
