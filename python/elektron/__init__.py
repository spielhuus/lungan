"""
This is the "example" module.

The example module supplies one function, factorial().  For example,

>>> factorial(5)
120
"""

import base64
import sys, os
import tempfile
from base64 import standard_b64encode

PLOTS = []

def plots():
    global PLOTS
    results = []
    for p in PLOTS:
        results.append(f"PLOTS({p['width']},{p['height']},{base64.b64encode(p['bytes']).decode('utf-8')})")
    PLOTS = []
    print(f"\n".join(results))

def reset():
    PLOTS.clear()

from matplotlib.backends.backend_agg import FigureCanvasAgg
from io import BytesIO

class FigureCanvasPng(FigureCanvasAgg):
    def get_png_data(self):
        # Create a BytesIO buffer to hold the PNG data
        buf = BytesIO()
        self.print_png(buf)  # Render the figure as PNG into the buffer
        png_data = buf.getvalue()  # Get the PNG data from the buffer
        buf.close()
        print(png_data)
        return png_data

from matplotlib.backend_bases import _Backend
from matplotlib.backend_bases import FigureManagerBase

class FigureManagerPng(FigureManagerBase):
    pass  # If no custom management needed, this can stay simple

class _BackendPng(_Backend):
    FigureCanvas = FigureCanvasPng
    FigureManager = FigureManagerPng

from io import BytesIO
from subprocess import run

from matplotlib import interactive, is_interactive
from matplotlib._pylab_helpers import Gcf
from matplotlib.backend_bases import (_Backend, FigureManagerBase)
from matplotlib.backends.backend_agg import FigureCanvasAgg


# XXX heuristic for interactive repl
if hasattr(sys, 'ps1') or sys.flags.interactive:
    interactive(True)


class FigureManagerElektron(FigureManagerBase):

    @classmethod
    def _run(cls, *cmd):
        def f(*args, output=True, **kwargs):
            if output:
                kwargs['capture_output'] = True
                kwargs['text'] = True
            r = run(cmd + args, **kwargs)
            if output:
                return r.stdout.rstrip()
        return f

    def show(self):

        with BytesIO() as buf:
            global PLOTS
            # Get the size in inches
            fig_size_inches = self.canvas.figure.get_size_inches()
            dpi = self.canvas.figure.dpi
            fig_size_pixels = fig_size_inches * dpi
            self.canvas.figure.savefig(buf, format='png')
            PLOTS = [{ 'width': int(fig_size_pixels[0]), 'height': int(fig_size_pixels[1]), 'bytes': bytes(buf.getvalue())}]

class FigureCanvasElektron(FigureCanvasAgg):
    manager_class = FigureManagerElektron


@_Backend.export
class _BackendElektronAgg(_Backend):

    FigureCanvas = FigureCanvasElektron
    FigureManager = FigureManagerElektron

    # Noop function instead of None signals that
    # this is an "interactive" backend
    mainloop = lambda: None

    # XXX: `draw_if_interactive` isn't really intended for
    # on-shot rendering. We run the risk of being called
    # on a figure that isn't completely rendered yet, so
    # we skip draw calls for figures that we detect as
    # not being fully initialized yet. Our heuristic for
    # that is the presence of axes on the figure.
    @classmethod
    def draw_if_interactive(cls):
        manager = Gcf.get_active()
        if is_interactive() and manager.canvas.figure.get_axes():
            cls.show()

    @classmethod
    def show(cls, *args, **kwargs):
        _Backend.show(*args, **kwargs)
        Gcf.destroy_all()
