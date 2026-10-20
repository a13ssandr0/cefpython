// Copyright (c) 2026 CEF Python, see the Authors file.
// All rights reserved. Licensed under BSD 3-clause license.
// Project website: https://github.com/cztomczak/cefpython

#include "views_delegate.h"


PyObjectRef::PyObjectRef(PyObject* object) : object_(object)
{
    PyGILState_STATE gil = PyGILState_Ensure();
    Py_XINCREF(object_);
    PyGILState_Release(gil);
}

PyObjectRef::~PyObjectRef()
{
    PyGILState_STATE gil = PyGILState_Ensure();
    Py_XDECREF(object_);
    PyGILState_Release(gil);
}


// ----------------------------------------------------------------------------
// ViewsWindowDelegate
// ----------------------------------------------------------------------------

// True when none of the browsers hosted by |window| needs more time to close.
static bool TryCloseBrowsers(CefRefPtr<CefWindow> window)
{
    bool canClose = true;
    const size_t count = window->GetChildViewCount();
    for (size_t i = 0; i < count; ++i) {
        CefRefPtr<CefView> view = window->GetChildViewAt(static_cast<int>(i));
        CefRefPtr<CefBrowserView> browserView =
                view ? view->AsBrowserView() : nullptr;
        CefRefPtr<CefBrowser> browser =
                browserView ? browserView->GetBrowser() : nullptr;
        if (browser && !browser->GetHost()->TryCloseBrowser()) {
            canClose = false;
        }
    }
    return canClose;
}

ViewsWindowDelegate::ViewsWindowDelegate(PyObject* pyDelegate)
    : py_(pyDelegate)
{
}

CefSize ViewsWindowDelegate::GetPreferredSize(CefRefPtr<CefView> view)
{
    int width = 0, height = 0;
    if (ViewsDelegate_GetSize(py_.get(), "GetPreferredSize", view, &width,
                              &height)) {
        return CefSize(width, height);
    }
    return CefWindowDelegate::GetPreferredSize(view);
}

CefSize ViewsWindowDelegate::GetMinimumSize(CefRefPtr<CefView> view)
{
    int width = 0, height = 0;
    if (ViewsDelegate_GetSize(py_.get(), "GetMinimumSize", view, &width,
                              &height)) {
        return CefSize(width, height);
    }
    return CefWindowDelegate::GetMinimumSize(view);
}

CefSize ViewsWindowDelegate::GetMaximumSize(CefRefPtr<CefView> view)
{
    int width = 0, height = 0;
    if (ViewsDelegate_GetSize(py_.get(), "GetMaximumSize", view, &width,
                              &height)) {
        return CefSize(width, height);
    }
    return CefWindowDelegate::GetMaximumSize(view);
}

int ViewsWindowDelegate::GetHeightForWidth(CefRefPtr<CefView> view, int width)
{
    int height = 0;
    if (ViewsDelegate_GetHeightForWidth(py_.get(), view, width, &height)) {
        return height;
    }
    return CefWindowDelegate::GetHeightForWidth(view, width);
}

void ViewsWindowDelegate::OnParentViewChanged(CefRefPtr<CefView> view,
                                              bool added,
                                              CefRefPtr<CefView> parent)
{
    ViewsDelegate_OnParentViewChanged(py_.get(), view, added, parent);
}

void ViewsWindowDelegate::OnChildViewChanged(CefRefPtr<CefView> view,
                                             bool added,
                                             CefRefPtr<CefView> child)
{
    ViewsDelegate_OnChildViewChanged(py_.get(), view, added, child);
}

void ViewsWindowDelegate::OnWindowChanged(CefRefPtr<CefView> view, bool added)
{
    ViewsDelegate_OnWindowChanged(py_.get(), view, added);
}

void ViewsWindowDelegate::OnLayoutChanged(CefRefPtr<CefView> view,
                                          const CefRect& new_bounds)
{
    ViewsDelegate_OnLayoutChanged(py_.get(), view, new_bounds);
}

