# Copyright (c) 2026 CEF Python, see the Authors file.
# All rights reserved. Licensed under BSD 3-clause license.
# Project website: https://github.com/cztomczak/cefpython

include "cefpython.pyx"

# CEF Views framework: top-level windows, browser views and their delegates
# (include/views/*.h). A Views window is created and owned by CEF itself, so
# it works on every Ozone platform CEF runs on (X11 and Wayland) and has no
# dependency on a GUI toolkit. See docs: api/Window.md, api/BrowserView.md,
# api/WindowDelegate.md, api/Display.md.

from cpython.ref cimport PyObject
from views_delegate cimport ViewsWindowDelegate, ViewsBrowserViewDelegate
# noinspection PyUnresolvedReferences
cimport cef_views

# cef_show_state_t, WindowDelegate.GetInitialShowState().
SHOW_STATE_NORMAL = cef_views.CEF_SHOW_STATE_NORMAL
SHOW_STATE_MINIMIZED = cef_views.CEF_SHOW_STATE_MINIMIZED
SHOW_STATE_MAXIMIZED = cef_views.CEF_SHOW_STATE_MAXIMIZED
SHOW_STATE_FULLSCREEN = cef_views.CEF_SHOW_STATE_FULLSCREEN
SHOW_STATE_HIDDEN = cef_views.CEF_SHOW_STATE_HIDDEN

# cef_runtime_style_t, WindowDelegate.GetWindowRuntimeStyle() and
# BrowserViewDelegate.GetBrowserRuntimeStyle().
RUNTIME_STYLE_DEFAULT = CEF_RUNTIME_STYLE_DEFAULT
RUNTIME_STYLE_CHROME = CEF_RUNTIME_STYLE_CHROME
RUNTIME_STYLE_ALLOY = CEF_RUNTIME_STYLE_ALLOY

# Windows and browser views known to Python, by address of the CefView.
# A Window is removed after WindowDelegate.OnWindowDestroyed(), a BrowserView
# after BrowserViewDelegate.OnBrowserDestroyed(). Entries keep the CEF objects
# alive, so that the same Python object is handed out for the same window.
cdef dict g_pyWindows = {}
cdef dict g_pyBrowserViews = {}

# -----------------------------------------------------------------------------
# Conversions

cdef inline list RectToList(const CefRect& rect):
    return [rect.x, rect.y, rect.width, rect.height]

cdef CefRect ListToRect(object value) except *:
    if value is None or len(value) != 4:
        raise Exception("Rectangle must be a list [x, y, width, height]")
    return CefRect(int(value[0]), int(value[1]), int(value[2]), int(value[3]))

cdef CefSize ListToSize(object value) except *:
    if value is None or len(value) != 2:
        raise Exception("Size must be a list [width, height]")
    return CefSize(int(value[0]), int(value[1]))

cdef inline uintptr_t ViewKey(CefView* view) noexcept:
    return <uintptr_t>view

# -----------------------------------------------------------------------------
# View (base of Panel, Window and BrowserView)

cdef object ViewWrap(CefRefPtr[CefView] cefView):
    """Returns the Python object of a CefView: the Window or BrowserView
    when it is one, otherwise a Panel or a View. None for a NULL view."""
    if not cefView.get():
        return None
    cdef CefRefPtr[CefPanel] cefPanel = cefView.get().AsPanel()
    cdef CefRefPtr[CefWindow] cefWindow
    cdef CefRefPtr[CefBrowserView] cefBrowserView
    cdef Panel panel
    cdef View view
    if cefPanel.get():
        cefWindow = cefPanel.get().AsWindow()
        if cefWindow.get():
            return WindowWrap(cefWindow)
        panel = Panel.__new__(Panel)
        panel.cefView = cefView
        return panel
    cefBrowserView = cefView.get().AsBrowserView()
    if cefBrowserView.get():
        return BrowserViewWrap(cefBrowserView)
    view = View.__new__(View)
    view.cefView = cefView
    return view

