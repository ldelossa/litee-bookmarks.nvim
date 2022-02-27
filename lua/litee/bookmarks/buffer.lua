local config = require('litee.bookmarks.config').config
local panel_config = require('litee.lib.config').config["panel"]
local lib_util_buf = require('litee.lib.util.buffer')

local M = {}

-- _setup_buffer performs an idempotent creation of
-- a bookmarks buffer.
function M._setup_buffer(name, buf, tab)
    -- see if we can reuse a buffer that currently exists.
    if buf == nil or not vim.api.nvim_buf_is_valid(buf) then
        buf = vim.api.nvim_create_buf(false, false)
        if buf == 0 then
            vim.api.nvim_err_writeln("bookmarks.buffer: buffer create failed")
            return
        end
    else
        return buf
    end

    -- set buf options
    vim.api.nvim_buf_set_name(buf, name .. ":" .. tab)
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'hide')
    vim.api.nvim_buf_set_option(buf, 'filetype', 'bookmarks')
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)
    vim.api.nvim_buf_set_option(buf, 'textwidth', 0)
    vim.api.nvim_buf_set_option(buf, 'wrapmargin', 0)

    -- set buffer local keymaps
    local opts = {silent=true}
    vim.api.nvim_buf_set_keymap(buf, "n",   config.keymaps.delete,      ":LTDeleteBookmark<CR>", opts)
    vim.api.nvim_buf_set_keymap(buf, "n",   config.keymaps.jump,   ":LTJumpBookmarks<CR>", opts)
    vim.api.nvim_buf_set_keymap(buf, "n",   config.keymaps.jump_split,      ":LTJumpBookmarksSplit<CR>", opts)
    vim.api.nvim_buf_set_keymap(buf, "n",   config.keymaps.jump_vsplit,      ":LTJumpBookmarksVSplit<CR>", opts)
    vim.api.nvim_buf_set_keymap(buf, "n",   config.keymaps.jump_tab,      ":LTJumpBookmarksTab<CR>", opts)
    vim.api.nvim_buf_set_keymap(buf, "n",   config.keymaps.hide,      ":LTHideBookmarks<CR>", opts)
    vim.api.nvim_buf_set_keymap(buf, "n",   config.keymaps.close,      ":LTCloseNotebook<CR>", opts)
    vim.api.nvim_buf_set_keymap(buf, "n",   config.keymaps.close_panel_pop_out,  ":LTClosePanelPopOut<CR>", opts)
    vim.api.nvim_buf_set_keymap(buf, "n",   config.keymaps.help,      ":lua require('litee.bookmarks').help(true)<CR>", opts)
	if config.map_resize_keys then
           lib_util_buf.map_resize_keys(panel_config.orientation, buf, opts)
    end
    return buf
end

return M
