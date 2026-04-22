-- Keybinding UI
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
  preset = "modern",
  spec = {
    { "<leader>f", group = "find/file", icon = " " },
    { "<leader>g", group = "git", icon = " " },
    { "<leader>u", group = "ui/toggle", icon = "󰙵 " },
    { "<leader>c", group = "code/config", icon = " " },
    { "<leader>b", group = "buffer", icon = "󰓩 " },
    { "<leader>s", group = "search/snacks", icon = " " },
    { "<leader>x", group = "diagnostics/trouble", icon = "󰒡 " },
  },
  win = {
    border = "rounded",
  },
  layout = {
    spacing = 6,
  },
  },
  keys = {
  {
    "<leader>?",
    function()
    require("which-key").show({ global = false })
    end,
    desc = "Buffer Local Keymaps (which-key)",
  },
  },
}