cdef class View:
    cdef CefRefPtr[CefView] cefView

    cdef CefView* GetCefView(self) except *:
        if not self.cefView.get():
            raise Exception("View: the CEF view was destroyed")
        return self.cefView.get()

    def GetTypeString(self):
        return CefToPyString(self.GetCefView().GetTypeString())

    def ToString(self, include_children=False):
        return CefToPyString(self.GetCefView().ToString(
                bool(include_children)))

    def IsValid(self):
        return self.cefView.get() != NULL and bool(self.cefView.get().IsValid())

    def IsAttached(self):
        return bool(self.GetCefView().IsAttached())

    def IsSame(self, View that):
        return bool(self.GetCefView().IsSame(that.cefView))

    def GetWindow(self):
        """Returns the Window this view is attached to, or None."""
        cdef CefRefPtr[CefWindow] cefWindow = self.GetCefView().GetWindow()
        if not cefWindow.get():
            return None
        return WindowWrap(cefWindow)

    def GetID(self):
        return int(self.GetCefView().GetID())

    def SetID(self, int id):
        self.GetCefView().SetID(id)

    def GetParentView(self):
        return ViewWrap(self.GetCefView().GetParentView())

    def GetViewForID(self, int id):
        return ViewWrap(self.GetCefView().GetViewForID(id))

    def SetBounds(self, bounds):
        self.GetCefView().SetBounds(ListToRect(bounds))

    def GetBounds(self):
        cdef CefRect rect = self.GetCefView().GetBounds()
        return RectToList(rect)

    def GetBoundsInScreen(self):
        cdef CefRect rect = self.GetCefView().GetBoundsInScreen()
        return RectToList(rect)

    def SetSize(self, size):
        self.GetCefView().SetSize(ListToSize(size))

    def GetSize(self):
        cdef CefSize size = self.GetCefView().GetSize()
        return [size.width, size.height]

    def SetPosition(self, position):
        cdef CefPoint point
        point.x = int(position[0])
        point.y = int(position[1])
        self.GetCefView().SetPosition(point)

    def GetPosition(self):
        cdef CefPoint point = self.GetCefView().GetPosition()
        return [point.x, point.y]

    def GetPreferredSize(self):
        cdef CefSize size = self.GetCefView().GetPreferredSize()
        return [size.width, size.height]

    def SizeToPreferredSize(self):
        self.GetCefView().SizeToPreferredSize()

    def GetMinimumSize(self):
        cdef CefSize size = self.GetCefView().GetMinimumSize()
        return [size.width, size.height]

    def GetMaximumSize(self):
        cdef CefSize size = self.GetCefView().GetMaximumSize()
        return [size.width, size.height]

    def InvalidateLayout(self):
        self.GetCefView().InvalidateLayout()

    def SetVisible(self, visible):
        self.GetCefView().SetVisible(bool(visible))

    def IsVisible(self):
        return bool(self.GetCefView().IsVisible())

    def IsDrawn(self):
        return bool(self.GetCefView().IsDrawn())

    def SetEnabled(self, enabled):
        self.GetCefView().SetEnabled(bool(enabled))

    def IsEnabled(self):
        return bool(self.GetCefView().IsEnabled())

    def SetFocusable(self, focusable):
        self.GetCefView().SetFocusable(bool(focusable))

    def IsFocusable(self):
        return bool(self.GetCefView().IsFocusable())

    def HasFocus(self):
        return bool(self.GetCefView().HasFocus())

    def RequestFocus(self):
        self.GetCefView().RequestFocus()

    def SetBackgroundColor(self, color):
        """Color as 0xAARRGGBB."""
        self.GetCefView().SetBackgroundColor(<cef_color_t>int(color))

    def GetBackgroundColor(self):
        return int(self.GetCefView().GetBackgroundColor())

    def ConvertPointToScreen(self, point):
        cdef CefPoint cefPoint
        cefPoint.x = int(point[0])
        cefPoint.y = int(point[1])
        if not self.GetCefView().ConvertPointToScreen(cefPoint):
            return None
        return [cefPoint.x, cefPoint.y]

    def ConvertPointFromScreen(self, point):
        cdef CefPoint cefPoint
        cefPoint.x = int(point[0])
        cefPoint.y = int(point[1])
        if not self.GetCefView().ConvertPointFromScreen(cefPoint):
            return None
        return [cefPoint.x, cefPoint.y]

