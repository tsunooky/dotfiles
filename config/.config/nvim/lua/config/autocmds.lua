-- File Templates
vim.api.nvim_create_autocmd("BufNewFile", {
  pattern = { "*.h" },
  callback = function()
  local name = vim.fn.expand("%:t:r"):upper() .. "_H_"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    "#ifndef " .. name,
    "#define " .. name,
    "",
    "",
    "",
    "#endif /* !" .. name .. " */"
  })
  vim.api.nvim_win_set_cursor(0, { 4, 0 })
  end
})

vim.api.nvim_create_autocmd("BufNewFile", {
  pattern = { "*.hh" },
  callback = function()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    "#pragma once",
    "",
  })
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  end
})

vim.api.nvim_create_autocmd("BufNewFile", {
  pattern = "CMakeLists.txt",
  callback = function()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    "cmake_minimum_required(VERSION 3.10)",
    "project(MyProject C CXX)",
    "",
    "set(CMAKE_C_STANDARD 99)",
    "set(CMAKE_CXX_STANDARD 20)",
    "",
    "add_executable(${PROJECT_NAME} main.c)"
  })
  vim.api.nvim_win_set_cursor(0, { 7, 0 })
  end
})

-- Indentation
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp", "python" },
  callback = function()
  vim.opt_local.shiftwidth = 4
  vim.opt_local.tabstop = 4
  vim.opt_local.softtabstop = 4
  end,
})

-- Smart Color Column (Dynamic)
local function update_smart_column()
  local ignored = { "help", "text", "markdown", "snacks_dashboard", "dashboard", "lazy", "mason", "notify", "toggleterm" }
  if vim.tbl_contains(ignored, vim.bo.filetype) or vim.bo.buftype == "terminal" then
    vim.opt_local.colorcolumn = ""
    return
  end

  local limit = 80
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local max_len = 0
  for _, line in ipairs(lines) do
    local len = vim.fn.strdisplaywidth(line)
    if len > max_len then max_len = len end
  end

  if max_len >= limit then
    vim.opt_local.colorcolumn = tostring(limit)
  else
    vim.opt_local.colorcolumn = ""
  end
end

vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "TextChanged", "TextChangedI" }, {
  pattern = "*",
  callback = update_smart_column,
})
