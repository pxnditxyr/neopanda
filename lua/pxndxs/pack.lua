-- Plugins: vim.pack, pinned in nvim-pack-lock.json (created with the first plugin; commit it).
-- :packupdate to update, :packupdate ++lockfile to revert, :packdel ++all after removing a spec.
local config = require("pxndxs.env").config
local pinned = config .. "/nvim-pack-lock.json"
local lockfile = pinned
local seed, marker -- only with a read-only config

-- A read-only config (Nix store) keeps a writable copy of the lockfile. The copy is replaced only when the pinned
-- one changes, so :packupdate lasts until then. Must be set before the first vim.pack call.
if not vim.uv.fs_access(config, "W") then
  local state = vim.fn.stdpath("state")
  lockfile, marker = state .. "/nvim-pack-lock.json", state .. "/nvim-pack-lock.seed"
  local lines = vim.fn.readfile(pinned)
  local hash = vim.fn.sha256(table.concat(lines, "\n"))
  local seeded = vim.uv.fs_stat(marker) and vim.fn.readfile(marker)[1]
  if seeded ~= hash then
    seed = { hash = hash, plugins = vim.json.decode(table.concat(lines, "\n")).plugins }
    vim.fn.mkdir(state, "p")
    vim.fn.writefile(lines, lockfile) -- not fs_copyfile: it would keep the store's read-only mode
  end
end
vim.o.packlockfile = lockfile

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
  "https://github.com/nvim-mini/mini.starter",
  "https://github.com/nvim-mini/mini.pick",
  "https://github.com/nvim-mini/mini.extra",
  "https://github.com/nvim-mini/mini.indentscope",
  "https://github.com/MeanderingProgrammer/render-markdown.nvim",
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/folke/sidekick.nvim",
  "https://github.com/coder/claudecode.nvim",
  "https://codeberg.org/mfussenegger/nvim-dap",
  "https://github.com/igorlfs/nvim-dap-view",
  "https://github.com/nvim-neotest/nvim-nio",
  "https://github.com/nvim-neotest/neotest",
  "https://github.com/fredrikaverpil/neotest-golang",
  "https://github.com/marilari88/neotest-vitest",
  "https://github.com/sidlatau/neotest-dart",
  "https://github.com/tpope/vim-dadbod",
  "https://github.com/kristijanhusak/vim-dadbod-ui",
  "https://github.com/kristijanhusak/vim-dadbod-completion",
  "https://github.com/MunifTanjim/nui.nvim",
  "https://github.com/jellydn/hurl.nvim",
  "https://github.com/saecki/crates.nvim",
}

-- Install only; lze loads each plugin from its spec in lua/pxndxs/plugins/
vim.pack.add(specs, { load = function() end, confirm = false })

-- A new pinned lockfile moves the plugins to it. The marker is written only when all of them got there, so a failed
-- download retries on the next start instead of losing pins.
if seed then
  local function synced()
    local revs = {}
    for _, p in ipairs(vim.pack.get()) do -- info: the rev on disk, not the lockfile's
      revs[p.spec.name] = p.rev
    end
    for name, data in pairs(seed.plugins) do
      if revs[name] ~= data.rev then
        return false
      end
    end
    return true
  end
  if not synced() then
    pcall(vim.pack.update, nil, { force = true, target = "lockfile" })
  end
  if synced() then
    vim.fn.writefile({ seed.hash }, marker)
  end
end
if not pcall(vim.cmd.packadd, "lze") then
  vim.notify(
    "Plugins not installed (no network?). They install on the next start.",
    vim.log.levels.WARN
  )
  return
end
require("lze").load({ import = "pxndxs.plugins" })