# -----------------------------------------------------------------------------
# Panel

cdef class Panel(View):

    cdef CefRefPtr[CefPanel] GetCefPanel(self) except *:
        # Returned by value: AsPanel() hands out a new reference (a new
        # wrapper object of the CEF library) that must be kept alive.
        cdef CefRefPtr[CefPanel] cefPanel = self.GetCefView().AsPanel()
        if not cefPanel.get():
            raise Exception("Panel: the CEF panel was destroyed")
        return cefPanel

    def SetToFillLayout(self):
        """Makes every child view fill the whole panel."""
        self.GetCefPanel().get().SetToFillLayout()

    def Layout(self):
        self.GetCefPanel().get().Layout()

    def AddChildView(self, View view):
        self.GetCefPanel().get().AddChildView(view.cefView)

    def AddChildViewAt(self, View view, int index):
        self.GetCefPanel().get().AddChildViewAt(view.cefView, index)

    def ReorderChildView(self, View view, int index):
        self.GetCefPanel().get().ReorderChildView(view.cefView, index)

    def RemoveChildView(self, View view):
        self.GetCefPanel().get().RemoveChildView(view.cefView)

    def RemoveAllChildViews(self):
        self.GetCefPanel().get().RemoveAllChildViews()

    def GetChildViewCount(self):
        return int(self.GetCefPanel().get().GetChildViewCount())

    def GetChildViewAt(self, int index):
        return ViewWrap(self.GetCefPanel().get().GetChildViewAt(index))

# -----------------------------------------------------------------------------
# Window

cdef Window WindowWrap(CefRefPtr[CefWindow] cefWindow):
    cdef uintptr_t key = ViewKey(<CefView*>cefWindow.get())
    cdef Window window
    if key in g_pyWindows:
        return g_pyWindows[key]
    window = Window.__new__(Window)
    window.cefView = CefRefPtr[CefView](<CefView*>cefWindow.get())
    window.userData = {}
    g_pyWindows[key] = window
    return window

