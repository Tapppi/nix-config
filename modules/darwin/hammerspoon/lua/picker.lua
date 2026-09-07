-- The link picker: one keypress chooses which browser profile opens a URL.
--
-- hs.hotkey.modal rather than hs.chooser, which takes focus — unusable when the
-- link was clicked from inside another application.
--
-- While entered, a modal swallows its keys from every application, so every
-- path out exits it and a timer guarantees an exit if none of them run.

local M = {}

local browsers = require("browsers")

-- Long enough to read the rows, short enough that a modal entered by mistake
-- returns the keyboard quickly. Refreshed by every link that joins the queue.
M.timeout = 15

-- The refresh above has no fixed point on its own: links arriving faster than
-- the countdown would hold every bound key machine-wide for as long as they
-- kept coming. This is the longest one picker can hold the keyboard, whatever
-- arrives.
M.maxHold = 60

local state = { modal = nil, alert = nil, queue = {}, timer = nil, ceiling = nil }

local function dismiss()
  if state.timer then
    state.timer:stop()
    state.timer = nil
  end
  if state.ceiling then
    state.ceiling:stop()
    state.ceiling = nil
  end
  if state.alert then
    hs.alert.closeSpecific(state.alert)
    state.alert = nil
  end
  if state.modal then
    state.modal:exit()
  end
end

local function drain()
  local urls = state.queue
  state.queue = {}
  return urls
end

local function choose(target)
  -- Dismiss before launching: releasing the keyboard matters more than the
  -- link, and a failure below must not leave the modal entered.
  dismiss()
  for _, url in ipairs(drain()) do
    browsers.launch(target, url)
  end
end

--- What both timers do when they run out: route rather than drop, because a
--- dropped link is invisible and leaves the user with nothing.
local function expire()
  local fallback = browsers.targets[1]
  if fallback then
    choose(fallback)
  else
    dismiss()
    drain()
  end
end

--- Put the queue on screen and hold the keyboard until something answers it.
---
--- Fallible: the profile names are read off disk. present() drains the queue if
--- any of this raises.
local function offer()
  -- Reopened so the queue count is visible.
  local reopening = state.alert ~= nil
  if reopening then
    hs.alert.closeSpecific(state.alert)
    state.alert = nil
  end

  local rows = {}
  for _, target in ipairs(browsers.targets) do
    rows[#rows + 1] = target.key .. "   " .. browsers.label(target)
  end
  if #state.queue > 1 then
    rows[#rows + 1] = ""
    rows[#rows + 1] = #state.queue .. " links queued"
  end
  rows[#rows + 1] = ""
  rows[#rows + 1] = "esc   cancel"

  -- Outlive the timeout, so the modal is never entered with nothing on screen
  -- to explain why the keyboard is behaving oddly.
  -- No screen argument: hs.alert scans optional arguments with ipairs, so a nil
  -- would truncate the scan and drop the duration to 2s while the modal held
  -- the keyboard for the full timeout.
  state.alert = hs.alert.show(table.concat(rows, "\n"), {
    textSize = 18,
    radius = 8,
  }, M.timeout + 1)

  -- Armed before the modal is entered, so the modal cannot outlive it. The
  -- countdown belongs to the newest link, so it restarts; the ceiling belongs
  -- to the picker and is armed once.
  if state.timer then
    state.timer:stop()
  end
  state.timer = hs.timer.doAfter(M.timeout, expire)
  if not state.ceiling then
    state.ceiling = hs.timer.doAfter(M.maxHold, expire)
  end

  if reopening then
    return
  end

  state.modal:enter()
end

--- Bind the modal once, at load. Rebinding per link would leak a hotkey set
--- for every URL opened.
function M.setup()
  if state.modal then
    return
  end

  state.modal = hs.hotkey.modal.new()

  for _, target in ipairs(browsers.targets) do
    state.modal:bind({}, target.key, function()
      choose(target)
    end)
  end

  state.modal:bind({}, "escape", function()
    dismiss()
    drain()
  end)
end

--- Offer the targets for a URL.
---
--- A second link joins the queue rather than replacing it, so a burst of clicks
--- opens all of them rather than all but one.
function M.present(url)
  -- With no targets the timeout would discard the link. Raising hands it to
  -- the stub's fallback instead.
  if #browsers.targets == 0 then
    error("no browser targets configured", 0)
  end

  -- A link can arrive through the stub's callback even when init.lua failed to
  -- load, and an unbound modal would throw on every click.
  M.setup()

  -- Whether a picker is already up decides what a failure below may discard.
  local reopening = state.timer ~= nil

  state.queue[#state.queue + 1] = url

  -- Every raise out of offer() reaches the stub's fallback, which opens the
  -- link that raised. The queue must not still hold it, or the next keypress
  -- opens it a second time.
  local offered, err = pcall(offer)
  if not offered then
    if reopening then
      -- A picker was already on screen with links behind it. Those are still
      -- answerable under the timers it armed, so only the link that raised is
      -- given up — dropping the rest would lose them with nothing on screen to
      -- say so, which is the one failure this module exists to avoid.
      for i = #state.queue, 1, -1 do
        if state.queue[i] == url then
          table.remove(state.queue, i)
          break
        end
      end
    else
      -- Nothing was on screen, so there is no picker to answer: release the
      -- keyboard and let the fallback have the link.
      dismiss()
      drain()
    end
    error(err, 0)
  end
end

return M
