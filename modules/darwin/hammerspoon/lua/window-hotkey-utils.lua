-- Window management utilities for hotkey-driven app toggling and layout.

local M = {}

M.hyper = { "cmd", "ctrl", "alt", "shift" }
M.us = "com.apple.keylayout.US"
M.fiProg = "org.sil.ukelele.keyboardlayout.finnishprogrammerkeyboard.finnish-prog"

-- ─── Input source ─────────────────────────────────────────────────

-- Retried once: macOS drops the first set (Hammerspoon #1429).
function M.setInputSource(sourceID)
  hs.keycodes.currentSourceID(sourceID)
  hs.timer.doAfter(0.05, function()
    if hs.keycodes.currentSourceID() ~= sourceID then
      hs.keycodes.currentSourceID(sourceID)
    end
  end)
end

-- ─── Screen helpers ───────────────────────────────────────────────

function M.activeScreen()
  return hs.mouse.getCurrentScreen() or hs.screen.primaryScreen()
end

function M.isWidescreen(screen)
  local f = screen:frame()
  return f.w / f.h > 2.2
end

function M.builtInScreen()
  for _, s in ipairs(hs.screen.allScreens()) do
    if (s:name() or ""):find("Built%-in") then
      return s
    end
  end
  return nil
end

-- ─── Frame builders (for custom layout functions) ─────────────────

function M.fullFrame(screen)
  return screen:frame()
end

function M.leftFrame(screen, fraction, margin)
  margin = margin or 0
  local f = screen:frame()
  return hs.geometry.rect(f.x + margin, f.y + margin, math.floor(f.w * fraction) - margin, f.h - 2 * margin)
end

function M.rightFrame(screen, fraction, margin)
  margin = margin or 0
  local f = screen:frame()
  local w = math.floor(f.w * fraction)
  return hs.geometry.rect(f.x + f.w - w, f.y + margin, w - margin, f.h - 2 * margin)
end

function M.centerFrame(screen, win)
  local f = screen:frame()
  local wf = win:frame()
  return hs.geometry.rect(f.x + (f.w - wf.w) / 2, f.y + (f.h - wf.h) / 2, wf.w, wf.h)
end

-- ─── Layout factories ─────────────────────────────────────────────
-- Each returns function(screen, win) → hs.geometry.rect, compatible
-- with bindToggle's layoutFn signature.

--- Sidebar: fraction of screen width on one side.
--- On widescreen the window occupies `fraction` of the width on `side`,
--- with `margin` on the outer edges (inner split edge has no margin so
--- adjacent sidebars tile flush).
--- On non-widescreen the window fills the screen with margin on all sides.
function M.sidebar(side, fraction, margin)
  margin = margin or 3
  return function(screen)
    if not M.isWidescreen(screen) then
      local f = screen:frame()
      return hs.geometry.rect(f.x + margin, f.y + margin, f.w - 2 * margin, f.h - 2 * margin)
    end
    if side == "right" then
      return M.rightFrame(screen, fraction, margin)
    end
    return M.leftFrame(screen, fraction, margin)
  end
end

--- Center: preserve current window size, center on active screen.
function M.center()
  return function(screen, win)
    return M.centerFrame(screen, win)
  end
end

--- Corner: fixed pixel dimensions anchored to a screen corner.
function M.corner(position, width, height, margin)
  margin = margin or 10
  return function(screen)
    local f = screen:frame()
    local x, y
    if position == "topleft" or position == "bottomleft" then
      x = f.x + margin
    else
      x = f.x + f.w - width - margin
    end
    if position == "topleft" or position == "topright" then
      y = f.y + margin
    else
      y = f.y + f.h - height - margin
    end
    return hs.geometry.rect(x, y, width, height)
  end
end

-- ─── Window helpers ───────────────────────────────────────────────

--- Position a window with a layout function, if there is anything to do.
---
--- A nil layoutFn means "never reposition", which is how toggle-only bindings
--- are expressed.
function M.applyLayout(win, layoutFn)
  if not win or not layoutFn then
    return false
  end
  win:setFrame(layoutFn(M.activeScreen(), win))
  return true
end

--- Is `win` one of `windows`?
---
--- hs.window:id() is nil for a window whose AX id cannot be read, and Chromium
--- keeps several such helper windows per real one. Comparing two nils would
--- report an unrelated window as a match, so a window with no id is never one.
function M.containsWindow(windows, win)
  local id = win and win:id()
  if not id then
    return false
  end
  for _, w in ipairs(windows) do
    if w:id() == id then
      return true
    end
  end
  return false
end

-- ─── Hotkey binding ───────────────────────────────────────────────
-- Bind a hyper+key hotkey that toggles an app and positions its window.
--
-- layoutFn(screen, win) → hs.geometry.rect
--   Pass nil to toggle/focus without ever repositioning the window.
--
-- opts.inputSource  — source ID to set on activation (default: M.fiProg)
-- opts.watchCreate  — auto-position every new window (for terminal apps)

M._filters = {}

function M.bindToggle(key, bundleID, layoutFn, opts)
  opts = opts or {}
  -- Explicit nil test: the `and`/`or` idiom cannot carry a falsey value, so
  -- `inputSource = false` would collapse to the default.
  local inputSource = M.fiProg
  if opts.inputSource ~= nil then
    inputSource = opts.inputSource
  end

  -- Track whether the filter was actually created: nameForBundleID returns nil
  -- for an app LaunchServices has not registered, and the option alone is no
  -- proof the filter exists.
  local watching = false
  if opts.watchCreate then
    local appName = hs.application.nameForBundleID(bundleID)
    if appName then
      local wf = hs.window.filter.new(appName)
      wf:subscribe(hs.window.filter.windowCreated, function(win)
        M.applyLayout(win, layoutFn)
        win:focus()
      end)
      M._filters[bundleID] = wf
      watching = true
    end
  end

  hs.hotkey.bind(M.hyper, key, function()
    local app = hs.application.get(bundleID)

    if not app or #app:allWindows() == 0 then
      hs.application.launchOrFocusByBundleID(bundleID)
      if inputSource then
        M.setInputSource(inputSource)
      end
      -- The window does not exist yet, so position it once the launch has
      -- produced one.
      if layoutFn and not watching then
        hs.timer.doAfter(1.5, function()
          local a = hs.application.get(bundleID)
          if not a then
            return
          end
          M.applyLayout(a:mainWindow(), layoutFn)
        end)
      end
      return
    end

    local win = app:mainWindow()

    if win and app:isFrontmost() then
      app:hide()
      return
    end

    if win then
      M.applyLayout(win, layoutFn)
      app:unhide()
      win:focus()
    else
      -- allWindows() counts minimized windows but mainWindow() returns nil
      -- unless one is AXMain.
      hs.application.launchOrFocusByBundleID(bundleID)
    end

    if inputSource then
      M.setInputSource(inputSource)
    end
  end)
end

return M
