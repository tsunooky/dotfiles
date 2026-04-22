-- UI Enhancements
return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = {
  "MunifTanjim/nui.nvim",
  "nvim-tree/nvim-web-devicons",
  },
  opts = {
  lsp = {
    override = {
    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
    ["vim.lsp.util.stylize_markdown"] = true,
    ["cmp.entry.get_documentation"] = true,
    },
  },
  presets = {
    bottom_search = true,
    command_palette = true,
    long_message_to_split = true,
    inc_rename = false,
    lsp_doc_border = true,
  },
  messages = {
    enabled = true,
    view = "notify",
    view_error = "notify",
    view_warn = "notify",
    view_history = "messages",
    view_search = "virtualtext",
  },
  views = {
    cmdline_popup = {
    position = {
      row = 5,
      col = "50%",
    },
    size = {
      width = 60,
      height = "auto",
    },
    win_options = {
      winhighlight = { Normal = "NormalFloat", FloatBorder = "FloatBorder" },
    },
    },
    popupmenu = {
    relative = "editor",
    position = {
      row = 8,
      col = "50%",
    },
    size = {
      width = 60,
      height = 10,
    },
    border = {
      style = "rounded",
      padding = { 0, 1 },
    },
    win_options = {
      winhighlight = { Normal = "NormalFloat", FloatBorder = "FloatBorder" },
    },
    },
  },
  },
}
