# Hammerspoon: the application, and the configuration it runs.
#
# Several choices here are load-bearing in ways the code cannot show: the
# config path, the module name the stub requires, the restart-vs-reload
# branch, the Lua version of the syntax gate, and systemPackages over
# home.packages. ./README.md explains each.
{ config, pkgs, lib, ... }:

let
  user = "tapani";
  home = "/Users/${user}";
  cfgDir = "${home}/.config/hammerspoon";

  hammerspoon = pkgs.callPackage ./package.nix { };

  # Read here, where `config` is still the darwin config — inside
  # home-manager.users.<name> it is shadowed by home-manager's own.
  luaDir = config.local.hammerspoon.luaDir;
  browsers = config.local.browsers.targets;

  # Baked into the stub's fallback so it depends on nothing loaded at runtime.
  # Escaped like every other option-derived value: unescaped it would be the one
  # interpolation that could break the generated Lua with no trace back here.
  # Safari only if no target is configured at all — it is the macOS default and
  # is always present.
  fallbackBundle = if browsers == [ ] then "com.apple.Safari" else (builtins.head browsers).bundle;

  # The bundle is rsynced to a stable path by nix-darwin's applications
  # activation; the store path is not a usable launch target.
  appPath = "/Applications/Nix Apps/Hammerspoon.app";

  # lua5_4 to match the interpreter the app embeds; pkgs.lua is still 5.2.
  checkedLua = name: text:
    pkgs.runCommand name
      {
        inherit text;
        passAsFile = [ "text" ];
        nativeBuildInputs = [ pkgs.lua5_4 ];
      } ''
      cp "$textPath" candidate.lua
      luac -p candidate.lua
      cp candidate.lua "$out"
    '';

  # Lua strings are byte strings, so UTF-8 passes through untouched; only the
  # delimiters and the control characters need escaping.
  luaStr =
    s:
    ''"'' + builtins.replaceStrings [ "\\" "\"" "\n" "\r" "\t" ] [ "\\\\" "\\\"" "\\n" "\\r" "\\t" ] s + ''"'';

  # One source of truth for the picker rows and the per-profile hotkeys, so the
  # two cannot drift. An absent profileDir omits the key rather than writing nil.
  # Assembled line by line rather than interpolated into a multi-line string: the
  # generated file is what someone reads when the picker misbehaves, so its
  # indentation should not depend on how nix strips a here-doc.
  targetsLua =
    let
      field = name: value: "    ${name} = ${luaStr value},";
      entry =
        t:
        lib.concatStringsSep "\n" (
          [
            "  {"
            (field "key" t.key)
            (field "label" t.label)
            (field "bundle" t.bundle)
          ]
          ++ lib.optional (t.profileDir != null) (field "profileDir" t.profileDir)
          ++ [ "  }," ]
        );
    in
    checkedLua "hammerspoon-targets.lua" (
      lib.concatStringsSep "\n" (
        [
          "-- Managed by systems/modules/darwin/hammerspoon, generated from"
          "-- local.browsers.targets. Edits here are replaced on the next build-switch."
          "return {"
        ]
        ++ map entry browsers
        ++ [
          "}"
          ""
        ]
      )
    );

  # Generated, and kept deliberately small: everything that can fail is loaded
  # through pcall from here, so a syntax error in a hand-edited module cannot
  # stop the parts that must always run.
  initLua = checkedLua "hammerspoon-init.lua" ''
    -- Managed by systems/modules/darwin/hammerspoon. Edits here are replaced
    -- on the next build-switch; hand-edited config lives in lua/.

    -- FIRST, before anything that can fail. With no httpCallback registered
    -- Hammerspoon does not forward the URL anywhere — it logs "no http callback
    -- has been set" and drops the event. Once it is the default handler that is
    -- every clicked link on the machine.
    --
    -- The load-time pcall further down cannot help here: it would not catch a
    -- callback that dispatches into a module which failed to load, since that
    -- error is raised per click. So this carries its own pcall and its own
    -- hard-coded fallback, depending on nothing outside this file.
    hs.urlevent.httpCallback = function(scheme, host, params, fullURL, senderPID)
      local dispatched, err = pcall(function()
        require("lua.router").dispatch(scheme, host, params, fullURL, senderPID)
      end)
      if not dispatched then
        print("hammerspoon: router failed, falling back: " .. tostring(err))
        -- pcall because openURLWithBundle raises on a non-string argument
        -- rather than returning false, and its boolean only reports that
        -- LaunchServices opened the bundle.
        pcall(hs.urlevent.openURLWithBundle, fullURL, ${luaStr fallbackBundle})
      end
    end

    -- Required for `hs -c`, which activation uses to reload. Opens an
    -- unauthenticated Mach port to anything running as this user — see
    -- "hs.ipc is a privilege surface" in README.md.
    require("hs.ipc")

    -- Hammerspoon has regressed on symlink resolution before, and the failure
    -- mode is a stale config that looks correct.
    local expected = "${cfgDir}"
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

    -- Global on purpose: hs.pathwatcher keeps no internal registry, so a
    -- watcher held only by a local is collected and hot reload stops silently.
    --
    -- Filtered and debounced because one editor write emits several events,
    -- and reloading on the first can read a half-flushed file.
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

    -- The DOTTED name is load-bearing. A bare require("init") resolves
    -- through Hammerspoon's own <configdir>/?.lua template back to THIS file
    -- when lua/init.lua is missing, and recurses until the stack blows — which
    -- the pcall then reports as success. "lua.init" cannot collide.
    local ok, err = pcall(require, "lua.init")
    if not ok then
      hs.notify.new({ title = "Hammerspoon config failed to load", informativeText = tostring(err) }):send()
      print("config load failed: " .. tostring(err))
    end
  '';
