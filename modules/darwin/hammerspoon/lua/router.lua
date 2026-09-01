-- Where an opened link goes.
--
-- Deliberately thin. Domain rules, URL rewriting, source-application rules and
-- short-link unshortening all need client-identifying data, so they wait for
-- the private kone repo. Until then every link is offered to the picker.

local M = {}

local picker = require("picker")

--- Called by the stub's hs.urlevent.httpCallback.
---
--- host is nil for a file:// URL, so nothing here may index it. The other
--- arguments are normalised by Hammerspoon: host is lowercased and its port
--- stripped, duplicate query parameters collapse to the last value, and
--- valueless flags are dropped. fullURL is the only faithful form, which is
--- why it alone is passed on.
function M.dispatch(_scheme, _host, _params, fullURL, _senderPID)
  picker.present(fullURL)
end

return M
