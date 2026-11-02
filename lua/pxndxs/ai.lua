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

-- Colors derived from the colorscheme, mixed in OKLab (perceptual, no muddy mid-tones)
local function oklab(c)
  local function lin(x)
    x = x / 255
    return x <= 0.04045 and x / 12.92 or ((x + 0.055) / 1.055) ^ 2.4
  end
  local r, g, b =
    lin(bit.rshift(c, 16)), lin(bit.band(bit.rshift(c, 8), 255)), lin(bit.band(c, 255))
  local l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ^ (1 / 3)
  local m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ^ (1 / 3)
  local s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ^ (1 / 3)
  return {
    0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
    1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
  }
end
-- `a` moved toward `b` by `t` (0..1), as #rrggbb
local function mix(a, b, t)
  local x, y = oklab(a), oklab(b)
  local L, A, B = x[1] + (y[1] - x[1]) * t, x[2] + (y[2] - x[2]) * t, x[3] + (y[3] - x[3]) * t
  local l = (L + 0.3963377774 * A + 0.2158037573 * B) ^ 3
  local m = (L - 0.1055613458 * A - 0.0638541728 * B) ^ 3
  local s = (L - 0.0894841775 * A - 1.2914855480 * B) ^ 3
  local function srgb(v)
    v = math.min(math.max(v, 0), 1)
    return math.floor(255 * (v <= 0.0031308 and 12.92 * v or 1.055 * v ^ (1 / 2.4) - 0.055) + 0.5)
  end
  return ("#%02x%02x%02x"):format(
    srgb(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
    srgb(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
    srgb(-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s)
  )
end
local function color(group, attr)
  return vim.api.nvim_get_hl(0, { name = group, link = false })[attr]
end

-- Ghost text: the hint accent dimmed toward the background. Dimmer than comments and a different hue
-- (catppuccin: teal #689796 vs gray italic comments), still ~5:1 contrast. NES diff: red struck-out
-- deletion and green addition, each on a faint tint of its own color.
local function set_highlights()
  local bg = color("Normal", "bg") or 0x000000
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
