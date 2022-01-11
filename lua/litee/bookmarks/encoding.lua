local lib_path      = require('litee.lib.util.path')
local lib_tree_node = require('litee.lib.tree.node')

-- encoding.lua handles the encoding of a bookmark
-- from lib/tree node to an on-disk representation
-- and vice versa.

local M = {}

-- encode_node will encode the bookmark node
-- into a bookmark file line suitable for saving
-- on disk.
function M.encode_node(node)
    local line = ""
    local file_and_linenr = vim.fn.split(node.key, ":")
    local file = lib_path.safe_encode(file_and_linenr[1])
    local linenr = file_and_linenr[2]
    local name = lib_path.safe_encode(node.name)
    local details = lib_path.safe_encode(node.details)
    line = string.format("%s:%s:%s:%s", file, linenr, name, details)
    return line
end

-- decode_node will decode a bookmark file line
-- into a lib/tree node suitable for usage in a
-- lib/tree tree.
function M.decode_node(line)
    -- split line into encoded elements
    local elements = vim.fn.split(line, ":")
    if #elements ~= 4 then
        return
    end

    -- decode our elements
    local bookmarked_file   = lib_path.safe_decode(elements[1])
    local linenr            = tonumber(lib_path.safe_decode(elements[2]))
    local name              = lib_path.safe_decode(elements[3])
    local details           = lib_path.safe_decode(elements[4])
    bookmarked_file         = lib_path.safe_decode(bookmarked_file)
    local key               = string.format("%s:%s", bookmarked_file, linenr)

    -- create location object
    local range = {}
    range["start"] = { line = linenr-1, character = 0}
    range["end"] = range["start"]
    local location = {
        uri = lib_path.add_file_prefix(bookmarked_file),
        range =  range
    }

    -- create node, we hardcode depth to 1, since
    -- bookmark trees are just a list under the
    -- pseudo root.
    local node = lib_tree_node.new_node(name, key, 1)
    node.location = location
    node.details = details
    return node
end

return M
