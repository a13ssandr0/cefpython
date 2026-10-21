# Copyright (c) 2026 CEF Python, see the Authors file.
# All rights reserved. Licensed under BSD 3-clause license.
# Project website: https://github.com/cztomczak/cefpython

from cpython.ref cimport PyObject
from cef_views cimport CefWindowDelegate, CefBrowserViewDelegate, CefDisplayObserver

cdef extern from "client_handler/views_delegate.h":

    cdef cppclass ViewsWindowDelegate(CefWindowDelegate):
        ViewsWindowDelegate(PyObject* pyDelegate)

    cdef cppclass ViewsBrowserViewDelegate(CefBrowserViewDelegate):
        ViewsBrowserViewDelegate(PyObject* pyDelegate)

    cdef cppclass ViewsDisplayObserver(CefDisplayObserver):
        ViewsDisplayObserver(PyObject* pyObserver)
