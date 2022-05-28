vim.g.Lf_UseCache = 0 -- don't use file cache
vim.g.Lf_UseMemoryCache = 0 -- refresh each time leaderf is called

-- Ignore list
vim.g.Lf_WildIgnore = {
  dir = {'.git', '__pycache__', '.DS_Store', 'node_modules'},
  file = {'*.exe', '*.dll', '*.o', '*.pyc'},
}

-- Only fuzzy-search file names
vim.g.Lf_DefaultMode = 'FullPath'

-- Use ripgrep as the default search tool
vim.g.Lf_DefaultExternalTool = "rg"

-- Show hidden files
vim.g.Lf_ShowHidden = true

-- Disable default mapping
vim.g.Lf_ShortcutF = ''
vim.g.Lf_ShortcutB = ''

-- Set up working directoryh for git repository
vim.g.LF_WorkingDirectoryMode = 'a'
