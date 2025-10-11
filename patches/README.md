# Gnuplot Source Patches

This directory contains patch files that need to be applied to the gnuplot source code.

## term.h.patch

This patch adds the luacmd terminal to gnuplot's terminal list by including `wxlua.trm` in `src/term.h`.

The build script will automatically:
1. Copy `terminal/wxlua.trm` to `gnuplot-source/term/`
2. Apply this patch to `gnuplot-source/src/term.h`
3. Copy `src/libgnuplot.{c,h}` to `gnuplot-source/src/`

This allows the gnuplot source directory to be deleted and re-cloned cleanly without losing our modifications.
