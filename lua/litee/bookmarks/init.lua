local lib_state     = require('litee.lib.state')
local lib_tree      = require('litee.lib.tree')
local lib_tree_node = require('litee.lib.tree.node')
local lib_panel     = require('litee.lib.panel')
local lib_lsp       = require('litee.lib.lsp')
local lib_jumps     = require('litee.lib.jumps')
local lib_navi      = require('litee.lib.navi')
local lib_util      = require('litee.lib.util')
local lib_util_win  = require('litee.lib.util.window')
local lib_notify    = require('litee.lib.notify')
local lib_hover     = require('litee.lib.lsp.hover')
local lib_details   = require('litee.lib.details')
local lib_path      = require('litee.lib.util.path')

local config        = require('litee.bookmarks.config').config
local marshal_func  = require('litee.bookmarks.marshal').marshal_func
local notebook      = require('litee.bookmarks.notebook')
local bookmarks_buf = require('litee.bookmarks.buffer')
local handlers      = require('litee.bookmarks.handlers')

local M = {}

-- ui_req_ctx creates a context table summarizing the
-- environment when a bookmarks request is being
-- made.
--
-- see return type for details.
local function ui_req_ctx()
    local buf    = vim.api.nvim_get_current_buf()
    local win    = vim.api.nvim_get_current_win()
    local tab    = vim.api.nvim_win_get_tabpage(win)
    local linenr = vim.api.nvim_win_get_cursor(win)
    local tree_type   = lib_state.get_type_from_buf(tab, buf)
    local tree_handle = lib_state.get_tree_from_buf(tab, buf)
    local state       = lib_state.get_state(tab)

    local cursor = nil
    local node = nil
    if state ~= nil then
        if state["bookmarks"] ~= nil and state["bookmarks"].win ~= nil and
            vim.api.nvim_win_is_valid(state["bookmarks"].win) then
            cursor = vim.api.nvim_win_get_cursor(state["bookmarks"].win)
        end
        if cursor ~= nil then
            node = lib_tree.marshal_line(cursor, state["bookmarks"].tree)
        end
    end

    return {
        -- the current buffer when the request is made
        buf = buf,
        -- the current win when the request is made
        win = win,
        -- the current tab when the request is made
        tab = tab,
        -- the current cursor pos when the request is made
        linenr = linenr,
        -- the type of tree if request is made in a lib_panel
        -- window.
        tree_type = tree_type,
        -- a hande to the tree if the request is made in a lib_panel
        -- window.
        tree_handle = tree_handle,
        -- the pos of the bookmarks cursor if a valid caltree exists.
        cursor = cursor,
        -- the current state provided by lib_state
        state = state,
        -- the current marshalled node if there's a valid bookmarks
        -- window present.
        node = node
    }
end

function M.open_notebook_by_select()
    local notebooks = notebook.list_notebooks()
    if #notebooks == 0 then
        lib_notify.notify_popup_with_timeout("You must first create a notebook with LTCreateNotebook", 7500, "error")
    end
    vim.ui.select(notebooks, { prompt = "Select a notebook to open: " }, function(item, _)
        if item == nil then
            return
        end
        handlers.bookmarks_handler(item)
    end)
end

function M.create_notebook(notebook_name)
    if notebook_name == nil or notebook_name == "" then
        notebook_name = vim.fn.getcwd()
    end

    local create = function ()
        local fd = notebook.create_notebook(notebook_name)
        if fd ~= nil then
            fd:close()
        else
            lib_notify.notify_popup_with_timeout("Failed to create notebook", 7500, "error")
        end
        lib_notify.notify_popup_with_timeout("Created notebook: " .. notebook_name, 7500, "info")
    end

    local nb_file = notebook.get_notebook(notebook_name)
    if nb_file ~= nil then
        vim.ui.input({prompt = string.format("Notebook %s already exists, overwrite? (bookmarks deleted) (y/n) ", notebook_name)},
        function(input)
            if input == nil then
                return
            end
            if input == "y" then
                create()
            elseif input ~= "n" then
                lib_notify.notify_popup_with_timeout(string.format("Did not understand %s please try again and use `y` or `n`", input), 7500, "error")
            end
        end)
    else
        create()
    end
end

function M.open_to()
    local ctx = ui_req_ctx()
    if
        ctx.state == nil or
        ctx.state["bookmarks"] == nil
    then
        lib_notify.notify_popup_with_timeout("Open a notebook first with LTOpenNotebook or LTListNotebooks to create a bookmark", 7500, "error")
        return
    end
    lib_panel.open_to("bookmarks", ctx.state)
