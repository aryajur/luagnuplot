#!/bin/bash
# Build script for libgnuplot and Lua bindings
# Works on Linux and Windows (MinGW/MSYS2)
# All intermediate files are built in build/ directory

set -e  # Exit on error

# Pinned gnuplot commit hash for reproducible builds
# To update: Get latest hash with: git ls-remote https://github.com/gnuplot/gnuplot.git HEAD
# Test the new version, then update this hash
GNUPLOT_COMMIT="fbeb88eadedf927a4d778b41dd118e373f33eacb"

echo "=== Building libgnuplot and Lua bindings ==="
echo "Gnuplot commit: ${GNUPLOT_COMMIT:0:12}"
echo ""

# Detect platform
case "$OSTYPE" in
    msys*|mingw*|cygwin*)
        PLATFORM="windows"
        LIB_EXT="dll"
        echo "Platform: Windows (MinGW/MSYS2)"
        ;;
    *)
        PLATFORM="unix"
        LIB_EXT="so"
        echo "Platform: Unix/Linux"
        ;;
esac
echo ""

# Set platform-appropriate null device
if [ "$PLATFORM" = "windows" ]; then
    NULL_DEVICE="NUL"
else
    NULL_DEVICE="/dev/null"
fi

# Check for required tools
command -v gcc >/dev/null 2>&1 || { echo "Error: gcc is required but not installed."; exit 1; }
command -v git >/dev/null 2>&1 || { echo "Error: git is required but not installed."; exit 1; }

# Create build directory early for library checks
BUILD_DIR="build"
mkdir -p "$BUILD_DIR"

# Check for readline library (required for terminal input)
TEMP_TEST="$BUILD_DIR/test_lib_$$"
TEMP_ERR="$BUILD_DIR/test_err_$$"
if ! gcc -lreadline -x c -o "$TEMP_TEST" - <<< "int main(){return 0;}" 2>"$TEMP_ERR"; then
    rm -f "$TEMP_TEST" "$TEMP_TEST.exe" "$TEMP_ERR" 2>/dev/null
    echo "Warning: readline library not found"
    echo "Terminal input functions will be unavailable"
    if [ "$PLATFORM" = "windows" ]; then
        echo "To install on MinGW:"
        echo "  pacman -S mingw-w64-i686-readline    # 32-bit"
        echo "  pacman -S mingw-w64-x86_64-readline  # 64-bit"
    else
        echo "To install on Linux:"
        echo "  sudo apt-get install libreadline-dev  # Ubuntu/Debian"
        echo "  sudo dnf install readline-devel       # Fedora/RHEL"
    fi
    echo ""
    HAVE_READLINE=0
else
    echo "✓ readline library found"
    HAVE_READLINE=1
    rm -f "$TEMP_TEST" "$TEMP_TEST.exe" "$TEMP_ERR" 2>/dev/null
fi

# Check for zlib library (required for PNG terminal support)
if ! gcc -lz -x c -o "$TEMP_TEST" - <<< "int main(){return 0;}" 2>"$TEMP_ERR"; then
    rm -f "$TEMP_TEST" "$TEMP_TEST.exe" "$TEMP_ERR" 2>/dev/null
    echo "Warning: zlib library not found"
    echo "PNG terminal support will be disabled"
    if [ "$PLATFORM" = "windows" ]; then
        echo "To install on MinGW:"
        echo "  pacman -S mingw-w64-i686-zlib    # 32-bit"
        echo "  pacman -S mingw-w64-x86_64-zlib  # 64-bit"
    else
        echo "To install on Linux:"
        echo "  sudo apt-get install zlib1g-dev  # Ubuntu/Debian"
        echo "  sudo dnf install zlib-devel      # Fedora/RHEL"
    fi
    echo ""
    HAVE_ZLIB=0
else
    echo "✓ zlib library found"
    HAVE_ZLIB=1
    rm -f "$TEMP_TEST" "$TEMP_TEST.exe" "$TEMP_ERR" 2>/dev/null
fi

# Check for libgd library (required for PNG/GIF/JPEG terminals)
if ! gcc -lgd -x c -o "$TEMP_TEST" - <<< "int main(){return 0;}" 2>"$TEMP_ERR"; then
    rm -f "$TEMP_TEST" "$TEMP_TEST.exe" "$TEMP_ERR" 2>/dev/null
    echo "Warning: libgd library not found"
    echo "PNG, GIF, and JPEG terminals will be disabled"
    if [ "$PLATFORM" = "windows" ]; then
        echo "To install on MinGW:"
        echo "  pacman -S mingw-w64-i686-gd    # 32-bit"
        echo "  pacman -S mingw-w64-x86_64-gd  # 64-bit"
    else
        echo "To install on Linux:"
        echo "  sudo apt-get install libgd-dev  # Ubuntu/Debian"
        echo "  sudo dnf install gd-devel       # Fedora/RHEL"
    fi
    echo ""
    HAVE_LIBGD=0
