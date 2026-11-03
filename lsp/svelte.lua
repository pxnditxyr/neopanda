-- Based on nvim-lspconfig (Apache-2.0)
---@type vim.lsp.Config
return {
  cmd = { "svelteserver", "--stdio" },
  filetypes = { "svelte" },
  root_markers = {
    { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock", "deno.lock" },
    { ".git" },
  },
  on_attach = function(client)
    -- Tell svelte about saved JS/TS files (sveltejs/language-tools#2008)
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = { "*.js", "*.ts" },
      group = vim.api.nvim_create_augroup("pxndxs.svelte." .. client.id, {}), -- one per client
      callback = function(ctx)
        client:notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
      end,
    })
  end,
}
