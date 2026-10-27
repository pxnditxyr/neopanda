-- Plugins: vim.pack, pinned in nvim-pack-lock.json (created with the first plugin; commit it).
-- :packupdate to update, :packupdate ++lockfile to revert, :packdel ++all after removing a spec.

-- Build steps run after install/update, e.g. build["nvim-treesitter"] = function() vim.cmd("TSUpdate") end
---@type table<string, fun(ev: table)>
local build = {}

-- Registered before vim.pack.add so it also runs on first install (including from the lockfile)
vim.api.nvim_create_autocmd("PackChanged", {
  group = vim.api.nvim_create_augroup("pxndxs.pack", {}),
  desc = "Run plugin build steps",
  callback = function(ev)
    local data = ev.data
    local step = build[data.spec.name]
    if not step or (data.kind ~= "install" and data.kind ~= "update") then
      return
    end
    vim.schedule(function()
      if not data.active then
        vim.cmd.packadd(data.spec.name)
      end
      local ok, err = pcall(step, ev)
      if not ok then
        vim.notify(("build %s: %s"):format(data.spec.name, err), vim.log.levels.WARN)
      end
    end)
  end,
})

---@type (string|vim.pack.Spec)[]
local specs = {
  "https://github.com/BirdeeHub/lze",
  "https://github.com/mason-org/mason.nvim",
}

-- Install only; lze loads each plugin from its spec in lua/pxndxs/plugins/
vim.pack.add(specs, { load = function() end })
vim.cmd.packadd("lze")
require("lze").load({ import = "pxndxs.plugins" })