else
    echo "✓ libgd library found (enables PNG, GIF, JPEG terminals)"
    HAVE_LIBGD=1
    rm -f "$TEMP_TEST" "$TEMP_TEST.exe" "$TEMP_ERR" 2>/dev/null
fi

# Create subdirectories for Windows files
if [ "$OSTYPE" = "msys" ] || [ "$OSTYPE" = "mingw"* ] || [ "$OSTYPE" = "cygwin" ]; then
    mkdir -p "$BUILD_DIR/win"
fi

# Step 1: Clone or update gnuplot source into build directory
GNUPLOT_SRC_DIR="$BUILD_DIR/gnuplot-source"

# Check if directory exists and is at the correct commit
if [ -d "$GNUPLOT_SRC_DIR" ]; then
    if [ -d "$GNUPLOT_SRC_DIR/.git" ] && [ -f "$GNUPLOT_SRC_DIR/src/gnuplot.h" ]; then
        # Check if we're at the correct commit
        cd "$GNUPLOT_SRC_DIR"
        CURRENT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
        cd - > /dev/null

        if [ "$CURRENT_COMMIT" = "$GNUPLOT_COMMIT" ]; then
            echo "Step 1: Gnuplot source already present at correct commit"
        else
            echo "Step 1: Gnuplot source at different commit, updating..."
            cd "$GNUPLOT_SRC_DIR"
            git fetch origin "$GNUPLOT_COMMIT" && git checkout "$GNUPLOT_COMMIT"
            cd - > /dev/null
            echo "✓ Updated to commit ${GNUPLOT_COMMIT:0:12}"
        fi
    else
        echo "Step 1: Detected incomplete gnuplot clone, re-cloning..."
        rm -rf "$GNUPLOT_SRC_DIR"

        # Clone and checkout specific commit
        MAX_RETRIES=3
        RETRY_COUNT=0

        while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
            if git clone https://github.com/gnuplot/gnuplot.git "$GNUPLOT_SRC_DIR" && \
               cd "$GNUPLOT_SRC_DIR" && \
               git checkout "$GNUPLOT_COMMIT" && \
               cd - > /dev/null; then
                echo "✓ Gnuplot source cloned at commit ${GNUPLOT_COMMIT:0:12}"
                break
            else
                RETRY_COUNT=$((RETRY_COUNT + 1))
                if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                    echo "⚠ Clone failed, retrying ($RETRY_COUNT/$MAX_RETRIES)..."
                    rm -rf "$GNUPLOT_SRC_DIR"
                    sleep 2
                else
                    echo "✗ Failed to clone gnuplot source after $MAX_RETRIES attempts"
                    echo ""
                    echo "Please manually clone the gnuplot repository:"
                    echo "  git clone https://github.com/gnuplot/gnuplot.git $GNUPLOT_SRC_DIR"
                    echo "  cd $GNUPLOT_SRC_DIR && git checkout $GNUPLOT_COMMIT"
                    echo ""
                    exit 1
                fi
            fi
        done
    fi
else
    echo "Step 1: Cloning gnuplot source to $BUILD_DIR/..."

    # Clone and checkout specific commit
    MAX_RETRIES=3
    RETRY_COUNT=0

    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if git clone https://github.com/gnuplot/gnuplot.git "$GNUPLOT_SRC_DIR" && \
           cd "$GNUPLOT_SRC_DIR" && \
           git checkout "$GNUPLOT_COMMIT" && \
           cd - > /dev/null; then
            echo "✓ Gnuplot source cloned at commit ${GNUPLOT_COMMIT:0:12}"
            break
        else
            RETRY_COUNT=$((RETRY_COUNT + 1))
            if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                echo "⚠ Clone failed, retrying ($RETRY_COUNT/$MAX_RETRIES)..."
                rm -rf "$GNUPLOT_SRC_DIR"
                sleep 2
            else
                echo "✗ Failed to clone gnuplot source after $MAX_RETRIES attempts"
                echo ""
                echo "Please manually clone the gnuplot repository:"
                echo "  git clone https://github.com/gnuplot/gnuplot.git $GNUPLOT_SRC_DIR"
                echo "  cd $GNUPLOT_SRC_DIR && git checkout $GNUPLOT_COMMIT"
                echo ""
                exit 1
            fi
        fi
    done
fi
echo ""

# Step 2: Apply our modifications to gnuplot source
echo "Step 2: Applying custom modifications..."

# Copy luacmd terminal
echo "  Copying luacmd terminal..."
cp terminal/luacmd.trm "$GNUPLOT_SRC_DIR/term/"

