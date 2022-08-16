CC = zig cc
CFLAGS = -O2
VERSION = dev-1
TARGET = x86_64-linux-musl

sources := $(shell find src -name '*.lua')
luajit_path := $(shell readlink -f "$$(dirname "$$(which luajit)")"/..)
arch := $(shell if [ ${TARGET} != 'i386-linux-musl' ]; then echo ${TARGET} | cut -d '-' -f 1; else echo 'x86'; fi)

.PHONY: all
all: batstat-${TARGET}-${VERSION}.tar.xz

.PHONY: clean
clean:
	./luarocks purge --tree lua_modules >/dev/null
	rm -rf bin build lib ext batstat-*.tar batstat-*.tar.xz
	find . -maxdepth 1 -type d -name 'batstat-*' -exec rm -r {} +

batstat-${TARGET}-${VERSION}.tar.xz: batstat-${TARGET}-${VERSION}.tar
	xz --keep --best --force $<

batstat-${TARGET}-${VERSION}.tar: batstat-${TARGET}-${VERSION}/
	tar -c -f $@ $<

batstat-${TARGET}-${VERSION}/: bin/batstat-${TARGET} service/systemd/batstat-daemon.service
	rm -rf $@
	mkdir -p $@
	cp -r service README.md LICENSE.txt CHANGELOG.md $@
	cp bin/batstat-${TARGET} $@/batstat

# TODO: Figure out why x86_64 doesn't work with compiled version of luajit
bin/batstat-x86_64-linux-musl: lib/lua_signal-${TARGET}.a lib/sleep-${TARGET}.a lib/libunwind-${TARGET}.a $(sources) \
		lua_modules/share/lua/5.1/argparse.lua lua_modules/bin/luastatic | build/ bin/
	cp ${sources} build/
	cp lua_modules/share/lua/5.1/argparse.lua build/
	cp lib/libunwind-${TARGET}.a lib/lua_signal-${TARGET}.a lib/sleep-${TARGET}.a build/
	cd build && CC="${CC}" ../lua_modules/bin/luastatic \
	   batstat.lua \
	   cli_parser.lua daemon.lua date_utils.lua func.lua math_utils.lua stats.lua battery_log_parser.lua \
	   argparse.lua \
	   lua_signal-${TARGET}.a sleep-${TARGET}.a libunwind-${TARGET}.a \
	   ${luajit_path}/lib/libluajit-5.1.a \
	   -target ${TARGET} -static -Bstatic ${CFLAGS} \
	   -I${luajit_path}/include \
	   -lm -lpthread -ldl -lunwind
	cp build/batstat bin/batstat-${TARGET}

bin/batstat-i386-linux-musl bin/batstat-arm-linux-musleabihf bin/batstat-aarch64-linux-musl: \
		lib/libluajit-${TARGET}.a lib/lua_signal-${TARGET}.a lib/sleep-${TARGET}.a \
		lib/libunwind-${TARGET}.a $(sources) lua_modules/share/lua/5.1/argparse.lua lua_modules/bin/luastatic \
		| build/ bin/
	cp ${sources} build/
	cp lua_modules/share/lua/5.1/argparse.lua build/
	cp lib/libluajit-${TARGET}.a lib/libunwind-${TARGET}.a lib/lua_signal-${TARGET}.a lib/sleep-${TARGET}.a build/
	cd build && CC="${CC}" ../lua_modules/bin/luastatic \
	   batstat.lua \
	   cli_parser.lua daemon.lua date_utils.lua func.lua math_utils.lua stats.lua battery_log_parser.lua \
	   argparse.lua \
	   libluajit-${TARGET}.a lua_signal-${TARGET}.a sleep-${TARGET}.a libunwind-${TARGET}.a \
	   -target ${TARGET} -static -Bstatic ${CFLAGS} \
	   -I${luajit_path}/include \
	   -lm -lpthread -ldl -lunwind
	cp build/batstat bin/batstat-${TARGET}

lib/libluajit-${TARGET}.a: ext/luajit/README | lib/
	cd ext/luajit && make clean && make \
		BUILDMODE="static" \
		HOST_CC="${CC} -target ${TARGET}" \
		CC="${CC} -target ${TARGET} -static -Bstatic" \
		LDFLAGS="-I../ext/libunwind/ -lunwind" \
		CCOPT_x86="" \
		TARGET_STRIP="echo"
	mv ext/luajit/src/libluajit.a $@

lib/libunwind-${TARGET}.a: ext/libunwind/README | lib/
	cd ext/libunwind && autoreconf -i && ./configure --target ${TARGET} && make
	mv ext/libunwind/src/.libs/libunwind-${arch}.a $@

lib/lua_signal-${TARGET}.a: ext/lua_signal/lsignal.c | lib/
	make --directory=ext/lua_signal CC="${CC}" CFLAGS="${CFLAGS} -target ${TARGET} -c -static -I${luajit_path}/include"
	mv ext/lua_signal/signal.so $@

lib/sleep-${TARGET}.a: ext/sleep/sleep.c | lib/
	${CC} ${CFLAGS} -target ${TARGET} -I${luajit_path}/include -Wall -fPIC -O2 -c -static ext/sleep/sleep.c -o $@

lua_modules/%:
	./luarocks build --only-deps >/dev/null

ext/luajit/README: | ext/download/luajit/
	curl -Lo ext/download/luajit-2.1.0-beta3.tar.gz https://luajit.org/download/LuaJIT-2.1.0-beta3.tar.gz
	tar --extract --file=ext/download/luajit-2.1.0-beta3.tar.gz --directory=ext/download
	rm -rf ext/luajit
	mv ext/download/LuaJIT-2.1.0-beta3 ext/luajit

ext/libunwind/README: | ext/download/libunwind/
	curl -Lo ext/download/libunwind-1.6.2.tar.gz https://github.com/libunwind/libunwind/releases/download/v1.6.2/libunwind-1.6.2.tar.gz
	tar --extract --file=ext/download/libunwind-1.6.2.tar.gz --directory=ext/download/
	rm -rf ext/libunwind
	mv ext/download/libunwind-1.6.2 ext/libunwind

ext/lua_signal/lsignal.c: | ext/download/lua_signal/
	./luarocks download --source lua_signal
	mv lua_signal-*.src.rock ext/download
	unzip -qq -o ext/download/lua_signal-*.src.rock -d ext/download/lua_signal
	rm -rf ext/lua_signal
	mv ext/download/lua_signal/lua-signal/ ext/lua_signal

ext/sleep/sleep.c: | ext/download/sleep/
	./luarocks download --source sleep
	mv sleep-*.src.rock ext/download/
	unzip -qq -o ext/download/sleep-*.src.rock -d ext/download/sleep
	rm -rf ext/sleep
	mv ext/download/sleep/sleep/ ext/

build/ bin/ lib/ ext/download/luajit/ ext/download/libunwind/ ext/download/lua_signal/ ext/download/sleep/:
	mkdir -p $@