void ViewsWindowDelegate::OnFocus(CefRefPtr<CefView> view)
{
    ViewsDelegate_OnViewEvent(py_.get(), "OnFocus", view);
}

void ViewsWindowDelegate::OnBlur(CefRefPtr<CefView> view)
{
    ViewsDelegate_OnViewEvent(py_.get(), "OnBlur", view);
}

void ViewsWindowDelegate::OnThemeChanged(CefRefPtr<CefView> view)
{
    ViewsDelegate_OnViewEvent(py_.get(), "OnThemeChanged", view);
}

void ViewsWindowDelegate::OnWindowCreated(CefRefPtr<CefWindow> window)
{
    WindowDelegate_OnWindowEvent(py_.get(), "OnWindowCreated", window);
}

void ViewsWindowDelegate::OnWindowClosing(CefRefPtr<CefWindow> window)
{
    WindowDelegate_OnWindowEvent(py_.get(), "OnWindowClosing", window);
}

void ViewsWindowDelegate::OnWindowDestroyed(CefRefPtr<CefWindow> window)
{
    WindowDelegate_OnWindowEvent(py_.get(), "OnWindowDestroyed", window);
}

void ViewsWindowDelegate::OnWindowActivationChanged(
        CefRefPtr<CefWindow> window, bool active)
{
    WindowDelegate_OnWindowActivationChanged(py_.get(), window, active);
}

void ViewsWindowDelegate::OnWindowBoundsChanged(CefRefPtr<CefWindow> window,
                                                const CefRect& new_bounds)
{
    WindowDelegate_OnWindowBoundsChanged(py_.get(), window, new_bounds);
}

void ViewsWindowDelegate::OnWindowFullscreenTransition(
        CefRefPtr<CefWindow> window, bool is_completed)
{
    WindowDelegate_OnWindowFullscreenTransition(py_.get(), window,
                                                is_completed);
}

CefRefPtr<CefWindow> ViewsWindowDelegate::GetParentWindow(
        CefRefPtr<CefWindow> window, bool* is_menu, bool* can_activate_menu)
{
    CefRefPtr<CefWindow> parent;
    if (WindowDelegate_GetParentWindow(py_.get(), window, is_menu,
                                       can_activate_menu, &parent)) {
        return parent;
    }
    return nullptr;
}

bool ViewsWindowDelegate::IsWindowModalDialog(CefRefPtr<CefWindow> window)
{
    bool result = false;
    if (WindowDelegate_GetBool(py_.get(), "IsWindowModalDialog", window,
                               &result)) {
        return result;
    }
    return CefWindowDelegate::IsWindowModalDialog(window);
}

CefRect ViewsWindowDelegate::GetInitialBounds(CefRefPtr<CefWindow> window)
{
    CefRect bounds;
    if (WindowDelegate_GetInitialBounds(py_.get(), window, &bounds)) {
        return bounds;
    }
    return CefWindowDelegate::GetInitialBounds(window);
}

cef_show_state_t ViewsWindowDelegate::GetInitialShowState(
        CefRefPtr<CefWindow> window)
{
    int state = CEF_SHOW_STATE_NORMAL;
    if (WindowDelegate_GetInitialShowState(py_.get(), window, &state)) {
        return static_cast<cef_show_state_t>(state);
    }
    return CefWindowDelegate::GetInitialShowState(window);
}

bool ViewsWindowDelegate::IsFrameless(CefRefPtr<CefWindow> window)
{
    bool result = false;
    if (WindowDelegate_GetBool(py_.get(), "IsFrameless", window, &result)) {
        return result;
    }
    return CefWindowDelegate::IsFrameless(window);
}

bool ViewsWindowDelegate::WithStandardWindowButtons(
        CefRefPtr<CefWindow> window)
{
    bool result = false;
    if (WindowDelegate_GetBool(py_.get(), "WithStandardWindowButtons", window,
                               &result)) {
        return result;
    }
    return CefWindowDelegate::WithStandardWindowButtons(window);
}

