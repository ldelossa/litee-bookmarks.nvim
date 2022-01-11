local config    = require('litee.bookmarks.config').config
local lib_icons = require('litee.lib.icons')

local M = {}

-- marshal_func is a function which returns the necessary
-- values for marshalling a bookmarks node into a buffer
-- line.
function M.marshal_func(node)
    local icon_set = nil
    if config.icon_set ~= nil then
        icon_set = lib_icons[config.icon_set]
    else
        icon_set = lib_icons["default"]
    end
    local name, detail, icon = "", "", ""

    name = node.name

    detail = node.details

    if node.depth == 0 then
        icon = icon_set["Notebook"]
    else
        icon = icon_set["Bookmark"]
    end

    return name, detail, icon, " "
end

return M
