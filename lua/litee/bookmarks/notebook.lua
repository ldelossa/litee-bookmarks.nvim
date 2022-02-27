local lib_notify    = require('litee.lib.notify')
local lib_path      = require('litee.lib.util.path')

local config        = require('litee.bookmarks.config').config
local encoding      = require('litee.bookmarks.encoding')

local M = {}

local function create_notebook_file_path(encoded_path)
    return vim.fn.expand(config.notebook_root_dir .. "/" .. encoded_path)
end

function M.create_notebook(notebook_name)
    -- create the owning notebook container dir for cwd
    local notebook_dir = vim.fn.getcwd()
    local notebook_dir_encoded = lib_path.safe_encode(vim.fn.expand(notebook_dir))
    notebook_dir = create_notebook_file_path(notebook_dir_encoded)
    if vim.fn.isdirectory(notebook_dir) == 0 then
        vim.fn.mkdir(notebook_dir)
    end

    local notebook_name_encoded = lib_path.safe_encode(notebook_name)
    local notebook_file = create_notebook_file_path(notebook_dir_encoded .. '/' .. notebook_name_encoded)
    local fd = io.open(vim.fn.expand(notebook_file), "w+")
    if fd == nil then
        lib_notify.notify_popup_with_timeout("path " .. notebook_name .. " failed to create bookmark file", 1000, "error")
        return nil
    end
    fd:write("")
    return fd
end

function M.get_notebook(notebook_name)
    local notebook_dir = vim.fn.getcwd()
    local notebook_dir_encoded = lib_path.safe_encode(vim.fn.expand(notebook_dir))
    notebook_dir = create_notebook_file_path(notebook_dir_encoded)
    local project_root = lib_path.safe_decode(lib_path.basename(notebook_dir))

    notebook_name = vim.fn.expand(notebook_name)
    local notebook_name_encoded = lib_path.safe_encode(notebook_name)
    local notebook_file = create_notebook_file_path(notebook_dir_encoded .. '/' .. notebook_name_encoded)
    if not lib_path.file_exists(notebook_file) then
        return nil
    end
    return notebook_file, project_root
end

function M.list_notebooks()
    local project_root = vim.fn.getcwd()
    local notebook_dir_encoded = lib_path.safe_encode(vim.fn.expand(project_root))
    local project_root_decoded = create_notebook_file_path(notebook_dir_encoded)

    local notebook_files = vim.fn.readdir(vim.fn.expand(project_root_decoded))
    local notebooks = {}
    for _, notebook_file in ipairs(notebook_files) do
        local decoded = lib_path.safe_decode(notebook_file)
        table.insert(notebooks, decoded)
    end
    return notebooks, project_root
end

function M.list_notebook_dirs()
    local notebook_dirs = vim.fn.readdir(vim.fn.expand(config.notebook_root_dir))
    if notebook_dirs == 0 then
        return nil
    end
    return notebook_dirs
end

function M.list_notebook_dirs_decoded()
    local notebook_dirs_encoded = M.list_notebook_dirs()
    if notebook_dirs_encoded == nil then
        return
    end
    local notebook_dirs_decoded = {}
    for _, dir in ipairs(notebook_dirs_encoded) do
        local dir_decoded = lib_path.safe_decode(dir)
        table.insert(notebook_dirs_decoded, dir_decoded)
    end
    return notebook_dirs_decoded
end

function M.move_notebook_repo(old, new)
    local old_encoded = create_notebook_file_path(lib_path.safe_encode(old))
    local new_encoded = create_notebook_file_path(lib_path.safe_encode(new))
    vim.fn.rename(old_encoded, new_encoded)
end

function M.migrate_notebook_cwd(old)
    local notebook_dir = vim.fn.getcwd()
    M.move_notebook_repo(old, notebook_dir)
end

function M.delete_notebook(notebook_name)
    local notebook_dir = vim.fn.getcwd()
    local notebook_dir_encoded = lib_path.safe_encode(vim.fn.expand(notebook_dir))
    notebook_dir = create_notebook_file_path(notebook_dir_encoded)

    local notebook_name_encoded = lib_path.safe_encode(notebook_name)
    local notebook_file = create_notebook_file_path(notebook_dir_encoded .. '/' .. notebook_name_encoded)

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
