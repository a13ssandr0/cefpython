// Copyright (c) 2026 CEF Python, see the Authors file.
// All rights reserved. Licensed under BSD 3-clause license.
// Project website: https://github.com/cztomczak/cefpython

// CEF Views framework delegates (windows and browser views). Browser process
// only. Every callback is forwarded to the Python delegate object given to
// cef.Window.CreateTopLevelWindow() / cef.BrowserView.CreateBrowserView();
// when the object has no method of that name the CEF default is used.

#pragma once

#include "common/cefpython_public_api.h"
#include "include/views/cef_browser_view.h"
#include "include/views/cef_browser_view_delegate.h"
#include "include/views/cef_display_observer.h"
#include "include/views/cef_window.h"
#include "include/views/cef_window_delegate.h"


// Strong reference to a Python object. Python's reference counting needs the
// GIL, and CEF may release the last reference to a delegate from any thread.
class PyObjectRef
{
public:
    explicit PyObjectRef(PyObject* object);
    ~PyObjectRef();
    PyObject* get() const { return object_; }
private:
    PyObject* object_;
};


class ViewsWindowDelegate : public CefWindowDelegate
{
public:
    // |pyDelegate| may be Py_None. A strong reference is kept until the
    // delegate is destroyed (which CEF does after OnWindowDestroyed).
    explicit ViewsWindowDelegate(PyObject* pyDelegate);

    // CefViewDelegate
    CefSize GetPreferredSize(CefRefPtr<CefView> view) override;
    CefSize GetMinimumSize(CefRefPtr<CefView> view) override;
    CefSize GetMaximumSize(CefRefPtr<CefView> view) override;
    int GetHeightForWidth(CefRefPtr<CefView> view, int width) override;
    void OnParentViewChanged(CefRefPtr<CefView> view, bool added,
                             CefRefPtr<CefView> parent) override;
    void OnChildViewChanged(CefRefPtr<CefView> view, bool added,
                            CefRefPtr<CefView> child) override;
    void OnWindowChanged(CefRefPtr<CefView> view, bool added) override;
    void OnLayoutChanged(CefRefPtr<CefView> view,
                         const CefRect& new_bounds) override;
    void OnFocus(CefRefPtr<CefView> view) override;
    void OnBlur(CefRefPtr<CefView> view) override;
    void OnThemeChanged(CefRefPtr<CefView> view) override;

    // CefWindowDelegate
    void OnWindowCreated(CefRefPtr<CefWindow> window) override;
    void OnWindowClosing(CefRefPtr<CefWindow> window) override;
    void OnWindowDestroyed(CefRefPtr<CefWindow> window) override;
    void OnWindowActivationChanged(CefRefPtr<CefWindow> window,
                                   bool active) override;
    void OnWindowBoundsChanged(CefRefPtr<CefWindow> window,
                               const CefRect& new_bounds) override;
    void OnWindowFullscreenTransition(CefRefPtr<CefWindow> window,
                                      bool is_completed) override;
    CefRefPtr<CefWindow> GetParentWindow(CefRefPtr<CefWindow> window,
                                         bool* is_menu,
                                         bool* can_activate_menu) override;
    bool IsWindowModalDialog(CefRefPtr<CefWindow> window) override;
    CefRect GetInitialBounds(CefRefPtr<CefWindow> window) override;
    cef_show_state_t GetInitialShowState(CefRefPtr<CefWindow> window) override;
    bool IsFrameless(CefRefPtr<CefWindow> window) override;
    bool WithStandardWindowButtons(CefRefPtr<CefWindow> window) override;
    bool CanResize(CefRefPtr<CefWindow> window) override;
    bool CanMaximize(CefRefPtr<CefWindow> window) override;
    bool CanMinimize(CefRefPtr<CefWindow> window) override;
    bool CanClose(CefRefPtr<CefWindow> window) override;
    cef_runtime_style_t GetWindowRuntimeStyle() override;
    bool GetLinuxWindowProperties(
            CefRefPtr<CefWindow> window,
            CefLinuxWindowProperties& properties) override;

private:
    PyObjectRef py_;

    IMPLEMENT_REFCOUNTING(ViewsWindowDelegate);
    DISALLOW_COPY_AND_ASSIGN(ViewsWindowDelegate);
};


class ViewsBrowserViewDelegate : public CefBrowserViewDelegate
{
public:
    explicit ViewsBrowserViewDelegate(PyObject* pyDelegate);

    // CefBrowserViewDelegate
    void OnBrowserCreated(CefRefPtr<CefBrowserView> browser_view,
                          CefRefPtr<CefBrowser> browser) override;
    void OnBrowserDestroyed(CefRefPtr<CefBrowserView> browser_view,
                            CefRefPtr<CefBrowser> browser) override;
    cef_runtime_style_t GetBrowserRuntimeStyle() override;

private:
    PyObjectRef py_;

    IMPLEMENT_REFCOUNTING(ViewsBrowserViewDelegate);
    DISALLOW_COPY_AND_ASSIGN(ViewsBrowserViewDelegate);
};


class ViewsDisplayObserver : public CefDisplayObserver
{
public:
    explicit ViewsDisplayObserver(PyObject* pyObserver);

    void OnDisplayAdded(CefRefPtr<CefDisplay> display) override;
    void OnDisplayRemoved(CefRefPtr<CefDisplay> display) override;
    void OnDisplayMetricsChanged(CefRefPtr<CefDisplay> display) override;

private:
    PyObjectRef py_;

    IMPLEMENT_REFCOUNTING(ViewsDisplayObserver);
    DISALLOW_COPY_AND_ASSIGN(ViewsDisplayObserver);
};
