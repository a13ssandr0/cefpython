[API categories](API-categories.md) | [API index](API-index.md)


# View (object)

Base of everything in a [Window](Window.md) (`CefView`). The objects you get are
a [Window](Window.md), a [BrowserView](BrowserView.md), a Panel or a plain View.
All methods must be called on the UI thread.

Table of contents:
* [View methods](#view-methods)
* [Panel (object)](#panel-object)


## View methods

| Method | Parameters | Return |
| --- | --- | --- |
| GetTypeString | | string |
| ToString | include_children (optional bool) | string |
| IsValid | | bool |
| IsAttached | | bool |
| IsSame | view ([View](View.md)) | bool |
| GetWindow | | [Window](Window.md) or None |
| GetID / SetID | int | int / void |
| GetParentView | | View or None |
| GetViewForID | int | View or None |
| SetBounds | list [x, y, width, height] | void |
| GetBounds / GetBoundsInScreen | | list [x, y, width, height] |
| SetSize | list [width, height] | void |
| GetSize | | list [width, height] |
| SetPosition | list [x, y] | void |
| GetPosition | | list [x, y] |
| GetPreferredSize / GetMinimumSize / GetMaximumSize | | list [width, height] |
| SizeToPreferredSize | | void |
| InvalidateLayout | | void |
| SetVisible / IsVisible / IsDrawn | bool | void / bool |
| SetEnabled / IsEnabled | bool | void / bool |
| SetFocusable / IsFocusable / HasFocus | bool | void / bool |
| RequestFocus | | void |
| SetBackgroundColor / GetBackgroundColor | int 0xAARRGGBB | void / int |
| ConvertPointToScreen / ConvertPointFromScreen | list [x, y] | list [x, y] or None |

These are the methods of `CefView` of the same name, see
[cef_view.h](https://github.com/chromiumembedded/cef/blob/master/include/views/cef_view.h)
for the exact semantics.


## Panel (object)

A View that has children (a [Window](Window.md) is a Panel). Methods in addition
to those of View:

| Method | Parameters | Return |
| --- | --- | --- |
| SetToFillLayout | | void (every child fills the panel) |
| Layout | | void |
| AddChildView | view ([View](View.md)) | void |
| AddChildViewAt | view, index (int) | void |
| ReorderChildView | view, index (int) | void |
| RemoveChildView | view | void |
| RemoveAllChildViews | | void |
| GetChildViewCount | | int |
| GetChildViewAt | index (int) | [View](View.md) or None |
