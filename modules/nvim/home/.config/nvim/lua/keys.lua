-- Habits from ordinary editors, kept next to Vim's own keys.
local map = vim.keymap.set
local all = { "n", "i", "v" }

map(all, "<C-s>", "<Cmd>w<CR><Esc>")
map(all, "<C-z>", "<Cmd>undo<CR>")
map(all, "<C-S-z>", "<Cmd>redo<CR>")

-- Ctrl+C/X take the line when nothing is selected. Ctrl+V is Ghostty's: it
-- pastes the clipboard itself, so block selection is on Ctrl+Q.
map("n", "<C-c>", '"+yy')
map("n", "<C-x>", '"+dd')
map("i", "<C-c>", '<Esc>"+yyi')
map("i", "<C-x>", '<Esc>"+ddi')
map("v", "<C-c>", '"+y')
map("v", "<C-x>", '"+c')

-- Ghostty sends Ctrl+Backspace as Alt+Backspace, which shells take as
-- "delete word"; here it would leave insert mode instead.
map("i", "<M-BS>", "<C-w>")
map("c", "<M-BS>", "<C-w>")
map("i", "<C-Del>", '<C-o>"_dw')

map("v", "<Tab>", ">gv")
map("v", "<S-Tab>", "<gv")
map("n", "<Tab>", ">>")
map("n", "<S-Tab>", "<<")
map("i", "<S-Tab>", "<C-d>")

for _, dir in ipairs({ "Up", "Down", "Left", "Right" }) do
    map("n", "<S-" .. dir .. ">", "v<" .. dir .. ">")
    map("v", "<S-" .. dir .. ">", "<" .. dir .. ">")
    map("i", "<S-" .. dir .. ">", "<C-o>v<" .. dir .. ">")
end

map("n", "<C-Up>", "5k")
map("n", "<C-Down>", "5j")
map({ "n", "v" }, "<C-Right>", "e")
map({ "n", "v" }, "<C-Left>", "b")
map("n", "<C-S-Right>", "ve")
map("n", "<C-S-Left>", "vb")
map("v", "<C-S-Right>", "e")
map("v", "<C-S-Left>", "b")
map("i", "<C-S-Right>", "<C-o>ve")
map("i", "<C-S-Left>", "<C-o>vb")

