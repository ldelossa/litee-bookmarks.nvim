local M = {}

function M.setup()
    -- Create a notebook and open it.
    vim.cmd("command! LTCreateNotebook lua require('litee.bookmarks').create_notebook()")
    -- Opens a created notebook by name, is no name is provided LTListNotebooks is called to list 
    -- available notebooks.
    vim.cmd("command! LTOpenNotebook            lua require('litee.bookmarks').open_notebook(<args>)")
    -- Lists created notebooks in a vim.ui.select prompt for opening.
    vim.cmd("command! LTListNotebooks           lua require('litee.bookmarks').open_notebook_by_select()")
    -- Lists created notebooks in a vim.ui.select prompt and deletes a selected one.
    vim.cmd("command! LTDeleteNotebook          lua require('litee.bookmarks').delete_notebook_by_select()")
    -- Move all notebooks associated with a root source code directory to the currently opened one.
    vim.cmd("command! LTMigrateNotebooks        lua require('litee.bookmarks').migrate_notebooks()")
    -- Creates a bookmark in the currently opened notebook.
    vim.cmd("command! -range LTCreateBookmark   lua require('litee.bookmarks').create_bookmark(<line1>, <line2>)")
    -- Deletes a bookmark in the currently opened notebook.
    vim.cmd("command! LTDeleteBookmark          lua require('litee.bookmarks').delete_bookmark()")
    -- Opens the `litee.nvim` panel directly to the notebook window.
    vim.cmd("command! LTOpenToNotebook          lua require('litee.bookmarks').open_to()")
    -- Opens the notebook window in a `litee.nvim` popout panel.
    vim.cmd("command! LTPopOutNotebook          lua require('litee.bookmarks').popout_to()")
    -- Closes the notebook and removes its state from Neovim.
    -- Will not show up after a panel toggle.
    vim.cmd("command! LTCloseNotebook           lua require('litee.bookmarks').close_notebook()")
    -- Hides the notebook from the `litee.nvim` panel but leaves state in Neovim.
    -- Will appear againt after a panel toggle.
    vim.cmd("command! LTHideBookmarks           lua require('litee.bookmarks').hide_bookmarks()")
    -- Move to next bookmark in the notebook window
    vim.cmd("command! LTNextBookmarks           lua require('litee.bookmarks').navigation('n')")
    -- Move to previous bookmark in the notebook window
    vim.cmd("command! LTPrevBookmarks           lua require('litee.bookmarks').navigation('p')")
    -- Jump to bookmark under the cursor
    vim.cmd("command! LTJumpBookmarks           lua require('litee.bookmarks').jump_bookmarks()")
    -- Jump to bookmark under the cursor in a split.
    vim.cmd("command! LTJumpBookmarksSplit      lua require('litee.bookmarks').jump_bookmarks('split')")
    -- Jump to bookmark under the cursor in a vsplit.
    vim.cmd("command! LTJumpBookmarksVSplit     lua require('litee.bookmarks').jump_bookmarks('vsplit')")
    -- Jump to bookmark under the cursor in a tab.
    vim.cmd("command! LTJumpBookmarksTab        lua require('litee.bookmarks').jump_bookmarks('tab')")
    -- vim.cmd("command! LTDetailsBookmarks     lua require('litee.bookmarks').details_bookmarks()")
    -- vim.cmd("command! LTDumpTreeBookmarks    lua require('litee.bookmarks').dump_tree()")
    -- vim.cmd("command! LTDumpNodeBookmarks    lua require('litee.bookmarks').dump_node()")
end

return M
