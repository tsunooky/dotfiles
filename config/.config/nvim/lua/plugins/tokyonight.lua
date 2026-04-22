-- Colorscheme
return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("tokyonight").setup({
      transparent = true,
      styles = { sidebars = "transparent", floats = "transparent" },
    })

    vim.cmd([[colorscheme tokyonight]])
    vim.api.nvim_set_hl(0, "MiniIndentscopeSymbol", { fg = "#7aa2f7" })
    vim.api.nvim_set_hl(0, "SnacksNotifierTitle", { link = "Title" })
    vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { link = "Title" })
    vim.api.nvim_set_hl(0, "SnacksDashboardTitle", { link = "Title" })
    vim.api.nvim_set_hl(0, "SnacksDashboardIcon", { link = "Directory" })
  end,
}