# Copy library wrapper files
echo "  Copying library wrapper files..."
cp src/libgnuplot.h src/libgnuplot.c "$GNUPLOT_SRC_DIR/src/"

# Note: We no longer copy winstubs files - not needed with correct build flags

# Apply term.h patch to include luacmd terminal and disable post.trm
echo "  Patching term.h..."
if ! grep -q "GNUPLOTMOD_PATCHED" "$GNUPLOT_SRC_DIR/src/term.h"; then
    # Add luacmd terminal after dumb.trm
    sed -i '/dumb\.trm/a\
\
/* Lua command capture terminal - GNUPLOTMOD_PATCHED */\
#include "luacmd.trm"' "$GNUPLOT_SRC_DIR/src/term.h"

    # Disable PostScript terminal (post.trm) - requires libgd or cairo
    sed -i 's|^#  include "post\.trm"|/* #  include "post.trm" */ /* Disabled - requires HAVE_GD_PNG or HAVE_CAIROPDF */|' "$GNUPLOT_SRC_DIR/src/term.h"
    sed -i 's|^#include "post\.trm"|/* #include "post.trm" */ /* Disabled - requires HAVE_GD_PNG or HAVE_CAIROPDF */|' "$GNUPLOT_SRC_DIR/src/term.h"

    # Disable pslatex terminal (pslatex.trm) - depends on post.trm
    sed -i 's|^#include "pslatex\.trm"|/* #include "pslatex.trm" */ /* Disabled - depends on post.trm */|' "$GNUPLOT_SRC_DIR/src/term.h"

    # Disable tkcanvas terminal (tkcanvas.trm) - uses ftruncate which is not available on Windows
    sed -i 's|^#include "tkcanvas\.trm"|/* #include "tkcanvas.trm" */ /* Disabled - uses ftruncate (POSIX only) */|' "$GNUPLOT_SRC_DIR/src/term.h"

    echo "  ✓ term.h patched (added luacmd terminal, disabled post.trm, pslatex.trm, tkcanvas.trm)"
else
    echo "  ✓ term.h already patched"
fi

echo "✓ Modifications applied"
echo ""

# Check if build directory has existing artifacts
if [ "$(ls -A $BUILD_DIR/*.o 2>/dev/null)" ]; then
    echo "Using existing build directory: $BUILD_DIR/ (reusing object files if unchanged)"
else
    echo "Using build directory: $BUILD_DIR/"
fi
echo ""

# Create config directory
CONFIG_DIR="$BUILD_DIR/config"
mkdir -p "$CONFIG_DIR"

# Step 3: Create config.h
echo "Step 3: Creating config.h..."

# Platform-specific defines
if [ "$PLATFORM" = "windows" ]; then
    # Note: _WIN32 is automatically defined by MinGW compiler, no need to define it in config.h
    WIN32_DEFINE="/* _WIN32 automatically defined by compiler */"
    STRCASECMP_DEFINE1="#define HAVE_STRICMP 1"
    STRCASECMP_DEFINE2="#define HAVE_STRNICMP 1"
else
    WIN32_DEFINE="/* Not Windows */"
    STRCASECMP_DEFINE1="#define HAVE_STRCASECMP 1"
    STRCASECMP_DEFINE2="#define HAVE_STRNCASECMP 1"
fi

# readline-dependent defines
if [ $HAVE_READLINE -eq 1 ]; then
    HAVE_LIBREADLINE_DEFINE="#define HAVE_LIBREADLINE 1"
    GNUPLOT_HISTORY_DEFINE="#define GNUPLOT_HISTORY 1"
else
    HAVE_LIBREADLINE_DEFINE="/* #define HAVE_LIBREADLINE 1 (readline not available) */"
    GNUPLOT_HISTORY_DEFINE="/* #define GNUPLOT_HISTORY 1 (readline not available) */"
fi

# zlib-dependent defines
if [ $HAVE_ZLIB -eq 1 ]; then
    HAVE_DEFLATE_ENCODER_DEFINE="#define HAVE_DEFLATE_ENCODER 1"
else
    HAVE_DEFLATE_ENCODER_DEFINE="/* #define HAVE_DEFLATE_ENCODER 1 (zlib not available) */"
fi

# libgd-dependent defines
if [ $HAVE_LIBGD -eq 1 ]; then
    HAVE_GD_PNG_DEFINE="#define HAVE_GD_PNG 1"
    HAVE_GD_JPEG_DEFINE="#define HAVE_GD_JPEG 1"
    HAVE_GD_GIF_DEFINE="#define HAVE_GD_GIF 1"