cdef class Window(Panel):
    cdef dict userData
    # The Python delegate is kept alive by the C++ ViewsWindowDelegate.

    cdef CefRefPtr[CefWindow] GetCefWindow(self) except *:
        cdef CefRefPtr[CefWindow] cefWindow
        cefWindow = self.GetCefPanel().get().AsWindow()
        if not cefWindow.get():
            raise Exception("Window: the CEF window was destroyed")
        return cefWindow

    @staticmethod
    def CreateTopLevelWindow(delegate=None):
        """Creates a top-level window. The window is not visible until Show()
        is called. |delegate| is any object with methods named like those of
        CefWindowDelegate (see WindowDelegate.md); all are optional."""
        cdef CefRefPtr[ViewsWindowDelegate] cefDelegate = \
                CefRefPtr[ViewsWindowDelegate](
                        new ViewsWindowDelegate(<PyObject*>delegate))
        cdef CefRefPtr[CefWindow] cefWindow = \
                CefWindow.CreateTopLevelWindow(
                        <CefRefPtr[CefWindowDelegate]?>cefDelegate)
        if not cefWindow.get():
            raise Exception("CreateTopLevelWindow() failed")
        return WindowWrap(cefWindow)

    def Show(self):
        self.GetCefWindow().get().Show()

    def Hide(self):
        self.GetCefWindow().get().Hide()

    def CenterWindow(self, size):
        self.GetCefWindow().get().CenterWindow(ListToSize(size))

    def Close(self):
        """Closes the window. The delegate's CanClose() decides (by default
        the browsers inside get their unload handlers run first) and the
        native window is destroyed, followed by OnWindowDestroyed()."""
        self.GetCefWindow().get().Close()

    def IsClosed(self):
        if not self.cefView.get():
            return True
        return bool(self.GetCefWindow().get().IsClosed())

    def Activate(self):
        self.GetCefWindow().get().Activate()

    def Deactivate(self):
        self.GetCefWindow().get().Deactivate()

    def IsActive(self):
        return bool(self.GetCefWindow().get().IsActive())

    def BringToTop(self):
        self.GetCefWindow().get().BringToTop()

    def SetAlwaysOnTop(self, on_top):
        self.GetCefWindow().get().SetAlwaysOnTop(bool(on_top))

    def IsAlwaysOnTop(self):
        return bool(self.GetCefWindow().get().IsAlwaysOnTop())

    def Maximize(self):
        self.GetCefWindow().get().Maximize()

    def Minimize(self):
        self.GetCefWindow().get().Minimize()

    def Restore(self):
        self.GetCefWindow().get().Restore()

    def SetFullscreen(self, fullscreen):
        self.GetCefWindow().get().SetFullscreen(bool(fullscreen))

    def IsMaximized(self):
        return bool(self.GetCefWindow().get().IsMaximized())

    def IsMinimized(self):
        return bool(self.GetCefWindow().get().IsMinimized())

    def IsFullscreen(self):
        return bool(self.GetCefWindow().get().IsFullscreen())

    def SetTitle(self, title):
        cdef CefString cefTitle
        PyToCefString(title, cefTitle)
        self.GetCefWindow().get().SetTitle(cefTitle)

    def GetTitle(self):
        return CefToPyString(self.GetCefWindow().get().GetTitle())

    def GetDisplay(self):
        """The Display the window is on."""
        return DisplayWrap(self.GetCefWindow().get().GetDisplay())

    def GetClientAreaBoundsInScreen(self):
        cdef CefRect rect = self.GetCefWindow().get().GetClientAreaBoundsInScreen()
        return RectToList(rect)

    def GetWindowHandle(self):
        return <WindowHandle>self.GetCefWindow().get().GetWindowHandle()

    def GetRuntimeStyle(self):
        return int(self.GetCefWindow().get().GetRuntimeStyle())

    def SetUserData(self, key, value):
        self.userData[key] = value

    def GetUserData(self, key):
        return self.userData.get(key)

    def __repr__(self):
        return "<Window %s>" % (
                "closed" if self.IsClosed() else self.GetTitle())

# -----------------------------------------------------------------------------
# BrowserView

cdef BrowserView BrowserViewWrap(CefRefPtr[CefBrowserView] cefBrowserView):
    cdef uintptr_t key = ViewKey(<CefView*>cefBrowserView.get())
    cdef BrowserView browserView
    if key in g_pyBrowserViews:
        return g_pyBrowserViews[key]
    browserView = BrowserView.__new__(BrowserView)
    browserView.cefView = CefRefPtr[CefView](<CefView*>cefBrowserView.get())
    g_pyBrowserViews[key] = browserView
    return browserView

