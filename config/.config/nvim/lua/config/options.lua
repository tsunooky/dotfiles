-- Core Options
vim.g.mapleader = " "

-- Appearance
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.cursorline = true
vim.opt.cursorlineopt = "both"
vim.opt.list = true
vim.opt.listchars = { tab = " ", trail = " " }
vim.opt.fillchars = { vert = "│", eob = " " }
vim.opt.signcolumn = "yes"
vim.opt.termguicolors = true
vim.opt.pumheight = 8

-- Indentation
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4

-- System
vim.opt.clipboard = "unnamedplus"
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
