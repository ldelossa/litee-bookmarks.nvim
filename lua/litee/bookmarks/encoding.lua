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
    local line  = ""
    local file_start_and_end = vim.fn.split(node.key, ":")
    local file  = lib_path.safe_encode(file_start_and_end[1])
    local start_line = node.location.range["start"].line+1
    local end_line  = node.location.range["end"].line+1
    local name  = lib_path.safe_encode(node.name)
    line = string.format("%s:%s:%s:%s", file, start_line, end_line, name)
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
    local start_line        = tonumber(lib_path.safe_decode(elements[2]))
    local end_line          = tonumber(lib_path.safe_decode(elements[3]))
    local name              = lib_path.safe_decode(elements[4])
    bookmarked_file         = lib_path.safe_decode(bookmarked_file)
    local key               = string.format("%s:%s:%s", bookmarked_file, start_line, end_line)

    -- create location object
    local range = {}
    range["start"] = { line = start_line-1, character = 0}
    range["end"] = { line = end_line-1, character = 0}
    local location = {
        uri = lib_path.add_file_prefix(bookmarked_file),
        range =  range
    }

    -- create node, we hardcode depth to 1, since
    -- bookmark trees are just a list under the
    -- pseudo root.
    local node = lib_tree_node.new_node(name, key, 1)
    node.location = location
    return node
end

return M
