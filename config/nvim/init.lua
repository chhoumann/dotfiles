require "user.options"
require "user.keymaps"
require "user.plugins"
require "user.colorscheme"

-- Plugins config
-- require "user.ultisnips"
require "user.cmp"
require "user.lsp"
require "user.leaderf"
require "user.treesitter"
require "user.autopairs"
require "user.telescope"
require "user.gitsigns"
require "user.nvim-tree"
require "user.bufferline"
require "user.lualine"
require "user.toggleterm"
require "user.project"
require "user.impatient"
require "user.indentline"
require "user.alpha"
require "user.whichkey"
require "user.vimtex"
require "user.nvim_hop"
require "user.wilder"
require "user.neoscroll"
require "user.autosave"
require "user.vim-mundo"
require 'user.zen-mode'
-- require "user.gh_nvim" -- Waiting for more improvements. Feels buggy.
require "user.luasnip_config"


-- Settings
vim.cmd"set undofile"
vim.cmd"set undodir=~/.vim/undo"

-- Check if we are in git repo and if we are, trigger autocmd.
-- https://github.com/wbthomason/packer.nvim/discussions/534
vim.cmd[[
  augroup git_repo_check
    autocmd!
    autocmd VimEnter,DirChanged * call Inside_git_repo()
  augroup END

  " Check if we are inside a Git repo
  function! Inside_git_repo() abort
    let res = system('git rev-parse --is-inside-work-tree')
    if match(res, 'true') == -1
      return v:false
    else
      " Trigger a speical user autocmd
      doautocmd User InGitRepo
      return v:true
    endif
  endfunction
]]

