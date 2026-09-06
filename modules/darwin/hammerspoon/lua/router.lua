-- Where an opened link goes.
--
-- Thin on purpose: domain rules, rewriting and unshortening all need
-- client-identifying data, so they wait for the private kone repo.

local M = {}

local picker = require("picker")

--- Called by the stub's hs.urlevent.httpCallback.
---
--- host is nil for a file:// URL, so nothing here may index it. fullURL is the
--- only faithful argument — Hammerspoon normalises the rest.
function M.dispatch(_scheme, _host, _params, fullURL, _senderPID)
  picker.present(fullURL)
end

return M
