-- Native LSP. Server configs live in lsp/*.lua. Defaults kept: gra grn grr gri grt grx gO K
-- <C-S>, <C-]> (definition via tagfunc), gq (formatexpr), document colors.
local autocmd = vim.api.nvim_create_autocmd
local sig_ns = vim.api.nvim_create_namespace("pxndxs.lsp_signature")

autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("pxndxs.lsp", {}),
  desc = "LSP buffer setup",
  callback = function(args)
    local buf = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      return
    end

    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buf = buf, desc = "LSP: " .. desc })
    end
    map("gd", vim.lsp.buf.definition, "Go to definition")
    map("gD", vim.lsp.buf.declaration, "Go to declaration")
    map("<leader>lr", "<Cmd>lsp restart<CR>", "Restart")
    map("<leader>li", "<Cmd>checkhealth vim.lsp<CR>", "Info")
    map("<leader>uh", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }), { bufnr = buf })
    end, "Toggle inlay hints")

    -- 'autocomplete' triggers the menu; this adds snippets, auto-imports and the resolve popup
    if client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, buf, {
        autotrigger = false,
        convert = require("pxndxs.completion").convert,
        cmp = require("pxndxs.completion").cmp,
      })
      vim.bo[buf].omnifunc = "v:lua.require'pxndxs.completion'.omnifunc"
    end

    -- Signature help pops up above the cursor (the completion menu opens below) on the server's trigger
    -- characters (`(`, `,`) and follows the cursor until the server has no signature (call left)
    local sig = client.server_capabilities.signatureHelpProvider
    if sig and sig.triggerCharacters then
      local chars =
        vim.list_extend(vim.list_slice(sig.triggerCharacters), sig.retriggerCharacters or {})
      local active = false
      -- shortcut: no stale-response check, add one if a slow server makes the window flicker
      local function refresh()
        local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
        client:request("textDocument/signatureHelp", params, function(_, result)
          local lines, hl
          if result and vim.api.nvim_get_mode().mode:sub(1, 1) == "i" then
            lines, hl = vim.lsp.util.convert_signature_help_to_markdown_lines(
              result,
              vim.bo[buf].filetype,
              sig.triggerCharacters
            )
          end
          if not lines or #lines == 0 then
            active = false
            local win = vim.b[buf].lsp_floating_preview
            if win and vim.api.nvim_win_is_valid(win) then
              vim.api.nvim_win_close(win, true)
            end
            return
          end
          local fbuf = vim.lsp.util.open_floating_preview(lines, "markdown", {
            focusable = false,
            anchor_bias = "above",
            close_events = { "InsertLeave", "BufLeave" },
          })
          if hl then
            vim.hl.range(
              fbuf,
              sig_ns,
              "LspSignatureActiveParameter",
              { hl[1], hl[2] },
              { hl[3], hl[4] }
            )
          end
        end, buf)
      end
      local group =
        vim.api.nvim_create_augroup("pxndxs.lsp_signature." .. buf .. "." .. client.id, {})
      autocmd("InsertCharPre", {
        group = group,
        buf = buf,
        callback = function()
          if vim.list_contains(chars, vim.v.char) then
            active = true
            vim.schedule(refresh)
          end
        end,
      })
      autocmd({ "CursorMovedI", "TextChangedP" }, {
        group = group,
        buf = buf,
        callback = function()
          if active then
            refresh()
          end
        end,
      })
      autocmd("InsertLeave", {
        group = group,
        buf = buf,
        callback = function()
          active = false
        end,
      })
    end

    -- LSP folding for the window showing this buffer (overrides treesitter folding)
    if client:supports_method("textDocument/foldingRange") then
      local win = vim.api.nvim_get_current_win()
      if vim.api.nvim_win_get_buf(win) == buf then
        vim.wo[win][0].foldmethod = "expr"
        vim.wo[win][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
      end
    end

    -- Highlight references of the symbol under the cursor
    if client:supports_method("textDocument/documentHighlight") then
      local group = vim.api.nvim_create_augroup("pxndxs.lsp_highlight." .. buf, {})
      autocmd({ "CursorHold", "CursorHoldI" }, {
        group = group,
        buf = buf,
        callback = vim.lsp.buf.document_highlight,
      })
      autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = group,
        buf = buf,
        callback = vim.lsp.buf.clear_references,
      })
      autocmd("LspDetach", {
        group = group,
        buf = buf,
        callback = function()
          vim.lsp.buf.clear_references()
          vim.api.nvim_del_augroup_by_id(group)
        end,
      })
    end
  end,
})

-- Opt-in features, active for every client that supports them
-- Linked editing stays off: it loses the tag pair once `ciw` empties the name; nvim-ts-autotag renames tags
vim.lsp.codelens.enable(true)
vim.lsp.on_type_formatting.enable(true)

local config = { root_markers = { ".git" } }
-- Neovim tells servers about created/deleted files only on macOS/Windows; vue_ls, astro and svelte need it
if require("pxndxs.env").is_linux then
  config.capabilities = { workspace = { didChangeWatchedFiles = { dynamicRegistration = true } } }
end
vim.lsp.config("*", config)

-- Compose and Bake files get their own filetypes (yamlls and treesitter still treat them as yaml/hcl), so
-- docker-language-server attaches to them and not to every YAML file
vim.filetype.add({
  pattern = {
    ["docker%-compose[%w.-]*%.ya?ml"] = "yaml.docker-compose",
    ["compose[%w.-]*%.ya?ml"] = "yaml.docker-compose",
    ["docker%-bake[%w.-]*%.hcl"] = "hcl.docker-bake",
  },
})

-- Without Nix, servers come from Mason: its bin must be on PATH before the check below
if not require("pxndxs.env").is_nix then
  vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH
end

-- Enable only the servers whose binary is installed
local servers = {
  "emmylua_ls",
  "nixd",
  "vtsls",
  "basedpyright",
  "ruff",
  "bashls",
  "jsonls",
  "yamlls",
  "taplo",
  "marksman",
  "rust_analyzer",
  "gopls",
  "vue_ls",
  "svelte",
  "astro",
  "html",
  "cssls",
  "tailwindcss",
  "eslint",
  "biome",
  "copilot",
  "sqls",
  "docker_language_server",
}
for _, name in ipairs(servers) do
  local cmd = (vim.lsp.config[name] or {}).cmd
  if type(cmd) == "table" and vim.fn.executable(cmd[1]) == 1 then
    vim.lsp.enable(name)
  end
end
