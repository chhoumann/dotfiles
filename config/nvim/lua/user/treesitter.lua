local configs = require("nvim-treesitter.configs")
configs.setup {
  ensure_installed = "all",
  sync_install = false,
  ignore_install = { "" }, -- List of parsers to ignore installing
  highlight = {
    enable = true, -- false will disable the whole extension
    disable = { "" }, -- list of language that will be disabled
    additional_vim_regex_highlighting = true,

  },
  indent = { enable = true, disable = { "yaml" } },
  autopairs = {
    enable = true
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection    = "<cr>",
      scope_incremental = "<cr>",
      node_incremental  = "<tab>",
      node_decremental  = "<s-tab>",
    },
  },
  -- Using incremental selection instead.
  textsubjects = {
      enable = false,
      -- prev_selection = ',', -- (Optional) keymap to select the previous selection
      keymaps = {
        ['<cr>'] = 'textsubjects-smart'
          -- ['.'] = 'textsubjects-smart',
          -- [';'] = 'textsubjects-container-outer',
          -- ['i;'] = 'textsubjects-container-inner',
      },
  },
  textobjects = {
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner"
      },
    },
    move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
      goto_next_start = {
        ["]m"] = "@function.outer",
        ["]]"] = "@class.outer",
      },
      goto_next_end = {
        ["]M"] = "@function.outer",
        ["]["] = "@class.outer",
      },
      goto_previous_start = {
        ["[m"] = "@function.outer",
        ["[["] = "@class.outer",
      },
      goto_previous_end = {
        ["[M"] = "@function.outer",
        ["[]"] = "@class.outer",
      },
    },
    lsp_interop = {
      enable = true,
      border = 'none',
      peek_definition_code = {
        ["<leader>df"] = "@function.outer",
        ["<leader>dF"] = "@class.outer",
      },
    },
  }
}