bool ViewsWindowDelegate::CanResize(CefRefPtr<CefWindow> window)
{
    bool result = false;
    if (WindowDelegate_GetBool(py_.get(), "CanResize", window, &result)) {
        return result;
    }
    return CefWindowDelegate::CanResize(window);
}

bool ViewsWindowDelegate::CanMaximize(CefRefPtr<CefWindow> window)
{
    bool result = false;
    if (WindowDelegate_GetBool(py_.get(), "CanMaximize", window, &result)) {
        return result;
    }
    return CefWindowDelegate::CanMaximize(window);
}

bool ViewsWindowDelegate::CanMinimize(CefRefPtr<CefWindow> window)
{
    bool result = false;
    if (WindowDelegate_GetBool(py_.get(), "CanMinimize", window, &result)) {
        return result;
    }
    return CefWindowDelegate::CanMinimize(window);
}

bool ViewsWindowDelegate::CanClose(CefRefPtr<CefWindow> window)
{
    bool result = true;
    if (WindowDelegate_GetBool(py_.get(), "CanClose", window, &result)) {
        return result;
    }
    // Like upstream cefsimple: give the page its unload handlers (and a
    // possible "beforeunload" dialog) a chance. TryCloseBrowser() returns
    // true at once when the browser is already closing.
    return TryCloseBrowsers(window);
}

cef_runtime_style_t ViewsWindowDelegate::GetWindowRuntimeStyle()
{
    // cefpython needs Alloy style: its JavaScript bindings and the Python
    // client handlers do not work in a Chrome style browser.
    int style = CEF_RUNTIME_STYLE_ALLOY;
    WindowDelegate_GetRuntimeStyle(py_.get(), &style);
    return static_cast<cef_runtime_style_t>(style);
}

bool ViewsWindowDelegate::GetLinuxWindowProperties(
        CefRefPtr<CefWindow> window, CefLinuxWindowProperties& properties)
{
#if defined(OS_LINUX)
    CefString app_id, wm_class_class, wm_class_name, wm_role_name;
    if (!WindowDelegate_GetLinuxWindowProperties(
                py_.get(), window, &app_id, &wm_class_class, &wm_class_name,
                &wm_role_name)) {
        return false;
    }
    CefString(&properties.wayland_app_id) = app_id;
    CefString(&properties.wm_class_class) = wm_class_class;
    CefString(&properties.wm_class_name) = wm_class_name;
    CefString(&properties.wm_role_name) = wm_role_name;
    return true;
#else
    return false;
#endif
}


// ----------------------------------------------------------------------------
// ViewsBrowserViewDelegate
// ----------------------------------------------------------------------------

ViewsBrowserViewDelegate::ViewsBrowserViewDelegate(PyObject* pyDelegate)
    : py_(pyDelegate)
{
}

void ViewsBrowserViewDelegate::OnBrowserCreated(
        CefRefPtr<CefBrowserView> browser_view, CefRefPtr<CefBrowser> browser)
{
    BrowserViewDelegate_OnBrowserEvent(py_.get(), "OnBrowserCreated",
                                       browser_view, browser);
}

void ViewsBrowserViewDelegate::OnBrowserDestroyed(
        CefRefPtr<CefBrowserView> browser_view, CefRefPtr<CefBrowser> browser)
{
    BrowserViewDelegate_OnBrowserEvent(py_.get(), "OnBrowserDestroyed",
                                       browser_view, browser);
}

cef_runtime_style_t ViewsBrowserViewDelegate::GetBrowserRuntimeStyle()
{
    int style = CEF_RUNTIME_STYLE_ALLOY;
    BrowserViewDelegate_GetRuntimeStyle(py_.get(), &style);
    return static_cast<cef_runtime_style_t>(style);
}
