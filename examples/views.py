# Example of the CEF Views framework: a frameless fullscreen window on a chosen
# output (display), with an application id, closed again after a few seconds.
# Needs no GUI toolkit and works on X11 and on Wayland (on Wayland use a
# compositor session with WAYLAND_DISPLAY set and no DISPLAY, cefpython then
# selects the Wayland backend; on X11 the window is simply fullscreen).
#
# Usage: views.py [URL] [OUTPUT_NAME] [SECONDS]
#   OUTPUT_NAME is a connector name such as DP-1 or HDMI-A-1 (see
#   Display.FindByOutputName); without it the compositor chooses the output.
# Window.SetFullscreenOnDisplay needs a CEF build with that API; without it
# the window goes fullscreen on the output the compositor chooses.

import sys
import time
from cefpython3 import cefpython as cef


class WindowDelegate(object):
    def __init__(self, view, output, app_id):
        self.view, self.output, self.app_id = view, output, app_id

    def OnWindowCreated(self, window):
        window.SetToFillLayout()
        window.AddChildView(self.view)  # CEF creates the browser now
        display = cef.Display.FindByOutputName(self.output) \
            if self.output else None
        if display and hasattr(window, "SetFullscreenOnDisplay"):
            window.SetFullscreenOnDisplay(display.GetID())
        else:
            window.SetFullscreen(True)
        window.Show()

    def OnWindowDestroyed(self, window):
        print("Window destroyed")

    def IsFrameless(self, window):
        return True

    def GetLinuxWindowProperties(self, window):
        # xdg_toplevel.app_id on Wayland (WM_CLASS on X11)
        return {"wayland_app_id": self.app_id, "wm_class_class": self.app_id}


class BrowserViewDelegate(object):
    def OnBrowserCreated(self, browser_view, browser):
        browser.SetClientCallback(
            "OnBeforeClose", lambda browser: print("Browser closed"))


def main():
    url = sys.argv[1] if len(sys.argv) > 1 else "https://www.example.com"
    output = sys.argv[2] if len(sys.argv) > 2 else None
    seconds = float(sys.argv[3]) if len(sys.argv) > 3 else 10
    sys.excepthook = cef.ExceptHook
    cef.Initialize()
    view = cef.BrowserView.CreateBrowserView(
        url=url, delegate=BrowserViewDelegate())
    window = cef.Window.CreateTopLevelWindow(
        WindowDelegate(view, output, "org.example.cefpython"))
    end = time.monotonic() + seconds
    while time.monotonic() < end:
        cef.MessageLoopWork()
        time.sleep(0.01)
    window.Close()  # CanClose(), then the window is destroyed for real
    end = time.monotonic() + 3
    while not window.IsClosed() and time.monotonic() < end:
        cef.MessageLoopWork()
        time.sleep(0.01)
    cef.Shutdown()


if __name__ == "__main__":
    main()
