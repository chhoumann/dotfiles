local status_ok, which_key = pcall(require, "which-key")
if not status_ok then
  return
end

local setup = {
  plugins = {
    marks = true, -- shows a list of your marks on ' and `
    registers = true, -- shows your registers on " in NORMAL or <C-r> in INSERT mode
    spelling = {
      enabled = true, -- enabling this will show WhichKey when pressing z= to select spelling suggestions
      suggestions = 20, -- how many suggestions should be shown in the list?
    },
    -- the presets plugin, adds help for a bunch of default keybindings in Neovim
    -- No actual key bindings are created
    presets = {
      operators = false, -- adds help for operators like d, y, ... and registers them for motion / text object completion
      motions = true, -- adds help for motions
      text_objects = true, -- help for text objects triggered after entering an operator
      windows = true, -- default bindings on <c-w>
      nav = true, -- misc bindings to work with windows
      z = true, -- bindings for folds, spelling and others prefixed with z
      g = true, -- bindings for prefixed with g
    },
  },
  -- add operators that will trigger motion and text object completion
  -- to enable all native operators, set the preset / operators plugin above
  operators = { gc = "Comments" },
  key_labels = {
    -- override the label used to display some keys. It doesn't effect WK in any other way.
    -- For example:
    -- ["<space>"] = "SPC",
    -- ["<cr>"] = "RET",
    -- ["<tab>"] = "TAB",
  },
  icons = {
    breadcrumb = "»", -- symbol used in the command line area that shows your active key combo
    separator = "➜", -- symbol used between a key and it's label
    group = "+", -- symbol prepended to a group
  },
  window = {
    border = "none", -- none, single, double, shadow
    position = "bottom", -- bottom, top
    margin = { 0, 0, 0, 0 }, -- extra window margin [top, right, bottom, left]
    padding = { 1, 0, 1, 0 }, -- extra window padding [top, right, bottom, left]
  },
  layout = {
    height = { min = 1, max = 25 }, -- min and max height of the columns
    width = { min = 20, max = 50 }, -- min and max width of the columns
    spacing = 1, -- spacing between columns
    align = "center", -- align columns left, center or right
  },
  ignore_missing = true, -- enable this to hide mappings for which you didn't specify a label
  hidden = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "call", "lua", "^:", "^ "}, -- hide mapping boilerplate
  show_help = true, -- show help message on the command line when the popup is visible
  triggers = "auto", -- automatically setup triggers
  -- triggers = {"<leader>"} -- or specify a list manually

  triggers_blacklist = {
    -- list of mode / prefixes that should never be hooked by WhichKey
    -- this is mostly relevant for key maps that start with a native binding
    -- most people should not need to change this
    n = { "o", "O" },
    i = { 'j', 'k'},
    v = {'j', 'k'},
  },
}

local opts = {
  mode = 'n',
  prefix = "<leader>",
  buffer = nil,
  silent = true,
  noremap = true,
  nowait = true,
}

