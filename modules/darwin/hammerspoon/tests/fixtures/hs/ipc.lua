-- The stub requires hs.ipc for its side effect of opening the Mach port that
-- `hs -c` needs, which is how activation reloads Hammerspoon. Nothing
-- off-machine can provide that, so this records the require and resolves.
_G.RECORDED.ipcRequired = true
return {}
