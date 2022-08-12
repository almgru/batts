#!/bin/sh

VERSION=dev-1

rm -rf dist
mkdir -p dist/batstat-"$VERSION"

./luarocks build

cp -r lua_modules dist/batstat-"$VERSION"

cat <<EOF > dist/batstat-"$VERSION"/batstat
#!/bin/sh
get_script_path() {
    ( CDPATH='' cd -- "\$(dirname "\$(readlink -f -- "\$0")")" || exit; pwd )
}

script_path="\$(get_script_path)"

LUA_PATH="\$script_path/lua_modules/share/lua/5.1/?.lua;\$script_path/lua_modules/share/lua/5.1/?/init.lua" LUA_CPATH="\$script_path/lua_modules/lib/lua/5.1/?.so;\$script_path/lua_modules/lib/lua/5.1/posix/?.so;\$script_path/lua_modules/lib/lua/5.1/posix/sys/?.so" /usr/bin/luajit "\$script_path"/lua_modules/lib/luarocks/rocks-5.1/batstat/dev-1/bin/batstat "\$@"
EOF

chmod +x dist/batstat-"$VERSION"/batstat

tar --create --gzip --file=batstat-"$VERSION".tar.gz --directory=dist batstat-"$VERSION"

