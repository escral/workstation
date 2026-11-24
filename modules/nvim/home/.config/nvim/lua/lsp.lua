-- Servers come from pacman (the module's packages), configs from lspconfig.
vim.lsp.config("ts_ls", {
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
    init_options = {
        plugins = { {
            name = "@vue/typescript-plugin",
            -- The vue-language-server package; the plugin resolves from it.
            location = "/usr/lib/node_modules/@vue/language-server",
            languages = { "vue" },
        } },
    },
})
vim.lsp.config("lua_ls", {
    -- vim in Neovim's config, hl in Hyprland's.
    settings = { Lua = { diagnostics = { globals = { "vim", "hl" } } } },
})
vim.lsp.enable({
    "ts_ls", "vue_ls", "cssls", "html", "jsonls", "yamlls",
    "intelephense", "bashls", "lua_ls",
})

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
        if client:supports_method("textDocument/completion") then
            vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
        end
        local function map(lhs, fn) vim.keymap.set("n", lhs, fn, { buffer = args.buf }) end
        local fzf = require("fzf-lua")
        map("gd", fzf.lsp_definitions)
        map("gr", fzf.lsp_references)
        -- As in the JetBrains IDEs.
        map("<C-b>", vim.lsp.buf.definition)
        map("<leader>rn", vim.lsp.buf.rename)
        map("<leader>ca", vim.lsp.buf.code_action)
        map("<leader>e", vim.diagnostic.open_float)
    end,
})

-- The menu preselects its first item: Enter or Tab takes it.
local function accept(key)
    return function() return vim.fn.pumvisible() == 1 and "<C-y>" or key end
end
vim.keymap.set("i", "<CR>", accept("<CR>"), { expr = true })
vim.keymap.set("i", "<Tab>", accept("<Tab>"), { expr = true })
vim.keymap.set("i", "<C-Space>", vim.lsp.completion.get)
