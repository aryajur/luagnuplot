/* GNUPLOT - libgnuplot.c */

/*
 * Library interface implementation for gnuplot
 */

#include "libgnuplot.h"
#include "plot.h"
#include "command.h"
#include "setshow.h"
#include "util.h"
#include "term_api.h"
#include "alloc.h"
#include "eval.h"
#include "gp_hist.h"
#include "loadpath.h"
#include "gplocale.h"
#include "misc.h"
#include "version.h"
#include "encoding.h"
#include "save.h"
#include "fit.h"
#include "gadgets.h"
#include "standard.h"
#include "datablock.h"

#include <signal.h>
#include <setjmp.h>
#include <string.h>
#include <stdlib.h>

/* Global state */
static int lib_initialized = 0;
static JMP_BUF lib_command_line_env;

/* Forward declarations */
static void init_memory_lib(void);

/* External variables and functions from gnuplot */
extern TBOOLEAN interactive;
extern TBOOLEAN noinputfiles;
extern TBOOLEAN successful_initialization;
extern char *gp_input_line;
extern size_t gp_input_line_len;
extern char *replot_line;
extern struct udvt_entry *udv_NaN;
extern struct udvt_entry **udv_user_head;

/* External functions from gnuplot internals */
extern void extend_input_line(void);
extern void extend_token_table(void);
extern struct udvt_entry *add_udv_by_name(char *);
extern struct udvt_entry *get_udv_by_name(char *);

/* Signal handler for library mode */
static RETSIGTYPE
lib_inter(int anint)
{
    (void) anint;
    (void) signal(SIGINT, (sigfunc) lib_inter);
    (void) signal(SIGFPE, SIG_DFL);

    /* In library mode, we don't jump back to command line on interrupt */
    /* Just reset and return */
    term_reset();
}

/* Initialize gnuplot library */
int gnuplot_init(void)
{
    if (lib_initialized) {
        return 0; /* Already initialized */
    }

    /* Set to non-interactive mode */
    interactive = FALSE;
    noinputfiles = FALSE;

    /* Prevent security issues during initialization */
    successful_initialization = FALSE;

    /* Initialize pre-loaded user variables */
    (void) add_udv_by_name("GNUTERM");
    (void) add_udv_by_name("I");
    (void) add_udv_by_name("Inf");
    (void) add_udv_by_name("NaN");

    init_constants();

    /* user-defined variables start immediately after NaN */
    udv_user_head = &(udv_NaN->next_udv);

    /* Initialize memory structures */
    init_memory_lib();

    /* Setup error handling */
    if (!SETJMP(lib_command_line_env, 1)) {
        interrupt_setup();

        /* Override default interrupt handler with library version */
        (void) signal(SIGINT, (sigfunc) lib_inter);

        get_user_env();
        init_loadpath();
        init_locale();

        memset(&sm_palette, 0, sizeof(sm_palette));
        init_fit();

#ifdef READLINE
        init_encoding();
#endif
        init_gadgets();

        /* Initialize terminal - use dumb terminal by default for library mode */
        /* Set GNUTERM to dumb if not already set by user */
        if (getenv("GNUTERM") == NULL) {
            static char gnuterm_env[] = "GNUTERM=dumb";
            putenv(gnuterm_env);
        }
        init_terminal();

        /* Allow pipes and system commands after initialization */
        successful_initialization = TRUE;

        /* Update GPVAL_ variables */
        update_gpval_variables(3);

        /* Execute reset to set default state */
        reset_command();

        lib_initialized = 1;
        return 0;
    } else {
        /* Initialization failed */
        lib_initialized = 0;
        return -1;
    }
}

/* Execute a gnuplot command */
int gnuplot_cmd(const char *command)
{
    if (!lib_initialized) {
        return -1; /* Not initialized */
    }

    if (command == NULL || strlen(command) == 0) {
        return -1; /* Invalid command */
    }

    /* Use gnuplot's built-in command execution */
    if (!SETJMP(lib_command_line_env, 1)) {
        do_string(command);
        return 0;
    } else {
        /* Error occurred during command execution */
        return -1;
    }
}

