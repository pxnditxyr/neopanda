-- :checkhealth neopanda — status of everything this config relies on.
-- Not repeated here: :checkhealth vim.lsp, vim.pack, vim.treesitter, vim.provider.
local health = vim.health
local env = require("pxndxs.env")
local settings = require("pxndxs.settings")

local config_dir = vim.fn.stdpath("config")

-- "name ······ " aligned to width
local function pad(name, width)
  return ("%s %s "):format(name, ("·"):rep(math.max(width - vim.fn.strdisplaywidth(name), 1)))
end

local function version_of(bin)
  local ok, res = pcall(function()
    return vim.system({ bin, "--version" }, { text = true }):wait(2000)
  end)
  return ok and res.code == 0 and (res.stdout or ""):match("%d+%.%d+[%.%d]*") or "?"
end

local function neovim()
  health.start("🐼 neopanda")
  local version = vim.api.nvim_exec2("version", { output = true }).output:match("NVIM v(%S+)")
  if vim.fn.has("nvim-0.13") == 1 then
    health.ok(pad("Neovim", 10) .. version)
  else
    health.error(pad("Neovim", 10) .. version, "neopanda targets Neovim nightly 0.13+")
  end
  health.ok(pad("Config", 10) .. vim.fn.fnamemodify(config_dir, ":~"))
end

local function environment()
  health.start("🖥️ Environment")
  local system = env.is_wsl and "🪟 WSL"
    or env.is_mac and "🍎 macOS"
    or env.is_linux and "🐧 Linux"
    or "❔ " .. vim.uv.os_uname().sysname
  health.info(pad("System", 10) .. system)
  health.info(pad("Nix", 10) .. (env.is_nix and "❄️ wrapper" or "○ no"))
  health.info(pad("SSH", 10) .. (env.is_ssh and "🔐 yes · OSC 52 clipboard" or "○ no"))
  local ok, tool = pcall(vim.fn["provider#clipboard#Executable"])
  if ok and tool ~= "" then
    health.info(pad("Clipboard", 10) .. "📋 " .. tool)
  else
    health.warn(pad("Clipboard", 10) .. "no clipboard tool", ":help clipboard")
  end
end

local function settings_section()
  health.start("⚙️ Settings")
  local names = vim.tbl_keys(settings)
  table.sort(names)
  for _, name in ipairs(names) do
    local value = settings[name]
    local shown = value == true and "● on" or value == false and "○ off" or vim.inspect(value)
    health.info(pad(name, 12) .. shown)
  end
  local has_local = vim.uv.fs_stat(config_dir .. "/lua/pxndxs/settings_local.lua") ~= nil
  health.info(
    pad("overrides", 12) .. (has_local and "📝 settings_local.lua" or "○ none · defaults")
  )
end

local function tools()
  health.start("🧰 Tools")
  local list = {
    { "git", health.error, "vim.pack needs git" },
    { "rg", health.warn, ":grep falls back to the internal grep" },
    { "fd", health.warn, ":find falls back to rg --files" },
  }
  for _, tool in ipairs(list) do
    local bin, report, advice = unpack(tool)
    if vim.fn.executable(bin) == 1 then
      health.ok(pad(bin, 6) .. version_of(bin))
    else
      report(pad(bin, 6) .. "not found", advice)
    end
  end
end

local function lsp_servers()
  health.start("🧠 LSP servers")
  local files = vim.fn.globpath(config_dir, "lsp/*.lua", false, true)
  local installed = 0
  for _, file in ipairs(files) do
    local name = vim.fn.fnamemodify(file, ":t:r")
    local cmd = (vim.lsp.config[name] or {}).cmd
    local bin = type(cmd) == "table" and cmd[1] or nil
    if bin and vim.fn.executable(bin) == 1 then
      installed = installed + 1
      health.ok(pad(name, 14) .. bin)
    else
      health.warn(
        pad(name, 14) .. "not installed · server skipped",
        env.is_nix and bin and ("put `" .. bin .. "` on PATH")
          or "install it with :Mason if it is there (nixd is Nix only)"
      )
    end
  end
  health.info(("🎯 %d/%d installed"):format(installed, #files))
end

local function plugins()
  health.start("📦 Plugins")
  if vim.uv.fs_access(config_dir, "W") then
    health.ok(pad("Config dir", 12) .. "writable")
  else
    health.error(pad("Config dir", 12) .. "read-only", "vim.pack writes nvim-pack-lock.json there")
  end
  local lockfile = vim.o.packlockfile
  if not vim.uv.fs_stat(lockfile) then
    health.ok(pad("Lockfile", 12) .. "none yet · no plugins")
    return
  end
  local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(lockfile), "\n"))
  if ok and type(data) == "table" then
    health.ok(pad("Lockfile", 12) .. ("%d pinned"):format(vim.tbl_count(data.plugins or {})))
  else
    health.error(pad("Lockfile", 12) .. "invalid JSON", "git checkout -- nvim-pack-lock.json")
  end
end

return {
  check = function()
    neovim()
    environment()
    settings_section()
    tools()
    lsp_servers()
    plugins()
  end,
}