cdef class BrowserView(View):
    # Set by CreateBrowserView(), used when the browser gets created.
    cdef dict browserSettings
    cdef CefRefPtr[RequestContextHandler] requestContextHandler
    cdef py_bool bindRequestContext

    cdef CefRefPtr[CefBrowserView] GetCefBrowserView(self) except *:
        cdef CefRefPtr[CefBrowserView] cefBrowserView = \
                self.GetCefView().AsBrowserView()
        if not cefBrowserView.get():
            raise Exception("BrowserView: the CEF view was destroyed")
        return cefBrowserView

    @staticmethod
    def CreateBrowserView(url="", settings=None, delegate=None, **kwargs):
        """Creates a browser view. The browser itself is created by CEF when
        the view gets attached to a window (Panel.AddChildView()); use
        BrowserViewDelegate.OnBrowserCreated() or GetBrowser() after that."""
        if "navigateUrl" in kwargs:
            url = kwargs.pop("navigateUrl")
        if "browserSettings" in kwargs:
            settings = kwargs.pop("browserSettings")
        for kwarg in kwargs:
            raise Exception("Invalid argument: " + kwarg)

        if not settings:
            settings = {}
        if "inherit_client_handlers_for_popups" not in settings:
            settings["inherit_client_handlers_for_popups"] = True
        cdef CefBrowserSettings cefBrowserSettings
        SetBrowserSettings(settings, &cefBrowserSettings)

        cdef CefString cefUrl
        PyToCefString(url, cefUrl)

        cdef CefRefPtr[ClientHandler] clientHandler = \
                <CefRefPtr[ClientHandler]?>new ClientHandler()

        # Request context, same as in CreateBrowserSync().
        cdef py_bool createSharedRequestContext = \
                bool(not g_shared_request_context.get())
        cdef CefRefPtr[CefBrowser] noBrowser
        cdef CefRefPtr[CefRequestContext] cefRequestContext
        cdef CefRefPtr[RequestContextHandler] requestContextHandler = \
                <CefRefPtr[RequestContextHandler]?>new RequestContextHandler(
                        noBrowser)
        cdef py_bool bindRequestContext = False
        if g_applicationSettings["unique_request_context_per_browser"]:
            cefRequestContext = CefRequestContext.CreateContext(
                    CefRequestContext.GetGlobalContext(),
                    <CefRefPtr[CefRequestContextHandler]?>requestContextHandler)
            bindRequestContext = True
        elif createSharedRequestContext:
            cefRequestContext = CefRequestContext.CreateContext(
                    CefRequestContext.GetGlobalContext(),
                    <CefRefPtr[CefRequestContextHandler]?>requestContextHandler)
            g_shared_request_context.Assign(cefRequestContext.get())
            bindRequestContext = True
        else:
            cefRequestContext.Assign(g_shared_request_context.get())

        cdef CefRefPtr[ViewsBrowserViewDelegate] cefDelegate = \
                CefRefPtr[ViewsBrowserViewDelegate](
                        new ViewsBrowserViewDelegate(<PyObject*>delegate))
        cdef CefRefPtr[CefDictionaryValue] extraInfo
        cdef CefRefPtr[CefBrowserView] cefBrowserView = \
                CefBrowserView.CreateBrowserView(
                        <CefRefPtr[CefClient]?>clientHandler, cefUrl,
                        cefBrowserSettings, extraInfo, cefRequestContext,
                        <CefRefPtr[CefBrowserViewDelegate]?>cefDelegate)
        if not cefBrowserView.get():
            raise Exception("CreateBrowserView() failed")
        cdef BrowserView browserView = BrowserViewWrap(cefBrowserView)
        # A copy, as |settings| is a reference only that might get destroyed.
        browserView.browserSettings = copy.deepcopy(settings)
        browserView.requestContextHandler = requestContextHandler
        browserView.bindRequestContext = bindRequestContext
        return browserView

    def GetBrowser(self):
        """The Browser object, or None until CEF created the browser (when
        the view is attached to a window)."""
        cdef CefRefPtr[CefBrowser] cefBrowser = \
                self.GetCefBrowserView().get().GetBrowser()
        if not cefBrowser.get():
            return None
        return GetPyBrowser(cefBrowser, "BrowserView.GetBrowser")

    def SetPreferAccelerators(self, prefer_accelerators):
        self.GetCefBrowserView().get().SetPreferAccelerators(
                bool(prefer_accelerators))

    def GetRuntimeStyle(self):
        return int(self.GetCefBrowserView().get().GetRuntimeStyle())

# -----------------------------------------------------------------------------
# Delegate callbacks (called from client_handler/views_delegate.cpp). Each
# Python delegate method is optional: the functions that return a value
# return False (not handled) when the delegate has no such method or it
# returned None, and the C++ side then uses the CEF default.

cdef object DelegateMethod(object delegate, const char* name):
    if delegate is None:
        return None
    return getattr(delegate, CharToPyString(name), None)

