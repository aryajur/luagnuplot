/* Lua bindings for libgnuplot */

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <stdlib.h>

/* Forward declare bitmap variables to avoid header conflicts */
typedef unsigned char pixels;
typedef pixels *bitmap[];
extern bitmap *b_p;
extern unsigned int b_xsize, b_ysize;
extern unsigned int b_planes;
extern unsigned int b_psize;

#include "libgnuplot.h"

/* Lua: gnuplot.init() */
static int l_gnuplot_init(lua_State *L)
{
    int result = gnuplot_init();
    lua_pushboolean(L, result == 0);
    return 1;
}

/* Lua: gnuplot.cmd(command) */
static int l_gnuplot_cmd(lua_State *L)
{
    const char *command = luaL_checkstring(L, 1);
    int result = gnuplot_cmd(command);
    lua_pushboolean(L, result == 0);
    return 1;
}

/* Lua: gnuplot.cmd_multi(commands) */
static int l_gnuplot_cmd_multi(lua_State *L)
{
    const char *commands = luaL_checkstring(L, 1);
    int result = gnuplot_cmd_multi(commands);
    lua_pushboolean(L, result == 0);
    return 1;
}

/* Lua: gnuplot.reset() */
static int l_gnuplot_reset(lua_State *L)
{
    gnuplot_reset();
    return 0;
}

/* Lua: gnuplot.close() */
static int l_gnuplot_close(lua_State *L)
{
    gnuplot_close();
    return 0;
}

/* Lua: gnuplot.version() */
static int l_gnuplot_version(lua_State *L)
{
    const char *version = gnuplot_get_version();
    lua_pushstring(L, version);
    return 1;
}

/* Lua: gnuplot.is_initialized() */
static int l_gnuplot_is_initialized(lua_State *L)
{
    int initialized = gnuplot_is_initialized();
    lua_pushboolean(L, initialized);
    return 1;
}

/* Lua: gnuplot.plot(data_or_function, [options]) */
static int l_gnuplot_plot(lua_State *L)
{
    const char *data = luaL_checkstring(L, 1);
    const char *options = luaL_optstring(L, 2, "");

    char command[4096];
    snprintf(command, sizeof(command), "plot %s %s", data, options);

    int result = gnuplot_cmd(command);
    lua_pushboolean(L, result == 0);
    return 1;
}

/* Lua: gnuplot.splot(data_or_function, [options]) */
static int l_gnuplot_splot(lua_State *L)
{
    const char *data = luaL_checkstring(L, 1);
    const char *options = luaL_optstring(L, 2, "");

    char command[4096];
    snprintf(command, sizeof(command), "splot %s %s", data, options);

    int result = gnuplot_cmd(command);
    lua_pushboolean(L, result == 0);
    return 1;
}

/* Lua: gnuplot.set(option) */
static int l_gnuplot_set(lua_State *L)
{
    const char *option = luaL_checkstring(L, 1);

    char command[4096];
    snprintf(command, sizeof(command), "set %s", option);

    int result = gnuplot_cmd(command);
    lua_pushboolean(L, result == 0);
    return 1;
}

/* Lua: gnuplot.unset(option) */
static int l_gnuplot_unset(lua_State *L)
{
    const char *option = luaL_checkstring(L, 1);

    char command[4096];
    snprintf(command, sizeof(command), "unset %s", option);

    int result = gnuplot_cmd(command);
    lua_pushboolean(L, result == 0);
    return 1;
}

/* Forward declare libgnuplot functions */
extern void* gnuplot_get_saved_bitmap_data(void);
extern void gnuplot_free_saved_bitmap(void);

/* Lua: gnuplot.get_rgb_data()
 * Returns RGB data as a string of bytes (width, height, rgb_data)
 * Use after 'set terminal pbm color' and plotting
 * Call this after 'set output' to close the output and trigger bitmap save
 */
static int l_gnuplot_get_rgb_data(lua_State *L)
{
    /* Get the already-saved bitmap data (saved by terminal text() function) */
    void *data_ptr = gnuplot_get_saved_bitmap_data();

    if (!data_ptr) {
        lua_pushnil(L);
        lua_pushstring(L, "No bitmap data available. Use 'set terminal pbm color', plot something, then close output with 'set output' before calling this.");
        return 2;
    }

    /* Extract width, height from saved data */
    unsigned int *header = (unsigned int *)data_ptr;
    unsigned int width = header[0];
    unsigned int height = header[1];
    unsigned char *rgb_data = (unsigned char*)data_ptr + sizeof(unsigned int) * 2;
    size_t rgb_size = width * height * 3;

    /* Create Lua table with width, height, and data */
    lua_newtable(L);

    lua_pushinteger(L, width);
    lua_setfield(L, -2, "width");

    lua_pushinteger(L, height);
    lua_setfield(L, -2, "height");

    /* Copy RGB data to Lua string */
    lua_pushlstring(L, (const char *)rgb_data, rgb_size);
    lua_setfield(L, -2, "data");

    /* Data is now copied to Lua, but we keep the saved version
     * in case user wants to call this multiple times */

    return 1;
}

