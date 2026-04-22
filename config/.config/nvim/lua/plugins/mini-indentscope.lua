-- Indentation Guide
return {
  "echasnovski/mini.indentscope",
  version = false,
  config = function()
    require("mini.indentscope").setup({
      symbol = "│",
      options = { 
        try_as_border = false,
      },
      draw = {
        delay = 100,
        priority = 2,
      },
    })

    vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
      pattern = { 
        "snacks_dashboard", 
        "dashboard", 
        "alpha", 
        "help", 
        "lazy", 
        "mason", 
        "notify", 
        "toggleterm",
        "snacks_notif",
        "snacks_terminal",
        "snacks_win",
        "nui",
        "netrw",
        "snacks_picker_input",
      },
      callback = function()
        vim.b.miniindentscope_disable = true
        vim.b.snacks_indent = false
      end,
    })
  end,
}
