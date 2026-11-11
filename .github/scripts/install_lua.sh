#!/usr/bin/env bash
# Lua 5.1.5 (lua5.1, luac5.1) fuer die Prueflaeufe - OHNE Netz.
#
# 1.0.5.50-52: nacheinander waren von den Laeufern aus die Ubuntu-
# Paketquellen, lua.org und der Spiegel auf GitHub nicht zu gebrauchen;
# jeder Release scheiterte, bevor ein Test lief. Darum liegt der
# Quelltext im Repo (.github/vendor/lua-5.1, MIT) und wird hier gebaut -
# braucht nur gcc, das jeder Laeufer hat, und dauert Sekunden.
set -eu
root=$(cd "$(dirname "$0")/../.." && pwd)
src="$root/.github/vendor/lua-5.1"
work=$(mktemp -d)
core=$(cd "$src" && ls *.c | grep -v -E '^(lua|luac|print)\.c$')
(cd "$src" && gcc -O2 -DLUA_USE_POSIX -o "$work/lua5.1" $core lua.c -lm)
(cd "$src" && gcc -O2 -DLUA_USE_POSIX -o "$work/luac5.1" $core luac.c print.c -lm)
sudo install -m 755 "$work/lua5.1" "$work/luac5.1" /usr/local/bin/
lua5.1 -v