local mappings = {
  ['a'] = {"<cmd>Alpha<cr>", "Alpha"},
  ['e'] = {'<cmd>NvimTreeToggle<cr>', "Explorer"},
  ['w'] = {':<C-U>update<cr>', 'Save'},
  ['q'] = {':<C-U>x<cr>', 'Quit'},
  ["P"] = { "<cmd>lua require('telescope').extensions.projects.projects()<cr>", "Projects" },
  ['V'] = {'<cmd>Vista<cr>', 'Vista'},
  ['M'] = {'<cmd>MundoToggle<cr>', 'Mundo'},
  ['Z'] = {'<cmd>ZenMode<cr>', 'ZenMode'},
  [' '] = {'<cmd>StripTrailingWhitespace<cr>', "Strip trailing whitespace"},
  ['A'] = {"<cmd>Neogen<cr>", 'Annotate'},
  ['o'] = {"<cmd>NvimTreeFindFile<cr>", 'Focus Explorer'},
  ['c'] = {"<cmd>bd<cr>", 'Close buffer'}, -- stands for buffer delete


  v = {
    name = "Pasting",
    p = {'m`o<ESC>p``', 'Paste linewise under'},
    P = {'m`O<ESC>p``', 'Paste linewise above'}
  },

  L = {
    name="LaTeX",
    c = {'<cmd>VimtexCompile<cr>', 'Continuous compilation'};
    C = {'<cmd>VimtexClean<cr>', 'Clean'},
    v = {'<cmd>VimtexView<cr>', 'View'},
    e = {'<cmd>VimtexErrors<cr>', 'Errors'},
  },

  x = {
    name="Trouble",
    x = {'<cmd>Trouble<cr>', 'Trouble'},
    w = {'<cmd>Trouble workspace_diagnostics<cr>', 'Trouble Workspace Diagnostics'},
    d = {'<cmd>Trouble document_diagnostics<cr>', 'Trouble Document Diagnostics'},
    l = {'<cmd>Trouble loclist<cr>', 'Trouble Loclist'},
    q = {'<cmd>Trouble quickfix<cr>', 'Trouble Quickfix'},
    R = {'<cmd>Trouble lsp_references<cr>', 'Trouble LSP References'},
  },

  p = {
    name = "Packer",
    c = { "<cmd>PackerCompile<cr>", "Compile" },
    i = { "<cmd>PackerInstall<cr>", "Install" },
    s = { "<cmd>PackerSync<cr>", "Sync" },
    S = { "<cmd>PackerStatus<cr>", "Status" },
    u = { "<cmd>PackerUpdate<cr>", "Update" },
  },

  g = {
    name = "Git",
    g = { "<cmd>lua _LAZYGIT_TOGGLE()<CR>", "Lazygit" },
    s = { "<cmd>Git<CR>", "Git" },
    w = { "<cmd>Gwrite<CR>", "Git (write) add / checkout" },
    c = { "<cmd>Git commit<CR>", "Git commit" },
    d = { "<cmd>Gdiffsplit<CR>", "Git diff split" },
    p = {
      l = { "<cmd>Git pull<CR>", "Git pull" },
      u = { "<cmd>15split | term git push<CR>", "Git push" },
    },
    -- j = { "<cmd>lua require 'gitsigns'.next_hunk()<cr>", "Next Hunk" },
    -- k = { "<cmd>lua require 'gitsigns'.prev_hunk()<cr>", "Prev Hunk" },
    -- l = { "<cmd>lua require 'gitsigns'.blame_line()<cr>", "Blame" },
    -- p = { "<cmd>lua require 'gitsigns'.preview_hunk()<cr>", "Preview Hunk" },
    -- r = { "<cmd>lua require 'gitsigns'.reset_hunk()<cr>", "Reset Hunk" },
    -- R = { "<cmd>lua require 'gitsigns'.reset_buffer()<cr>", "Reset Buffer" },
    -- s = { "<cmd>lua require 'gitsigns'.stage_hunk()<cr>", "Stage Hunk" },
    -- u = {
    --   "<cmd>lua require 'gitsigns'.undo_stage_hunk()<cr>",
    --   "Undo Stage Hunk",
    -- },
    o = { "<cmd>Telescope git_status<cr>", "Open changed file" },
    b = { "<cmd>Telescope git_branches<cr>", "Checkout branch" },
    C = { "<cmd>Telescope git_commits<cr>", "Checkout commit" },
    D = {
      "<cmd>Gitsigns diffthis HEAD<cr>",
      "Diff",
    },

    h = {
        name = "+Github",
        c = {
            name = "+Commits",
            c = { "<cmd>GHCloseCommit<cr>", "Close" },
            e = { "<cmd>GHExpandCommit<cr>", "Expand" },
            o = { "<cmd>GHOpenToCommit<cr>", "Open To" },
            p = { "<cmd>GHPopOutCommit<cr>", "Pop Out" },
            z = { "<cmd>GHCollapseCommit<cr>", "Collapse" },
        },
        i = {
            name = "+Issues",
            p = { "<cmd>GHPreviewIssue<cr>", "Preview" },
        },
        l = {
            name = "+Litee",
            t = { "<cmd>LTPanel<cr>", "Toggle Panel" },
        },
        r = {
            name = "+Review",
            b = { "<cmd>GHStartReview<cr>", "Begin" },
            c = { "<cmd>GHCloseReview<cr>", "Close" },
            d = { "<cmd>GHDeleteReview<cr>", "Delete" },
            e = { "<cmd>GHExpandReview<cr>", "Expand" },
            s = { "<cmd>GHSubmitReview<cr>", "Submit" },
            z = { "<cmd>GHCollapseReview<cr>", "Collapse" },
        },
        p = {
            name = "+Pull Request",
            c = { "<cmd>GHClosePR<cr>", "Close" },
            d = { "<cmd>GHPRDetails<cr>", "Details" },
            e = { "<cmd>GHExpandPR<cr>", "Expand" },
            o = { "<cmd>GHOpenPR<cr>", "Open" },
            p = { "<cmd>GHPopOutPR<cr>", "PopOut" },
            r = { "<cmd>GHRefreshPR<cr>", "Refresh" },
            t = { "<cmd>GHOpenToPR<cr>", "Open To" },
            z = { "<cmd>GHCollapsePR<cr>", "Collapse" },
        },
        t = {
            name = "+Threads",
            c = { "<cmd>GHCreateThread<cr>", "Create" },
            n = { "<cmd>GHNextThread<cr>", "Next" },
            t = { "<cmd>GHToggleThread<cr>", "Toggle" },
        },
    },
  },

  l = {
    name = "LSP",
    a = { "<cmd>lua vim.lsp.buf.code_action()<cr>", "Code Action" },
    d = {
      "<cmd>Telescope lsp_document_diagnostics<cr>",
      "Document Diagnostics",
    },
    w = {
      "<cmd>Telescope lsp_workspace_diagnostics<cr>",
      "Workspace Diagnostics",
    },
    f = { "<cmd>lua vim.lsp.buf.formatting()<cr>", "Format" },
    i = { "<cmd>LspInfo<cr>", "Info" },
    I = { "<cmd>LspInstallInfo<cr>", "Installer Info" },
    j = {
      "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>",
      "Next Diagnostic",
    },
    k = {
      "<cmd>lua vim.lsp.diagnostic.goto_prev()<cr>",
      "Prev Diagnostic",
    },
    l = { "<cmd>lua vim.lsp.codelens.run()<cr>", "CodeLens Action" },
    q = { "<cmd>lua vim.lsp.diagnostic.set_loclist()<cr>", "Quickfix" },
    r = { "<cmd>lua vim.lsp.buf.rename()<cr>", "Rename" },
    s = { "<cmd>Telescope lsp_document_symbols<cr>", "Document Symbols" },
    S = {
      "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>",
      "Workspace Symbols",
    },
  },

  f = {
    name = "Find",
    f = {':<C-U>Leaderf file --popup<CR>', "Find files"},
    p = {':<C-U>Leaderf rg --no-messages --popup<CR>', "Grep project files in popup"},
    h = {':<C-U>Leaderf help --popup<CR>', 'Search VIM help files'},
    t = {':<C-U>Leaderf bufTag --popup<CR>', 'Search tags in current buffer'},
    b = {':<C-U>Leaderf buffer --popup<CR>', 'Switch buffers'},
    r = {':<C-U>Leaderf mru --popup --absolute-path<CR>', 'Search recent files'},
  },

  t = {
    name = "Terminal",
    n = { "<cmd>lua _NODE_TOGGLE()<cr>", "Node" },
    u = { "<cmd>lua _NCDU_TOGGLE()<cr>", "NCDU" },
    t = { "<cmd>lua _HTOP_TOGGLE()<cr>", "Htop" },
    p = { "<cmd>lua _PYTHON_TOGGLE()<cr>", "Python" },
    f = { "<cmd>ToggleTerm direction=float<cr>", "Float" },
    h = { "<cmd>ToggleTerm size=10 direction=horizontal<cr>", "Horizontal" },
    v = { "<cmd>ToggleTerm size=80 direction=vertical<cr>", "Vertical" },
  },

  h = {
    name = "+Hop",
    W = { '<cmd>HopWord<cr>', 'HopWord'},
    L = { '<cmd>HopLine<cr>', 'HopLine'},
    w = { "<cmd>HopWordAC<CR>", 'HopWord before cursor' },
    b = { "<cmd>HopWordBC<CR>", 'HopWord after cursor' },
    j = { "<cmd>HopLineAC<CR>", 'HopLine after cursor' },
    k = { "<cmd>HopLineBC<CR>", 'HopLine before cursor' },
    f = { "<cmd>lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.AFTER_CURSOR, current_line_only = true })<cr>", "Forward find"},
    F = { "<cmd>lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.BEFORE_CURSOR, current_line_only = true })<cr>", "Backward find" },
    t = { "<cmd>lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.AFTER_CURSOR, current_line_only = true })<cr>", "Forward to" },
    T = { "<cmd>lua require'hop'.hint_char1({ direction = require'hop.hint'.HintDirection.BEFORE_CURSOR, current_line_only = true })<cr>", "Backward to" },
    s = { "<cmd>HopPattern<cr>", "Pattern search"},
  }
}

which_key.setup(setup)
which_key.register(mappings, opts)