end

function M.popout_to()
    local ctx = ui_req_ctx()
    if
        ctx.state == nil or
        ctx.state["bookmarks"] == nil
    then
        lib_notify.notify_popup_with_timeout("Open a notebook first with LTOpenNotebook or LTListNotebooks to create a bookmark", 7500, "error")
    end
    lib_panel.popout_to("bookmarks", ctx.state)
end

-- close_notebook will close the opened notebook in the current tab
-- and remove the corresponding tree from memory.
--
-- use hide_bookmarks if you simply want to hide a bookmarks
-- component temporarily (not removing the tree from memory)
function M.close_notebook()
    local ctx = ui_req_ctx()
    if ctx.state["bookmarks"].win ~= nil then
        if vim.api.nvim_win_is_valid(ctx.state["bookmarks"].win) then
            vim.api.nvim_win_close(ctx.state["bookmarks"].win, true)
        end
    end
    if ctx.state["bookmarks"].buf ~= nil then
        if vim.api.nvim_buf_is_valid(ctx.state["bookmarks"].buf) then
            vim.api.nvim_buf_delete(ctx.state["bookmarks"].buf, {force = true})
        end
    end
    if ctx.state["bookmarks"].tree ~= nil then
        lib_tree.remove_tree(ctx.state["bookmarks"].tree)
    end
    lib_state.put_component_state(ctx.tab, "bookmarks", nil)
end

-- hide_notebook will remove the filetree component from
-- the a panel temporarily.
--
-- on panel toggle the filetree will be restored.
function M.hide_notebook()
    local ctx = ui_req_ctx()
    if ctx.tree_type ~= "bookmarks" then
        return
    end
    if ctx.state["bookmarks"].win ~= nil then
        if vim.api.nvim_win_is_valid(ctx.state["bookmarks"].win) then
            vim.api.nvim_win_close(ctx.state["bookmarks"].win, true)
        end
    end
    if vim.api.nvim_win_is_valid(ctx.state["bookmarks"].invoking_win) then
        vim.api.nvim_set_current_win(ctx.state["bookmarks"].invoking_win)
    end
end

function M.delete_bookmark()
    local ctx = ui_req_ctx()
    if
        ctx.state == nil
        or ctx.state["bookmarks"] == nil
        or ctx.state["bookmarks"].tree == nil
        or ctx.node == nil
    then
        lib_notify.notify_popup_with_timeout("Open a notebook first with LTOpenNotebook or LTListNotebooks to create a bookmark", 7500, "error")
        return
    end

    -- get current tree
    local t = lib_tree.get_tree(ctx.state["bookmarks"].tree)
    if t.root == nil then
        return
    end

    -- root of a notebook tree will have the notebook name, and we
    -- can retrieve the notebook_file from this.
    local notebook_file = notebook.get_notebook(t.root.notebook)
    if notebook_file == nil then
        return
    end

    -- erase node from root's children
    local new_children = {}
    for _, child in ipairs(t.root.children) do
        if child.key ~= ctx.node.key then
            table.insert(new_children, child)
        end
    end
    t.root.children = new_children

    -- write our tree
    lib_tree.write_tree(
        ctx.state["bookmarks"].buf,
        ctx.state["bookmarks"].tree,
        marshal_func
    )

    -- encode tree to notebook
    notebook.encode_tree_to_notebook(t.root, notebook_file)
end

function M.create_bookmark()
    local ctx = ui_req_ctx()
    if
        ctx.state == nil
        or ctx.state["bookmarks"] == nil
        or ctx.state["bookmarks"].tree == nil
    then
        lib_notify.notify_popup_with_timeout("Open a notebook first with LTOpenNotebook or LTListNotebooks to create a bookmark", 7500, "error")
        return
    end

    -- get current tree
    local t = lib_tree.get_tree(ctx.state["bookmarks"].tree)
    if t.root == nil then
        return
    end

    -- root of a notebook tree will have the notebook name, and we
    -- can retrieve the notebook_file from this.
    local notebook_file = notebook.get_notebook(t.root.notebook)
    if notebook_file == nil then
        return
    end

    -- get current file and line number
    local cur_file = vim.fn.expand('%:p')
    local cur_linenr = vim.api.nvim_win_get_cursor(0)

    -- get bookmark name from user, rest of logic is in callback.
    vim.ui.input({prompt="Name your new bookmark: "}, function(input)
        -- create node representing bookmark.
        local key = string.format("%s:%d", cur_file, cur_linenr[1])

        local node = lib_tree_node.new_node(input, key, 1)

        node.details = string.format("%s line:%s", lib_util.relative_path_from_uri(cur_file), cur_linenr[1])

        -- create location obj
        local range = {}
        range["start"] = { line = cur_linenr[1]-1, character = 0}
        range["end"] = range["start"]
        local location = {
            uri = lib_path.add_file_prefix(cur_file),
            range =  range
        }
        node.location = location

        -- add a new child to the existing tree
        table.insert(t.root.children, node)

        -- write our tree
        lib_tree.write_tree(
            ctx.state["bookmarks"].buf,
            ctx.state["bookmarks"].tree,
            marshal_func
        )

        -- encode tree to file
        notebook.encode_tree_to_notebook(t.root, notebook_file)
        end
    )
