-- The link picker: one keypress chooses which browser profile opens a URL.
--
-- hs.hotkey.modal rather than hs.chooser. A chooser cannot commit on a single
-- keypress, and it TAKES focus — which is the disqualifying half, since a link
-- is clicked from inside another application. A modal binds real hotkeys, so
-- the choice is made while that application still holds focus.
--
-- The danger of a modal is the mirror of its usefulness: while entered, it
-- swallows its keys from every application. A modal left entered would make
-- those letters untypeable machine-wide, so every path out of here exits it,
-- and a timer guarantees an exit even if none of them run.

local M = {}

local browsers = require("browsers")

-- Long enough to read the rows, short enough that a modal entered by mistake
-- returns the keyboard quickly.
M.timeout = 10

local state = { modal = nil, alert = nil, queue = {}, timer = nil }

local function dismiss()
  if state.timer then
    state.timer:stop()
    state.timer = nil
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
--- A second link arriving while the picker is up joins the queue rather than
--- replacing it or opening a second picker: one choice then opens all of them.
--- Clicking several links in a burst is the case this serves; the alternative
--- would silently drop every link but one.
function M.present(url)
  -- With no targets there is nothing to offer and the timeout below would
  -- discard the link without opening anything. Raising instead hands it to the
  -- stub's hard-coded fallback, which is the whole point of that fallback.
  -- Reachable in practice: generated/targets.lua is placed by build-switch,
  -- but the hand-edited tree hot-reloads on any write, so merging this branch
  -- loads the picker before the generated file exists.
  if #browsers.targets == 0 then
    error("no browser targets configured", 0)
  end

  -- Idempotent, and called here as well as from init.lua: a link can arrive
  -- through the stub's callback even when the hand-edited config failed to
  -- load, and an unbound modal would throw on every click.
  M.setup()

  state.queue[#state.queue + 1] = url

  -- Reopening rather than returning early, so the queue count is visible. The
  -- timer is deliberately NOT restarted: the first link's clock governs, or a
  -- steady trickle of links could hold the keyboard indefinitely.
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
  -- The screen argument is deliberately omitted rather than passed. hs.alert
  -- scans its optional arguments with ipairs, so a nil there would truncate the
  -- scan and silently drop the duration back to the 2s default — the alert would
  -- vanish while the modal still held the keyboard for the full timeout. It
  -- defaults to the main screen internally anyway.
  state.alert = hs.alert.show(table.concat(rows, "\n"), {
    textSize = 18,
    radius = 8,
  }, M.timeout + 1)

  if reopening then
    return
  end

  -- Armed before entering, so the modal cannot outlive it.
  state.timer = hs.timer.doAfter(M.timeout, function()
    local fallback = browsers.targets[1]
    if fallback then
      choose(fallback)
    else
      dismiss()
      drain()
    end
  end)

  -- If entering fails, the armed timer would still fire and open the link a
  -- second time, on top of whatever the stub's fallback already did. Tear the
  -- whole thing down first, then let the caller's pcall see the error.
  local entered, err = pcall(function()
    state.modal:enter()
  end)
  if not entered then
    dismiss()
    drain()
    error(err, 0)
  end
end

return M
