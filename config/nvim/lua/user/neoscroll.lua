local status_ok, neoscroll = pcall(require, 'neoscroll')
if not status_ok then
  return
end

neoscroll.setup({
  easing_function = "quadratic",
})

-- local t
-- t["zb"] = { 'zb', { '10' }}

require('neoscroll.config').set_mappings()