in
{
  options.local.hammerspoon.luaDir = lib.mkOption {
    type = lib.types.str;
    default = "${home}/project/github/tapppi/systems/modules/darwin/hammerspoon/lua";
    description = ''
      Absolute path to the live, hand-edited Lua directory, symlinked out of
      the store so edits apply without a rebuild.

      Defaults to the MAIN checkout: the running config should follow reviewed
      code, not whatever branch is checked out. Note the consequence — the
      reload watcher fires on any *.lua write there, so ordinary git
      operations in that tree are live deploys of this config.

      It is a plain string with no store context, so nix cannot verify it: a
      wrong or missing path builds cleanly and fails only at runtime, which is
      why activation checks it.

      Override it to a worktree path to activate an in-progress branch, and
      revert that before merging.
    '';
  };

  options.local.browsers.targets = lib.mkOption {
    type = lib.types.listOf (
      lib.types.submodule {
        options = {
          key = lib.mkOption {
            type = lib.types.strMatching "[a-z0-9]";
            description = "Picker key and hyper hotkey. One character, so a choice is one keypress.";
          };
          label = lib.mkOption {
            type = lib.types.str;
            description = ''
              Row text in the picker. Deliberately generic: this repo is public, so a
              client's name must not appear here. Real display names are read from the
              browser's Local State at runtime instead.
            '';
          };
          bundle = lib.mkOption {
            type = lib.types.str;
            description = "Bundle id of the browser to launch.";
          };
          profileDir = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = ''
              On-disk profile directory — "Profile 1", never the display name. null for a
              browser launched without --profile-directory at all.
            '';
          };
        };
      }
    );
    default = [
      {
        key = "b";
        label = "Personal";
        bundle = "com.brave.Browser";
        profileDir = "Default";
      }
      {
        key = "v";
        label = "Company";
        bundle = "com.google.Chrome";
        profileDir = "Profile 1";
      }
      {
        key = "c";
        label = "Client";
        bundle = "com.google.Chrome";
        profileDir = "Profile 2";
      }
    ];
    description = ''
      Browser profiles an opened link can be routed to, in picker order.

      Generates both the picker and the hyper hotkeys. Keys must not collide with
      each other or with the app hotkeys bound in lua/init.lua.
    '';
  };

  config = {
    # A duplicate key is silent at runtime: the second hs.hotkey.bind wins and the
    # first target becomes unreachable, with the picker still offering both rows.
    assertions = [
      {
        assertion = lib.length (lib.unique (map (t: t.key) browsers)) == lib.length browsers;
        message = "local.browsers.targets: duplicate key. Each key binds one hotkey and one picker row.";
      }
    ];

    # Must be systemPackages, not home.packages: the TCC argument in README.md
    # rests on nix-darwin rsyncing the bundle into /Applications/Nix Apps, and
    # that activation reads environment.systemPackages only. home-manager's own
    # app placement is off entirely at this stateVersion, so a home.packages
    # app would not be placed at all.
    environment.systemPackages = [ hammerspoon ];

    # Written in the userDefaults phase, before the files below are placed.
    # Hammerspoon reads it once at launch, hence the restart branch below.
    # Write-only: removing this module leaves the key behind.
    system.defaults.CustomUserPreferences."org.hammerspoon.Hammerspoon" = {
      MJConfigFile = "${cfgDir}/init.lua";

      # Sparkle cannot replace a read-only store bundle, so a check can only
      # advertise a version this host cannot install.
      SUEnableAutomaticChecks = false;
      SUAutomaticallyUpdate = false;
    };

    home-manager.users.${user} = { config, ... }: {
      home.file.".config/hammerspoon/init.lua".source = initLua;
      home.file.".config/hammerspoon/generated/targets.lua".source = targetsLua;

      # Out of store so edits apply without a rebuild. A deliberate exception:
      # store-managed content is the point everywhere else.
      home.file.".config/hammerspoon/lua".source =
        config.lib.file.mkOutOfStoreSymlink luaDir;
    };

    system.activationScripts.postActivation.text = lib.mkAfter ''
      echo "configuring Hammerspoon" >&2

      if [ -n "''${DRY_RUN:-}" ] || /bin/ps -o args= -p "$PPID" 2>/dev/null | /usr/bin/grep -q -- ' --dry-run'; then
        # darwin-rebuild runs activate even for --dry-run. The env check keeps
        # this in step with home-manager's own guard.
        echo "  hammerspoon: --dry-run; leaving the running instance alone." >&2
      elif [ ! -d ${lib.escapeShellArg luaDir} ]; then
        # nix cannot verify an out-of-store path, and restarting into a
        # missing config would leave the machine with no hotkeys.
        echo "  hammerspoon: luaDir is missing; leaving the running instance alone." >&2
        echo "  hammerspoon:   ${luaDir}" >&2
        echo "  hammerspoon: set local.hammerspoon.luaDir when activating from a worktree." >&2
      elif /usr/bin/pgrep -qx Hammerspoon >/dev/null 2>&1; then
        hsUid="$(/usr/bin/id -u ${user})"
        asUser() {
          /bin/launchctl asuser "$hsUid" /usr/bin/sudo -u ${user} --set-home "$@"
        }

        # -a is load-bearing: with no instance running, `hs` otherwise puts up a
        # Launch/Cancel alert, and under launchctl/sudo nothing can answer it —
        # activation would hang on a modal nobody sees. `hs -h` does not list
        # the flag, but hs.man documents it: "If Hammerspoon is not currently
        # running, exit with EX_TEMPFAIL rather than prompt the user." Its
        # opposite is -A, which launches instead of prompting; the print-cloning
        # flag people confuse it with is -C. -t bounds the send/receive wait,
        # which the CLI otherwise defaults to 4s.
        #
        # A failed probe counts as a mismatch: on the first switch the running
        # instance predates hs.ipc and cannot answer at all.
        have="$(asUser ${hammerspoon}/bin/hs -a -t 5 -c 'print(hs.configdir)' 2>/dev/null || true)"

        if [ "$have" = '${cfgDir}' ]; then
          asUser ${hammerspoon}/bin/hs -a -t 5 -c 'hs.reload()' >/dev/null 2>&1 || true
        else
          # Verified rather than assumed: shutdown handlers can outlast a
          # fixed sleep, and `open -a` on a live instance only activates it.
          /usr/bin/killall Hammerspoon >/dev/null 2>&1 || true

          for _ in 1 2 3 4 5 6 7 8 9 10; do
            /usr/bin/pgrep -qx Hammerspoon >/dev/null 2>&1 || break
            /bin/sleep 0.5
          done

          if /usr/bin/pgrep -qx Hammerspoon >/dev/null 2>&1; then
            echo "  hammerspoon: old instance still running after 5s; not relaunching." >&2
            echo "  hammerspoon: quit it and reopen ${appPath}." >&2
          else
            asUser /usr/bin/open -a '${appPath}' >/dev/null 2>&1 || true

            now=""
            for _ in 1 2 3 4 5 6 7 8 9 10; do
              /bin/sleep 1
              # This loop is waiting for an instance to appear, so it is the
              # one place that genuinely runs with none. -a makes `hs` exit
              # rather than prompt; the pgrep is belt and braces, and also
              # avoids a pointless port attempt on every iteration.
              /usr/bin/pgrep -qx Hammerspoon >/dev/null 2>&1 || continue
              now="$(asUser ${hammerspoon}/bin/hs -a -t 5 -c 'print(hs.configdir)' 2>/dev/null || true)"
              [ "$now" = '${cfgDir}' ] && break
            done

            if [ "$now" != '${cfgDir}' ]; then
              echo "  hammerspoon: relaunched but configdir reports \"$now\"." >&2
            fi
          fi
        fi
      else
        # Nothing to restart. The login item still points at the Homebrew
        # bundle; both share a bundle id and so read the same config. Phase 3
        # removes the cask and takes over launching.
        echo "  hammerspoon: not running; start ${appPath} to pick up the new config." >&2
      fi
    '';
  };
}