cdef public cpp_bool ViewsDelegate_GetSize(
        object delegate, const char* name, CefRefPtr[CefView] cefView,
        int* width, int* height) noexcept with gil:
    try:
        method = DelegateMethod(delegate, name)
        if method is None:
            return False
        result = method(ViewWrap(cefView))
        if result is None:
            return False
        width[0] = int(result[0])
        height[0] = int(result[1])
        return True
    except:
        (exc_type, exc_value, exc_trace) = sys.exc_info()
        sys.excepthook(exc_type, exc_value, exc_trace)
        return False

cdef public cpp_bool ViewsDelegate_GetHeightForWidth(
        object delegate, CefRefPtr[CefView] cefView, int width,
        int* height) noexcept with gil:
    try:
        method = DelegateMethod(delegate, "GetHeightForWidth")
        if method is None:
            return False
        result = method(ViewWrap(cefView), width)
        if result is None:
            return False
        height[0] = int(result)
        return True
    except:
        (exc_type, exc_value, exc_trace) = sys.exc_info()
        sys.excepthook(exc_type, exc_value, exc_trace)
        return False

cdef public void ViewsDelegate_OnParentViewChanged(
        object delegate, CefRefPtr[CefView] cefView, cpp_bool added,
        CefRefPtr[CefView] cefParent) noexcept with gil:
    try:
        method = DelegateMethod(delegate, "OnParentViewChanged")
        if method is not None:
            method(ViewWrap(cefView), bool(added), ViewWrap(cefParent))
    except:
        (exc_type, exc_value, exc_trace) = sys.exc_info()
        sys.excepthook(exc_type, exc_value, exc_trace)

cdef public void ViewsDelegate_OnChildViewChanged(
        object delegate, CefRefPtr[CefView] cefView, cpp_bool added,
        CefRefPtr[CefView] cefChild) noexcept with gil:
    try:
        method = DelegateMethod(delegate, "OnChildViewChanged")
        if method is not None:
            method(ViewWrap(cefView), bool(added), ViewWrap(cefChild))
    except:
        (exc_type, exc_value, exc_trace) = sys.exc_info()
        sys.excepthook(exc_type, exc_value, exc_trace)

cdef public void ViewsDelegate_OnWindowChanged(
        object delegate, CefRefPtr[CefView] cefView,
        cpp_bool added) noexcept with gil:
    try:
        method = DelegateMethod(delegate, "OnWindowChanged")
        if method is not None:
            method(ViewWrap(cefView), bool(added))
    except:
        (exc_type, exc_value, exc_trace) = sys.exc_info()
        sys.excepthook(exc_type, exc_value, exc_trace)

cdef public void ViewsDelegate_OnLayoutChanged(
        object delegate, CefRefPtr[CefView] cefView,
        const CefRect& newBounds) noexcept with gil:
    try:
        method = DelegateMethod(delegate, "OnLayoutChanged")
        if method is not None:
            method(ViewWrap(cefView), RectToList(newBounds))
    except:
        (exc_type, exc_value, exc_trace) = sys.exc_info()
        sys.excepthook(exc_type, exc_value, exc_trace)

cdef public void ViewsDelegate_OnViewEvent(
        object delegate, const char* name,
        CefRefPtr[CefView] cefView) noexcept with gil:
    # OnFocus, OnBlur, OnThemeChanged
    try:
        method = DelegateMethod(delegate, name)
        if method is not None:
            method(ViewWrap(cefView))
    except:
        (exc_type, exc_value, exc_trace) = sys.exc_info()
        sys.excepthook(exc_type, exc_value, exc_trace)

cdef public void WindowDelegate_OnWindowEvent(
        object delegate, const char* name,
        CefRefPtr[CefWindow] cefWindow) noexcept with gil:
    # OnWindowCreated, OnWindowClosing, OnWindowDestroyed
    cdef Window window
    cdef uintptr_t key
    try:
        window = WindowWrap(cefWindow)
        method = DelegateMethod(delegate, name)
        try:
            if method is not None:
                method(window)
        finally:
            if CharToPyString(name) == "OnWindowDestroyed":
                # The CEF window is gone: let go of it.
                key = ViewKey(<CefView*>cefWindow.get())
                g_pyWindows.pop(key, None)
                window.cefView.Assign(nullptr)
    except:
        (exc_type, exc_value, exc_trace) = sys.exc_info()
        sys.excepthook(exc_type, exc_value, exc_trace)

