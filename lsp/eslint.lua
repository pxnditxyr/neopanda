-- Based on nvim-lspconfig (Apache-2.0)
local configs = {
  ".eslintrc",
  ".eslintrc.js",
  ".eslintrc.cjs",
  ".eslintrc.yaml",
  ".eslintrc.yml",
  ".eslintrc.json",
  "eslint.config.js",
  "eslint.config.mjs",
  "eslint.config.cjs",
  "eslint.config.ts",
  "eslint.config.mts",
  "eslint.config.cts",
}

---@type vim.lsp.Config
return {
  cmd = { "vscode-eslint-language-server", "--stdio" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue",
    "svelte",
    "astro",
  },
  -- Only where the project has an ESLint config; never in Deno projects
  root_dir = function(bufnr, on_dir)
    if vim.fs.root(bufnr, { "deno.json", "deno.jsonc", "deno.lock" }) then
      return
    end
    local config_root = vim.fs.root(bufnr, configs)
    if config_root then
      local locks = { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" }
      on_dir(vim.fs.root(bufnr, { locks, { ".git" } }) or config_root)
    end
  end,
  -- See https://github.com/Microsoft/vscode-eslint#settings-options
  settings = {
    validate = "on",
    useESLintClass = false,
    experimental = {},
    codeActionOnSave = { enable = false, mode = "all" },
    format = true,
    quiet = false,
    onIgnoredFiles = "off",
    rulesCustomizations = {},
    run = "onType",
    problems = { shortenToSingleLine = false },
    nodePath = "",
    workingDirectory = { mode = "auto" },
    codeAction = {
      disableRuleComment = { enable = true, location = "separateLine" },
      showDocumentation = { enable = true },
    },
  },
  -- The server limits its config search to the workspace folder
  before_init = function(_, config)
    if config.root_dir then
      config.settings.workspaceFolder = {
        uri = vim.uri_from_fname(config.root_dir),
        name = vim.fs.basename(config.root_dir),
      }
    end
  end,
  handlers = {
    ["eslint/openDoc"] = function(_, result)
      if result then
        vim.ui.open(result.url)
      end
      return {}
    end,
    ["eslint/confirmESLintExecution"] = function(_, result)
      return result and 4 or nil -- 4 = approved
    end,
    ["eslint/probeFailed"] = function()
      vim.notify("ESLint probe failed", vim.log.levels.WARN)
      return {}
    end,
    ["eslint/noLibrary"] = function()
      vim.notify("ESLint library not found", vim.log.levels.WARN)
      return {}
    end,
  },
  on_attach = function(client, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, "LspEslintFixAll", function()
      client:request_sync("workspace/executeCommand", {
        command = "eslint.applyAllFixes",
        arguments = {
          { uri = vim.uri_from_bufnr(bufnr), version = vim.lsp.util.buf_versions[bufnr] },
        },
      }, nil, bufnr)
    end, { desc = "Fix all ESLint problems" })
  end,
}
