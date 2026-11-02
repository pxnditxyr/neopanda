-- Based on nvim-lspconfig (Apache-2.0)
-- Only in projects with a sqls config.yml (its connections give live-schema completion); elsewhere it
-- would just warn "no database connection". Its completion stays out of the SQL menu (dadbod's
-- source, plugins/lang.lua); diagnostics, hover and formatting work.
---@type vim.lsp.Config
return {
  cmd = { "sqls" },
  filetypes = { "sql", "mysql" },
  root_markers = { "config.yml" },
  workspace_required = true,
}