cdef public void WindowDelegate_OnWindowActivationChanged(
        object delegate, CefRefPtr[CefWindow] cefWindow,
        cpp_bool active) noexcept with gil:
    try:
        method = DelegateMethod(delegate, "OnWindowActivationChanged")
        if method is not None:
            method(WindowWrap(cefWindow), bool(active))
    except:
        (exc_type, exc_value, exc_trace) = sys.exc_info()
        sys.excepthook(exc_type, exc_value, exc_trace)

cdef public void WindowDelegate_OnWindowBoundsChanged(
        object delegate, CefRefPtr[CefWindow] cefWindow,
        const CefRect& newBounds) noexcept with gil:
    try:
        method = DelegateMethod(delegate, "OnWindowBoundsChanged")
        if method is not None:
            method(WindowWrap(cefWindow), RectToList(newBounds))
    except:
        (exc_type, exc_value, exc_trace) = sys.exc_info()
        sys.excepthook(exc_type, exc_value, exc_trace)

cdef public void WindowDelegate_OnWindowFullscreenTransition(
        object delegate, CefRefPtr[CefWindow] cefWindow,
        cpp_bool isCompleted) noexcept with gil:
    try:
        method = DelegateMethod(delegate, "OnWindowFullscreenTransition")
        if method is not None:
            method(WindowWrap(cefWindow), bool(isCompleted))
    except:
        (exc_type, exc_value, exc_trace) = sys.exc_info()
        sys.excepthook(exc_type, exc_value, exc_trace)

cdef public cpp_bool WindowDelegate_GetParentWindow(
        object delegate, CefRefPtr[CefWindow] cefWindow, cpp_bool* isMenu,
        cpp_bool* canActivateMenu,
        CefRefPtr[CefWindow]* parent) noexcept with gil:
    cdef Window parentWindow
    try:
        method = DelegateMethod(delegate, "GetParentWindow")
        if method is None:
            return False
        result = method(WindowWrap(cefWindow))
        if result is None:
            return False
        # Either a Window, or (Window, is_menu, can_activate_menu).
        if isinstance(result, tuple):
            parentWindow = result[0]
            isMenu[0] = bool(result[1]) if len(result) > 1 else False
            canActivateMenu[0] = bool(result[2]) if len(result) > 2 else True
        else:
            parentWindow = result
        parent[0].Assign(parentWindow.GetCefWindow().get())
        return True
    except:
        (exc_type, exc_value, exc_trace) = sys.exc_info()
        sys.excepthook(exc_type, exc_value, exc_trace)
        return False

cdef public cpp_bool WindowDelegate_GetBool(
        object delegate, const char* name, CefRefPtr[CefWindow] cefWindow,
        cpp_bool* result) noexcept with gil:
    # IsWindowModalDialog, IsFrameless, WithStandardWindowButtons, CanResize,
    # CanMaximize, CanMinimize, CanClose
    try:
        method = DelegateMethod(delegate, name)
        if method is None:
            return False
        value = method(WindowWrap(cefWindow))
        if value is None:
            return False
        result[0] = bool(value)
        return True
    except:
        (exc_type, exc_value, exc_trace) = sys.exc_info()
        sys.excepthook(exc_type, exc_value, exc_trace)
        return False

cdef public cpp_bool WindowDelegate_GetInitialBounds(
        object delegate, CefRefPtr[CefWindow] cefWindow,
        CefRect* bounds) noexcept with gil:
    try:
        method = DelegateMethod(delegate, "GetInitialBounds")
        if method is None:
            return False
        result = method(WindowWrap(cefWindow))
        if result is None:
            return False
        bounds[0] = ListToRect(result)
        return True
    except:
        (exc_type, exc_value, exc_trace) = sys.exc_info()
        sys.excepthook(exc_type, exc_value, exc_trace)
        return False

