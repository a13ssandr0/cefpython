[API categories](API-categories.md) | [API index](API-index.md)


# BrowserView (object)

A [View](View.md) that shows a browser (`CefBrowserView`). Add it to a
[Window](Window.md) with `AddChildView()`: the browser is created by CEF at
that moment, not before. All methods must be called on the UI thread.

Table of contents:
* [Static methods](#static-methods)
  * [CreateBrowserView](#createbrowserview)
* [Methods](#methods)
  * [GetBrowser](#getbrowser)
  * [SetPreferAccelerators](#setpreferaccelerators)
  * [GetRuntimeStyle](#getruntimestyle)
* [BrowserViewDelegate](#browserviewdelegate)


## Static methods


### CreateBrowserView

| Parameter | Type |
| --- | --- |
| url (optional) | string |
| settings (optional) | [BrowserSettings](BrowserSettings.md) |
| delegate (optional) | [BrowserViewDelegate](#browserviewdelegate) |
| __Return__ | [BrowserView](BrowserView.md) |

Same arguments and meaning as for
[cefpython](cefpython.md).CreateBrowserSync(), minus `window_info` (the
window is the one the view is added to). The request context follows the
`unique_request_context_per_browser` application setting.


## Methods


### GetBrowser

| | |
| --- | --- |
| __Return__ | [Browser](Browser.md) or None |

None until the view is attached to a window.


### SetPreferAccelerators

| Parameter | Type |
| --- | --- |
| prefer_accelerators | bool |
| __Return__ | void |


### GetRuntimeStyle

| | |
| --- | --- |
| __Return__ | int |


## BrowserViewDelegate

An object with these optional methods, passed as `delegate`:

| Method | Description |
| --- | --- |
| `OnBrowserCreated(browser_view, browser)` | The browser exists. Install the [client handlers](Browser.md#setclienthandler) here, the page has not started loading yet. |
| `OnBrowserDestroyed(browser_view, browser)` | Just before `OnBeforeClose`. Close the window here when it has nothing else to show. |
| `GetBrowserRuntimeStyle()` | One of `RUNTIME_STYLE_*`. The default is `RUNTIME_STYLE_ALLOY`. |