else
    HAVE_GD_PNG_DEFINE="/* #define HAVE_GD_PNG 1 (libgd not available) */"
    HAVE_GD_JPEG_DEFINE="/* #define HAVE_GD_JPEG 1 (libgd not available) */"
    HAVE_GD_GIF_DEFINE="/* #define HAVE_GD_GIF 1 (libgd not available) */"
fi

cat > "$CONFIG_DIR/config.h" << 'EOF'
/* config.h for simplified build - generated by build.sh */

#define PACKAGE_NAME "gnuplot"
#define PACKAGE_VERSION "5.4"
#define PACKAGE_STRING "gnuplot 5.4"
#define PACKAGE_TARNAME "gnuplot"
#define PACKAGE_BUGREPORT "gnuplot-bugs@lists.sourceforge.net"

/* Standard C headers */
#define STDC_HEADERS 1
#define HAVE_STDLIB_H 1
#define HAVE_STRING_H 1
#define HAVE_STRINGS_H 1
#define HAVE_MATH_H 1
#define HAVE_FLOAT_H 1
#define HAVE_LIMITS_H 1
#define HAVE_STDINT_H 1
#define HAVE_INTTYPES_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_TIME_H 1
#define HAVE_ERRNO_H 1
#define HAVE_LOCALE_H 1
#define HAVE_STDDEF_H 1

/* String functions */
#define HAVE_STRCHR 1
#define HAVE_STRRCHR 1
#define HAVE_STRSTR 1
#define HAVE_STRCSPN 1
#define HAVE_MEMCPY 1
#define HAVE_MEMMOVE 1
#define HAVE_MEMSET 1

/* Platform-specific string functions - will be replaced */
STRCASECMP_DEFINES

/* Readline and history support */
HAVE_LIBREADLINE_DEFINE
GNUPLOT_HISTORY_DEFINE

/* Math library */
#define HAVE_LIBM 1
#define HAVE_ERF 1
#define HAVE_ERFC 1
#define HAVE_LGAMMA 1
#define HAVE_GAMMA 1
#define HAVE_ATAN2 1
#define HAVE_ACOS 1
#define HAVE_ASIN 1
#define HAVE_COS 1
#define HAVE_SIN 1
#define HAVE_TAN 1
#define HAVE_LOG 1
#define HAVE_LOG10 1
#ifndef POW
#define HAVE_POW 1
#endif
#ifndef SQRT
#define HAVE_SQRT 1
#endif
#define HAVE_FLOOR 1
#define HAVE_CEIL 1
#define HAVE_EXP 1
#define HAVE_SINH 1
#define HAVE_COSH 1
#define HAVE_TANH 1
#define HAVE_ASINH 1
#define HAVE_ACOSH 1
#define HAVE_ATANH 1

/* Complex math */
#define HAVE_COMPLEX_H 1
#define HAVE_CABS 1
#define HAVE_CEXP 1
#define HAVE_CLOG 1
#define HAVE_CSQRT 1

/* Other functions */
#define HAVE_STRERROR 1
#define HAVE_GETCWD 1
#define HAVE_SLEEP 1
#define HAVE_VFPRINTF 1
#define HAVE_DOPRNT 1
#define HAVE_SNPRINTF 1
#define HAVE_VSNPRINTF 1
#define HAVE_SETLOCALE 1
#define HAVE_ATEXIT 1

/* Time functions */
#define HAVE_TIME_T_IN_TIME_H 1
#define HAVE_MKTIME 1
#define HAVE_STRFTIME 1

/* setjmp/longjmp - use regular setjmp on Windows */
/* #define HAVE_SIGSETJMP 1 */

/* I/O functions */
#define HAVE_FSEEKO 1
#define HAVE_OFF_T 1

/* Misc defines */
#define HAVE_STRINGIZE 1
#define PROTOTYPES 1
#define NO_GIH 1
HAVE_DEFLATE_ENCODER_DEFINE

/* Image terminal support (libgd) */
HAVE_GD_PNG_DEFINE
HAVE_GD_JPEG_DEFINE
HAVE_GD_GIF_DEFINE

/* Bool support */
#define HAVE_STDBOOL_H 1
#define HAVE__BOOL 1

/* Windows specific - will be replaced */
WIN32_DEFINE

/* Gnuplot features */
#define USE_MOUSE 1
#define THIN_PLATE_SPLINES_GRID 1

/* Terminal settings */
#define DEFAULT_TERM "dumb"
#define DEFLIBDIR "."
#define X11_DRIVER_DIR "/usr/libexec/gnuplot/5.4"

/* Size types */
#define SIZEOF_INT 4
#define SIZEOF_LONG 4
#define SIZEOF_FLOAT 4
#define SIZEOF_DOUBLE 8

/* Disable features we don't need */
/* Note: Don't define X11 to avoid conflicts with Windows headers */
/* #define X11 0 */
#define HAVE_LIBX11 0

EOF

