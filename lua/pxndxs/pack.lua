-- Plugins: vim.pack, pinned in nvim-pack-lock.json (created with the first plugin; commit it).
-- :packupdate to update, :packupdate ++lockfile to revert, :packdel ++all after removing a spec.

-- Build steps run after install/update
---@type table<string, fun(ev: table)>
local build = {
  -- Parsers must match the plugin revision
  ["nvim-treesitter"] = function()
    vim.cmd("TSUpdate")
  end,
}

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
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
  "https://github.com/nvim-treesitter/nvim-treesitter-context",
  "https://github.com/HiPhish/rainbow-delimiters.nvim",
  "https://github.com/windwp/nvim-ts-autotag",
  "https://github.com/Wansmer/treesj",
  "https://github.com/folke/ts-comments.nvim",
  "https://github.com/b0o/SchemaStore.nvim",
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/nvim-flutter/flutter-tools.nvim",
  "https://github.com/nvim-mini/mini.snippets",
  "https://github.com/rafamadriz/friendly-snippets",
  "https://github.com/nvim-mini/mini.pairs",
  "https://github.com/nvim-mini/mini.surround",
  "https://github.com/nvim-mini/mini.ai",
  "https://github.com/nvim-mini/mini.hipatterns",
  "https://github.com/folke/flash.nvim",
  "https://github.com/nvim-mini/mini.clue",
  "https://github.com/stevearc/oil.nvim",
  "https://github.com/MagicDuck/grug-far.nvim",
  { src = "https://github.com/catppuccin/nvim", name = "catppuccin" },
  "https://github.com/nvim-mini/mini.icons",
  "https://github.com/nvim-mini/mini.pick",
  "https://github.com/nvim-mini/mini.extra",
  "https://github.com/nvim-mini/mini.indentscope",
  "https://github.com/MeanderingProgrammer/render-markdown.nvim",
  "https://github.com/lewis6991/gitsigns.nvim",
}

-- Install only; lze loads each plugin from its spec in lua/pxndxs/plugins/
vim.pack.add(specs, { load = function() end })
vim.cmd.packadd("lze")
require("lze").load({ import = "pxndxs.plugins" })
