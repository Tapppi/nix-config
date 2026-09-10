-- A stub `hs` large enough to load the browser modules and exercise their
-- logic off-machine. Hammerspoon embeds Lua but its API is native, so nothing
-- here can be required outside the app — this substitutes the few calls the
-- modules make and records what they did.
--
-- It is not a Hammerspoon simulator. It covers the pure decisions: which
-- window belongs to which profile, what argv a launch produces, and how the
-- picker sequences. Anything involving real key capture or a real window
-- server has to be tested on the machine.

local recorded = {
  launches = {},
  alerts = {},
  binds = {},
  entered = 0,
  exited = 0,
  focused = {},
  minimized = {},
  unminimized = {},
  notified = {},
  launchOrFocus = {},
  timers = {},
  timersStopped = 0,
}
_G.RECORDED = recorded

--- opts: { visible = false, minimized = true, app = <app stub> }
function _G.mkwin(id, title, opts)
  opts = opts or {}
  local minimized = opts.minimized or false
  local owner = opts.app
  local win
  win = {
    id = function()
      return id
    end,
    title = function()
      return title
    end,
    isVisible = function()
      return opts.visible ~= false and not minimized
    end,
    isMinimized = function()
      return minimized
    end,
    -- Chromium gives every window a companion status-bar window. Those are
    -- not standard, have no id and are never minimized, so a fixture needs to
    -- be able to produce one.
    isStandard = function()
      return opts.standard ~= false
    end,
    unminimize = function()
      minimized = false
      recorded.unminimized[#recorded.unminimized + 1] = id
    end,
    minimize = function()
      minimized = true
      recorded.minimized[#recorded.minimized + 1] = id
    end,
    application = function()
      return owner
    end,
    -- mkapp calls this, so a window and its application can refer to each
    -- other without the fixture having to build them in dependency order.
    _setApp = function(app)
      owner = app
    end,
    focus = function()
      recorded.focused[#recorded.focused + 1] = id
    end,
    setFrame = function() end,
  }
  return win
end

--- An application owning a fixed set of windows.
function _G.mkapp(windows)
  local app
  app = {
    allWindows = function()
      return windows
    end,
    visibleWindows = function()
      local out = {}
      for _, w in ipairs(windows) do
        if w:isVisible() then
          out[#out + 1] = w
        end
      end
      return out
    end,
    hide = function()
      recorded.hidden = (recorded.hidden or 0) + 1
    end,
    unhide = function()
      recorded.unhidden = (recorded.unhidden or 0) + 1
    end,
  }
  for _, w in ipairs(windows) do
    w._setApp(app)
  end
  return app
end

-- A single fake screen, wide enough that the sidebar layouts take their
-- widescreen branch.
_G.SCREEN = {
  frame = function()
    return { x = 0, y = 0, w = 3440, h = 1440 }
  end,
  name = function()
    return "Fake Display"
  end,
}

_G.APPS = {}
_G.NAMES = {}
_G.STAT = {}
_G.JSON = {}
_G.PATHS = {}
_G.FOCUSED = nil

_G.hs = {
  fs = {
    attributes = function(path)
      return _G.STAT[path]
    end,
  },
  json = {
    read = function(path)
      return _G.JSON[path]
    end,
  },
  application = {
    applicationsForBundleID = function(bundle)
      return _G.APPS[bundle] or {}
    end,
    pathForBundleID = function(bundle)
      return _G.PATHS[bundle]
    end,
    nameForBundleID = function(bundle)
      return _G.NAMES and _G.NAMES[bundle] or nil
    end,
    get = function(bundle)
      local apps = _G.APPS[bundle]
      return apps and apps[1] or nil
    end,
    launchOrFocusByBundleID = function(bundle)
      recorded.launchOrFocus[#recorded.launchOrFocus + 1] = bundle
      return true
    end,
  },
  window = {
    focusedWindow = function()
      return _G.FOCUSED
    end,
    -- init.lua builds window filters for the per-app layout forcing. They are
    -- inert here: the point is that the file loads and its hotkeys bind, not
    -- that focus tracking works.
    filter = {
      windowFocused = "windowFocused",
      windowNotVisible = "windowNotVisible",
      windowCreated = "windowCreated",
      new = function()
        local f = {}
        function f:subscribe()
          return self
        end
        function f:setAppFilter()
          return self
        end
        return f
      end,
    },
  },
  keycodes = {
    currentSourceID = function(set)
      if set then
        recorded.inputSource = set
        return nil
      end
      return "com.apple.keylayout.US"
    end,
  },
  notify = {
    new = function(spec)
      return {
        send = function()
          recorded.notified[#recorded.notified + 1] = spec and spec.title or "?"
          -- The stub swallows a config load failure into its own pcall and
          -- reports it only here, so without the body a broken init.lua fails
          -- with no reason attached.
          recorded.notifiedText = spec and spec.informativeText or nil
        end,
      }
    end,
  },
  mouse = {
    getCurrentScreen = function()
      return _G.SCREEN
    end,
  },
  geometry = {
    rect = function(x, y, w, h)
      return { x = x, y = y, w = w, h = h }
    end,
  },
  pathwatcher = {
    new = function(path, fn)
      if _G.PATHWATCHER_RAISES then
        error("pathwatcher unavailable")
      end
      recorded.watched = { path = path, fn = fn }
      return {
        start = function()
          recorded.watcherStarted = true
        end,
      }
    end,
  },
  -- The stub registers the http callback and reaches for a fallback when
  -- dispatch raises. Both are recorded rather than performed.
  urlevent = {
    openURLWithBundle = function(url, bundle)
      recorded.fallbackOpened = { url = url, bundle = bundle }
      return true
    end,
  },
  reload = function()
    recorded.reloaded = (recorded.reloaded or 0) + 1
  end,
  screen = {
    mainScreen = function()
      return _G.SCREEN
    end,
    primaryScreen = function()
      return _G.SCREEN
    end,
    allScreens = function()
      return { _G.SCREEN }
    end,
  },
  task = {
    new = function(command, _callback, args)
      return {
        start = function()
          recorded.launches[#recorded.launches + 1] = { command = command, args = args }
          return true
        end,
      }
    end,
  },
  alert = {
    -- The real signature is (str, style, screen, duration) and hs.alert
    -- shuffles: it scans the optional arguments and takes the first number as
    -- the duration. Modelling the shuffle rather than a fixed position means
    -- the duration assertion tests behaviour, not argument order — otherwise a
    -- correct refactor to the four-argument form would record a screen table
    -- as the duration and fail with a nonsense message.
    show = function(text, ...)
      local duration, style
      for _, arg in ipairs({ ... }) do
        if type(arg) == "number" and not duration then
          duration = arg
        elseif type(arg) == "table" and not style then
          style = arg
        end
      end
      recorded.alerts[#recorded.alerts + 1] = text
      recorded.alertShown = { text = text, style = style, duration = duration }
      return "alert-" .. #recorded.alerts
    end,
    closeSpecific = function(id)
      recorded.closed = id
    end,
  },
  timer = {
    -- Records enough to assert that a timer was cancelled, not merely that one
    -- was created. dismiss() stopping the timeout timer is the property that
    -- keeps a modal from outliving its alert, so a stub whose stop() does
    -- nothing would make that untestable.
    doAfter = function(seconds, fn)
      local t = { seconds = seconds, fn = fn, stopped = false }
      function t:stop()
        self.stopped = true
        recorded.timersStopped = recorded.timersStopped + 1
      end
      recorded.timers[#recorded.timers + 1] = t
      return t
    end,
  },
  hotkey = {
    bind = function(_mods, key, fn)
      recorded.binds["hyper:" .. key] = fn
    end,
    modal = {
      new = function()
        local modal = {}
        function modal:bind(_mods, key, fn)
          recorded.binds[key] = fn
          return self
        end
        function modal:enter()
          recorded.entered = recorded.entered + 1
        end
        function modal:exit()
          recorded.exited = recorded.exited + 1
        end
        return modal
      end,
    },
  },
}
