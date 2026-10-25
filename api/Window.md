[API categories](API-categories.md) | [API index](API-index.md)


# Window (object)

A top-level window of the CEF Views framework (`CefWindow`). Windows are
created, drawn and owned by CEF itself: there is no GUI toolkit and no X11
window id involved, so they work on every Ozone platform, **including Wayland**,
where the windowed browser created through
[WindowInfo](WindowInfo.md) does not exist. A window hosts
[BrowserView](BrowserView.md) objects (and other [Panel](View.md#panel-object)
children) and calls back into a [WindowDelegate](WindowDelegate.md).

To create an object call `cefpython.Window.CreateTopLevelWindow()`. `Window` is
a [Panel](View.md#panel-object), which is a [View](View.md#view-object): all
their methods are available too.

All methods must be called on the UI thread (the thread that runs the
message loop).

Table of contents:
* [Overview](#overview)
* [Constants](#constants)
* [Static methods](#static-methods)
  * [CreateTopLevelWindow](#createtoplevelwindow)
* [Methods](#methods)
  * [Show](#show)
  * [Hide](#hide)
  * [Close](#close)
  * [IsClosed](#isclosed)
  * [CenterWindow](#centerwindow)
  * [Activate](#activate)
  * [Deactivate](#deactivate)
  * [IsActive](#isactive)
  * [BringToTop](#bringtotop)
  * [SetAlwaysOnTop](#setalwaysontop)
  * [IsAlwaysOnTop](#isalwaysontop)
  * [Maximize](#maximize)
  * [Minimize](#minimize)
  * [Restore](#restore)
  * [SetFullscreen](#setfullscreen)
  * [SetFullscreenOnDisplay](#setfullscreenondisplay)
  * [IsMaximized](#ismaximized)
  * [IsMinimized](#isminimized)
  * [IsFullscreen](#isfullscreen)
  * [SetTitle](#settitle)
  * [GetTitle](#gettitle)
  * [GetDisplay](#getdisplay)
  * [GetClientAreaBoundsInScreen](#getclientareaboundsinscreen)
  * [GetWindowHandle](#getwindowhandle)
  * [GetRuntimeStyle](#getruntimestyle)
  * [SetUserData](#setuserdata)
  * [GetUserData](#getuserdata)
* [CreateBrowserSync on Wayland](#createbrowsersync-on-wayland)


## Overview

Open a frameless fullscreen window on a given output of a Wayland compositor,
with an application id (`xdg_toplevel.app_id`, what the compositor's window
rules match), and close it again so that it really goes away (the toplevel is
destroyed, `OnBeforeClose` is called):

```python
import time
from cefpython3 import cefpython as cef

class WindowDelegate:
    def __init__(self, view, output, app_id):
        self.view, self.output, self.app_id = view, output, app_id

    def OnWindowCreated(self, window):
        window.SetToFillLayout()
        window.AddChildView(self.view)       # CEF creates the browser now
        display = cef.Display.FindByOutputName(self.output)
        if display:
            window.SetFullscreenOnDisplay(display.GetID())
        else:
            window.SetFullscreen(True)
        window.Show()

    def OnWindowDestroyed(self, window):
        print("window destroyed")

    def IsFrameless(self, window):
        return True

    def GetLinuxWindowProperties(self, window):
        return {"wayland_app_id": self.app_id}

class BrowserViewDelegate:
    def OnBrowserCreated(self, browser_view, browser):
        browser.SetClientCallback("OnBeforeClose", lambda browser: print("closed"))

# WAYLAND_DISPLAY set and DISPLAY unset: the Wayland backend is selected
# automatically (see "ozone-platform" in CommandLineSwitches.md).
cef.Initialize()
view = cef.BrowserView.CreateBrowserView(
        url="https://example.com", delegate=BrowserViewDelegate())
window = cef.Window.CreateTopLevelWindow(WindowDelegate(view, "HDMI-A-1", "org.example.kiosk"))

end = time.monotonic() + 10
while time.monotonic() < end:
    cef.MessageLoopWork()
    time.sleep(0.01)
window.Close()                                # asks CanClose(), then destroys
for _ in range(100):
    cef.MessageLoopWork()
    time.sleep(0.01)
cef.Shutdown()
```

A complete, runnable version is [examples/views.py](../examples/views.py).

Notes:
* With the CEF patch for frameless Wayland windows (`remove_standard_frame`), a frameless window
  asks the compositor for client-side decorations only (see `IsFrameless`); without it the
  compositor may draw its own title bar.
* Until the window is shown nothing exists in the compositor.
* The delegate object is optional, as is every one of its methods: CEF's
  defaults are used for what is missing. The Alloy runtime style is
  the default of these windows because JavaScript bindings and the client
  handlers of cefpython need it.
* `Close()` is the way to destroy a window. `Browser.CloseBrowser()` only closes
  the browser: close the window from `BrowserViewDelegate.OnBrowserDestroyed`
  if the window has nothing else to show.


## Constants

Show states for `WindowDelegate.GetInitialShowState()`, in the cefpython
module: `SHOW_STATE_NORMAL`, `SHOW_STATE_MINIMIZED`, `SHOW_STATE_MAXIMIZED`,
`SHOW_STATE_FULLSCREEN`, `SHOW_STATE_HIDDEN`.

Runtime styles: `RUNTIME_STYLE_DEFAULT`, `RUNTIME_STYLE_CHROME`,
`RUNTIME_STYLE_ALLOY`.


## Static methods


### CreateTopLevelWindow

| Parameter | Type |
| --- | --- |
| delegate (optional) | [WindowDelegate](WindowDelegate.md) |
| __Return__ | [Window](Window.md) |

Creates a top-level window. It is not visible until `Show()` is called.
`OnWindowCreated` of the delegate is called before this function returns.


## Methods


### Show

| | |
| --- | --- |
| __Return__ | void |

Shows the window and activates it.


### Hide

| | |
| --- | --- |
| __Return__ | void |

Hides the window.


### Close

| | |
| --- | --- |
| __Return__ | void |

Closes the window. `WindowDelegate.CanClose()` is asked first; when it is not
implemented the browsers inside are asked to close (their `beforeunload` and
unload handlers run) and the window closes when they are done. Then:
`BrowserViewDelegate.OnBrowserDestroyed`, `OnBeforeClose` of the browser,
`OnWindowClosing`, `OnWindowDestroyed` (the native window is gone). After that the object cannot be used any more.


### IsClosed

| | |
| --- | --- |
| __Return__ | bool |


### CenterWindow

| Parameter | Type |
| --- | --- |
| size | list [width, height] |
| __Return__ | void |

Sizes the window and centers it on the screen where the platform lets
applications place windows (a Wayland compositor decides itself).


### Activate

| | |
| --- | --- |
| __Return__ | void |

Activates the window (a Wayland compositor may refuse).


### Deactivate

| | |
| --- | --- |
| __Return__ | void |


### IsActive

| | |
| --- | --- |
| __Return__ | bool |


### BringToTop

| | |
| --- | --- |
| __Return__ | void |


### SetAlwaysOnTop

| Parameter | Type |
| --- | --- |
| on_top | bool |
| __Return__ | void |


### IsAlwaysOnTop

| | |
| --- | --- |
| __Return__ | bool |


### Maximize

| | |
| --- | --- |
| __Return__ | void |


### Minimize

| | |
| --- | --- |
| __Return__ | void |


### Restore

| | |
| --- | --- |
| __Return__ | void |


### SetFullscreen

| Parameter | Type |
| --- | --- |
| fullscreen | bool |
| __Return__ | void |

Enters or leaves fullscreen. The compositor chooses the output (on Wayland:
`xdg_toplevel.set_fullscreen` without an output); use
[SetFullscreenOnDisplay](#setfullscreenondisplay) to choose.
`WindowDelegate.OnWindowFullscreenTransition` is called.


### SetFullscreenOnDisplay

| Parameter | Type |
| --- | --- |
| display_id | int |
| __Return__ | void |

Enters fullscreen on the [Display](Display.md) with this id
(`Display.GetID()`), and moves a window that is already fullscreen to it.
**Only Wayland honours the display** (`xdg_toplevel.set_fullscreen(wl_output)`, so no
compositor specific key binding or window rule is needed). On every other platform and
Linux backend (Windows, macOS, X11) and for an invalid id it is exactly
`SetFullscreen(True)`: nothing of this exists there. May be called before `Show()` (for
example in `OnWindowCreated`). Display ids change when an output is unplugged and plugged
back: look the display up again (`Display.FindByOutputName`) after a hot-plug, and only
once it is listed (see "Hot-plug timing" in [Display](Display.md)).

Requires a CEF build with the `CefWindow::SetFullscreenOnDisplay` patch
(an experimental API of CEF, proposed upstream).


### IsMaximized

| | |
| --- | --- |
| __Return__ | bool |


### IsMinimized

| | |
| --- | --- |
| __Return__ | bool |


### IsFullscreen

| | |
| --- | --- |
| __Return__ | bool |


### SetTitle

| Parameter | Type |
| --- | --- |
| title | string |
| __Return__ | void |

The title of the toplevel (`xdg_toplevel.set_title`).


### GetTitle

| | |
| --- | --- |
| __Return__ | string |


### GetDisplay

| | |
| --- | --- |
| __Return__ | [Display](Display.md) |

The display the window is on (on Wayland: the output the compositor entered
the surface on, known after the window was shown; a Wayland client does not
know the position of its window, so with a CEF build without the `GetDisplay`
patch this was matched by window bounds and wrong for any output but the
first).


### GetClientAreaBoundsInScreen

| | |
| --- | --- |
| __Return__ | list [x, y, width, height] |


### GetWindowHandle

| | |
| --- | --- |
| __Return__ | int |

A native handle: an X11 window id on X11. On Wayland it is an opaque Chromium
id, not a `wl_surface`.


### GetRuntimeStyle

| | |
| --- | --- |
| __Return__ | int |

One of the `RUNTIME_STYLE_*` constants.


### SetUserData

| Parameter | Type |
| --- | --- |
| key | object |
| value | object |
| __Return__ | void |

Attach any Python object to the window. The same `Window` object is handed out
every time CEF refers to the window, in delegate callbacks as well.


### GetUserData

| Parameter | Type |
| --- | --- |
| key | object |
| __Return__ | object |


## CreateBrowserSync on Wayland

CEF's windowed browser (the one `WindowInfo.SetAsChild(0)` or `WindowInfo()`
ask for) is implemented for X11 only in upstream CEF
(`CefBrowserPlatformDelegateNativeLinux::CreateHostWindow` is `#if
BUILDFLAG(SUPPORTS_OZONE_X11)`). On the Wayland backend it ends up as a
Chrome-style window without title and `app_id`, which `CloseBrowser()` never
destroys (a zombie toplevel stays until `Shutdown()`).

When cefpython runs on the Wayland backend, `CreateBrowserSync()` called with a
`WindowInfo` that has no parent window therefore opens the browser in a Views
window of its own (800x600, framed, the compositor places it; `windowName` is
its title) and closing the browser closes the window. Applications that care
about the window (frameless, fullscreen, an output, an `app_id`) use the Views
API described on this page instead. Embedding into a parent handle
(`SetAsChild(handle)`) is X11 only and stays so: use the X11 backend
(`ozone-platform=x11`, XWayland) for that.
