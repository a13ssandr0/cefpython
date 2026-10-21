# Copyright (c) 2017 CEF Python, see the Authors file.
# All rights reserved. Licensed under BSD 3-clause license.
# Project website: https://github.com/cztomczak/cefpython

# Declarations of the CEF Views framework (include/views/*.h): windows,
# browser views and displays. See docs/api/Window.md.

include "compile_time_constants.pxi"

from libc.stdint cimport int64_t, uint32_t
from libcpp cimport bool as cpp_bool
from libcpp.vector cimport vector

IF UNAME_SYSNAME == "Windows":
    from cef_win cimport CefWindowHandle, cef_runtime_style_t
ELIF UNAME_SYSNAME == "Linux":
    from cef_linux cimport CefWindowHandle, cef_runtime_style_t
ELIF UNAME_SYSNAME == "Darwin":
    from cef_mac cimport CefWindowHandle, cef_runtime_style_t

from cef_ptr cimport CefRefPtr
from cef_browser cimport CefBrowser
from cef_client cimport CefClient
from cef_types cimport CefRect, CefSize, CefPoint, cef_color_t
from cef_types cimport CefBrowserSettings
from cef_string cimport CefString
from cef_request_context cimport CefRequestContext
from cef_values cimport CefDictionaryValue

cdef extern from "include/internal/cef_types.h":
    ctypedef enum cef_show_state_t:
        CEF_SHOW_STATE_NORMAL
        CEF_SHOW_STATE_MINIMIZED
        CEF_SHOW_STATE_MAXIMIZED
        CEF_SHOW_STATE_FULLSCREEN
        CEF_SHOW_STATE_HIDDEN

cdef extern from "include/views/cef_display.h":
    cdef cppclass CefDisplay:
        @staticmethod
        CefRefPtr[CefDisplay] GetPrimaryDisplay()
        @staticmethod
        CefRefPtr[CefDisplay] GetDisplayNearestPoint(
                const CefPoint& point, cpp_bool input_pixel_coords)
        @staticmethod
        CefRefPtr[CefDisplay] GetDisplayMatchingBounds(
                const CefRect& bounds, cpp_bool input_pixel_coords)
        @staticmethod
        size_t GetDisplayCount()
        @staticmethod
        void GetAllDisplays(vector[CefRefPtr[CefDisplay]]& displays)
        int64_t GetID()
        float GetDeviceScaleFactor()
        CefRect GetBounds()
        CefRect GetWorkArea()
        int GetRotation()
        CefString GetLabel()
        @staticmethod
        void AddObserver(CefRefPtr[CefDisplayObserver] observer)
        @staticmethod
        void RemoveObserver(CefRefPtr[CefDisplayObserver] observer)

cdef extern from "include/views/cef_view.h":
    cdef cppclass CefView:
        CefRefPtr[CefBrowserView] AsBrowserView()
        CefRefPtr[CefPanel] AsPanel()
        CefString GetTypeString()
        CefString ToString(cpp_bool include_children)
        cpp_bool IsValid()
        cpp_bool IsAttached()
        cpp_bool IsSame(CefRefPtr[CefView] that)
        CefRefPtr[CefWindow] GetWindow()
        int GetID()
        void SetID(int id)
        CefRefPtr[CefView] GetParentView()
        CefRefPtr[CefView] GetViewForID(int id)
        void SetBounds(const CefRect& bounds)
        CefRect GetBounds()
        CefRect GetBoundsInScreen()
        void SetSize(const CefSize& size)
        CefSize GetSize()
        void SetPosition(const CefPoint& position)
        CefPoint GetPosition()
        CefSize GetPreferredSize()
        void SizeToPreferredSize()
        CefSize GetMinimumSize()
        CefSize GetMaximumSize()
        void InvalidateLayout()
        void SetVisible(cpp_bool visible)
        cpp_bool IsVisible()
        cpp_bool IsDrawn()
        void SetEnabled(cpp_bool enabled)
        cpp_bool IsEnabled()
        void SetFocusable(cpp_bool focusable)
        cpp_bool IsFocusable()
        cpp_bool HasFocus()
        void RequestFocus()
        void SetBackgroundColor(cef_color_t color)
        cef_color_t GetBackgroundColor()
        cpp_bool ConvertPointToScreen(CefPoint& point)
        cpp_bool ConvertPointFromScreen(CefPoint& point)

cdef extern from "include/views/cef_display_observer.h":
    cdef cppclass CefDisplayObserver:
        pass

cdef extern from "include/views/cef_fill_layout.h":
    cdef cppclass CefFillLayout:
        pass

cdef extern from "include/views/cef_panel.h":
    cdef cppclass CefPanel(CefView):
        CefRefPtr[CefWindow] AsWindow()
        CefRefPtr[CefFillLayout] SetToFillLayout()
        void Layout()
        void AddChildView(CefRefPtr[CefView] view)
        void AddChildViewAt(CefRefPtr[CefView] view, int index)
        void ReorderChildView(CefRefPtr[CefView] view, int index)
        void RemoveChildView(CefRefPtr[CefView] view)
        void RemoveAllChildViews()
        size_t GetChildViewCount()
        CefRefPtr[CefView] GetChildViewAt(int index)

cdef extern from "include/views/cef_window.h":
    cdef cppclass CefWindow(CefPanel):
        @staticmethod
        CefRefPtr[CefWindow] CreateTopLevelWindow(
                CefRefPtr[CefWindowDelegate] delegate)
        void Show()
        void Hide()
        void CenterWindow(const CefSize& size)
        void Close()
        cpp_bool IsClosed()
        void Activate()
        void Deactivate()
        cpp_bool IsActive()
        void BringToTop()
        void SetAlwaysOnTop(cpp_bool on_top)
        cpp_bool IsAlwaysOnTop()
        void Maximize()
        void Minimize()
        void Restore()
        void SetFullscreen(cpp_bool fullscreen)
        void SetFullscreenOnDisplay(int64_t display_id)
        cpp_bool IsMaximized()
        cpp_bool IsMinimized()
        cpp_bool IsFullscreen()
        void SetTitle(const CefString& title)
        CefString GetTitle()
        CefRefPtr[CefDisplay] GetDisplay()
        CefRect GetClientAreaBoundsInScreen()
        CefWindowHandle GetWindowHandle()
        cef_runtime_style_t GetRuntimeStyle()

cdef extern from "include/views/cef_window_delegate.h":
    cdef cppclass CefWindowDelegate:
        pass

cdef extern from "include/views/cef_browser_view.h":
    cdef cppclass CefBrowserView(CefView):
        @staticmethod
        CefRefPtr[CefBrowserView] CreateBrowserView(
                CefRefPtr[CefClient] client,
                const CefString& url,
                const CefBrowserSettings& settings,
                CefRefPtr[CefDictionaryValue] extra_info,
                CefRefPtr[CefRequestContext] request_context,
                CefRefPtr[CefBrowserViewDelegate] delegate)
        @staticmethod
        CefRefPtr[CefBrowserView] GetForBrowser(
                CefRefPtr[CefBrowser] browser)
        CefRefPtr[CefBrowser] GetBrowser()
        void SetPreferAccelerators(cpp_bool prefer_accelerators)
        cef_runtime_style_t GetRuntimeStyle()

cdef extern from "include/views/cef_browser_view_delegate.h":
    cdef cppclass CefBrowserViewDelegate:
        pass
