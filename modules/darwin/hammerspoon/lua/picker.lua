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

  state.queue[#state.queue + 1] = url

  -- Reopened so the queue count is visible. The timer is not restarted, or a
  -- trickle of links would hold the keyboard indefinitely.
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

  -- Otherwise the armed timer still fires and opens the link a second time, on
  -- top of whatever the stub's fallback already did.
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
