
# skynet
linux macosx freebsd :
	cd 3rd/skynet && $(MAKE) $@

MY_LUA_CLIB = rand

all : \
  $(foreach v, $(MY_LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so) 

$(LUA_CLIB_PATH)/rand.so : ../../lib-src/rand.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@