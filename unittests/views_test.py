# Copyright (c) 2026 CEF Python, see the Authors file.
# All rights reserved. Licensed under BSD 3-clause license.
# Project website: https://github.com/cztomczak/cefpython

"""CEF Views windows: Window, BrowserView, Display and their delegates.

Runs on every Ozone backend (X11 under xvfb, a Wayland compositor): the Views
windows are created by CEF itself and do not depend on the platform.
"""

import unittest
# noinspection PyUnresolvedReferences
import _test_runner
from _common import *

from cefpython3 import cefpython as cef

import os
import sys
import time

g_events = []


def pump(until, timeout=MESSAGE_LOOP_TIMEOUT):
    """Run the message loop until until() is true or the timeout expires."""
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        cef.MessageLoopWork()
        if until():
            return True
        time.sleep(MESSAGE_LOOP_POLL_INTERVAL)
    return until()


class ViewsTest_IsolatedTest(unittest.TestCase):
    def test_views(self):
        """All the code must run inside one single test, otherwise strange
        things happen."""
        print("")
        print("CEF Python {ver}".format(ver=cef.__version__))
        settings = {"debug": False, "log_severity": cef.LOGSEVERITY_ERROR,
                    "log_file": ""}
        if "--debug" in sys.argv:
            settings["debug"] = True
            settings["log_severity"] = cef.LOGSEVERITY_INFO
        cef.Initialize(settings=settings)
        subtest_message("cef.Initialize() ok")

        # Display
        displays = cef.Display.GetAllDisplays()
        self.assertTrue(displays)
        self.assertEqual(len(displays), cef.Display.GetDisplayCount())
        primary = cef.Display.GetPrimaryDisplay()
        bounds = primary.GetBounds()
        self.assertEqual(len(bounds), 4)
        self.assertGreater(bounds[2], 0)
        self.assertGreater(bounds[3], 0)
        self.assertIsInstance(primary.GetID(), int)
        self.assertIsInstance(primary.GetLabel(), str)
        self.assertIn(primary, displays)
        self.assertIsNone(cef.Display.FindByOutputName("no-such-output"))
        subtest_message("Display ok")

        # Window with delegates
        delegate = WindowDelegate()
        view_delegate = BrowserViewDelegate()
        view = cef.BrowserView.CreateBrowserView(
                url=cef.GetDataUrl("<body>views</body>"), delegate=view_delegate)
        self.assertIsNone(view.GetBrowser())  # created when attached
        delegate.view = view
        window = cef.Window.CreateTopLevelWindow(delegate)
        subtest_message("Window.CreateTopLevelWindow() ok")
        self.assertIs(delegate.window, window)  # same object everywhere
        self.assertEqual(g_events[:2], ["OnWindowCreated", "OnBrowserCreated"])
        self.assertTrue(pump(lambda: "OnLoadEnd" in g_events))
        subtest_message("browser created and page loaded ok")

        browser = view.GetBrowser()
        self.assertIsNotNone(browser)
        self.assertIs(browser, view_delegate.browser)
        self.assertEqual(view.GetWindow(), window)
        self.assertEqual(window.GetChildViewCount(), 1)
        window.SetTitle("views test")
        self.assertEqual(window.GetTitle(), "views test")
        window.SetUserData("key", 42)
        self.assertEqual(window.GetUserData("key"), 42)
        self.assertFalse(window.IsClosed())
        self.assertEqual(window.GetRuntimeStyle(), cef.RUNTIME_STYLE_ALLOY)
        window.SetFullscreenOnDisplay(primary.GetID())
        window.SetFullscreen(False)
        subtest_message("window methods ok")

        # Close: the unload handlers run, OnBeforeClose, then the window goes
        window.Close()
        self.assertTrue(pump(lambda: "OnWindowDestroyed" in g_events))
        self.assertTrue(window.IsClosed())
        self.assertIn("OnBeforeClose", g_events)
        self.assertIn("OnBrowserDestroyed", g_events)
        self.assertLess(g_events.index("OnBeforeClose"),
                        g_events.index("OnWindowDestroyed"))
        self.assertIn("OnWindowClosing", g_events)
        with self.assertRaises(Exception):
            window.Show()
        subtest_message("Window.Close() ok")

        cef.Shutdown()
        subtest_message("cef.Shutdown() ok")
        show_test_summary(__file__)
        sys.stdout.flush()


class WindowDelegate(object):
    window = None
    view = None

    def OnWindowCreated(self, window):
        g_events.append("OnWindowCreated")
        self.window = window
        window.SetToFillLayout()
        window.AddChildView(self.view)
        window.Show()

    def OnWindowClosing(self, window):
        g_events.append("OnWindowClosing")

    def OnWindowDestroyed(self, window):
        g_events.append("OnWindowDestroyed")

    def GetInitialBounds(self, window):
        return [0, 0, 400, 300]

    def IsFrameless(self, window):
        return True

    def GetLinuxWindowProperties(self, window):
        return {"wayland_app_id": "org.cefpython.test"}


class LoadHandler(object):
    def OnLoadEnd(self, browser, frame, http_code):
        if frame.IsMain():
            g_events.append("OnLoadEnd")


class LifespanHandler(object):
    def OnBeforeClose(self, browser):
        g_events.append("OnBeforeClose")


class BrowserViewDelegate(object):
    browser = None

    def OnBrowserCreated(self, browser_view, browser):
        g_events.append("OnBrowserCreated")
        self.browser = browser
        browser.SetClientHandler(LoadHandler())
        browser.SetClientHandler(LifespanHandler())

    def OnBrowserDestroyed(self, browser_view, browser):
        g_events.append("OnBrowserDestroyed")


if __name__ == "__main__":
    _test_runner.main(os.path.basename(__file__))
