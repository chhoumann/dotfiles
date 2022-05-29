local fn = vim.fn

-- Automatically install packer
local install_path = fn.stdpath "data" .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
  PACKER_BOOTSTRAP = fn.system {
    "git",
    "clone",
    "--depth",
    "1",
    "https://github.com/wbthomason/packer.nvim",
    install_path,
  }
  print "Installing packer close and reopen Neovim..."
  vim.cmd [[packadd packer.nvim]]
end

-- Autocommand that reloads neovim whenever you save the plugins.lua file
vim.cmd [[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup end
]]

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
  return
end

-- Have packer use a popup window
packer.init {
  display = {
    open_fn = function()
      return require("packer.util").float { border = "rounded" }
    end,
  },
}

-- Install your plugins here
return packer.startup(function(use)
  -- My plugins here
  use "wbthomason/packer.nvim" -- Have packer manage itself
  use "nvim-lua/popup.nvim" -- An implementation of the Popup API from vim in Neovim
  use "nvim-lua/plenary.nvim" -- Useful lua functions used ny lots of plugins
  use { 'windwp/nvim-autopairs' } -- autopairs integrates with cmp and treesitter
  use { 'tpope/vim-commentary' } -- for commenting
  use { 'lewis6991/gitsigns.nvim' } -- annotates with git signs
  use { 'kyazdani42/nvim-web-devicons' }
  use { 'kyazdani42/nvim-tree.lua' }
  use "akinsho/bufferline.nvim"
  use "jose-elias-alvarez/null-ls.nvim" -- for formatters and linters
  use "nvim-lualine/lualine.nvim"
  use "akinsho/toggleterm.nvim"
  use "ahmedkhalf/project.nvim"
  use "lukas-reineke/indent-blankline.nvim"
  use 'goolord/alpha-nvim'
  use "antoinemadec/FixCursorHold.nvim" -- This is needed to fix lsp doc highlight
  use "folke/which-key.nvim"
  use "machakann/vim-sandwich"
  use "lervag/vimtex"
  use {"phaazon/hop.nvim"}
  use {'kevinhwang91/nvim-bqf', ft = 'qf'}
  use {"kevinhwang91/nvim-hlslens"}
  use {'gelguy/wilder.nvim'}
  use "karb94/neoscroll.nvim"
  use {'liuchengxu/vista.vim', cmd="Vista"}
  use "Pocco81/AutoSave.nvim"
  use {'simnalamburt/vim-mundo', cmd={"MundoToggle", "MundoShow"}}
  use {"folke/zen-mode.nvim", cmd="ZenMode"}
  use {"jdhao/whitespace.nvim"}
  use {'nvim-telescope/telescope-ui-select.nvim' }
  use {"j-hui/fidget.nvim", config=function() require("fidget").setup() end}
  use {'stevearc/dressing.nvim'}
  use {'rcarriga/nvim-notify'}
  use { "beauwilliams/focus.nvim", config = function() require("focus").setup() end }

  -- Git command inside vim
  use({ "tpope/vim-fugitive", event = "User InGitRepo" })

  -- Better git log display
  use({ "rbong/vim-flog", requires = "tpope/vim-fugitive", cmd = { "Flog" } })

  use({ "christoomey/vim-conflicted", requires = "tpope/vim-fugitive", cmd = {"Conflicted"}})

  -- Doesn't work very well right now. Hopefully it does in the future!
  -- use {
  --   'ldelossa/gh.nvim',
  --   requires = { { 'ldelossa/litee.nvim' } }
  -- }

  -- Better git commit experience
  use({"rhysd/committia.vim", opt = true, setup = [[vim.cmd('packadd committia.vim')]]})

  -- optional
  use {'junegunn/fzf', run = function()
      vim.fn['fzf#install']()
  end
  }

  -- Colorschemes
  use "EdenEast/nightfox.nvim"

  -- cmp plugins
  use "hrsh7th/nvim-cmp" -- completion plugin
  use "hrsh7th/cmp-nvim-lsp"
  use 'hrsh7th/cmp-nvim-lua'
  use 'hrsh7th/cmp-buffer' -- buffer completions
  use 'hrsh7th/cmp-path' -- path completions
  use 'hrsh7th/cmp-cmdline' -- cmdline completions
  use 'hrsh7th/cmp-calc' -- math calc

  -- use {"quangnguyen30192/cmp-nvim-ultisnips", after = {'nvim-cmp', 'ultisnips'}} -- snippet engine support
  use { 'saadparwaiz1/cmp_luasnip' }

  -- Snippet engine & snippets
  use "L3MON4D3/LuaSnip" --snippet engine
  --use "SirVer/ultisnips" -- snippet engine
  use({"honza/vim-snippets"})
  use({"rafamadriz/friendly-snippets"})

  -- LSP
  use 'neovim/nvim-lspconfig' -- enable LSP
  use 'williamboman/nvim-lsp-installer' -- easy to use language server installer

  -- File search, tag search, etc
  use { 'Yggdroot/LeaderF' }

  -- Treesitter
  use { 'nvim-treesitter/nvim-treesitter', run = ":TSUpdate" }
  use { 'nvim-telescope/telescope.nvim' }
  use {'nvim-treesitter/nvim-treesitter-textobjects'}
  use { 'RRethy/nvim-treesitter-textsubjects', after = { 'nvim-treesitter' } }

  use {
    "danymat/neogen",
    config = function()
        require('neogen').setup {}
    end,
    requires = "nvim-treesitter/nvim-treesitter",
    -- Uncomment next line if you want to follow only stable versions
    -- tag = "*"
}

  use {
    "folke/trouble.nvim",
    requires = "kyazdani42/nvim-web-devicons",
    config = function()
      require("trouble").setup {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
      }
    end
    }

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if PACKER_BOOTSTRAP then
    require("packer").sync()
  end
end)
