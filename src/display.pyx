# Copyright (c) 2026 CEF Python, see the Authors file.
# All rights reserved. Licensed under BSD 3-clause license.
# Project website: https://github.com/cztomczak/cefpython

include "cefpython.pyx"

# Wrapper of CefDisplay (include/views/cef_display.h): one monitor as seen by
# Chromium. Obtain instances with the static methods or Window.GetDisplay().

cdef Display DisplayWrap(CefRefPtr[CefDisplay] cefDisplay):
    if not cefDisplay.get():
        return None
    cdef Display display = Display.__new__(Display)
    display.cefDisplay = cefDisplay
    return display

cdef class Display:
    cdef CefRefPtr[CefDisplay] cefDisplay

    @staticmethod
    def GetPrimaryDisplay():
        return DisplayWrap(CefDisplay.GetPrimaryDisplay())

    @staticmethod
    def GetDisplayNearestPoint(point, input_pixel_coords=False):
        cdef CefPoint cefPoint
        cefPoint.x = int(point[0])
        cefPoint.y = int(point[1])
        return DisplayWrap(CefDisplay.GetDisplayNearestPoint(
                cefPoint, bool(input_pixel_coords)))

    @staticmethod
    def GetDisplayMatchingBounds(bounds, input_pixel_coords=False):
        cdef CefRect cefRect = CefRect(int(bounds[0]), int(bounds[1]),
                                       int(bounds[2]), int(bounds[3]))
        return DisplayWrap(CefDisplay.GetDisplayMatchingBounds(
                cefRect, bool(input_pixel_coords)))

    @staticmethod
    def GetDisplayCount():
        return int(CefDisplay.GetDisplayCount())

    @staticmethod
    def GetAllDisplays():
        cdef vector[CefRefPtr[CefDisplay]] cefDisplays
        cdef size_t i
        CefDisplay.GetAllDisplays(cefDisplays)
        return [DisplayWrap(cefDisplays[i]) for i in range(cefDisplays.size())]

    def GetID(self):
        return int(self.cefDisplay.get().GetID())

    def GetDeviceScaleFactor(self):
        return float(self.cefDisplay.get().GetDeviceScaleFactor())

    def GetBounds(self):
        cdef CefRect r = self.cefDisplay.get().GetBounds()
        return [r.x, r.y, r.width, r.height]

    def GetWorkArea(self):
        cdef CefRect r = self.cefDisplay.get().GetWorkArea()
        return [r.x, r.y, r.width, r.height]

    def GetRotation(self):
        return int(self.cefDisplay.get().GetRotation())

    def GetLabel(self):
        """User-friendly label given by the platform, may be empty. On
        Wayland it is the wl_output description."""
        return CefToPyString(self.cefDisplay.get().GetLabel())

    @staticmethod
    def FindByOutputName(name):
        """The Display of the output called |name| (the connector name such
        as "DP-1" or "HDMI-A-1"), or None. Chromium has no output name in
        its Display, only the label; wlroots based compositors (labwc, sway,
        river, cage, wayfire) end it with the name in parentheses, e.g.
        "Dell Inc. U2720Q ABC123 (DP-1)"."""
        # "(DP-1)", or "(DP-1 via <adapter>)" for some connector types
        pattern = re.compile(r"\(%s( via [^)]*)?\)$" % re.escape(name))
        for display in Display.GetAllDisplays():
            if pattern.search(display.GetLabel()):
                return display
        return None

    def __eq__(self, other):
        return isinstance(other, Display) and self.GetID() == other.GetID()

    def __hash__(self):
        return hash(self.GetID())

    def __repr__(self):
        return "<Display id=%d bounds=%s>" % (self.GetID(), self.GetBounds())
