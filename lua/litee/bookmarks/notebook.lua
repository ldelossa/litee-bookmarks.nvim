local lib_notify    = require('litee.lib.notify')
local lib_path      = require('litee.lib.util.path')

local config        = require('litee.bookmarks.config').config
local encoding      = require('litee.bookmarks.encoding')

local M = {}

local function create_notebook_file_path(encoded_path)
    return vim.fn.expand(config.notebook_root_dir .. "/" .. encoded_path)
end

function M.create_notebook(notebook_name)
    if notebook_name == nil or notebook_name == "" then
        notebook_name = vim.fn.getcwd()
    end
    -- expand if this is a notebook associated with a directory,
    -- this will expand tilde.
    notebook_name = vim.fn.expand(notebook_name)
    local encoded_path = lib_path.safe_encode(notebook_name)
    local notebook_file = create_notebook_file_path(encoded_path)
    local fd = io.open(vim.fn.expand(notebook_file), "w+")
    if fd == nil then
        lib_notify.notify_popup_with_timeout("path " .. notebook_name .. " failed to create bookmark file", 1000, "error")
        return nil
    end
    fd:write("")
    return fd
end

function M.get_notebook(notebook_name)
    if notebook_name == nil or notebook_name == "" then
        notebook_name = vim.fn.getcwd()
    end
    notebook_name = vim.fn.expand(notebook_name)
    local encoded_path = lib_path.safe_encode(notebook_name)
    local notebook_file = create_notebook_file_path(encoded_path)
    if not lib_path.file_exists(notebook_file) then
        return nil
    end
    return notebook_file
end

function M.list_notebooks()
    local notebook_files = vim.fn.readdir(vim.fn.expand(config.notebook_root_dir))
    local notebooks = {}
    for _, notebook_file in ipairs(notebook_files) do
        local decoded = lib_path.safe_decode(notebook_file)
        table.insert(notebooks, decoded)
    end
    return notebooks
end

function M.delete_notebook(notebook_name)
    if notebook_name == nil or notebook_name == "" then
        notebook_name = vim.fn.getcwd()
    end
    notebook_name = vim.fn.expand(notebook_name)
    local encoded_path = lib_path.safe_encode(notebook_name)
    local notebook_file = create_notebook_file_path(encoded_path)
    if not lib_path.file_exists(notebook_file) then
        return nil
    end
    vim.fn.delete(notebook_file)
end

function M.encode_tree_to_notebook(root, bookmark_file)
    -- w+ to truncate the file
    local fd = io.open(vim.fn.expand(bookmark_file), "w+")
    if fd == nil then
        return
    end

    for _, child in ipairs(root.children) do
        local line = encoding.encode_node(child)
        fd:write(line .. "\n")
    end
    fd:close()
end

return M