cdef public cpp_bool WindowDelegate_GetInitialShowState(
        object delegate, CefRefPtr[CefWindow] cefWindow,
        int* state) noexcept with gil:
    try:
        method = DelegateMethod(delegate, "GetInitialShowState")
        if method is None:
            return False
        result = method(WindowWrap(cefWindow))
        if result is None:
            return False
        state[0] = int(result)
        return True
    except:
        (exc_type, exc_value, exc_trace) = sys.exc_info()
        sys.excepthook(exc_type, exc_value, exc_trace)
        return False

cdef public cpp_bool WindowDelegate_GetRuntimeStyle(
        object delegate, int* style) noexcept with gil:
    try:
        method = DelegateMethod(delegate, "GetWindowRuntimeStyle")
        if method is None:
            return False
        result = method()
        if result is None:
            return False
        style[0] = int(result)
        return True
    except:
        (exc_type, exc_value, exc_trace) = sys.exc_info()
        sys.excepthook(exc_type, exc_value, exc_trace)
        return False

cdef public cpp_bool WindowDelegate_GetLinuxWindowProperties(
        object delegate, CefRefPtr[CefWindow] cefWindow, CefString* appId,
        CefString* wmClassClass, CefString* wmClassName,
        CefString* wmRoleName) noexcept with gil:
    try:
        method = DelegateMethod(delegate, "GetLinuxWindowProperties")
        if method is None:
            return False
        result = method(WindowWrap(cefWindow))
        if not result:
            return False
        PyToCefStringPointer(result.get("wayland_app_id", ""), appId)
        PyToCefStringPointer(result.get("wm_class_class", ""), wmClassClass)
        PyToCefStringPointer(result.get("wm_class_name", ""), wmClassName)
        PyToCefStringPointer(result.get("wm_role_name", ""), wmRoleName)
        return True
    except:
        (exc_type, exc_value, exc_trace) = sys.exc_info()
        sys.excepthook(exc_type, exc_value, exc_trace)
        return False

cdef public void BrowserViewDelegate_OnBrowserEvent(
        object delegate, const char* name,
        CefRefPtr[CefBrowserView] cefBrowserView,
        CefRefPtr[CefBrowser] cefBrowser) noexcept with gil:
    # OnBrowserCreated, OnBrowserDestroyed
    cdef BrowserView browserView
    cdef PyBrowser pyBrowser
    cdef int browserId
    cdef uintptr_t key
    cdef py_bool created = (CharToPyString(name) == "OnBrowserCreated")
    try:
        browserView = BrowserViewWrap(cefBrowserView)
        pyBrowser = GetPyBrowser(cefBrowser, CharToPyString(name))
        if created:
            # What CreateBrowserSync() does after creating the browser.
            browserId = cefBrowser.get().GetIdentifier()
            g_browser_settings[browserId] = browserView.browserSettings or {}
            pyBrowser.SetUserData("__outerWindowHandle", 0)
            if browserView.bindRequestContext \
                    and browserView.requestContextHandler.get() != NULL:
                browserView.requestContextHandler.get().SetBrowser(cefBrowser)
        method = DelegateMethod(delegate, name)
        try:
            if method is not None:
                method(browserView, pyBrowser)
        finally:
            if not created:
                key = ViewKey(<CefView*>cefBrowserView.get())
                g_pyBrowserViews.pop(key, None)
                browserView.requestContextHandler.Assign(nullptr)
    except:
        (exc_type, exc_value, exc_trace) = sys.exc_info()
        sys.excepthook(exc_type, exc_value, exc_trace)

cdef public cpp_bool BrowserViewDelegate_GetRuntimeStyle(
        object delegate, int* style) noexcept with gil:
    try:
        method = DelegateMethod(delegate, "GetBrowserRuntimeStyle")
        if method is None:
            return False
        result = method()
        if result is None:
            return False
        style[0] = int(result)
        return True
    except:
        (exc_type, exc_value, exc_trace) = sys.exc_info()
        sys.excepthook(exc_type, exc_value, exc_trace)
        return False