end

M.jump_bookmarks = function(split)
    local ctx = ui_req_ctx()
    if
        ctx.state == nil or
        ctx.cursor == nil or
        ctx.state["bookmarks"].tree == nil
    then
        lib_notify.notify_popup_with_timeout("Open a notebook first with LTOpenNotebook or LTListNotebooks to create a bookmark", 7500, "error")
        return
    end
    local location = ctx.node.location
    if location == nil or location.range.start.line == -1 then
        return
    end

    if split == "tab" then
        lib_jumps.jump_tab(location, ctx.node)
        return
    end

    if split == "split" or split == "vsplit" then
        lib_jumps.jump_split(split, location, ctx.node)
        return
    end

    if config.jump_mode == "neighbor" then
        lib_jumps.jump_neighbor(location, ctx.node)
        return
    end

    if config.jump_mode == "invoking" then
            local invoking_win = ctx.state["bookmarks"].invoking_win
            ctx.state["bookmarks"].invoking_win = lib_jumps.jump_invoking(location, invoking_win, ctx.node)
        return
    end
end

function M.navigation(dir)
    local ctx = ui_req_ctx()
    if ctx.state == nil then
        return
    end
    if dir == "n" then
        lib_navi.next(ctx.state["bookmarks"])
    elseif dir == "p" then
        lib_navi.previous(ctx.state["bookmarks"])
    end
    vim.cmd("redraw!")
end

local function bookmarks_buffer_search()
    local tabs = vim.api.nvim_list_tabpages()
    for _, tab in ipairs(tabs) do
        local comp_state = lib_state.get_component_state(tab, "bookmarks")
        if comp_state ~= nil then
            if comp_state.buf ~= nil and vim.api.nvim_buf_is_valid(comp_state.buf) then
                return comp_state.buf
            end
        end
    end
    return nil
end

function M.setup(user_config)
    local function pre_window_create(state)
        if state["bookmarks"].tree == nil then
            return false
        end

        -- we want to actually share the same buffer between all
        -- tabs, so we'll do a search for any open and valid buffer
        -- and return this, before creating one.
        local existing_buf = bookmarks_buffer_search()

        if existing_buf ~= nil then
            state["bookmarks"].buf = existing_buf
        else
            local buf_name = "bookmarks"
            state["bookmarks"].buf =
                bookmarks_buf._setup_buffer(buf_name, state["bookmarks"].buf, state["bookmarks"].tab)
        end

        lib_tree.write_tree(
            state["bookmarks"].buf,
            state["bookmarks"].tree,
            marshal_func
        )
        return true
    end

    local function post_window_create()
        if not config.no_hls then
            lib_util_win.set_tree_highlights()
        end
        -- set scrolloff to 9999 to keep items centered
        vim.api.nvim_win_set_option(vim.api.nvim_get_current_win(), "scrolloff", 9999)
    end

    -- merge in config
    if user_config ~= nil then
        for key, val in pairs(user_config) do
            config[key] = val
        end
    end

    if not pcall(require, "litee.lib") then
        lib_notify.notify_popup_with_timeout("Cannot start litee-bookmarks without the litee.lib library.", 1750, "error")
        return
    end

    if vim.fn.mkdir(vim.fn.expand(config.notebook_root_dir), "p") == 0 then
        lib_notify.notify_popup_with_timeout("Failed to create notebook_root_dir, cannot continue.", 1750, "error")
    end


    lib_panel.register_component("bookmarks", pre_window_create, post_window_create)

    require('litee.bookmarks.commands').setup()
end

return M
