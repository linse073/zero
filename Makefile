include platform.mk

LUA_CLIB_PATH ?= 3rd/skynet/luaclib

CFLAGS = -g -O2 -Wall -I$(LUA_INC) $(MYCFLAGS)

LUA_INC ?= 3rd/skynet/3rd/lua

LUA_CLIB = rand webclient cjson

all : \
  $(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so)

$(LUA_CLIB_PATH) :
	mkdir $(LUA_CLIB_PATH)

$(LUA_CLIB_PATH)/rand.so : lib-src/rand.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@	
	
$(LUA_CLIB_PATH)/webclient.so : 3rd/webclient/webclient.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -lcurl
	
$(LUA_CLIB_PATH)/cjson.so : 3rd/cjson/lua_cjson.c 3rd/cjson/strbuf.c 3rd/cjson/fpconv.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -DNDEBUG -I3rd/cjson $^ -o $@

clean :
	rm -f $(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so)

cleanall : clean
	cd 3rd/skynet && $(MAKE) cleanall

