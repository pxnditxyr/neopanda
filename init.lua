-- neopanda 🐼
vim.g.pxndxs_start = vim.uv.hrtime() -- start screen footer
-- Set by the Nix wrapper (config in the store) or by hand (a clone, to edit it live)
if vim.env.NEOPANDA_CONFIG then
  vim.opt.runtimepath:prepend(vim.env.NEOPANDA_CONFIG)
end
vim.loader.enable()

require("pxndxs.options")
require("pxndxs.extras")
require("pxndxs.keymaps")
require("pxndxs.autocmds")
require("pxndxs.diagnostics")
require("pxndxs.completion")
require("pxndxs.lsp")
require("pxndxs.format")
require("pxndxs.session")
require("pxndxs.theme") -- before the modules that derive colors from it
require("pxndxs.statusline")
require("pxndxs.tabline")
require("pxndxs.statuscolumn")
require("pxndxs.breadcrumbs")
require("pxndxs.git")
require("pxndxs.ai")
require("pxndxs.treesitter")
require("pxndxs.pack")
