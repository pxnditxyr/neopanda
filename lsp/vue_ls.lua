-- Based on nvim-lspconfig (Apache-2.0). Needs vtsls with @vue/typescript-plugin (lsp/vtsls.lua).
---@type vim.lsp.Config
return {
  cmd = { "vue-language-server", "--stdio" },
  filetypes = { "vue" },
  root_markers = { "package.json" },
  -- vue_ls asks vtsls for TypeScript data through tsserver/request
  on_init = function(client)
    local retries = 0
    local function forward(_, result, context)
      local ts = vim.lsp.get_clients({ bufnr = context.bufnr, name = "vtsls" })[1]
      if not ts then
        -- vtsls can attach a moment later
        if retries < 10 then
          retries = retries + 1
          vim.defer_fn(function()
            forward(_, result, context)
          end, 100)
        else
          vim.notify("vue_ls needs vtsls, which is not attached", vim.log.levels.ERROR)
        end
        return
      end
      retries = 0
      local id, command, payload = unpack(unpack(result))
      ts:exec_cmd({
        title = "vue_request_forward",
        command = "typescript.tsserverRequest",
        arguments = { command, payload },
      }, { bufnr = context.bufnr }, function(_, res)
        client:notify("tsserver/response", { { id, res and res.body } })
      end)
    end
    client.handlers["tsserver/request"] = forward
  end,
}