/* Execute multiple commands */
int gnuplot_cmd_multi(const char *commands)
{
    char *cmd_copy, *line, *saveptr;
    int result = 0;

    if (!lib_initialized) {
        return -1;
    }

    if (commands == NULL || strlen(commands) == 0) {
        return -1;
    }

    /* Make a copy since strtok_r/strtok_s modifies the string */
    cmd_copy = gp_strdup(commands);

    /* Split by newlines and execute each command */
#ifdef _WIN32
    line = strtok_s(cmd_copy, "\n", &saveptr);
#else
    line = strtok_r(cmd_copy, "\n", &saveptr);
#endif
    while (line != NULL) {
        /* Skip empty lines */
        while (*line == ' ' || *line == '\t') line++;

        if (*line != '\0' && *line != '#') {
            if (gnuplot_cmd(line) != 0) {
                result = -1;
                break;
            }
        }
#ifdef _WIN32
        line = strtok_s(NULL, "\n", &saveptr);
#else
        line = strtok_r(NULL, "\n", &saveptr);
#endif
    }

    free(cmd_copy);
    return result;
}

/* Reset gnuplot to initial state */
void gnuplot_reset(void)
{
    if (!lib_initialized) {
        return;
    }

    gnuplot_cmd("reset");
}

/* Cleanup and close gnuplot */
void gnuplot_close(void)
{
    if (!lib_initialized) {
        return;
    }

    term_reset();
    lib_initialized = 0;
}

/* Get gnuplot version */
const char* gnuplot_get_version(void)
{
    extern const char gnuplot_version[];
    extern const char gnuplot_patchlevel[];
    static char version_str[256];
    snprintf(version_str, sizeof(version_str), "%s patchlevel %s",
             gnuplot_version, gnuplot_patchlevel);
    return version_str;
}

/* Check if initialized */
int gnuplot_is_initialized(void)
{
    return lib_initialized;
}

/* Set datablock content directly */
int gnuplot_set_datablock(const char *name, const char *data)
{
    struct udvt_entry *datablock;
    char *datablock_name;

    if (!lib_initialized) {
        return -1; /* Not initialized */
    }

    if (name == NULL || data == NULL) {
        return -1; /* Invalid parameters */
    }

    /* Ensure name starts with $ */
    if (name[0] == '$') {
        datablock_name = gp_strdup(name);
    } else {
        /* Add $ prefix */
        datablock_name = (char *)gp_alloc(strlen(name) + 2, "datablock name");
        datablock_name[0] = '$';
        strcpy(datablock_name + 1, name);
    }

    /* Create or get the datablock variable */
    datablock = add_udv_by_name(datablock_name);

    /* Initialize as empty datablock if not already one */
    if (datablock->udv_value.type != DATABLOCK) {
        free_value(&datablock->udv_value);
        datablock->udv_value.type = DATABLOCK;
        datablock->udv_value.v.data_array = NULL;
    }

    /* Clear existing data if any */
    if (datablock->udv_value.v.data_array) {
        gpfree_datablock(&datablock->udv_value);
        datablock->udv_value.type = DATABLOCK;
        datablock->udv_value.v.data_array = NULL;
    }

    /* Add the data using gnuplot's append_multiline function
     * This handles newlines and creates the data_array properly */
    append_multiline_to_datablock(&datablock->udv_value, gp_strdup(data));

    free(datablock_name);
    return 0;
}

/* Initialize memory (simplified version of init_memory from plot.c) */
static void init_memory_lib(void)
{
    extend_input_line();
    extend_token_table();
    replot_line = gp_strdup("");
}

/* Include bitmap functions */
#include "bitmap.h"

/* Global buffer for saved bitmap data */
static unsigned char *saved_rgb_data = NULL;
static unsigned int saved_width = 0;
static unsigned int saved_height = 0;

