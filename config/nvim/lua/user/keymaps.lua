local opts = { noremap = true, silent = true }

local term_opts = { silent = true }

-- Shorten function name
local keymap = vim.api.nvim_set_keymap

--Remap space as leader key EDIT: comma
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- Faster save and exit
-- Fast save
keymap("n", "<leader>w", ":<C-U>update<CR>", opts)
-- Fast exit
keymap("n", "<leader>q", ":<C-U>x<CR>", opts)
-- Quit all opened buffers
--keymap("n", "<leaderQ", "<C-U>qa!<CR>", opts)

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

-- Normal --
-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

-- Navigate windows with arrow keys
keymap('n', '<Left>', '<C-W>h', opts)
keymap('n', '<Right>', '<C-W>l', opts)
keymap('n', '<Up>', '<C-W>k', opts)
keymap('n', '<Down>', '<C-W>j', opts)

keymap("n", "<leader>e", ":NvimTreeToggle<cr>", opts)

-- Resize with arrows
keymap("n", "<C-Up>", ":resize +2<CR>", opts)
keymap("n", "<C-Down>", ":resize -2<CR>", opts)
keymap("n", "<C-Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- Navigate buffers
keymap("n", "<S-l>", ":bnext<CR>", opts)
keymap("n", "<S-h>", ":bprevious<CR>", opts)

-- Close buffer
keymap('n', '<A-w>', ':bwipeout<CR>', opts)

-- Move cursor based on physical lines, not actual lines
vim.cmd"nnoremap <expr> j (v:count == 0 ? 'gj' : 'j')"
vim.cmd"nnoremap <expr> k (v:count == 0 ? 'gk' : 'k')"
keymap("n", "^", "g^", opts)
keymap("n", "0", "g0", opts)

-- Jump to matching pairs easily in normal mode
--keymap("n", "<Tab", "%", opts)

-- Remove trailing whitespace characters
--keymap('n', '<leader><Space>', ':<C-U>StripTrailingWhitespace<CR>', opts)

-- Clear highlighting
keymap('n', '<C-L>', ":<C-U>nohlsearch<C-R>=has('diff')?'<Bar>diffupdate':''<CR><CR><C-L>", opts)

-- Insert --
-- Press jk fast to enter
keymap("i", "jk", "<ESC>", opts)

-- Visual --
-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Move text up and down
keymap("v", "<A-j>", ":m .+1<CR>==", opts)
keymap("v", "<A-k>", ":m .-2<CR>==", opts)

-- Don't yank when pasting over selected text
keymap("v", "p", '"_dP', opts)

-- Visual Block --
-- Move text up and down
keymap("x", "J", ":move '>+1<CR>gv-gv", opts)
keymap("x", "K", ":move '<-2<CR>gv-gv", opts)
keymap("x", "<A-j>", ":move '>+1<CR>gv-gv", opts)
keymap("x", "<A-k>", ":move '<-2<CR>gv-gv", opts)

-- Do not include what space characters when using $ in visual mode.
-- see https://vi.stackexchange.com/q/12607/15292
keymap('x', '$', 'g_', opts)

-- Terminal --
-- Better terminal navigation
keymap("t", "<C-h>", "<C-\\><C-N><C-w>h", term_opts)
keymap("t", "<C-j>", "<C-\\><C-N><C-w>j", term_opts)
keymap("t", "<C-k>", "<C-\\><C-N><C-w>k", term_opts)
keymap("t", "<C-l>", "<C-\\><C-N><C-w>l", term_opts)

-- MISC --
-- Change text without putting it into the vim register.
keymap("n", 'c', '"_c', opts)
keymap("n", 'C', '"_C', opts)
keymap("n", 'cc', '"_cc', opts)
keymap("x", 'c', '"_c', opts)

-- PLUGINS --
-- Leaderf --
-- Search files in popup
vim.cmd"nnoremap <silent> <leader>ff :<C-U>Leaderf file --popup<CR>"

-- Grep project files in popup
vim.cmd"nnoremap <silent> <leader>fp :<C-U>Leaderf rg --no-messages --popup<CR>"

-- Search vim help files
vim.cmd"nnoremap <silent> <leader>fh :<C-U>Leaderf help --popup<CR>"

-- Search tags in current buffer
vim.cmd"nnoremap <silent> <leader>ft :<C-U>Leaderf bufTag --popup<CR>"

-- Switch buffers
vim.cmd"nnoremap <silent> <leader>fb :<C-U>Leaderf buffer --popup<CR>"

-- Search recent files
vim.cmd"nnoremap <silent> <leader>fr :<C-U>Leaderf mru --popup --absolute-path<CR>"

-- TELESCOPE --
--keymap("n", "<leader>tf", "<cmd>lua require'telescope.builtin'.find_files(require('telescope.themes').get_dropdown({ previewer = false }))<cr>", opts)
-- Live grep
keymap("n", "<c-t>", "<cmd>Telescope live_grep<cr>", opts)
-- -- See git branches
-- keymap('n', '<leader>fgb', '<cmd>Telescope git_branches<cr>', opts)
-- -- See git commits
-- keymap('n', '<leader>fgc', '<cmd>Telescope git_commits<cr>', opts)
-- -- See commits for buffer
-- keymap('n', '<leader>fgC', '<cmd>Telescope git_bcommits<cr>', opts)
-- -- See git status
-- keymap('n', '<leader>fgs', '<cmd>Telescope git_status<cr>', opts)
-- See Treesitter functions, variables, etc.
keymap('n', '<leader>fT', '<cmd>Telescope treesitter<cr>', opts)

-- HOP --
-- -- place this in one of your configuration file(s)
-- normal mode (easymotion-like)
vim.api.nvim_set_keymap("n", "<leader>hb", "<cmd>HopWordBC<CR>", {noremap=true})
vim.api.nvim_set_keymap("n", "<leader>hw", "<cmd>HopWordAC<CR>", {noremap=true})
vim.api.nvim_set_keymap("n", "<leader>hj", "<cmd>HopLineAC<CR>", {noremap=true})
vim.api.nvim_set_keymap("n", "<leader>hk", "<cmd>HopLineBC<CR>", {noremap=true})

-- visual mode (easymotion-like)
vim.api.nvim_set_keymap("v", "<leader>hw", "<cmd>HopWordAC<CR>", {noremap=true})
vim.api.nvim_set_keymap("v", "<leader>hb", "<cmd>HopWordBC<CR>", {noremap=true})
vim.api.nvim_set_keymap("v", "<leader>hj", "<cmd>HopLineAC<CR>", {noremap=true})
vim.api.nvim_set_keymap("v", "<leader>hk", "<cmd>HopLineBC<CR>", {noremap=true})


-- normal mode (sneak-like)
vim.api.nvim_set_keymap("n", "s", "<cmd>HopChar2AC<CR>", {noremap=false})
vim.api.nvim_set_keymap("n", "S", "<cmd>HopChar2BC<CR>", {noremap=false})

-- visual mode (sneak-like)
vim.api.nvim_set_keymap("v", "s", "<cmd>HopChar2AC<CR>", {noremap=false})
vim.api.nvim_set_keymap("v", "S", "<cmd>HopChar2BC<CR>", {noremap=false})

-- HLSLENS
vim.api.nvim_set_keymap('n', 'n', [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]], opts)
vim.api.nvim_set_keymap('n', 'N', [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]], opts)
vim.api.nvim_set_keymap('n', '*', [[*<Cmd>lua require('hlslens').start()<CR>]], opts)
vim.api.nvim_set_keymap('n', '#', [[#<Cmd>lua require('hlslens').start()<CR>]], opts)
vim.api.nvim_set_keymap('n', 'g*', [[g*<Cmd>lua require('hlslens').start()<CR>]], opts)
vim.api.nvim_set_keymap('n', 'g#', [[g#<Cmd>lua require('hlslens').start()<CR>]], opts)
