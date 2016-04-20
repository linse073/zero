
# skynet
linux macosx freebsd :
	cd 3rd/skynet && $(MAKE) $@

MY_LUA_CLIB_PATH ?= 3rd/skynet/luaclib

MY_CFLAGS = -g -O2 -Wall -I$(MY_LUA_INC) $(MYCFLAGS)

# lua
MY_LUA_INC ?= 3rd/skynet/3rd/lua

MY_LUA_CLIB = rand

all : \
  $(foreach v, $(MY_LUA_CLIB), $(MY_LUA_CLIB_PATH)/$(v).so) 

$(MY_LUA_CLIB_PATH)/rand.so : lib-src/rand.c | $(MY_LUA_CLIB_PATH)
	$(CC) $(MY_CFLAGS) $(SHARED) $^ -o $@