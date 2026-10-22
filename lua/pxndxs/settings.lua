-- User toggles. Per-machine overrides go in settings_local.lua (gitignored),
-- which returns a table merged over these defaults.
local defaults = {
  ui2 = true,
  autoformat = true,
}

local ok, overrides = pcall(require, "pxndxs.settings_local")
if not ok then
  if not overrides:find("module 'pxndxs.settings_local' not found", 1, true) then
    vim.notify("settings_local.lua: " .. overrides, vim.log.levels.WARN)
  end
  return defaults
end

return vim.tbl_extend("force", defaults, type(overrides) == "table" and overrides or {})
