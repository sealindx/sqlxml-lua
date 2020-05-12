#include <stdio.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

static int lgensql(lua_State *L) {

	

	return 0;
}


int luaopen_mylib(lua_State *L) {

	static const struct luaL_Reg mylib[] = {
		{"gensql", lgensql},
		{NULL, NULL}
	};

	luaL_newlib(L, mylib);
	return 1;
}