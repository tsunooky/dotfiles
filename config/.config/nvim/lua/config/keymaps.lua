-- File Operations
vim.keymap.set("n", "<C-s>", "<cmd>w<CR>", { desc = "Save file" })
vim.keymap.set("i", "<C-s>", "<Esc><cmd>w<CR>a", { desc = "Save file" })
vim.keymap.set("n", "<C-q>", "<cmd>qa!<CR>", { desc = "Quit without saving" })
vim.keymap.set("i", "<C-q>", "<Esc><cmd>qa!<CR>", { desc = "Quit without saving" })
vim.keymap.set("n", "<C-x>", "<cmd>wq<CR>", { desc = "Save and quit" })
vim.keymap.set("i", "<C-x>", "<Esc><cmd>wq<CR>", { desc = "Save and quit" })

-- Navigation
vim.keymap.set("n", "+", "<cmd>tabnew<CR>", { desc = "New tab" })
vim.keymap.set("n", "<", "<cmd>tabprevious<CR>", { desc = "Previous tab" })
vim.keymap.set("n", ">", "<cmd>tabnext<CR>", { desc = "Next tab" })
vim.keymap.set("n", "gb", "<C-o>", { desc = "Go back" })
vim.keymap.set("n", "<leader><leader>", function()
  if vim.bo.filetype == "snacks_explorer" or vim.bo.filetype == "snacks_explorer_input" then
  vim.cmd("wincmd p")
  else
  local win = vim.api.nvim_get_current_win()
  Snacks.explorer.reveal()
  if vim.api.nvim_get_current_win() == win then
    vim.cmd("wincmd p")
  end
  end
end, { desc = "Toggle Explorer/Code" })

-- Editing
vim.keymap.set("n", "<leader>/", "gcc", { remap = true, desc = "Toggle comment" })
vim.keymap.set("v", "<leader>/", "gc", { remap = true, desc = "Toggle comment" })
vim.keymap.set("n", "<C-z>", "u", { desc = "Undo" })
vim.keymap.set("i", "<C-z>", "<Esc>ua", { desc = "Undo in insert mode" })
