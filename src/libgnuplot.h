/* GNUPLOT - libgnuplot.h */

/*
 * Library interface for gnuplot
 * Allows gnuplot to be used as a library instead of a standalone program
 */

#ifndef LIBGNUPLOT_H
#define LIBGNUPLOT_H

/* DLL export/import declarations for Windows */
#if defined(_WIN32) || defined(__CYGWIN__)
  #ifdef BUILDING_GNUPLOT_DLL
    #define GNUPLOT_API __declspec(dllexport)
  #else
    #define GNUPLOT_API __declspec(dllimport)
  #endif
#else
  #define GNUPLOT_API
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* Initialize gnuplot library
 * Must be called before any other library functions
 * Returns 0 on success, non-zero on error
 */
GNUPLOT_API int gnuplot_init(void);

/* Execute a gnuplot command string
 * Example: gnuplot_cmd("plot sin(x)")
 * Returns 0 on success, non-zero on error
 */
GNUPLOT_API int gnuplot_cmd(const char *command);

/* Execute multiple gnuplot commands separated by newlines or semicolons
 * Example: gnuplot_cmd("set terminal png; set output 'plot.png'; plot sin(x)")
 */
GNUPLOT_API int gnuplot_cmd_multi(const char *commands);

/* Reset gnuplot to initial state */
GNUPLOT_API void gnuplot_reset(void);

/* Cleanup and shutdown gnuplot library
 * Should be called before program exit
 */
GNUPLOT_API void gnuplot_close(void);

/* Get gnuplot version string */
GNUPLOT_API const char* gnuplot_get_version(void);

/* Check if gnuplot is initialized */
GNUPLOT_API int gnuplot_is_initialized(void);

/* Set datablock content directly (bypasses heredoc syntax)
 * name: datablock name (e.g., "$DATA")
 * data: newline-separated data lines
 * Returns 0 on success, non-zero on error
 * Example: gnuplot_set_datablock("$DATA", "1 2\n2 4\n3 6")
 */
GNUPLOT_API int gnuplot_set_datablock(const char *name, const char *data);

/* Save PBM bitmap RGB data to a global buffer before it gets freed
 * This is called automatically by the PBM terminal text() function
 * ONLY works with 'set terminal pbm color' - returns NULL for other terminals
 * Use with 'set terminal pbm color' followed by plot commands
 * Returns pointer to RGB data buffer, or NULL on error
 * The buffer contains width, height, and raw RGB bytes
 */
GNUPLOT_API void* gnuplot_save_bitmap_data(void);

/* Get the saved PBM bitmap RGB data (already saved by terminal)
 * Returns pointer to the saved RGB data buffer, or NULL if not available
 * The buffer contains width, height (as two unsigned ints), followed by raw RGB bytes
 * ONLY works if PBM terminal was used
 */
GNUPLOT_API void* gnuplot_get_saved_pbm_rgb_data(void);

/* Free the saved PBM bitmap data buffer */
GNUPLOT_API void gnuplot_free_saved_pbm_bitmap(void);

/* luacmd terminal command capture functions */
typedef struct {
    int type;          /* Command type (move, vector, text, etc.) */
    int x1, y1;       /* Primary coordinates */
    int x2, y2;       /* Secondary coordinates (for vector start point) */
    char *text;       /* Text string (for text commands) */
    unsigned int color; /* RGB color value */
    double value;     /* Generic value (linewidth, angle, etc.) */
} luacmd_command_t;

/* Add a drawing command to the buffer */
GNUPLOT_API void luacmd_add_command(int type, int x1, int y1, int x2, int y2,
                      const char *text, unsigned int color, double value);

/* Clear all commands */
GNUPLOT_API void luacmd_clear_commands(void);

/* Mark beginning/end of plot */
GNUPLOT_API void luacmd_begin_plot(int width, int height);
GNUPLOT_API void luacmd_end_plot(void);

/* Get all commands (returns array and count) */
GNUPLOT_API luacmd_command_t* luacmd_get_commands(int *count, int *width, int *height);

/* Free commands array returned by luacmd_get_commands */
GNUPLOT_API void luacmd_free_commands(luacmd_command_t *commands);

#ifdef __cplusplus
}
#endif

#endif /* LIBGNUPLOT_H */
