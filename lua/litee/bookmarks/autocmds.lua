local lib_tree      = require('litee.lib.tree')
local lib_state     = require('litee.lib.state')
local lib_path      = require('litee.lib.util.path')
local lib_hi        = require('litee.lib.highlights')
local lib_win       = require('litee.lib.util.window')
local lib_icons     = require('litee.lib.icons')

local notebook      = require('litee.bookmarks.notebook')
local marshal_func  = require('litee.bookmarks.marshal').marshal_func
local config        = require('litee.bookmarks.config').config

local M = {}

M.bookmarks_hl_ns = vim.api.nvim_create_namespace("bookmarks")

function M.clear_all_virtualtext()
    local bufs = vim.api.nvim_list_bufs()
    for _, buf in ipairs(bufs) do
        vim.api.nvim_buf_clear_namespace(
            buf,
            M.bookmarks_hl_ns,
            0,
            -1
        )
    end
end

function M.clear_virtualtext(state, root, buf)
    -- update line ranges before clearing
    local encode_tree = false
    for _, child in ipairs(root.children) do
        if child.extmark ~= nil then
            local ext_buf = child.extmark.buf
            local ext_id  = child.extmark.id
            local latest_ext_mark = vim.api.nvim_buf_get_extmark_by_id(
                ext_buf,
                M.bookmarks_hl_ns,
                ext_id,
                {}
            )
            if #latest_ext_mark == 2 then
                local range = child.location.range
                local relative_line_count = range["end"].line - range["start"].line
                range["start"].line = latest_ext_mark[1]
                range["end"].line = range["start"].line + relative_line_count
                encode_tree = true
            end
        end
    end

    if encode_tree == true then
        -- write our tree
        lib_tree.write_tree(
            state["bookmarks"].buf,
            state["bookmarks"].tree,
            marshal_func
        )
        local notebook_file = notebook.get_notebook(root.notebook)
        notebook.encode_tree_to_notebook(root, notebook_file)
    end

    local bufs = nil
    if buf ~= nil then
        bufs = {buf}
    else
        bufs = vim.api.nvim_list_bufs()
    end
    for _, b in ipairs(bufs) do
        if
            b ~= nil and
            vim.api.nvim_buf_is_valid(b)
        then
            vim.api.nvim_buf_clear_namespace(
                b,
                M.bookmarks_hl_ns,
                0,
                -1
            )
        end
    end
end

function M.set_virtualtext()
    local buf    = vim.api.nvim_get_current_buf()
    local buf_name = vim.api.nvim_buf_get_name(buf)
    local win    = vim.api.nvim_get_current_win()
    local tab    = vim.api.nvim_win_get_tabpage(win)
    local state  = lib_state.get_state(tab)
    if
        state == nil or
        state["bookmarks"] == nil or
        state["bookmarks"].tree == nil or
        lib_win.inside_component_win()
    then
        M.clear_all_virtualtext()
        return
    end

    local t = lib_tree.get_tree(state["bookmarks"].tree)
    if t.root == nil then
        return
    end

    M.clear_virtualtext(state, t.root, buf)

    local icon_set = "default"
    if config.icon_set ~= nil then
        icon_set = lib_icons[config.icon_set]
    end

    for _, child in ipairs(t.root.children) do
        local child_uri = lib_path.strip_file_prefix(child.location.uri)
        if child_uri == buf_name then
            local start_line = child.location.range["start"].line
            local opts = {
                virt_text_pos = "right_align",
                virt_text = {{string.format("%s  %s", icon_set["Bookmark"], child.name), lib_hi.hls.SymbolDetailHL}},
            }
            local extmark = {
                buf = buf,
                id = vim.api.nvim_buf_set_extmark(
                    buf,
                    M.bookmarks_hl_ns,
                    start_line,
                    0,
                    opts
                )
            }
            child.extmark = extmark
        end
    end
end


return M