# Replace platform-specific placeholders
# Use printf with sed to handle newlines properly
sed -i "s|STRCASECMP_DEFINES|$STRCASECMP_DEFINE1\n$STRCASECMP_DEFINE2|" "$CONFIG_DIR/config.h"
sed -i "s|WIN32_DEFINE|$WIN32_DEFINE|" "$CONFIG_DIR/config.h"
sed -i "s|HAVE_LIBREADLINE_DEFINE|$HAVE_LIBREADLINE_DEFINE|" "$CONFIG_DIR/config.h"
sed -i "s|GNUPLOT_HISTORY_DEFINE|$GNUPLOT_HISTORY_DEFINE|" "$CONFIG_DIR/config.h"
sed -i "s|HAVE_DEFLATE_ENCODER_DEFINE|$HAVE_DEFLATE_ENCODER_DEFINE|" "$CONFIG_DIR/config.h"
sed -i "s|HAVE_GD_PNG_DEFINE|$HAVE_GD_PNG_DEFINE|" "$CONFIG_DIR/config.h"
sed -i "s|HAVE_GD_JPEG_DEFINE|$HAVE_GD_JPEG_DEFINE|" "$CONFIG_DIR/config.h"
sed -i "s|HAVE_GD_GIF_DEFINE|$HAVE_GD_GIF_DEFINE|" "$CONFIG_DIR/config.h"

echo "✓ config.h created in $CONFIG_DIR/"
echo ""

# Step 4: Compile gnuplot source files
echo "Step 4: Compiling gnuplot core files..."

GNUPLOT_SRC="$GNUPLOT_SRC_DIR/src"
INCLUDES="-I$GNUPLOT_SRC -I$CONFIG_DIR -I$GNUPLOT_SRC_DIR/term"

# Platform-specific CFLAGS
if [ "$PLATFORM" = "windows" ]; then
    # Windows: Use WGP_CONSOLE mode with GDI+ backend
    # WGP_CONSOLE disables GUI text window (like gnuplot.exe console mode)
    # HAVE_GDIPLUS and HAVE_D2D enable Windows terminal backends
    CFLAGS="-O2 -std=c99 -DHAVE_CONFIG_H -DNO_GIH -DWGP_CONSOLE -DPIPES -DHAVE_GDIPLUS -DHAVE_D2D -DUSE_WATCHPOINTS"
    CXXFLAGS="-O2 -DHAVE_CONFIG_H -DNO_GIH -DWGP_CONSOLE -DPIPES -DHAVE_GDIPLUS -DHAVE_D2D -DUSE_WATCHPOINTS"
else
    # Unix/Linux - include USE_WATCHPOINTS for bisect_hit function
    CFLAGS="-O2 -std=c99 -D_GNU_SOURCE -DHAVE_CONFIG_H -DNO_GIH -fPIC -DUSE_WATCHPOINTS"
    CXXFLAGS="-O2 -D_GNU_SOURCE -DHAVE_CONFIG_H -DNO_GIH -fPIC -DUSE_WATCHPOINTS"
fi

# Find all .c files to compile
echo "Finding all .c files to compile..."
cd "$GNUPLOT_SRC"
SOURCES=()
for cfile in *.c; do
    # Skip main entry points, platform-specific files, and watch.c (added separately for both platforms)
    if [[ "$cfile" != "bf_test.c" && "$cfile" != "gplt_x11.c" && "$cfile" != "libgnuplot.c" && "$cfile" != "watch.c" ]]; then
        SOURCES+=("$cfile")
    fi
done

# Add watch.c for bisect_hit function (needed on both Windows and Linux with USE_WATCHPOINTS)
SOURCES+=("watch.c")

# On Windows, add required Windows support files
if [ "$PLATFORM" = "windows" ]; then
    # Add Windows support files matching CONSOLE variant from official MinGW Makefile
    # WINOBJS = winmain, wgnuplib, wgraph, wprinter, wpause, wgdiplus, wd2d
    # WINOBJS_WGNUPLOT (NOT included) = wtext, screenbuf, wmenu, wredirect
    # WGP_CONSOLE flag disables GUI text window code paths via conditional compilation
    SOURCES+=("win/winmain.c" "win/wgnuplib.c" "win/wgraph.c" "win/wprinter.c" "win/wpause.c")
    # C++ files for GDI+ and Direct2D (for terminal drivers)
    SOURCES+=("win/wgdiplus.cpp" "win/wd2d.cpp")
fi

cd - > /dev/null

echo "Found ${#SOURCES[@]} source files to compile"
echo ""

# Compile each source file into build directory
OBJECTS=""
SUCCESS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

# Platform-specific files to skip
SKIP_FILES=()
SKIP_FILES+=("vms.c")  # VMS-specific (skip on all platforms)

