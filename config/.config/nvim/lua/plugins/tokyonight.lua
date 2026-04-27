-- Colorscheme
return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("tokyonight").setup({
      transparent = true,
      styles = { sidebars = "transparent", floats = "transparent" },
      on_highlights = function(hl, c)
        hl.NeoTreeNormal = { bg = "none" }
        hl.NeoTreeNormalNC = { bg = "none" }
        hl.NormalFloat = { bg = "none" }
        hl.FloatBorder = { bg = "none" }
        hl.Pmenu = { bg = "none" }
        hl.NormalNC = { bg = "none" }
        hl.CmpPmenu = { bg = "none" }
        hl.CmpPmenuBorder = { bg = "none" }
      end,
    })

    vim.cmd([[colorscheme tokyonight]])
    vim.api.nvim_set_hl(0, "Whitespace", { fg = "#3b4261" })
    vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#7aa2f7", bold = true })
    vim.api.nvim_set_hl(0, "ColorColumn", { bg = "#1f2335" })
    vim.api.nvim_set_hl(0, "CursorLine", { bg = "#292e42" })
    vim.api.nvim_set_hl(0, "LspInlayHint", { bg = "none", fg = "#545c7e" })
    vim.api.nvim_set_hl(0, "MiniIndentscopeSymbol", { fg = "#7aa2f7" })
    vim.api.nvim_set_hl(0, "SnacksNotifierTitle", { link = "Title" })
    vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { link = "Title" })
    vim.api.nvim_set_hl(0, "SnacksDashboardTitle", { link = "Title" })
    vim.api.nvim_set_hl(0, "SnacksDashboardIcon", { link = "Directory" })
  end,
}