/* Save bitmap RGB data - must be called while bitmap still exists */
void* gnuplot_save_bitmap_data(void)
{
    /* Check if bitmap exists */
    if (!b_p || b_xsize == 0 || b_ysize == 0) {
        return NULL;
    }

    /* Check if color mode (need 4 planes for RGB) */
    if (b_planes < 4) {
        return NULL;
    }

    unsigned int width = b_ysize;   /* Reversed due to raster mode */
    unsigned int height = b_xsize;

    /* Calculate buffer size */
    size_t rgb_size = width * height * 3;

    /* Free previous saved data if any */
    if (saved_rgb_data) {
        free(saved_rgb_data);
    }

    /* Allocate new buffer (with space for width/height header) */
    saved_rgb_data = (unsigned char *)malloc(sizeof(unsigned int) * 2 + rgb_size);
    if (!saved_rgb_data) {
        return NULL;
    }

    /* Store width and height at start of buffer */
    ((unsigned int*)saved_rgb_data)[0] = width;
    ((unsigned int*)saved_rgb_data)[1] = height;

    /* Extract RGB data - same logic as PBM_colortext() */
    unsigned char *rgb_ptr = saved_rgb_data + sizeof(unsigned int) * 2;

    for (int x = height - 1; x >= 0; x--) {
        int row = (width / 8) - 1;
        for (int j = row; j >= 0; j--) {
            int mask = 0x80;
            int plane1 = (*((*b_p)[j] + x));
            int plane2 = (*((*b_p)[j + b_psize] + x));
            int plane3 = (*((*b_p)[j + b_psize + b_psize] + x));
            int plane4 = (*((*b_p)[j + b_psize + b_psize + b_psize] + x));

            for (int i = 0; i < 8; i++) {
                int red = (plane3 & mask) ? 1 : 3;
                int green = (plane2 & mask) ? 1 : 3;
                int blue = (plane1 & mask) ? 1 : 3;
                if (plane4 & mask) {
                    red--;
                    green--;
                    blue--;
                }
                /* Scale to 0-255 range (85 = 255/3) */
                *rgb_ptr++ = (unsigned char)(red * 85);
                *rgb_ptr++ = (unsigned char)(green * 85);
                *rgb_ptr++ = (unsigned char)(blue * 85);
                mask >>= 1;
            }
        }
    }

    saved_width = width;
    saved_height = height;

    return saved_rgb_data;
}

/* Get the saved bitmap data (already saved by terminal) */
void* gnuplot_get_saved_bitmap_data(void)
{
    return saved_rgb_data;
}

/* Free saved bitmap data */
void gnuplot_free_saved_bitmap(void)
{
    if (saved_rgb_data) {
        free(saved_rgb_data);
        saved_rgb_data = NULL;
        saved_width = 0;
        saved_height = 0;
    }
}

/* luacmd terminal command capture implementation */
static luacmd_command_t *command_buffer = NULL;
static int command_count = 0;
static int command_capacity = 0;
static int plot_width = 800;
static int plot_height = 600;

void luacmd_begin_plot(int width, int height)
{
    plot_width = width;
    plot_height = height;
    luacmd_clear_commands();
}

void luacmd_end_plot(void)
{
    /* Plot is complete, commands are ready to be retrieved */
}

void luacmd_clear_commands(void)
{
    /* Free all text strings */
    for (int i = 0; i < command_count; i++) {
        if (command_buffer[i].text) {
            free(command_buffer[i].text);
        }
    }

    /* Reset count but keep buffer allocated */
    command_count = 0;
}

void luacmd_add_command(int type, int x1, int y1, int x2, int y2,
                      const char *text, unsigned int color, double value)
{
    /* Grow buffer if needed */
    if (command_count >= command_capacity) {
        command_capacity = (command_capacity == 0) ? 1024 : command_capacity * 2;
        command_buffer = (luacmd_command_t *)realloc(command_buffer,
                                                     command_capacity * sizeof(luacmd_command_t));
        if (!command_buffer) {
            command_count = 0;
            command_capacity = 0;
            return;
        }
    }

    /* Add command */
    luacmd_command_t *cmd = &command_buffer[command_count++];
    cmd->type = type;
    cmd->x1 = x1;
    cmd->y1 = y1;
    cmd->x2 = x2;
    cmd->y2 = y2;
    cmd->text = text ? strdup(text) : NULL;
    cmd->color = color;
    cmd->value = value;
}

luacmd_command_t* luacmd_get_commands(int *count, int *width, int *height)
{
    *count = command_count;
    *width = plot_width;
    *height = plot_height;

    /* Return copy of commands */
    if (command_count == 0) {
        return NULL;
    }

    luacmd_command_t *copy = (luacmd_command_t *)malloc(command_count * sizeof(luacmd_command_t));
    if (!copy) {
        return NULL;
    }

    for (int i = 0; i < command_count; i++) {
        copy[i] = command_buffer[i];
        /* Duplicate text strings */
        copy[i].text = command_buffer[i].text ? strdup(command_buffer[i].text) : NULL;
    }

    return copy;
}

void luacmd_free_commands(luacmd_command_t *commands)
{
    if (!commands) {
        return;
    }

    /* Note: We don't know the count here, but in practice this function
     * won't be used - Lua will manage the memory */
    free(commands);
}
