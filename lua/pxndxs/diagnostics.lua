-- Native maps: ]d [d ]D [D jump (opening a float via on_jump), <C-w>d shows the line float.
local severity = vim.diagnostic.severity
local nerd_font = require("pxndxs.settings").nerd_font

---@type vim.diagnostic.Opts.VirtualLines
local virtual_lines = { current_line = true }

local signs = {
  numhl = {
    [severity.ERROR] = "DiagnosticSignError",
    [severity.WARN] = "DiagnosticSignWarn",
  },
}
-- Without a Nerd Font, the default E/W/I/H letters are used
if nerd_font then
  signs.text = {
    [severity.ERROR] = "\u{f057} ",
    [severity.WARN] = "\u{f071} ",
    [severity.HINT] = "\u{f0335} ",
    [severity.INFO] = "\u{f05a} ",
  }
end

vim.diagnostic.config({
  severity_sort = true,
  signs = signs,
  -- Errors inline on every line except the cursor line, where virtual_lines shows the full message
  virtual_text = {
    severity = { min = severity.ERROR },
    spacing = 4,
    prefix = "■",
    current_line = false,
  },
  virtual_lines = virtual_lines,
  float = { source = "if_many" },
  jump = {
    on_jump = function(diagnostic, bufnr)
      if diagnostic then
        vim.diagnostic.open_float({ bufnr = bufnr, scope = "cursor", focus = false })
      end
    end,
  },
})

vim.keymap.set("n", "<leader>ud", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })

vim.keymap.set("n", "<leader>uv", function()
  local enabled = vim.diagnostic.config().virtual_lines ~= false
  vim.diagnostic.config({ virtual_lines = not enabled and virtual_lines or false })
end, { desc = "Toggle diagnostic virtual lines" })
