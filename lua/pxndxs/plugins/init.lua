-- lze specs, one module per area, loaded in this order: { import = "pxndxs.plugins.<area>" }
return {
  { import = "pxndxs.plugins.ui" }, -- colorscheme first
  { import = "pxndxs.plugins.mason" },
  { import = "pxndxs.plugins.treesitter" },
  { import = "pxndxs.plugins.lsp" },
  { import = "pxndxs.plugins.completion" },
  { import = "pxndxs.plugins.editor" },
  { import = "pxndxs.plugins.git" },
  { import = "pxndxs.plugins.ai" },
}
