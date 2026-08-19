import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import SddmComponents

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: config.background

    property string cAccent: config.accent
    property string cFg: config.foreground
    property string cFgDim: config.foregroundDim
    property string cSurface: config.surface
    property string cBorder: config.border
    property string uiFont: config.font

    TextConstants { id: textConstants }

    Connections {
        target: sddm
        function onLoginSucceeded() {
            errorMessage.text = ""
        }
        function onLoginFailed() {
            errorMessage.text = textConstants.loginFailed
            password.text = ""
            password.forceActiveFocus()
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 18

        // Clock
        Text {
            id: clock
            Layout.alignment: Qt.AlignHCenter
            color: root.cFg
            font.family: root.uiFont
            font.pointSize: 48
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
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 20
            color: root.cFgDim
            font.family: root.uiFont
            font.pointSize: 12
            text: Qt.formatDateTime(new Date(), "dddd d MMMM")
        }

        // User
        Text {
            Layout.alignment: Qt.AlignHCenter
            color: root.cFg
            font.family: root.uiFont
            font.pointSize: 14
            text: userModel.lastUser
        }

        // Password
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 320
            height: 46
            radius: 12
            color: root.cSurface
            border.width: 1
            border.color: password.activeFocus ? root.cAccent : root.cBorder

            TextInput {
                id: password
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                passwordCharacter: "•"
                color: root.cFg
                font.family: root.uiFont
                font.pointSize: 12
                focus: true
                clip: true

                onAccepted: sddm.login(userModel.lastUser, password.text, sessionModel.lastIndex)

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.cFgDim
                    font: parent.font
                    text: textConstants.password
                    visible: password.text.length === 0 && !password.activeFocus
                }
            }
        }

        Text {
            id: errorMessage
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 16
            color: root.cAccent
            font.family: root.uiFont
            font.pointSize: 10
            text: ""
        }
    }

    // Session picker + power, bottom row
    RowLayout {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 28
        spacing: 24

        ComboBox {
            id: sessionBox
            model: sessionModel
            currentIndex: sessionModel.lastIndex
            textRole: "name"
            implicitWidth: 200
            font.family: root.uiFont
            font.pointSize: 10
        }

        Button {
            text: "Redémarrer"
            font.family: root.uiFont
            font.pointSize: 10
            enabled: sddm.canReboot
            onClicked: sddm.reboot()
        }

        Button {
            text: "Éteindre"
            font.family: root.uiFont
            font.pointSize: 10
            enabled: sddm.canPowerOff
            onClicked: sddm.powerOff()
        }
    }

    Component.onCompleted: password.forceActiveFocus()
}
