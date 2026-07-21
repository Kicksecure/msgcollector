#!/usr/bin/python3 -su

## Copyright (C) 2014 troubadour <trobador@riseup.net>
## Copyright (C) 2014 - 2025 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>

"""
This script creates a GUI message dialog using PyQt5.

Usage:
/usr/libexec/msgcollector/generic_gui_message.py <message_type> <title> <message> <question> <button_type>

Arguments:
1. message_type: 'info', 'warning', or 'error'
2. title: The window title
3. message: The main message text
4. question: An additional question or prompt
5. button_type: 'ok' for a single OK button, 'yesno' for Yes and No buttons

Examples:
/usr/libexec/msgcollector/generic_gui_message.py warning "Alert" "This is a warning message." "Do you want to continue?" yesno
/usr/libexec/msgcollector/generic_gui_message.py info "Info" "This is an info message with a link: <a href='https://www.example.com'>Click here</a>" "" ok
"""

import os
import sys
import signal
import argparse
from PyQt5 import QtCore, QtGui, QtWidgets
from PyQt5.QtGui import QIcon, QPixmap


class SafeTextBrowser(QtWidgets.QTextBrowser):
    """
    Defense-in-depth QTextBrowser that refuses to load ANY resource.

    Messages are rendered via setText()/setHtml() from caller-constructed
    HTML. Refusing every resource load guarantees a message can never trigger
    a network or filesystem fetch (e.g. '<img src="http://...">'), even if an
    unsanitized value reaches the widget. Legitimate messages contain only
    text and links, never embedded resources.
    """

    def loadResource(self, resource_type, url):
        return None


def signal_handler(sig, frame):
    sys.exit(128 + sig)


def select_qt_platform(environ):
    """Choose a Qt QPA platform for a Wayland session when none is pinned.

    Qt5 defaults to the "xcb" platform even inside a Wayland session. When
    no X server (or XWayland) is reachable -- for example this dialog is
    launched from a .desktop shortcut on a Wayland-only Kicksecure/Whonix
    session -- xcb aborts the process with no window, and a caller running
    under "set -o errexit" (update-torbrowser) then dies silently. Prefer
    Wayland with an xcb fallback so the dialog appears under both session
    types.

    Returns the platform string to set, or None to leave Qt's own default
    in place: when QT_QPA_PLATFORM is already pinned (e.g. by
    sandbox-update-torbrowser) or when this is not a Wayland session.
    """
    if environ.get("QT_QPA_PLATFORM"):
        return None
    ## A Wayland session is signalled by WAYLAND_DISPLAY, or by
    ## XDG_SESSION_TYPE=wayland even with WAYLAND_DISPLAY unset (libwayland then
    ## defaults to the "wayland-0" socket) -- msgdispatcher routes both to the
    ## GUI path, so both must get the fallback.
    if environ.get("WAYLAND_DISPLAY") or environ.get("XDG_SESSION_TYPE") == "wayland":
        return "wayland;xcb"
    return None


