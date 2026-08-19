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
        }

        Item { width: 1; height: 24 }

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

        Item { width: 1; height: 6 }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 320
            horizontalAlignment: Text.AlignLeft
            color: config.foregroundDim
            font.family: config.font
            font.pixelSize: 13
            text: textConstants.password
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

        // Hand-rolled dropdown rather than SddmComponents.ComboBox: that one
        // has no radius property, and it anchors its list to its own bottom
        // edge with no way to flip it (so at the bottom of the screen the
        // sessions opened off-screen). This one is rounded and lives in the
        // centre column, where there's room below it to expand.
        Item {
            id: sessionBox
            anchors.horizontalCenter: parent.horizontalCenter
            width: 320
            height: 40
            property alias index: sessionList.currentIndex

            Rectangle {
                id: sessionHeader
                anchors.fill: parent
                radius: 12
                color: config.surface
                border.width: 1
                border.color: sessionPopup.visible ? config.accent : config.border

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: config.foreground
                    font.family: config.font
                    font.pixelSize: 14
                    text: sessionList.currentItem ? sessionList.currentItem.sessionName : ""
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: config.foregroundDim
                    font.pixelSize: 10
                    text: sessionPopup.visible ? "▲" : "▼"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sessionPopup.visible = !sessionPopup.visible
                }
            }

            Rectangle {
                id: sessionPopup
                visible: false
                z: 10
                anchors.top: sessionHeader.bottom
                anchors.topMargin: 6
                width: parent.width
                height: Math.min(sessionList.contentHeight + 8, 220)
                radius: 12
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
                        radius: 8
                        color: itemArea.containsMouse ? config.accent : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: model.name
                            color: itemArea.containsMouse ? config.background : config.foreground
                            font.family: config.font
                            font.pixelSize: 14
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
