#!/bin/sh

VERSION=0.1.0

rm -rf dist
mkdir -p dist/batstat-"$VERSION"

./luarocks build

cp lua dist/batstat-"$VERSION"
cp -r lua_modules dist/batstat-"$VERSION"

cat <<EOF > dist/batstat-"$VERSION"/batstat
#!/bin/sh

LUA_PATH='./lua_modules/share/lua/5.1/?.lua;./lua_modules/share/lua/5.1/?/init.lua' LUA_CPATH='./lua_modules/lib/lua/5.1/?.so;./lua_modules/lib/lua/5.1/posix/?.so;./lua_modules/lib/lua/5.1/posix/sys/?.so' ./lua ./lua_modules/lib/luarocks/rocks-5.1/batstat/dev-1/bin/batstat
EOF

chmod +x dist/batstat-"$VERSION"/batstat

tar --create --gzip --file=batstat-"$VERSION".tar.gz dist/batstat-"$VERSION"

