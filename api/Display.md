[API categories](API-categories.md) | [API index](API-index.md)


# Display (object)

One monitor as seen by Chromium (`CefDisplay`). Obtain objects from the static
methods or from [Window](Window.md).GetDisplay(). Must be used on the UI thread.

Table of contents:
* [Static methods](#static-methods)
  * [GetPrimaryDisplay](#getprimarydisplay)
  * [GetDisplayNearestPoint](#getdisplaynearestpoint)
  * [GetDisplayMatchingBounds](#getdisplaymatchingbounds)
  * [GetDisplayCount](#getdisplaycount)
  * [GetAllDisplays](#getalldisplays)
  * [FindByOutputName](#findbyoutputname)
  * [AddObserver](#addobserver)
  * [RemoveObserver](#removeobserver)
* [Methods](#methods)
  * [GetID](#getid)
  * [GetDeviceScaleFactor](#getdevicescalefactor)
  * [GetBounds](#getbounds)
  * [GetWorkArea](#getworkarea)
  * [GetRotation](#getrotation)
  * [GetLabel](#getlabel)


## Static methods


### GetPrimaryDisplay

| | |
| --- | --- |
| __Return__ | [Display](Display.md) |


### GetDisplayNearestPoint

| Parameter | Type |
| --- | --- |
| point | list [x, y] |
| input_pixel_coords (optional) | bool |
| __Return__ | [Display](Display.md) |


### GetDisplayMatchingBounds

| Parameter | Type |
| --- | --- |
| bounds | list [x, y, width, height] |
| input_pixel_coords (optional) | bool |
| __Return__ | [Display](Display.md) |


### GetDisplayCount

| | |
| --- | --- |
| __Return__ | int |

Mirrored displays are not counted.


### GetAllDisplays

| | |
| --- | --- |
| __Return__ | list of [Display](Display.md) |


### FindByOutputName

| Parameter | Type |
| --- | --- |
| name | string |
| __Return__ | [Display](Display.md) or None |

The display of the output called `name` (the connector name: `"DP-1"`,
`"HDMI-A-1"`, ...). Chromium's Display has no output name, only the label
(see [GetLabel](#getlabel)): the compositors based on wlroots (labwc, sway,
river, cage, wayfire) end the `wl_output` description with the name in
parentheses (`"Dell Inc. U2720Q ABC123 (DP-1)"`) and this function compares
with that. For other compositors match on [GetBounds](#getbounds) (the
positions that `wlr-randr`/`kscreen-doctor` print).


### AddObserver

| Parameter | Type |
| --- | --- |
| observer | object |
| __Return__ | void |

Calls `observer` when the set of displays or their metrics change, instead of polling `GetAllDisplays()`. `observer` is any
object with these optional methods, called on the UI thread with a [Display](Display.md) (for a removed display it is a snapshot):

* `OnDisplayAdded(display)`: after the display was added (an output switched on or plugged in);
  `FindByOutputName()` finds it from now on.
* `OnDisplayRemoved(display)`
* `OnDisplayMetricsChanged(display)`: bounds, work area, scale factor, rotation, label ...

The observer is kept alive until `RemoveObserver()`; adding the same object twice has no effect. Requires a CEF build with
`CefDisplay::AddObserver` (an experimental API of CEF, proposed upstream). A complete example is
[examples/views_hotplug.py](../examples/views_hotplug.py).


### RemoveObserver

| Parameter | Type |
| --- | --- |
| observer | object |
| __Return__ | void |

Unregisters an observer added with `AddObserver()`. Unknown objects are ignored.


## Hot-plug timing

Chromium learns of a new output asynchronously (the `wl_output` global is announced, bound and described by the compositor, then the
display list is updated), so right after an output is switched on `GetAllDisplays()` and `FindByOutputName()` may not list it yet,
even if the application's own toolkit already knows it. A window made at that moment with `SetFullscreenOnDisplay(...)` for an id
looked up too early, or with `SetFullscreen(True)`, goes fullscreen on another output. Wait until `FindByOutputName(name)` returns the
display before using it, or use [AddObserver](#addobserver) and wait for `OnDisplayAdded`.

## Methods


### GetID

| | |
| --- | --- |
| __Return__ | int |

Unique identifier (on Wayland: the registry name of the `wl_output` global; it
changes when the output is unplugged and plugged back). The value
`Window.SetFullscreenOnDisplay()` takes.


### GetDeviceScaleFactor

| | |
| --- | --- |
| __Return__ | float |


### GetBounds

| | |
| --- | --- |
| __Return__ | list [x, y, width, height] |

In DIP screen coordinates.


### GetWorkArea

| | |
| --- | --- |
| __Return__ | list [x, y, width, height] |


### GetRotation

| | |
| --- | --- |
| __Return__ | int |

Degrees.


### GetLabel

| | |
| --- | --- |
| __Return__ | string |

User-friendly label given by the platform, possibly empty. On Wayland it is the
`wl_output` description. Requires a CEF build with `CefDisplay::GetLabel`
(an experimental API of CEF, proposed upstream).
