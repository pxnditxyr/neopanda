-- Format on save through LSP. vim.g.autoformat is global, vim.b.autoformat overrides it per buffer.
vim.g.autoformat = require("pxndxs.settings").autoformat

-- One formatter per buffer: biome when the project uses it, vue_ls over vtsls in .vue files
local function formatter(buf)
  local clients = vim.lsp.get_clients({ bufnr = buf, method = "textDocument/formatting" })
  local names = {}
  for _, c in ipairs(clients) do
    names[c.name] = true
  end
  for _, c in ipairs(clients) do
    if names.biome then
      return c.name == "biome" and c or nil
    end
    if not (names.vue_ls and c.name == "vtsls") then
      return c
    end
  end
end

vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("pxndxs.format", {}),
  desc = "Format on save",
  callback = function(args)
    local enabled = vim.b[args.buf].autoformat
    if enabled == nil then
      enabled = vim.g.autoformat
    end
    local client = enabled and formatter(args.buf)
    if client then
      vim.lsp.buf.format({ bufnr = args.buf, id = client.id, timeout_ms = 3000 })
    end
  end,
})

local function state(on)
  return on and "on" or "off"
end

vim.keymap.set("n", "<leader>uf", function()
  vim.g.autoformat = not vim.g.autoformat
  vim.notify("Format on save: " .. state(vim.g.autoformat))
end, { desc = "Toggle format on save" })

vim.keymap.set("n", "<leader>uF", function()
  local current = vim.b.autoformat
  if current == nil then
    current = vim.g.autoformat
  end
  vim.b.autoformat = not current
  vim.notify("Format on save (buffer): " .. state(vim.b.autoformat))
end, { desc = "Toggle format on save (buffer)" })