for src in "${SOURCES[@]}"; do
    srcfile="$GNUPLOT_SRC/$src"
    # Preserve directory structure for object files
    # Remove .c or .cpp extension and add .o
    objfile="$BUILD_DIR/${src%.c*}.o"
    # Create directory for object file if needed
    mkdir -p "$(dirname "$objfile")"

    # Check if file should be skipped
    SHOULD_SKIP=0
    for skip in "${SKIP_FILES[@]}"; do
        if [ "$src" = "$skip" ]; then
            SHOULD_SKIP=1
            break
        fi
    done

    if [ $SHOULD_SKIP -eq 1 ]; then
        echo "  Skipping $src (platform-specific)"
        SKIP_COUNT=$((SKIP_COUNT + 1))
        continue
    fi

    if [ -f "$srcfile" ]; then
        echo -n "  Compiling $src... "
        # Use g++ for C++ files, gcc for C files
        if [[ "$src" == *.cpp ]]; then
            COMPILER="g++"
            COMPILER_FLAGS="$CXXFLAGS"
        else
            COMPILER="gcc"
            COMPILER_FLAGS="$CFLAGS"
        fi
        if $COMPILER $COMPILER_FLAGS $INCLUDES -c "$srcfile" -o "$objfile" 2>"$BUILD_DIR/compile_errors.tmp"; then
            echo "✓"
            OBJECTS="$OBJECTS $objfile"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            echo "⚠ (error)"
            cat "$BUILD_DIR/compile_errors.tmp" | head -3
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    fi
done

echo ""
echo "Compiled: $SUCCESS_COUNT files, Skipped: $SKIP_COUNT files, Failed: $FAIL_COUNT files"
echo ""

if [ $SUCCESS_COUNT -eq 0 ]; then
    echo "Error: No files compiled successfully!"
    exit 1
fi

# Check if term.o was created (critical file)
if [ ! -f "$BUILD_DIR/term.o" ]; then
    echo "⚠ Warning: term.c failed to compile - this will cause linking errors"
    echo "  This is usually due to terminal driver conflicts on Windows"
    if [ $FAIL_COUNT -gt 0 ]; then
        echo "  Failed files need to be addressed for successful linking"
    fi
    echo ""
fi

# Step 5: Compile library wrapper
echo "Step 5: Compiling libgnuplot wrapper..."

# Add BUILDING_GNUPLOT_DLL for Windows DLL export
if gcc $CFLAGS $INCLUDES -DBUILDING_GNUPLOT_DLL -c "$GNUPLOT_SRC/libgnuplot.c" -o "$BUILD_DIR/libgnuplot_wrapper.o" 2>&1 | tee "$BUILD_DIR/compile_lib.log"; then
    echo "✓ Library wrapper compiled"
else
    echo "✗ Failed to compile library wrapper"
    echo "See $BUILD_DIR/compile_lib.log for details"
    exit 1
fi
echo ""

# Step 6: Link library
echo "Step 6: Creating libgnuplot.$LIB_EXT..."

if [ "$PLATFORM" = "windows" ]; then
    # Windows/MinGW - allow undefined symbols like Linux does
    EXTRA_LIBS=""
    if [ $HAVE_ZLIB -eq 1 ]; then
        EXTRA_LIBS="$EXTRA_LIBS -lz"
    fi
    if [ $HAVE_LIBGD -eq 1 ]; then
        EXTRA_LIBS="$EXTRA_LIBS -lgd"
    fi
    if [ $HAVE_READLINE -eq 1 ]; then
        EXTRA_LIBS="$EXTRA_LIBS -lreadline"
    fi
    # Add Windows system libraries (matching official gnuplot MinGW build)
    EXTRA_LIBS="$EXTRA_LIBS -lkernel32 -lgdi32 -lwinspool -lcomdlg32 -lcomctl32 -ladvapi32 -lshell32"
    EXTRA_LIBS="$EXTRA_LIBS -lmsimg32 -lgdiplus -lshlwapi -ld2d1 -ldwrite -lole32 -lhtmlhelp"
    # Use g++ for linking since we have C++ code
    g++ -shared -Wl,--allow-shlib-undefined -o libgnuplot.$LIB_EXT "$BUILD_DIR/libgnuplot_wrapper.o" $OBJECTS -lm $EXTRA_LIBS 2>&1 | tee "$BUILD_DIR/link.log"
    LINK_STATUS=$?
else
    # Unix/Linux - link with common libraries
    EXTRA_LIBS="-lm"
    if [ $HAVE_LIBGD -eq 1 ]; then
        EXTRA_LIBS="$EXTRA_LIBS -lgd"
    fi
    if [ $HAVE_READLINE -eq 1 ]; then
        EXTRA_LIBS="$EXTRA_LIBS -lreadline"
    fi

    gcc -shared -o libgnuplot.$LIB_EXT "$BUILD_DIR/libgnuplot_wrapper.o" $OBJECTS $EXTRA_LIBS 2>&1 | tee "$BUILD_DIR/link.log"
    LINK_STATUS=$?
