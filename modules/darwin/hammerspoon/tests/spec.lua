-- Behaviour tests for the browser modules, run by `nix flake check`.
--
-- The syntax gate next to this one proves the Lua parses. This proves it
-- decides correctly — above all that a window is matched to the right profile,
-- since a regression there routes a client's links into the wrong browser
-- without any visible symptom.

dofile(HARNESS)

local failures = 0

local function check(name, condition, detail)
  if condition then
    print("  ok   " .. name)
  else
    print("  FAIL " .. name .. (detail and (" -- " .. detail) or ""))
    failures = failures + 1
  end
end

local chrome = os.getenv("HOME") .. "/Library/Application Support/Google/Chrome/Local State"
local brave = os.getenv("HOME") .. "/Library/Application Support/BraveSoftware/Brave-Browser/Local State"

STAT[chrome] = { mode = "file", modification = 1, size = 10 }
STAT[brave] = { mode = "file", modification = 1, size = 10 }

-- Shaped like the real thing: signed-in profiles carry gaia_given_name, and a
-- default-named one does not.
JSON[chrome] = {
  profile = {
    info_cache = {
      ["Default"] = { name = "Your Chrome" },
      ["Profile 1"] = { name = "acme.example", gaia_given_name = "Tapani" },
      ["Profile 2"] = { name = "Client Co", gaia_given_name = "Tapani" },
    },
  },
}
JSON[brave] = { profile = { info_cache = { ["Default"] = { name = "Personal" } } } }

local browsers = require("browsers")
local personal, company, client = browsers.targets[1], browsers.targets[2], browsers.targets[3]

