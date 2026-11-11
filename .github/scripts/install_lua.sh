#!/usr/bin/env bash
# Lua 5.1 (lua5.1, luac5.1) fuer die Prueflaeufe.
# 1.0.5.50: die Paketquellen der GitHub-Server waren nicht aufloesbar
# ("Temporary failure resolving 'azure.archive.ubuntu.com'"), auch auf
# 24.04. Darum: erst kurz apt, sonst Lua 5.1 aus dem Quelltext bauen -
# von lua.org, sonst aus dem Spiegel auf GitHub (github.com ist sicher
# erreichbar, der Checkout kam ja an). Ohne Lua scheitert der Lauf.
set -u
if timeout 120 sudo apt-get install -y lua5.1 >/dev/null 2>&1 && command -v luac5.1 >/dev/null; then
  echo "Lua 5.1 aus apt"; exit 0
fi
work=$(mktemp -d)
cd "$work"
if curl -fsSL --retry 3 -o lua.tgz https://www.lua.org/ftp/lua-5.1.5.tar.gz; then
  tar xzf lua.tgz && src=lua-5.1.5/src
else
  git clone -q --depth 1 --branch v5.1 https://github.com/lua/lua.git lua-git || exit 1
  src=lua-git
  [ -d lua-git/src ] && src=lua-git/src
fi
cd "$src"
core=$(ls *.c | grep -v -E '^(lua|luac|print)\.c$')
gcc -O2 -DLUA_USE_POSIX -o lua5.1 $core lua.c -lm || exit 1
gcc -O2 -DLUA_USE_POSIX -o luac5.1 $core luac.c print.c -lm || exit 1
sudo install -m 755 lua5.1 luac5.1 /usr/local/bin/
lua5.1 -v