class GuiMessage(QtWidgets.QDialog):
    def __init__(self, args):
        super(GuiMessage, self).__init__()
        self.args = args
        self.setup_ui()

    def setup_ui(self):
        message_type = self.args.message_type
        title = self.args.title
        message = self.args.message
        question = self.args.question
        self.button = self.args.button_type

        icon_dir = "/usr/share/icons/gnome-colors-common/scalable/status/"
        # Set default icon path for 'info' type
        icon_image = "dialog-information.svg"
        if message_type == "warning":
            icon_image = "dialog-warning.svg"
        elif message_type == "error":
            icon_image = "dialog-error.svg"
        icon_path = os.path.join(icon_dir, icon_image)

        if not os.path.exists(icon_path):
            print(f"INFO: The icon path '{icon_path}' does not exist.", file=sys.stderr)

        if question:
            message = message + '<p>' + question + '</p>'

        self.gridLayout = QtWidgets.QGridLayout(self)

        # We use QTextBrowser with a white background.
        # Set a default (transparent) background.
        palette = QtGui.QPalette()
        brush = QtGui.QBrush(QtGui.QColor(255, 255, 255, 0))
        brush.setStyle(QtCore.Qt.SolidPattern)
        palette.setBrush(QtGui.QPalette.Active, QtGui.QPalette.Base, brush)
        palette.setBrush(QtGui.QPalette.Inactive, QtGui.QPalette.Base, brush)
        brush = QtGui.QBrush(QtGui.QColor(244, 244, 244))
        brush.setStyle(QtCore.Qt.SolidPattern)
        palette.setBrush(QtGui.QPalette.Disabled, QtGui.QPalette.Base, brush)
        self.setPalette(palette)

        self.setWindowIcon(QIcon("/usr/share/icons/gnome/24x24/status/info.png"))
        self.setWindowTitle(title)

        self.label = QtWidgets.QLabel(self)
        image = QtGui.QImage(icon_path)
        self.label.setPixmap(QPixmap.fromImage(image))

        self.label.setAlignment(QtCore.Qt.AlignLeft | QtCore.Qt.AlignTop)
        self.gridLayout.addWidget(self.label, 0, 0)

        self.text = SafeTextBrowser(self)
        self.text.setMinimumSize(535, 0)
        self.text.setAlignment(QtCore.Qt.AlignLeft | QtCore.Qt.AlignTop)
        self.text.setFrameShape(QtWidgets.QFrame.NoFrame)
        self.text.setTextInteractionFlags(QtCore.Qt.LinksAccessibleByMouse | QtCore.Qt.TextSelectableByMouse)
        self.text.setOpenExternalLinks(True)
        self.text.setText(message)
        self.gridLayout.addWidget(self.text, 0, 1)

        self.buttonBox = QtWidgets.QDialogButtonBox(self)
        if self.button == 'yesno':
            self.buttonBox.setStandardButtons(QtWidgets.QDialogButtonBox.Yes | QtWidgets.QDialogButtonBox.No)

            self.yes_button = self.buttonBox.button(QtWidgets.QDialogButtonBox.Yes)
            self.yes_button.clicked.connect(self.yes_pressed)

            self.no_button = self.buttonBox.button(QtWidgets.QDialogButtonBox.No)
            self.no_button.setAutoDefault(True)
            self.no_button.setDefault(True)
            self.no_button.clicked.connect(self.reject)

        elif self.button == 'ok':
            self.buttonBox.setStandardButtons(QtWidgets.QDialogButtonBox.Ok)
            self.ok_button = self.buttonBox.button(QtWidgets.QDialogButtonBox.Ok)
            self.ok_button.clicked.connect(self.accept)

        self.gridLayout.addWidget(self.buttonBox, 1, 1)

        QtCore.QTimer.singleShot(0, self.setSize)

    def setSize(self):
        ## Size is returned
        messageHeight = int(self.text.document().size().height())
        maximumHeight = int(QtWidgets.QDesktopWidget().availableGeometry().height() - 60)
        if messageHeight <= maximumHeight:
            self.resize(620, messageHeight + 60)
        else:
            self.resize(620, maximumHeight)

        self.center()

        if self.button == 'yesno':
            self.no_button.setFocus()
        elif self.button == 'ok':
            self.ok_button.setFocus()

    def center(self):
        frameGm = self.frameGeometry()
        centerPoint = QtWidgets.QDesktopWidget().availableGeometry().center()
        frameGm.moveCenter(centerPoint)
        self.move(frameGm.topLeft())

    def yes_pressed(self):
        print("16384")
        sys.exit()

    def reject(self):
        print("65536")
        sys.exit()


def main():
    parser = argparse.ArgumentParser(description="Create a GUI message dialog using PyQt5.")
    parser.add_argument('message_type', choices=['info', 'warning', 'error'], help="Type of the message ('info', 'warning', or 'error')")
    parser.add_argument('title', help="The window title")
    parser.add_argument('message', help="The main message text")
    parser.add_argument('question', help="An additional question or prompt")
    parser.add_argument('button_type', choices=['ok', 'yesno'], help="Type of the button ('ok' for a single OK button, 'yesno' for Yes and No buttons)")

    args = parser.parse_args()

    qt_platform = select_qt_platform(os.environ)
    if qt_platform:
        os.environ["QT_QPA_PLATFORM"] = qt_platform

    app = QtWidgets.QApplication(sys.argv)
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    timer = QtCore.QTimer()
    timer.start(500)
    timer.timeout.connect(lambda: None)

    message = GuiMessage(args)
    message.show()
    app.exec_()


if __name__ == '__main__':
    main()
