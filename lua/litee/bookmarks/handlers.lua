local lib_state         = require('litee.lib.state')
local lib_panel         = require('litee.lib.panel')
local lib_tree          = require('litee.lib.tree')
local lib_tree_node     = require('litee.lib.tree.node')
local lib_path          = require('litee.lib.util.path')
local lib_notify        = require('litee.lib.notify')

local config            = require('litee.bookmarks.config').config
local marshal_func      = require('litee.bookmarks.marshal').marshal_func
local encoding          = require('litee.bookmarks.encoding')
local notebook          = require('litee.bookmarks.notebook')

local M = {}

-- bookmarks_handler handles the initial request for creating
-- a bookmarks UI for a particular tab.
function M.bookmarks_handler(notebook_name)
    local cur_win = vim.api.nvim_get_current_win()
    local cur_tabpage = vim.api.nvim_win_get_tabpage(cur_win)
    local state_was_nil = false

    -- use project_root if passed, if not get current base dir.
    if notebook_name == nil or notebook_name == "" then
        notebook_name = vim.fn.getcwd()
    end

    local state = lib_state.get_component_state(cur_tabpage, "bookmarks")
    if state == nil then
        state_was_nil = true
        state = {}
        -- create new tree, throwing old one out if exists
        if state.bookmarks_handle ~= nil then
            lib_tree.remove_tree(state.tree)
        end
        state.tree = lib_tree.new_tree("bookmarks")
        -- store the window invoking the bookmarks, jumps will
        -- occur here.
        state.invoking_win = vim.api.nvim_get_current_win()
        -- store the tab which invoked the bookmarks.
        state.tab = cur_tabpage
    end

    -- create the synthetic root node.
    local key = string.format("%s:%s", notebook_name, "1")
    local name = lib_path.basename(notebook_name)
    local root = lib_tree_node.new_node(name, key, 0)
    root.location = nil -- not jumpable.
    root.details = "Notebook"
    root.notebook = notebook_name

    -- check if bookmark file exists
    local bookmark_file = notebook.get_notebook(notebook_name)
    if bookmark_file == nil then
        lib_notify.notify_popup_with_timeout("Could not find notebook " .. notebook_name, 1000, "error")
        return
    end

    -- encode lines in into children
    local file_iter = io.lines(bookmark_file)
    if file_iter == nil then
        return
    end
    local children = {}
    for line in file_iter do
        local child_node = encoding.decode_node(line)
        table.insert(children, child_node)
    end

    -- add to tree
    lib_tree.add_node(state.tree, root, children)

    -- update component state and grab the global since we need it to toggle
    -- the panel open.
    local global_state = lib_state.put_component_state(cur_tabpage, "bookmarks", state)

    -- state was not nil, can we reuse the existing win
    -- and buffer?
    if
        not state_was_nil
        and state.win ~= nil
        and vim.api.nvim_win_is_valid(state.win)
        and state.buf ~= nil
        and vim.api.nvim_buf_is_valid(state.buf)
    then
        lib_tree.write_tree(
            state.buf,
            state.tree,
            marshal_func
        )
    else
        -- we have no state, so open up the panel or popout to create
        -- a window and buffer.
        if config.on_open == "popout" then
            lib_panel.popout_to("bookmarks", global_state)
        else
            lib_panel.toggle_panel(global_state, true, false)
        end
    end
end

return M
