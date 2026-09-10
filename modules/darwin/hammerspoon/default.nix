# Hammerspoon: the application, and the configuration it runs.
#
# Several choices here fail in ways the code cannot show; ./README.md explains
# each.
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

  # The bundles whose profile list lua/browsers.lua can read, taken from the
  # module itself so the two cannot drift. Read here rather than restated,
  # because the paths that make a bundle supported have to live next to the
  # code that reads them, and a second copy in this option would be the thing
  # the assertion below is meant to prevent.
  #
  # This reads the module's own browsers.lua, not the one the machine loads:
  # luaDir is an out-of-store symlink and can be pointed at a worktree, so a
  # target added there is checked against that tree's table while Hammerspoon
  # runs the main checkout's. The assertion catches a target the *evaluated*
  # tree cannot support, which is the common case; it cannot see that skew.
  supportedBundles =
    let
      lines = lib.splitString "\n" (builtins.readFile ./lua/browsers.lua);
      openIdx = lib.lists.findFirstIndex (l: builtins.match "M\\.localState = [{]" l != null) null lines;
      rest = lib.lists.sublist (openIdx + 1) (builtins.length lines) lines;
      # builtins.match anchors on the whole line, so the body ends at the
      # table's own closing brace in column 0 and a nested table value cannot
      # truncate the list. Each key is matched on its own line, so a
      # commented-out entry cannot join it.
      closeIdx = lib.lists.findFirstIndex (l: builtins.match "[}].*" l != null) null rest;
      body =
        if closeIdx == null then
          throw (
            "hammerspoon: M.localState in lua/browsers.lua has no closing brace in column 0; "
            + "the supported-bundle list cannot be delimited"
          )
        else
          lib.lists.sublist 0 closeIdx rest;
      keys = builtins.filter (m: m != null) (
        map (l: builtins.match "[[:space:]]*[[]\"([^\"]+)\"[]][[:space:]]*=.*" l) body
      );
    in
    if openIdx == null then
      throw "hammerspoon: no M.localState table in lua/browsers.lua; the supported-bundle assertion cannot be derived"
    else
      map builtins.head keys;

  # profileDir is what makes an unreadable bundle harmful: without one the
  # target wants every window of the app anyway, which is what it gets.
  unsupported = lib.unique (
    map (t: t.bundle) (lib.filter (t: t.profileDir != null && !(lib.elem t.bundle supportedBundles)) browsers)
  );

  # The same collision from the other direction, and on a bundle the Lua reads
  # perfectly well: a target with no profileDir claims every window of its
  # bundle, so pairing one with a profiled target on that bundle means the
  # unprofiled one swallows the profiled one's windows.
  overlapping = lib.unique (
    map (t: t.bundle) (
      lib.filter (
        t: t.profileDir == null && lib.any (o: o.bundle == t.bundle && o.profileDir != null) browsers
      ) browsers
    )
  );

  # The bundle is rsynced to a stable path by nix-darwin's applications
  # activation; the store path is not a usable launch target.
  appPath = "/Applications/Nix Apps/Hammerspoon.app";

  bundleId = "org.hammerspoon.Hammerspoon";

  # What Hammerspoon claims but cannot route. Web types are excluded: they are
  # the default-browser identity on macOS, so moving one away asks to change the
  # browser back, and they reach the picker as file:// URLs anyway. A .url is a
  # shortcut file rather than web content — the picker hands the browser the
  # file instead of following the link inside it.
  restorableExts = "txt text url";

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

  luaStr = import ./lua-str.nix;

  # One source of truth, so the picker rows and the hotkeys cannot drift.
  # Assembled line by line because this file is read when the picker misbehaves,
  # and its indentation should not depend on how nix strips a here-doc.
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
  initLua = checkedLua "hammerspoon-init.lua" (import ./stub.nix { inherit cfgDir; });
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

  options.local.browsers.claimDefaultHandler = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Make Hammerspoon the system handler for http and https, so clicked links
      reach the router.

      Hammerspoon's Info.plist also claims html, txt, url and `*`, which macOS
      transfers along with the browser. Web types are left with it — they open
      as file:// URLs and reach the picker — but the rest are put back.
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
      # Degrades silently otherwise: with no profile list every window of the
      # bundle matches every target naming it, so two of them fight over one.
      {
        assertion = overlapping == [ ];
        message =
          "local.browsers.targets: ${lib.concatStringsSep ", " overlapping} has both a target with no "
          + "profileDir and one with a profileDir. The first claims every window of the bundle, "
          + "including the second's, so give every target on a bundle a profileDir.";
      }
      {
        assertion = unsupported == [ ];
        message =
          "local.browsers.targets: profileDir is set on ${lib.concatStringsSep ", " unsupported}, "
          + "whose profile list lua/browsers.lua cannot read. It knows "
          + "${lib.concatStringsSep ", " supportedBundles}; add this browser's Local State path to "
          + "M.localState there, or drop profileDir to accept every window of the bundle.";
      }
    ];

    # systemPackages, not home.packages: only that is rsynced into
    # /Applications/Nix Apps, which the TCC grant depends on.
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

    system.activationScripts.postActivation.text = lib.mkAfter (
      ''
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

        # -a makes `hs` exit rather than raise a Launch/Cancel alert that
        # nothing under launchctl can answer. It is absent from `hs -h` but
        # documented in hs.man. A failed probe counts as a mismatch, since an
        # instance predating hs.ipc cannot answer at all.
        have="$(asUser ${hammerspoon}/bin/hs -a -t 5 -c 'print(hs.configdir)' 2>/dev/null || true)"

        if [ "$have" = '${cfgDir}' ]; then
          asUser ${hammerspoon}/bin/hs -a -t 5 -c 'hs.reload()' >/dev/null 2>&1 || true
        else
          # Shutdown handlers can outlast a fixed sleep, and `open -a` on a
          # live instance only activates it.
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
              # The one place that genuinely runs with no instance, so the
              # process check is made here rather than inherited.
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
        # The login item starts this bundle at login, so a missing process
        # means it was quit, not that it was never configured.
        echo "  hammerspoon: not running; start ${appPath} to pick up the new config." >&2
      fi
      ''
      + lib.optionalString config.local.browsers.claimDefaultHandler ''

      if [ -n "''${DRY_RUN:-}" ] || /bin/ps -o args= -p "$PPID" 2>/dev/null | /usr/bin/grep -q -- ' --dry-run'; then
        :
      elif ! /usr/bin/pgrep -qx Hammerspoon >/dev/null 2>&1; then
        echo "  hammerspoon: not running; cannot claim the http handler." >&2
      else
        hsUid2="$(/usr/bin/id -u ${user})"
        asUser2() {
          /bin/launchctl asuser "$hsUid2" /usr/bin/sudo -u ${user} --set-home "$@"
        }
        handlerFor() {
          asUser2 ${pkgs.duti}/bin/duti -x "$1" 2>/dev/null | /usr/bin/tail -1 || true
        }

        # duti, because hs.urlevent.setDefaultHandler fails silently on macOS
        # 26.6.2 — it reports success and leaves the handler unchanged.
        current="$(asUser2 ${hammerspoon}/bin/hs -a -t 10 -c 'print(hs.urlevent.getDefaultHandler("http"))' </dev/null 2>/dev/null | /usr/bin/tail -1 || true)"

        if [ "$current" != '${bundleId}' ]; then
          echo "  hammerspoon: claiming the http handler (macOS will ask you to confirm)" >&2

          for ext in ${restorableExts}; do
            eval "was_$ext=\"$(handlerFor "$ext")\""
          done

          # https follows http, and duti returns -54 for it either way.
          asUser2 ${pkgs.duti}/bin/duti -s '${bundleId}' http >/dev/null 2>&1 || true

          # Wait for the dialog to be answered before undoing anything, or the
          # restore lands first and the answer re-takes the types.
          for _ in $(/usr/bin/seq 1 30); do
            now="$(asUser2 ${hammerspoon}/bin/hs -a -t 10 -c 'print(hs.urlevent.getDefaultHandler("http"))' </dev/null 2>/dev/null | /usr/bin/tail -1 || true)"
            [ "$now" = '${bundleId}' ] && break
            /bin/sleep 1
          done

          if [ "$now" = '${bundleId}' ]; then
            /bin/sleep 2
            for ext in ${restorableExts}; do
              eval "prev=\$was_$ext"
              [ -n "$prev" ] || continue
              [ "$prev" = '${bundleId}' ] && continue
              [ "$(handlerFor "$ext")" = '${bundleId}' ] || continue
              echo "  hammerspoon: returning .$ext to $prev" >&2
              asUser2 ${pkgs.duti}/bin/duti -s "$prev" ".$ext" all >/dev/null 2>&1 || true
            done
          else
            echo "  hammerspoon: handler unchanged; nothing to undo." >&2
          fi
        fi
        fi
      ''
    );
  };
}