fi

if [ -f libgnuplot.$LIB_EXT ]; then
    echo "✓ libgnuplot.$LIB_EXT created"
else
    echo "✗ Failed to create library"
    echo "See $BUILD_DIR/link.log for details"
    exit 1
fi
echo ""

# Step 7: Build Lua module
echo "Step 7: Building Lua module..."

# Detect Lua
LUA_INCDIR=""
LUA_LIBDIR=""
LUA_LIB=""

# Check build/inc and build/lib directories first
if [ -d "$BUILD_DIR/inc" ] && [ -f "$BUILD_DIR/inc/lua.h" ]; then
    LUA_INCDIR="$BUILD_DIR/inc"
    echo "Found Lua headers in $BUILD_DIR/inc"

    if [ -d "$BUILD_DIR/lib" ]; then
        LUA_LIBDIR="$BUILD_DIR/lib"
        if [ -f "$BUILD_DIR/lib/lua53.dll" ] || [ -f "$BUILD_DIR/lib/liblua53.a" ] || [ -f "$BUILD_DIR/lib/liblua5.3.a" ]; then
            LUA_LIB="lua53"
        elif [ -f "$BUILD_DIR/lib/lua54.dll" ] || [ -f "$BUILD_DIR/lib/liblua54.a" ] || [ -f "$BUILD_DIR/lib/liblua5.4.a" ]; then
            LUA_LIB="lua54"
        elif [ -f "$BUILD_DIR/lib/lua52.dll" ] || [ -f "$BUILD_DIR/lib/liblua52.a" ] || [ -f "$BUILD_DIR/lib/liblua5.2.a" ]; then
            LUA_LIB="lua52"
        fi
        if [ -n "$LUA_LIB" ]; then
            echo "Found Lua library in $BUILD_DIR/lib"
        fi
    fi
fi

# Try system paths if not found locally
if [ -z "$LUA_INCDIR" ]; then
    for ver in 5.4 5.3 5.2 5.1; do
        if [ -f "/usr/include/lua$ver/lua.h" ]; then
            LUA_INCDIR="/usr/include/lua$ver"
            LUA_LIB="lua$ver"
            echo "Found system Lua $ver"
            break
        fi
    done
fi

if [ -z "$LUA_INCDIR" ]; then
    echo "Warning: Lua headers not found"
    echo ""

    # Create directories and provide instructions
    mkdir -p "$BUILD_DIR/inc"
    mkdir -p "$BUILD_DIR/lib"

    echo "Created directories for Lua development files:"
    echo "  $BUILD_DIR/inc/  - for Lua header files"
    echo "  $BUILD_DIR/lib/  - for Lua library files"
    echo ""
    echo "Please add Lua development files to continue:"
    echo ""
    if [ "$PLATFORM" = "windows" ]; then
        echo "For Windows/MinGW:"
        echo "  1. Copy lua.h, lauxlib.h, lualib.h to $BUILD_DIR/inc/"
        echo "  2. Copy lua53.dll (or lua54.dll) to $BUILD_DIR/lib/"
        echo "  3. Copy corresponding .a library files to $BUILD_DIR/lib/"
    else
        echo "Option 1 - Use system Lua (recommended for Linux):"
        echo "  In another terminal, run:"
        echo "    sudo apt-get install liblua5.3-dev  # Ubuntu/Debian"
        echo "    sudo dnf install lua-devel           # Fedora/RHEL"
        echo ""
        echo "Option 2 - Manual installation:"
        echo "  1. Copy lua.h, lauxlib.h, lualib.h to $BUILD_DIR/inc/"
        echo "  2. Copy liblua5.3.a (or similar) to $BUILD_DIR/lib/"
    fi
    echo ""
    echo "Press Enter when ready to continue (or Ctrl+C to exit)..."
    read -r

    # Re-check for Lua headers after user input
    if [ -f "$BUILD_DIR/inc/lua.h" ]; then
        LUA_INCDIR="$BUILD_DIR/inc"
        echo "✓ Found Lua headers in $BUILD_DIR/inc"

        if [ -d "$BUILD_DIR/lib" ]; then
            LUA_LIBDIR="$BUILD_DIR/lib"
            if [ -f "$BUILD_DIR/lib/lua53.dll" ] || [ -f "$BUILD_DIR/lib/liblua53.a" ] || [ -f "$BUILD_DIR/lib/liblua5.3.a" ]; then
                LUA_LIB="lua53"
            elif [ -f "$BUILD_DIR/lib/lua54.dll" ] || [ -f "$BUILD_DIR/lib/liblua54.a" ] || [ -f "$BUILD_DIR/lib/liblua5.4.a" ]; then
                LUA_LIB="lua54"
            elif [ -f "$BUILD_DIR/lib/lua52.dll" ] || [ -f "$BUILD_DIR/lib/liblua52.a" ] || [ -f "$BUILD_DIR/lib/liblua5.2.a" ]; then
                LUA_LIB="lua52"
            fi
            if [ -n "$LUA_LIB" ]; then
                echo "✓ Found Lua library in $BUILD_DIR/lib"
            fi
        fi
    else
        # Try system paths one more time
        for ver in 5.4 5.3 5.2 5.1; do
            if [ -f "/usr/include/lua$ver/lua.h" ]; then
                LUA_INCDIR="/usr/include/lua$ver"
                LUA_LIB="lua$ver"
                echo "✓ Found system Lua $ver"
                break
            fi
        done

        if [ -z "$LUA_INCDIR" ]; then
            echo "✗ Lua headers still not found. Skipping Lua module build."
            echo ""
        fi
    fi
