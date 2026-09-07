# The init.lua Hammerspoon actually loads.
#
# A separate file so `nix flake check` can build it with test values and run
# it. It is the one file whose failure loses every clicked link on the machine,
# and nothing else executes it: home.file gets the built store path, and the
# hand-written modules under lua/ are what the rest of the suite covers.
{ cfgDir }:

let
  luaStr = import ./lua-str.nix;
in
''
    -- Managed by systems/modules/darwin/hammerspoon. Edits here are replaced
    -- on the next build-switch; hand-edited config lives in lua/.

    -- Registered before anything that can fail: with no httpCallback,
    -- Hammerspoon drops every clicked link on the machine. The load-time pcall
    -- below cannot cover this, because a broken dispatch raises per click — so
    -- the callback carries its own pcall and a fallback needing nothing else.
    hs.urlevent.httpCallback = function(scheme, host, params, fullURL, senderPID)
      local dispatched, err = pcall(function()
        require("lua.router").dispatch(scheme, host, params, fullURL, senderPID)
      end)
      if not dispatched then
        print("hammerspoon: router failed, falling back: " .. tostring(err))
        -- Safari, hard-coded: this runs precisely when the configured targets
        -- could not be loaded, so it must name a bundle that is always present
        -- and depend on nothing outside this file. The profile is whichever
        -- Safari last used — a link in the wrong profile is recoverable, a link
        -- that goes nowhere is not.
        -- pcall because openURLWithBundle raises on a non-string argument
        -- rather than returning false, and its boolean only reports that
        -- LaunchServices opened the bundle.
        pcall(hs.urlevent.openURLWithBundle, fullURL, "com.apple.Safari")
      end
    end

    -- Required for `hs -c`, which activation uses to reload. Opens an
    -- unauthenticated Mach port to anything running as this user — see
    -- "hs.ipc is a privilege surface" in README.md.
    require("hs.ipc")

    -- Hammerspoon has regressed on symlink resolution before, and the failure
    -- mode is a stale config that looks correct.
    local expected = ${luaStr cfgDir}
    if hs.configdir ~= expected then
      -- print() as well: notifications need an authorization this bundle may
      -- not have yet.
      print("hammerspoon: configdir is " .. tostring(hs.configdir) .. ", expected " .. expected)
      hs.notify.new({
        title = "Hammerspoon config dir drift",
        informativeText = "configdir=" .. tostring(hs.configdir) .. " expected=" .. expected,
      }):send()
    end

    -- Lets the modules under lua/ require each other by bare name.
    package.path = hs.configdir .. "/lua/?.lua;" .. hs.configdir .. "/lua/?/init.lua;" .. package.path

    -- Global because hs.pathwatcher keeps no registry: a watcher held only by
    -- a local is collected and hot reload stops silently. Debounced because one
    -- editor write emits several events, and the first can read a partial file.
    hsConfigReloadTimer = nil
    hsConfigWatcher = hs.pathwatcher.new(hs.configdir .. "/lua", function(files)
      local touchedLua = false
      for _, f in ipairs(files or {}) do
        if f:match("%.lua$") then
          touchedLua = true
          break
        end
      end
      if not touchedLua then
        return
      end
      if hsConfigReloadTimer then
        hsConfigReloadTimer:stop()
      end
      hsConfigReloadTimer = hs.timer.doAfter(0.5, hs.reload)
    end)
    hsConfigWatcher:start()

    -- Dotted, because a bare require("init") resolves back to this file
    -- through Hammerspoon's own <configdir>/?.lua template and recurses until
    -- the stack blows — which the pcall then reports as success.
    local ok, err = pcall(require, "lua.init")
    if not ok then
      hs.notify.new({ title = "Hammerspoon config failed to load", informativeText = tostring(err) }):send()
      print("config load failed: " .. tostring(err))
    end
''
