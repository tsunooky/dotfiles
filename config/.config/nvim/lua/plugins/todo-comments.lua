-- Todo Comments
return {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {},
  keys = {
  { "]t", function() require("todo-comments").jump_next() end, desc = "Next Todo" },
  { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous Todo" },
  { "<leader>xt", "<cmd>TodoTrouble<cr>", desc = "Todo (Trouble)" },
  { "<leader>st", function() Snacks.picker.todo() end, desc = "Todo (Snacks)" },
  },
}
