CC = musl-gcc
CFLAGS = -O2
VERSION=dev-1

sources := $(shell find src -name '*.lua')
luajit_path := $(shell readlink -f "$$(dirname "$$(which luajit)")"/..)
libunwind_path := $(shell find / -path '*/lib/*' -name 'libunwind.a' -print -quit 2>/dev/null)

.PHONY: all
all: batstat-${VERSION}.tar.xz

.PHONY: clean
clean:
	./luarocks purge --tree lua_modules >/dev/null
	rm -rf bin build obj ext batstat-*.tar batstat-*.tar.xz

batstat-${VERSION}.tar.xz: batstat-${VERSION}.tar
	xz --keep --best --force $<

batstat-${VERSION}.tar: batstat-${VERSION}/
	tar -c -f $@ $<

batstat-${VERSION}/: bin/batstat
	rm -rf $@
	mkdir -p $@
	cp -r bin/batstat service README.md LICENSE.txt CHANGELOG.md $@

bin/batstat: obj/lua_signal.o obj/sleep.o $(sources) | luarocks_deps build/ bin/
	cp ${sources} build/
	cp lua_modules/share/lua/5.1/argparse.lua build/
	cp obj/lua_signal.o obj/sleep.o build/
	cd build && CC="zig cc" ../lua_modules/bin/luastatic \
	   batstat.lua \
	   cli_parser.lua daemon.lua date_utils.lua func.lua math_utils.lua stats.lua battery_log_parser.lua \
	   argparse.lua \
	   lua_signal.o sleep.o \
	   ${luajit_path}/lib/libluajit-5.1.a \
	   -target x86_64-linux-musl -static -Bstatic ${CFLAGS} \
	   -I${luajit_path}/include \
	   -L${libunwind_path}/lib/libunwind -lunwind \
	   -lm -lpthread -ldl
	mv build/batstat bin/batstat

obj/lua_signal.o: ext/lua_signal/lsignal.c | obj/
	make --directory=ext/lua_signal CC="$(CC)" CFLAGS="${CFLAGS} -c -static -I${luajit_path}/include"
	mv ext/lua_signal/signal.so obj/lua_signal.o

obj/sleep.o: ext/sleep/sleep.c | obj/
	$(CC) ${CFLAGS} -I${luajit_path}/include -Wall -fPIC -O2 -c -static ext/sleep/sleep.c -o $@

.PHONY: luarocks_deps
luarocks_deps:
	./luarocks build --only-deps >/dev/null

ext/lua_signal/lsignal.c: | ext/download/lua_signal
	./luarocks download --source lua_signal
	mkdir -p ext/download/lua_signal
	mv lua_signal-*.src.rock ext/download
	unzip -qq -o ext/download/lua_signal-*.src.rock -d ext/download/lua_signal
	rm -rf ext/lua_signal
	mv ext/download/lua_signal/lua-signal/ ext/lua_signal

ext/sleep/sleep.c: | ext/download/sleep
	./luarocks download --source sleep
	mkdir -p ext/download/sleep
	mv sleep-*.src.rock ext/download/
	unzip -qq -o ext/download/sleep-*.src.rock -d ext/download/sleep
	rm -rf ext/sleep
	mv ext/download/sleep/sleep/ ext/

build/:
	mkdir -p build

bin/:
	mkdir -p bin

obj/:
	mkdir -p obj

ext/download/lua_signal:
	mkdir -p ext/download/lua_signal

ext/download/sleep:
	mkdir -p ext/download/sleep
