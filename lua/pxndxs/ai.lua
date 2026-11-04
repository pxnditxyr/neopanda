-- AI inline suggestions: Copilot through the native LSP client (lsp/copilot.lua + vim.lsp.inline_completion).
-- sidekick (Copilot NES + AI CLIs) lives in plugins/ai.lua.
local M = {}

-- File names never sent to AI suggestions
local secrets = {
  "^%.env$",
  "^%.env%.",
  "%.pem$",
  "%.key$",
  "^id_rsa",
  "^id_ed25519",
  "^id_ecdsa",
  "^secrets?%.",
  "^%.netrc$",
  "^credentials",
  "%.kdbx$",
}

---@param buf? integer
function M.is_secret(buf)
  local name = vim.fs.basename(vim.api.nvim_buf_get_name(buf or 0)):lower()
  for _, pattern in ipairs(secrets) do
    if name:find(pattern) then
      return true
    end
  end
  return false
end

M.enabled = true

-- Copilot NES (sidekick) follows the inline suggestions toggle
local function apply()
  vim.lsp.inline_completion.enable(M.enabled)
  vim.g.sidekick_nes = M.enabled
end
apply()

-- Colors derived from the colorscheme
local mix = require("pxndxs.theme").mix
local function color(group, attr)
  return vim.api.nvim_get_hl(0, { name = group, link = false })[attr]
end

-- Ghost text: the hint accent dimmed toward the background. Dimmer than comments and a different hue
-- (catppuccin: teal #689796 vs gray italic comments), still ~5:1 contrast. NES diff: red struck-out
-- deletion and green addition, each on a faint tint of its own color.
local function set_highlights()
  local bg = require("pxndxs.theme").bg or 0x000000
  local hint = color("DiagnosticHint", "fg") or color("Comment", "fg") or 0x808080
  vim.api.nvim_set_hl(0, "ComplHint", { fg = mix(hint, bg, 0.35) })
  vim.api.nvim_set_hl(0, "ComplHintMore", { fg = mix(hint, bg, 0.2), bold = true })
  for group, src in pairs({
    SidekickDiffDelete = "DiagnosticError",
    SidekickDiffAdd = "DiagnosticOk",
  }) do
    local fg = color(src, "fg") or 0x808080
    vim.api.nvim_set_hl(0, group, {
      fg = fg,
      bg = mix(fg, bg, 0.78),
      strikethrough = group == "SidekickDiffDelete",
    })
  end
end
set_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("pxndxs.ai", {}),
  callback = set_highlights,
})

-- <Tab> in Insert: accept the suggestion, else jump to the next snippet field, else a real <Tab>.
-- In Normal: jump to / apply the Copilot next edit (NES), else <Tab> (= <C-i>, jump forward).
local function feed(key)
  vim.api.nvim_feedkeys(vim.keycode(key), "in", false) -- "i": before keys typed after it
end
vim.keymap.set("i", "<Tab>", function()
  if vim.lsp.inline_completion.get() then
    return
  end
  if vim.snippet.active({ direction = 1 }) then
    return vim.snippet.jump(1)
  end
  feed("<Tab>")
end, { desc = "Accept AI suggestion / next snippet field / Tab" })
vim.keymap.set("n", "<Tab>", function()
  if not (package.loaded["sidekick"] and require("sidekick").nes_jump_or_apply()) then
    feed("<Tab>")
  end
end, { desc = "Next edit suggestion (jump / apply)" })

vim.keymap.set("i", "<M-n>", function()
  vim.lsp.inline_completion.select({ count = 1 })
end, { desc = "Next AI suggestion" })
vim.keymap.set("i", "<M-p>", function()
  vim.lsp.inline_completion.select({ count = -1 })
end, { desc = "Previous AI suggestion" })

vim.keymap.set("n", "<leader>ua", function()
  M.enabled = not M.enabled
  apply()
  vim.notify("AI suggestions: " .. (M.enabled and "on" or "off"))
end, { desc = "Toggle AI suggestions" })

return M
