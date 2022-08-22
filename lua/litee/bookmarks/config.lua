local M = {}

M.config = {
    notebook_root_dir = "~/.litee-notebooks",
    icon_set = "codicons",
    jump_mode   = "invoking",
    no_hls      = false,
    map_resize_keys = true,
    use_web_devicons = true,
    on_open = "popout",
    virtual_text = true,
    virtual_text_pos = "eol",
    keymaps = {
      jump = "<CR>",
      jump_split = "s",
      jump_vsplit = "v",
      jump_tab = "t",
      details = "d",
      close = "X",
      close_panel_pop_out = "<Esc>",
      help = "?",
      hide = "<C-[>",
      delete = "D",
    },
    icon_set = "default",
    icon_set_custom = nil,
}

return M
