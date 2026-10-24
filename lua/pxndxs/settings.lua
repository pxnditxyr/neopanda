-- User toggles. Per-machine overrides go in settings_local.lua (gitignored),
-- which returns a table merged over these defaults.
---@class pxndxs.Settings
---@field ui2 boolean
---@field autoformat boolean
---@field nerd_font boolean

---@type pxndxs.Settings
local defaults = {
  ui2 = true,
  autoformat = true,
  nerd_font = true, -- false: plain letters instead of icons
}

local ok, overrides = pcall(require, "pxndxs.settings_local")
if not ok then
  if not overrides:find("module 'pxndxs.settings_local' not found", 1, true) then
    vim.notify("settings_local.lua: " .. overrides, vim.log.levels.WARN)
  end
  return defaults
end

---@type pxndxs.Settings
local settings = vim.tbl_extend("force", defaults, type(overrides) == "table" and overrides or {})
return settings