fi

# Build Lua module if we have the headers (either from initial check or user-provided)
if [ -n "$LUA_INCDIR" ]; then
    echo "Using Lua from $LUA_INCDIR"

    LUA_LDFLAGS=""
    if [ -n "$LUA_LIBDIR" ]; then
        LUA_LDFLAGS="-L$LUA_LIBDIR"
    fi
    if [ -n "$LUA_LIB" ]; then
        LUA_LDFLAGS="$LUA_LDFLAGS -l$LUA_LIB"
    fi

    # Build Lua module
    if gcc -shared -o gnuplot.$LIB_EXT src/lua_gnuplot.c \
        -I"$LUA_INCDIR" \
        -I"$GNUPLOT_SRC_DIR/src" \
        -I. \
        -L. -lgnuplot \
        $LUA_LDFLAGS \
        -lm 2>"$BUILD_DIR/lua_build.log"; then
        echo "✓ gnuplot.$LIB_EXT (Lua module) created"
    elif gcc -shared -o gnuplot.$LIB_EXT src/lua_gnuplot.c \
        -I"$LUA_INCDIR" \
        -I"$GNUPLOT_SRC_DIR/src" \
        -I. \
        -L. -lgnuplot \
        -lm 2>&1 | tee "$BUILD_DIR/lua_build.log"; then
        echo "✓ gnuplot.$LIB_EXT (Lua module) created (without Lua linking)"
    else
        echo "⚠ Warning: Lua module build had issues (see $BUILD_DIR/lua_build.log)"
    fi
fi
echo ""

# Step 8: Copy libraries to ~/Lua
if [ -d ~/Lua ]; then
    echo "Step 8: Copying libraries to ~/Lua..."
    cp libgnuplot.$LIB_EXT ~/Lua/ 2>/dev/null && echo "  ✓ Copied libgnuplot.$LIB_EXT to ~/Lua/"
    cp gnuplot.$LIB_EXT ~/Lua/ 2>/dev/null && echo "  ✓ Copied gnuplot.$LIB_EXT to ~/Lua/"
    echo ""
fi

# Step 9: Summary
echo "=== Build Complete ==="
echo ""
echo "Created files:"
ls -lh libgnuplot.$LIB_EXT 2>/dev/null && echo "  ✓ libgnuplot.$LIB_EXT ($(du -h libgnuplot.$LIB_EXT | cut -f1))"
ls -lh gnuplot.$LIB_EXT 2>/dev/null && echo "  ✓ gnuplot.$LIB_EXT ($(du -h gnuplot.$LIB_EXT | cut -f1))"
echo ""

echo "Build artifacts:"
echo "  Intermediate files: $BUILD_DIR/ ($(du -sh $BUILD_DIR 2>/dev/null | cut -f1))"
echo "  Object files: $SUCCESS_COUNT compiled"
echo ""

if [ -f gnuplot.$LIB_EXT ]; then
    echo "To test the Lua bindings:"
    if [ "$PLATFORM" = "windows" ]; then
        echo "  set PATH=%PATH%;%CD%"
        echo "  set LUA_CPATH=./?.dll;;"
    else
        echo "  export LD_LIBRARY_PATH=.:\$LD_LIBRARY_PATH"
        echo "  export LUA_CPATH='./?.so;;'"
    fi
    echo "  lua examples.lua"
    echo ""
fi

echo "To clean all build artifacts and source:"
echo "  rm -rf $BUILD_DIR/"
echo ""

echo "Build logs saved in $BUILD_DIR/:"
echo "  - compile_lib.log"
echo "  - link.log"
echo "  - lua_build.log"
