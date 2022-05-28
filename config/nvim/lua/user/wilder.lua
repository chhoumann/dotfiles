local status_ok, wilder = pcall(require, "wilder")
if not status_ok then
  return
end

wilder.setup({
    modes = {
      ':',
      '/',
      '?'
    }
  })

wilder.set_option('pipeline', {
  wilder.branch(
    wilder.python_file_finder_pipeline({
      -- to use ripgrep : {'rg', '--files'}
      -- to use fd      : {'fd', '-tf'}
      file_command = {'rg', '--files'},
      -- to use fd      : {'fd', '-td'}
      dir_command = {'find', '.', '-type', 'd', '-printf', '%P\n'},
      -- use {'cpsm_filter'} for performance, requires cpsm vim plugin
      -- found at https://github.com/nixprime/cpsm
      filters = {'fuzzy_filter', 'difflib_sorter'},
    }),
    wilder.cmdline_pipeline(),
    wilder.python_search_pipeline()
  ),
})

wilder.set_option('renderer', wilder.popupmenu_renderer({
  -- highlighter applies highlighting to the candidates
  highlighter = wilder.basic_highlighter(),
  pumblend = 20,
  left = {' ', wilder.popupmenu_devicons()},
  right = {' ', wilder.popupmenu_scrollbar()},
}))