print("profile names")
check("targets load from the generated table", #browsers.targets == 3, "#=" .. #browsers.targets)
check(
  "label gains the runtime profile name",
  browsers.label(company) == "Company — acme.example",
  browsers.label(company)
)
check(
  "label stays bare when the name matches the label",
  browsers.label(personal) == "Personal",
  browsers.label(personal)
)
check(
  "an unknown profile falls back to its directory",
  (function()
    local name, found = browsers.displayName({ bundle = "com.google.Chrome", profileDir = "Profile 9" })
    return name == "Profile 9" and found == false
  end)()
)
check(
  "a browser with no Local State path degrades quietly",
  (function()
    local name, found = browsers.displayName({ bundle = "org.mozilla.firefox", profileDir = "default" })
    return name == "default" and found == false
  end)()
)
check(
  "an unreadable Local State keeps the last known good",
  (function()
    local before = browsers.label(company)
    local saved = JSON[chrome]
    JSON[chrome] = nil
    STAT[chrome] = { mode = "file", modification = 2, size = 11 }
    local after = browsers.label(company)
    -- Restored, or every later Chrome read in this file is served from the
    -- stale-cache fallback rather than exercising a real parse.
    JSON[chrome] = saved
    STAT[chrome] = { mode = "file", modification = 3, size = 12 }
    return before == after
  end)(),
  "stale name should survive a failed read"
)

print("shared window helpers")
local whu = require("window-hotkey-utils")
check(
  "containsWindow never matches on a nil id",
  (function()
    -- Chromium keeps helper windows whose AX id cannot be read. Comparing two
    -- nils would report an unrelated window as a match.
    local noId = mkwin(nil, "helper")
    local other = mkwin(nil, "another helper")
    return whu.containsWindow({ noId }, other) == false
  end)()
)
check(
  "containsWindow matches by id, not identity",
  (function()
    return whu.containsWindow({ mkwin(70, "a") }, mkwin(70, "different title")) == true
      and whu.containsWindow({ mkwin(70, "a") }, mkwin(71, "a")) == false
  end)()
)
check(
  "applyLayout is a no-op without a layout function",
  (function()
    -- nil layoutFn is how a toggle-only binding is expressed, so this must not
    -- reposition rather than erroring.
    return whu.applyLayout(mkwin(72, "x"), nil) == false and whu.applyLayout(nil, function() end) == false
  end)()
)

print("window matching")
local chromeWins = {
  mkwin(1, "Some page - Google Chrome - Tapani (acme.example)"),
  mkwin(2, "Other - Google Chrome - Tapani (Client Co)"),
}
-- An automation copy driven with its own --user-data-dir. Same bundle id, same
-- bundle path, and its titles carry no profile suffix at all.
local automationWins = { mkwin(3, "devtools harness - Google Chrome") }
APPS["com.google.Chrome"] = { mkapp(chromeWins), mkapp(automationWins) }
APPS["com.brave.Browser"] = { mkapp({ mkwin(10, "x - Brave"), mkwin(11, "y - Brave") }) }

check(
  "a non-standard companion window is never a browser window",
  (function()
    -- Chromium gives every window a status-bar companion. It has no id and is
    -- never minimized, so unfiltered it is selected as "the" window whenever the
    -- real one is minimized, and the hotkey goes dead.
    local real = mkwin(40, "page - Brave", { minimized = true })
    local helper = mkwin(nil, "page - Brave", { standard = false })
    APPS["com.brave.Browser"] = { mkapp({ helper, real }) }
    local found = browsers.windowsFor(personal)
    APPS["com.brave.Browser"] = { mkapp({ mkwin(10, "x - Brave"), mkwin(11, "y - Brave") }) }
    return #found == 1 and found[1]:id() == 40
  end)()
)
check(
  "one profile name being a suffix of another does not steal its windows",
  (function()
    STAT[brave] = { mode = "file", modification = 9, size = 90 }
    JSON[brave] = {
      profile = {
        info_cache = {
          -- The LONGER name sits on the earlier-sorting directory on purpose,
          -- so "last match wins" and "longest match wins" disagree. With them
          -- the other way round the two rules are indistinguishable here.
          ["Default"] = { name = "Client Work" },
          ["Profile 7"] = { name = "Work" },
        },
      },
    }
    APPS["com.brave.Browser"] = { mkapp({ mkwin(50, "page - Brave - Client Work") }) }
    local longer = browsers.windowsFor({ bundle = "com.brave.Browser", profileDir = "Default", label = "C" })
    local shorter = browsers.windowsFor({ bundle = "com.brave.Browser", profileDir = "Profile 7", label = "W" })
    STAT[brave] = { mode = "file", modification = 10, size = 91 }
    JSON[brave] = { profile = { info_cache = { ["Default"] = { name = "Personal" } } } }
    APPS["com.brave.Browser"] = { mkapp({ mkwin(10, "x - Brave"), mkwin(11, "y - Brave") }) }
    return #shorter == 0 and #longer == 1
  end)(),
  "longest matching tail must win"
)
check(
  "a profile with no GAIA name is matched by its bare name",
  (function()
    APPS["com.google.Chrome"] = { mkapp({ mkwin(60, "page - Google Chrome - Your Chrome") }) }
    local found = browsers.windowsFor({ bundle = "com.google.Chrome", profileDir = "Default", label = "D" })
    APPS["com.google.Chrome"] = { mkapp(chromeWins), mkapp(automationWins) }
    return #found == 1 and found[1]:id() == 60
  end)()
)

local companyWins = browsers.windowsFor(company)
local clientWins = browsers.windowsFor(client)
check("company matches only its own window", #companyWins == 1 and companyWins[1]:id() == 1, "#=" .. #companyWins)
check("client matches only its own window", #clientWins == 1 and clientWins[1]:id() == 2, "#=" .. #clientWins)
check(
  "a suffix-less automation window matches no profile",
  (function()
    for _, w in ipairs(companyWins) do
      if w:id() == 3 then
        return false
      end
    end
    for _, w in ipairs(clientWins) do
      if w:id() == 3 then
        return false
      end
    end
    return true
  end)(),
  "Chrome knows 3 profiles, so a bare title is unknown, not Default"
)
check("a single-profile browser matches all its windows", #browsers.windowsFor(personal) == 2)

check(
  "a bundle with no Local State path is reported as unknown, not as one profile",
  (function()
    local _, count, known = browsers.profiles("com.example.NotABrowser")
    return count == 0 and known == false
  end)(),
  "otherwise every window matches every target"
)
check(
  "a readable single-profile browser is reported as known",
  (function()
    local _, count, known = browsers.profiles("com.brave.Browser")
    return count == 1 and known == true
  end)()
)

print("toggling")
check(
  "a minimized window is restored, not just focused",
  (function()
    local win = mkwin(20, "z - Brave", { minimized = true })
    local app = mkapp({ win })
    APPS["com.brave.Browser"] = { app }
    FOCUSED = nil
    local before = #RECORDED.launches
    browsers.toggle(personal, nil)
    -- allWindows counts minimized windows, so without unminimize this focuses a
    -- window the window server will not raise and the hotkey goes dead.
    return #RECORDED.unminimized == 1
      and RECORDED.unminimized[1] == 20
      and RECORDED.focused[#RECORDED.focused] == 20
      and #RECORDED.launches == before
  end)()
)
check(
  "hiding is used when the app has no other visible window",
  (function()
    local win = mkwin(21, "only - Brave")
    local app = mkapp({ win })
    APPS["com.brave.Browser"] = { app }
    FOCUSED = win
    local hiddenBefore = RECORDED.hidden or 0
    browsers.toggle(personal, nil)
    return (RECORDED.hidden or 0) == hiddenBefore + 1 and #RECORDED.minimized == 0
  end)()
)
check(
  "minimizing is used when another profile's window is still visible",
  (function()
    local mine = mkwin(22, "Some page - Google Chrome - Tapani (acme.example)")
    local theirs = mkwin(23, "Other - Google Chrome - Tapani (Client Co)")
    APPS["com.google.Chrome"] = { mkapp({ mine, theirs }) }
    FOCUSED = mine
    local hiddenBefore = RECORDED.hidden or 0
    browsers.toggle(company, nil)
    -- app:hide() would take the client's window down with it.
    return #RECORDED.minimized == 1 and RECORDED.minimized[1] == 22 and (RECORDED.hidden or 0) == hiddenBefore
  end)()
)
check(
  "an empty profile with no windows launches",
  (function()
    APPS["com.google.Chrome"] = {}
    FOCUSED = nil
    local before = #RECORDED.launches
    browsers.toggle(company, nil)
    return #RECORDED.launches == before + 1
  end)()
)

print("launching")
PATHS["com.google.Chrome"] = "/Applications/Google Chrome.app"
browsers.launch(company, "https://example.com/x")
local launch = RECORDED.launches[#RECORDED.launches]
local argv = table.concat(launch.args, " ")
check("runs open by absolute path", launch.command == "/usr/bin/open")
check("passes -n, without which --args is dropped", launch.args[1] == "-n", argv)
check(
  "targets the app by path when one resolves",
  launch.args[2] == "-a" and launch.args[3] == "/Applications/Google Chrome.app",
  argv
)
check("carries the profile directory", argv:find("--profile%-directory=Profile 1") ~= nil, argv)
check("puts the url last", launch.args[#launch.args] == "https://example.com/x", argv)
check(
  "falls back to the bundle id when no path resolves",
  (function()
    PATHS["com.google.Chrome"] = nil
    browsers.launch(client, nil)
    local l = RECORDED.launches[#RECORDED.launches]
    return l.args[2] == "-b" and l.args[3] == "com.google.Chrome"
  end)()
)
check(
  "omits the url entirely when opening a bare profile",
  (function()
    local l = RECORDED.launches[#RECORDED.launches]
    return l.args[#l.args] == "--profile-directory=Profile 2"
  end)()
)

check(
  "a url on a profile-less target is opened, not passed as argv",
  (function()
    PATHS["com.apple.Safari"] = "/Applications/Safari.app"
    browsers.launch({ bundle = "com.apple.Safari", label = "Safari" }, "https://example.com/s")
    local l = RECORDED.launches[#RECORDED.launches]
    local joined = table.concat(l.args, " ")
    -- open(1): everything after --args is handed to the app as argv and is "not
    -- opened or interpreted by the open tool". Only Chromium reads a URL back
    -- out of argv, so any other browser would drop the link entirely. -n would
    -- also force a real second instance of a browser with no singleton.
    return joined:find("%-%-args") == nil and l.args[1] ~= "-n" and l.args[#l.args] == "https://example.com/s"
  end)()
)
check(
  "omits -n for a target with neither profile nor url",
  (function()
    PATHS["com.apple.Safari"] = "/Applications/Safari.app"
    browsers.launch({ bundle = "com.apple.Safari", label = "Safari" }, nil)
    local l = RECORDED.launches[#RECORDED.launches]
    -- -n on a browser with no singleton to collapse it forces a real second copy.
    return l.args[1] ~= "-n" and l.args[1] == "-a"
  end)()
)

print("picker")
local picker = require("picker")
picker.setup()
check("binds one plain key per target", RECORDED.binds["b"] and RECORDED.binds["v"] and RECORDED.binds["c"] ~= nil)
check("binds escape", RECORDED.binds["escape"] ~= nil)

picker.present("https://one.example")
check("shows an alert for the first link", #RECORDED.alerts == 1)
check("enters the modal once", RECORDED.entered == 1)
check("lists every target", RECORDED.alerts[1]:find("Company") ~= nil, RECORDED.alerts[1])

picker.present("https://two.example")
check("a second link reopens the alert", #RECORDED.alerts == 2)
check("a second link does not re-enter the modal", RECORDED.entered == 1, "entered=" .. RECORDED.entered)
check("a second link shows the queue depth", RECORDED.alerts[2]:find("2 links queued") ~= nil, RECORDED.alerts[2])

local before = #RECORDED.launches
local exitedBefore = RECORDED.exited
local stoppedBefore = RECORDED.timersStopped
RECORDED.binds["v"]()
check("one choice opens every queued link", #RECORDED.launches - before == 2, "delta=" .. (#RECORDED.launches - before))
check("choosing exits the modal", RECORDED.exited == exitedBefore + 1, "delta=" .. (RECORDED.exited - exitedBefore))
-- The timeout timer must be cancelled, not merely dropped. A live timer would
-- fire after the choice and open every queued link a second time.
check("choosing cancels the timeout timer", RECORDED.timersStopped > stoppedBefore, "no timer was stopped")
-- Nothing else asserts the queue is emptied, so choose() could iterate it in
-- place and re-open every earlier link on the next choice.
local afterChoice = #RECORDED.launches
RECORDED.binds["c"]()
check("choosing again opens nothing, because the queue was emptied", #RECORDED.launches == afterChoice)

picker.present("https://three.example")
local afterEscape = #RECORDED.launches
local exitedBeforeEscape = RECORDED.exited
RECORDED.binds["escape"]()
check("escape opens nothing", #RECORDED.launches == afterEscape)
-- Without this, escape could stop dismissing and the modal would stay entered,
-- swallowing b/v/c/escape machine-wide until the timeout fired.
check(
  "escape exits the modal",
  RECORDED.exited == exitedBeforeEscape + 1,
  "delta=" .. (RECORDED.exited - exitedBeforeEscape)
)

picker.present("https://four.example")
check("escape cleared the queue", RECORDED.alerts[#RECORDED.alerts]:find("queued") == nil)
local beforeTimeout = #RECORDED.launches
RECORDED.timerFn()
check("the timeout routes rather than dropping the link", #RECORDED.launches - beforeTimeout == 1)
check("the timeout is bounded", RECORDED.timerAfter and RECORDED.timerAfter <= 30, tostring(RECORDED.timerAfter))

check(
  "an empty target list raises rather than swallowing the link",
  (function()
    local saved = browsers.targets
    browsers.targets = {}
    local ok = pcall(picker.present, "https://lost.example")
    browsers.targets = saved
    -- Raising is what reaches the stub's hard-coded openURLWithBundle fallback.
    return ok == false
  end)()
)

print("router")
local router = require("router")
local beforeRouter = #RECORDED.launches
local alertsBefore = #RECORDED.alerts
-- host is nil for a file:// URL. A router that indexed it would throw here,
-- and the throw would reach the stub's fallback on every single link.
local ok = pcall(router.dispatch, "file", nil, {}, "file:///tmp/x.html", -1)
check("a nil host does not throw", ok)
check("the router does not open anything itself", #RECORDED.launches == beforeRouter)
-- Asserting a delta, not a cumulative count: with `> 0` the check passed even
-- when dispatch did nothing at all, because earlier checks had left alerts
-- behind. present(nil) is also a silent no-op on the queue, so passing the
-- wrong argument has to be caught here too.
check("the router raises exactly one picker", #RECORDED.alerts == alertsBefore + 1)
check(
  "the router hands the picker the full url",
  (function()
    local queuedBefore = #RECORDED.launches
    RECORDED.binds["b"]()
    local l = RECORDED.launches[#RECORDED.launches]
    return #RECORDED.launches == queuedBefore + 1 and l.args[#l.args] == "file:///tmp/x.html"
  end)(),
  "the dispatched url never reached a launch"
)

print("init.lua")
-- Loading the real entry point. It is the file this change rewired, and until
-- now nothing executed it: a typo in the hotkey loop or a renamed helper would
-- pass luac -p and then throw on the machine, leaving no hotkeys at all.
NAMES["com.mitchellh.ghostty"] = "Ghostty"
local loaded, err = pcall(dofile, INITLUA)
check("init.lua loads", loaded, tostring(err))

if loaded then
  local expected = { "s", "k", "i", "f", "x", "j", "m", "d", "z", "b", "v", "c" }
  local missing = {}
  for _, key in ipairs(expected) do
    if not RECORDED.binds["hyper:" .. key] then
      missing[#missing + 1] = key
    end
  end
  check("every hyper hotkey binds", #missing == 0, "missing: " .. table.concat(missing, ","))
  check("calendar moved off c, which is now a browser profile", RECORDED.binds["hyper:x"] ~= nil)
  check(
    "no browser target collides with an app hotkey",
    (function()
      -- The nix assertion only compares targets against each other; it cannot see
      -- this file. hs.hotkey lets the later bind win silently, and the browser
      -- keys bind last — so a collision would kill an app hotkey with no error
      -- and every key in the list above would still test as bound.
      local appKeys = { s = true, k = true, i = true, f = true, x = true, j = true, m = true, d = true, z = true }
      for _, target in ipairs(browsers.targets) do
        if appKeys[target.key] then
          return false
        end
      end
      return true
    end)()
  )
  check(
    "the browser keys come from the target list",
    (function()
      for _, target in ipairs(browsers.targets) do
        if not RECORDED.binds["hyper:" .. target.key] then
          return false
        end
      end
      return true
    end)()
  )
end

if failures == 0 then
  print("\nall checks passed")
  os.exit(0)
end
print("\n" .. failures .. " failed")
os.exit(1)
