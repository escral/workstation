vim.pack.add({
    "https://github.com/folke/tokyonight.nvim",
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
    "https://github.com/neovim/nvim-lspconfig",
    "https://github.com/ibhagwan/fzf-lua",
})

-- Tokyo Night's highlight groups, painted with the theme's colours.
require("tokyonight").setup({
    style = "night",
    on_colors = function(c)
        for name, value in pairs(require("palette")) do c[name] = value end
    end,
})
vim.cmd.colorscheme("tokyonight")

local parsers = require("parsers")
require("nvim-treesitter").install(parsers)
vim.api.nvim_create_autocmd("FileType", {
    callback = function(args)
        if not pcall(vim.treesitter.start, args.buf) then return end
        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
})

local fzf = require("fzf-lua")
fzf.setup({ defaults = { file_icons = false } })
local map = vim.keymap.set
map({ "n", "i", "v" }, "<C-p>", fzf.files)
map("n", "<leader><space>", fzf.buffers)
map("n", "<leader>?", fzf.oldfiles)
map("n", "<leader>/", fzf.blines)
map("n", "<leader>sg", fzf.live_grep)
map("n", "<leader>sw", fzf.grep_cword)
map("n", "<leader>sd", fzf.diagnostics_document)
map("n", "<leader>sh", fzf.helptags)
map("n", "<leader>sb", fzf.git_branches)
-- Redo stays on Ctrl+Shift+Z.
map("n", "<C-r>", fzf.lsp_document_symbols)
