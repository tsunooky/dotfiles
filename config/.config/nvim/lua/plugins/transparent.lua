-- Transparency Support
return {
  "xiyaowong/transparent.nvim",
  lazy = false,
  config = function()
    require("transparent").setup({
      extra_groups = { 
        "NeoTreeNormal", 
        "NeoTreeNormalNC",
        "MiniIndentscopeSymbol",
        "NormalFloat", 
        "FloatBorder",
        "Pmenu",
        "PmenuSel",
        "PmenuSbar",
        "PmenuThumb",
        "NoiceCmdlinePopup",
        "NoiceCmdlinePopupBorder",
        "NoicePopupmenu",
        "NoicePopupmenuBorder",
        "NoiceCmdline",
        "CmpPmenu",
        "CmpPmenuBorder",
        "NormalNC",
      },
    })
  end,
}
