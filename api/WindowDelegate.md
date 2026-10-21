[API categories](API-categories.md) | [API index](API-index.md)


# WindowDelegate (interface)

Callbacks of a [Window](Window.md) (`CefWindowDelegate`, `CefPanelDelegate`,
`CefViewDelegate`). Pass any Python object to
`Window.CreateTopLevelWindow(delegate)`; every method is optional. A method
that returns `None` (or does not exist) gets CEF's default. All are called on
the UI thread with the `Window` (or `View`) as first argument.

Table of contents:
* [Window callbacks](#window-callbacks)
* [View callbacks](#view-callbacks)
* [Not available](#not-available)


## Window callbacks

| Method | Return | Default / notes |
| --- | --- | --- |
| `OnWindowCreated(window)` | | Called before `CreateTopLevelWindow` returns: add the views and `Show()` here. |
| `OnWindowClosing(window)` | | The window is about to be destroyed. |
| `OnWindowDestroyed(window)` | | The native window is gone. After it the `Window` object is invalid. |
| `OnWindowActivationChanged(window, active)` | | |
| `OnWindowBoundsChanged(window, new_bounds)` | | `new_bounds` is a list [x, y, width, height]. |
| `OnWindowFullscreenTransition(window, is_completed)` | | |
| `GetParentWindow(window)` | `Window`, or `(Window, is_menu, can_activate_menu)`, or None | No parent. |
| `IsWindowModalDialog(window)` | bool | False. |
| `GetInitialBounds(window)` | list [x, y, width, height] | 800x600; a Wayland compositor places the window. |
| `GetInitialShowState(window)` | `SHOW_STATE_*` | `SHOW_STATE_NORMAL`. |
| `IsFrameless(window)` | bool | False. True: no decorations (on Wayland, with the CEF frameless patch, client-side decorations are requested). |
| `WithStandardWindowButtons(window)` | bool | Not frameless. |
| `CanResize(window)`, `CanMaximize(window)`, `CanMinimize(window)` | bool | True. |
| `CanClose(window)` | bool | The browsers inside are asked to close (`TryCloseBrowser`), the window closes once they are done. |
| `GetWindowRuntimeStyle()` | `RUNTIME_STYLE_*` | `RUNTIME_STYLE_ALLOY`: needed by JavaScript bindings and the client handlers. |
| `GetLinuxWindowProperties(window)` | dict with `wayland_app_id`, `wm_class_class`, `wm_class_name`, `wm_role_name` (all optional strings), or None | The `xdg_toplevel.app_id` that window rules match; on X11 the `WM_CLASS` and `WM_WINDOW_ROLE`. |


## View callbacks

Called for the window and for views inside it (the first argument is the view
concerned):

| Method | Return |
| --- | --- |
| `GetPreferredSize(view)`, `GetMinimumSize(view)`, `GetMaximumSize(view)` | list [width, height] |
| `GetHeightForWidth(view, width)` | int |
| `OnParentViewChanged(view, added, parent)` | |
| `OnChildViewChanged(view, added, child)` | |
| `OnWindowChanged(view, added)` | |
| `OnLayoutChanged(view, new_bounds)` | |
| `OnFocus(view)`, `OnBlur(view)`, `OnThemeChanged(view)` | |


## Not available

`CefWindowDelegate` callbacks that need types cefpython does not wrap yet:
`GetTitlebarHeight`, `AcceptsFirstMouse`, `OnAccelerator`, `OnKeyEvent`,
`OnThemeColorsChanged` (CEF's defaults apply), and the other Views classes
(buttons, text fields, menus, overlays, layouts other than fill).