/* Lua: gnuplot.set_datablock(name, data)
 * Set datablock content directly (bypasses heredoc syntax)
 * name: datablock name (can include $ or not)
 * data: newline-separated data lines
 * Example: gnuplot.set_datablock("$DATA", "1 2\n2 4\n3 6")
 */
static int l_gnuplot_set_datablock(lua_State *L)
{
    const char *name = luaL_checkstring(L, 1);
    const char *data = luaL_checkstring(L, 2);
    int result = gnuplot_set_datablock(name, data);
    lua_pushboolean(L, result == 0);
    return 1;
}

/* Lua: gnuplot.get_commands()
 * Returns drawing commands captured by luacmd terminal
 * Returns: {width=N, height=M, commands={{type=0, x=100, y=200, ...}, ...}}
 */
static int l_gnuplot_get_commands(lua_State *L)
{
    int count, width, height;
    luacmd_command_t *commands = luacmd_get_commands(&count, &width, &height);

    if (!commands || count == 0) {
        lua_pushnil(L);
        lua_pushstring(L, "No commands available. Use 'set terminal luacmd' and plot something first.");
        return 2;
    }

    /* Create result table */
    lua_newtable(L);

    /* Add width and height */
    lua_pushinteger(L, width);
    lua_setfield(L, -2, "width");

    lua_pushinteger(L, height);
    lua_setfield(L, -2, "height");

    /* Add commands array */
    lua_newtable(L);
    for (int i = 0; i < count; i++) {
        lua_newtable(L);

        lua_pushinteger(L, commands[i].type);
        lua_setfield(L, -2, "type");

        lua_pushinteger(L, commands[i].x1);
        lua_setfield(L, -2, "x");

        lua_pushinteger(L, commands[i].y1);
        lua_setfield(L, -2, "y");

        /* VECTOR (type 1) and FILLBOX (type 7) commands have x2, y2 */
        if (commands[i].type == 1 || commands[i].type == 7) {
            lua_pushinteger(L, commands[i].x2);
            lua_setfield(L, -2, "x2");

            lua_pushinteger(L, commands[i].y2);
            lua_setfield(L, -2, "y2");
        }

        if (commands[i].text) {
            lua_pushstring(L, commands[i].text);
            lua_setfield(L, -2, "text");
        }

        /* Always add color field for COLOR commands (type 3) */
        if (commands[i].type == 3 || commands[i].color != 0) {
            lua_pushinteger(L, commands[i].color);
            lua_setfield(L, -2, "color");
        }

        if (commands[i].value != 0.0) {
            lua_pushnumber(L, commands[i].value);
            lua_setfield(L, -2, "value");
        }

        lua_rawseti(L, -2, i + 1);

        /* Free text if allocated */
        if (commands[i].text) {
            free(commands[i].text);
        }
    }

    lua_setfield(L, -2, "commands");

    /* Free commands array */
    free(commands);

    return 1;
}

/* Library registration */
static const struct luaL_Reg gnuplot_lib[] = {
    {"init", l_gnuplot_init},
    {"cmd", l_gnuplot_cmd},
    {"cmd_multi", l_gnuplot_cmd_multi},
    {"reset", l_gnuplot_reset},
    {"close", l_gnuplot_close},
    {"version", l_gnuplot_version},
    {"is_initialized", l_gnuplot_is_initialized},
    {"plot", l_gnuplot_plot},
    {"splot", l_gnuplot_splot},
    {"set", l_gnuplot_set},
    {"unset", l_gnuplot_unset},
    {"set_datablock", l_gnuplot_set_datablock},
    {"get_rgb_data", l_gnuplot_get_rgb_data},
    {"get_commands", l_gnuplot_get_commands},
    {NULL, NULL}
};

/* Module initialization */
int luaopen_gnuplot(lua_State *L)
{
    luaL_newlib(L, gnuplot_lib);
    return 1;
}
