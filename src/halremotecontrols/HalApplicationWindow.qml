/****************************************************************************
**
** Copyright (C) 2014 Alexander Rössler
** License: LGPL version 2.1
**
** This file is part of QtQuickVcp.
**
** All rights reserved. This program and the accompanying materials
** are made available under the terms of the GNU Lesser General Public License
** (LGPL) version 2.1 which accompanies this distribution, and is available at
** http://www.gnu.org/licenses/lgpl-2.1.html
**
** This library is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
** Lesser General Public License for more details.
**
** Contributors:
** Alexander Rössler @ The Cool Tool GmbH <mail DOT aroessler AT gmail DOT com>
**
****************************************************************************/
import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Window 2.0
import Machinekit.HalRemote 1.0
import Machinekit.HalRemote.Controls 1.0

/*!
    \qmltype HalApplicationWindow
    \inqmlmodule Machinekit.HalRemote.Controls
    \brief Provides a application window to simplify HAL application deployment.
    \ingroup halremotecontrols

    In order to create working HAL remote UI have to set \l title and \l name
    of the application window accordingly.

    \qml
    HalApplicationWindow {
        id: halApplicationWindow
        title: "My HAL application"
        name: "myhalapp"
    }
    \endqml
*/

Rectangle {
    /*! This property holds the title of the application window.
    */
    property string title: "HAL Application Template"

    /*! \qmlproperty string name

        This property holds the name of the HAL remote component that will
        contain all HAL pins created inside the window.
    */
    property alias name: remoteComponent.name

    /*! \qmlproperty int heartbeadPeriod

        This property holds the period time of the heartbeat timer in ms.

        The default value is \c{3000}.
    */
    property alias heartbeatPeriod: remoteComponent.heartbeatPeriod

    /*! \qmlproperty string halrcmdUri

        This property holds the halrcmd service uri. It needs to be set in
        case the internal services are not used.
    */
    property alias halrcmdUri: remoteComponent.halrcmdUri

    /*! \qmlproperty string halrcompUri

        This property holds the halrcomp service uri. It needs to be set in
        case the internal services are not used.
    */
    property alias halrcompUri: remoteComponent.halrcompUri

    /*! \qmlproperty bool ready

        This property holds wheter the application window is ready or not.
        Per default this property is set using the internal services
        if you want to overwrite the services set this property to \c true.
    */
    property alias ready: remoteComponent.ready

    /*! \qmlproperty list<Service> services

        This property holds the services used by the application.
    */
    property list<Service> services

    /*! \qmlproperty list<Service> internalServices

        This property holds the services used internally by the HalApplicationWindow.
    */
    property list<Service> internalServices: [
        Service {
            id: halrcompService
            type: "halrcomp"
        },
        Service {
            id: halrcmdService
            type: "halrcmd"
        }
    ]

    id: main

    width: 500
    height: 800
    color: systemPalette.window

    SystemPalette {
        id: systemPalette;
        colorGroup: enabled ? SystemPalette.Active : SystemPalette.Disabled
    }

    Text {
        id: dummyText
    }

    Rectangle {
        id: discoveryPage

        anchors.fill: parent
        visible: false
        z: 100
        color: systemPalette.window


        Label {
            id: connectingLabel

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: connectingIndicator.top
            anchors.bottomMargin: Screen.logicalPixelDensity
            font.pixelSize: dummyText.font.pixelSize * 1.5
            text: (remoteComponent.connectionState === HalRemoteComponent.Disconnected)
                ? qsTr("Waiting for services to appear...")
                : qsTr("Connecting...")
        }

        BusyIndicator {
            id: connectingIndicator

            anchors.centerIn: parent
            running: true
            height: parent.height * 0.15
            width: height
        }

        CheckBox {
            id: halrcompCheck

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: connectingIndicator.bottom
            anchors.topMargin: Screen.logicalPixelDensity
            enabled: false
            text: qsTr("halrcomp service available")
            checked: halrcompService.ready
        }

        CheckBox {
            id: halrcmdCheck

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: halrcompCheck.bottom
            anchors.topMargin: Screen.logicalPixelDensity
            enabled: false
            text: qsTr("halrcmd service available")
            checked: halrcmdService.ready
        }

        Label {
            id: errorLabel

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Screen.logicalPixelDensity * 2
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.pixelSize: dummyText.font.pixelSize * 1.5
            text: {
                var headerText

                switch (remoteComponent.error)
                {
                case HalRemoteComponent.BindError: headerText = qsTr("Bind rejected error:"); break;
                case HalRemoteComponent.PinChange: headerText = qsTr("Pin change rejected error:"); break;
                case HalRemoteComponent.CommandError: headerText = qsTr("Command error:"); break;
                case HalRemoteComponent.TimeoutError: headerText = qsTr("Timeout error:"); break;
                case HalRemoteComponent.SocketError: headerText = qsTr("Socket error:"); break;
                default: headerText = qsTr("No error")
                }

                return headerText + "\n" + remoteComponent.errorString
            }
        }
    }

    HalRemoteComponent {
        id: remoteComponent

        name: main.name
        halrcmdUri: halrcmdService.uri
        halrcompUri: halrcompService.uri
        heartbeatPeriod: 3000
        ready: halrcompService.ready && halrcmdService.ready
        containerItem: parent
    }

    /* This timer is a workaround to make the discoveryPage invisible in QML designer */
    Timer {
        interval: 10
        repeat: false
        running: true
        onTriggered: {
            discoveryPage.visible = true
        }
    }

    state: {
        switch (remoteComponent.connectionState) {
        case HalRemoteComponent.Connected:
            return "connected"
        case HalRemoteComponent.Error:
            return "error"
        default:
            return "disconnected"
        }
    }

    states: [
        State {
            name: "disconnected"
            PropertyChanges { target: discoveryPage; opacity: 1.0; enabled: true }
            PropertyChanges { target: connectingLabel; visible: true }
            PropertyChanges { target: connectingIndicator; visible: true }
            PropertyChanges { target: halrcompCheck; visible: true }
            PropertyChanges { target: halrcmdCheck; visible: true }
            PropertyChanges { target: errorLabel; visible: false }
        },
        State {
            name: "error"
            PropertyChanges { target: discoveryPage; opacity: 1.0; enabled: true }
            PropertyChanges { target: connectingLabel; visible: false }
            PropertyChanges { target: connectingIndicator; visible: false }
            PropertyChanges { target: halrcompCheck; visible: false }
            PropertyChanges { target: halrcmdCheck; visible: false }
            PropertyChanges { target: errorLabel; visible: true }
        },
        State {
            name: "connected"
            PropertyChanges { target: discoveryPage; opacity: 0.0; enabled: false }
        }
    ]

    transitions: Transition {
            PropertyAnimation { duration: 500; properties: "opacity"; easing.type: Easing.InCubic}
        }
}
