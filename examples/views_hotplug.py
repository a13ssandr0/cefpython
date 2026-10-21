# Example of cef.Display.AddObserver(): one fullscreen frameless Views window
# per output, opened and closed as outputs are switched on and off (for
# instance `wlr-randr --output DP-1 --off` / `--on` on a Wayland compositor),
# with no polling: the windows follow OnDisplayAdded / OnDisplayRemoved.
#
# Usage: views_hotplug.py [URL] [SECONDS]
# Needs a CEF build with CefDisplay::AddObserver and Window.SetFullscreenOnDisplay.

import re
import sys
import time
from cefpython3 import cefpython as cef


def output_name(display):
    # Wayland compositors based on wlroots end the label with "(NAME)"
    match = re.search(r"\(([^ )]+)( via [^)]*)?\)$", display.GetLabel())
    return match.group(1) if match else str(display.GetID())


class WindowDelegate(object):
    def __init__(self, view, display, owner):
        self.view, self.display, self.owner = view, display, owner

    def OnWindowCreated(self, window):
        window.SetToFillLayout()
        window.AddChildView(self.view)
        window.SetFullscreenOnDisplay(self.display.GetID())
        window.Show()

    def OnWindowDestroyed(self, window):
        self.owner.windows.pop(self.display.GetID(), None)

    def IsFrameless(self, window):
        return True

    def GetLinuxWindowProperties(self, window):
        return {"wayland_app_id": "org.example.views-hotplug"}


class Screens(object):
    """Keeps one window per display."""

    def __init__(self, url):
        self.url = url
        self.windows = {}  # display id -> Window

    def open(self, display):
        if display.GetID() in self.windows:
            return
        print("open a window on", output_name(display))
        view = cef.BrowserView.CreateBrowserView(url=self.url)
        self.windows[display.GetID()] = cef.Window.CreateTopLevelWindow(
            WindowDelegate(view, display, self))

    # Display observer
    def OnDisplayAdded(self, display):
        self.open(display)

    def OnDisplayRemoved(self, display):
        print("output removed:", output_name(display))
        window = self.windows.pop(display.GetID(), None)
        if window and not window.IsClosed():
            window.Close()


def main():
    url = sys.argv[1] if len(sys.argv) > 1 else "https://www.example.com"
    seconds = float(sys.argv[2]) if len(sys.argv) > 2 else 60
    sys.excepthook = cef.ExceptHook
    cef.Initialize()
    screens = Screens(url)
    cef.Display.AddObserver(screens)
    for display in cef.Display.GetAllDisplays():
        screens.open(display)
    end = time.monotonic() + seconds
    while time.monotonic() < end:
        cef.MessageLoopWork()
        time.sleep(0.01)
    cef.Display.RemoveObserver(screens)
    for window in list(screens.windows.values()):
        window.Close()
    end = time.monotonic() + 3
    while time.monotonic() < end:
        cef.MessageLoopWork()
        time.sleep(0.01)
    cef.Shutdown()


if __name__ == "__main__":
    main()
