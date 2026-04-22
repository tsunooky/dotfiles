-- Central Utility Configuration
return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
  -- Core Utilities
  bigfile = { enabled = true },
  quickfile = { enabled = true },
  statuscolumn = { enabled = true },
  words = { enabled = true },
  
  -- UI & Interaction
  dashboard = {
    enabled = true,
    sections = {
    { section = "header" },
    { section = "keys", gap = 1, padding = 1 },
    { section = "startup" },
    },
  },
  explorer = { 
    enabled = true,
    replace_netrw = true,
  },
  picker = { enabled = true },
  notifier = {
    enabled = true,
    timeout = 3000,
    width = { min = 40, max = 0.4 },
  },
  input = { enabled = true },
  select = { enabled = true },
  
  -- Visual & Animations
  indent = { 
    enabled = true,
    scope = { enabled = false },
  },
  scroll = { 
    enabled = true,
    animate = {
    duration = { step = 5, total = 80 },
    easing = "linear",
    },
    spamming = 5,
  },
  dim = { enabled = true },
  animate = { enabled = true },
  
  -- Workspace
  terminal = { enabled = true },
  rename = { enabled = true },
  },
  keys = {
  -- File & Search
  { "<leader>e", function() Snacks.explorer() end, desc = "File Explorer" },
  { "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files" },
  { "<leader>fg", function() Snacks.picker.grep() end, desc = "Grep" },
  { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
  { "<leader>fh", function() Snacks.picker.help() end, desc = "Help Pages" },
  { "<leader>sq", function() Snacks.picker.recent() end, desc = "Recent Files" },
  { "<leader>sl", function() Snacks.picker.lsp_symbols() end, desc = "LSP Symbols" },
  
  -- Git
  { "<leader>gb", function() Snacks.git.blame_line() end, desc = "Git Blame Line" },
  { "<leader>gB", function() Snacks.gitbrowse() end, desc = "Git Browse" },
  
  -- Utilities
  { "<leader>t", function() Snacks.terminal() end, desc = "Toggle Terminal" },
  { "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete Buffer" },
  },
}
