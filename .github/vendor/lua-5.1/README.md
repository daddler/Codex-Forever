# Lua 5.1.5 (Quelltext, unverändert)

Für die Prüfläufe der Actions (`.github/scripts/install_lua.sh`): `lua5.1`
und `luac5.1` werden daraus gebaut – ohne Paketquellen und ohne Netz. Im
November 2026 waren von den Läufern aus die Ubuntu-Paketquellen, lua.org
und zeitweise der Spiegel auf GitHub nicht zu gebrauchen; jeder Release
scheiterte, bevor ein Test lief.

Stand: Lua 5.1.5 (`src/` aus github.com/LuaDist/lua, Tag 5.1.5;
`luaconf.h` = deren `luaconf.h.orig`). Lizenz: MIT, siehe COPYRIGHT
(Lua.org, PUC-Rio). Wird nicht mit dem Addon ausgeliefert.
