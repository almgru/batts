CC = gcc
CFLAGS = -O2
VERSION = dev-1

sources := $(shell find src -name '*.lua')
luajit_path := $(shell readlink -f "$$(dirname "$$(which luajit)")"/..)

.PHONY: all
all: batts-${VERSION}.tar.xz

.PHONY: clean
clean:
	./luarocks purge --tree lua_modules >/dev/null
	rm -rf bin build lib ext batts-*.tar batts-*.tar.xz
	find . -maxdepth 1 -type d -name 'batts-*' -exec rm -r {} +

batts-${VERSION}.tar.xz: batts-${VERSION}.tar
	xz --keep --best --force $<

batts-${VERSION}.tar: batts-${VERSION}/
	tar -c -f $@ $<

batts-${VERSION}/: bin/batts service/systemd/batts-daemon.service
	rm -rf $@
	mkdir -p $@
	cp -r service README.md LICENSE.txt CHANGELOG.md $@
	cp bin/batts $@/batts

bin/batts: lib/lua_signal.a lib/sleep.a $(sources) lua_modules/share/lua/5.1/argparse.lua \
		lua_modules/share/lua/5.1/ansicolors.lua lua_modules/share/lua/5.1/ftcsv.lua lua_modules/bin/luastatic \
		| build/ bin/
	cp ${sources} build/
	cp lua_modules/share/lua/5.1/argparse.lua lua_modules/share/lua/5.1/ansicolors.lua \
		lua_modules/share/lua/5.1/ftcsv.lua build/
	cp lib/lua_signal.a lib/sleep.a build/
	cd build && CC="${CC}" ../lua_modules/bin/luastatic \
	   batts.lua \
	   cli_parser.lua daemon.lua date_utils.lua func.lua math_utils.lua stats.lua battery_log_parser.lua \
	   argparse.lua ansicolors.lua ftcsv.lua \
	   lua_signal.a sleep.a \
	   ${luajit_path}/lib/libluajit-5.1.a \
	   -Bstatic -static-libgcc \
	   ${CFLAGS}
	patchelf --set-rpath /usr/lib --set-interpreter /lib/ld-linux-x86-64.so.2 build/batts
	cp build/batts bin/batts

lib/lua_signal.a: ext/lua_signal/lsignal.c | lib/
	make --directory=ext/lua_signal CC="${CC}" CFLAGS="${CFLAGS} -c -Bstatic -I${luajit_path}/include"
	mv ext/lua_signal/signal.so $@

lib/sleep.a: ext/sleep/sleep.c | lib/
	${CC} ${CFLAGS} -I${luajit_path}/include -Wall -fPIC -O2 -c -Bstatic ext/sleep/sleep.c -o $@

lua_modules/%:
	./luarocks build --only-deps >/dev/null

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

build/ bin/ lib/ ext/download/lua_signal/ ext/download/sleep/:
	mkdir -p $@
