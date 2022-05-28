local status_ok, autosave = pcall(require, 'autosave')
if not status_ok then
  return
end

autosave.setup({
  enabled = true,
  execution_message = "Autosaved at " .. vim.fn.strftime("%H:%M:%S"),
  events = { "InsertLeave", "TextChanged" },
  conditions = {
    exists = true,
    filename_is_not = {"plugins.lua"}
  }
})
