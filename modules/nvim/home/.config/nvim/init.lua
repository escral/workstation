vim.cmd.source(vim.fn.stdpath("config") .. "/common.vim")

vim.o.mouse = "a"
vim.o.undofile = true
vim.o.breakindent = true
vim.o.signcolumn = "yes"
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.expandtab = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.laststatus = 3
vim.o.completeopt = "menuone,noinsert,popup,fuzzy"

vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function() vim.hl.on_yank() end,
})

require("keys")
require("plugins")
require("lsp")
