-- Language tooling, only where Neovim and the LSP servers fall short. Native: go.mod upgrades (gopls code
-- lenses), SQL keywords (sqls), Dockerfile/Compose (docker-language-server). Databases: dadbod (<leader>D).
-- HTTP: hurl.nvim on .hurl files (<leader>r). Cargo.toml: crates.nvim as an in-process LSP.

-- The sql ftplugin maps <C-c>* in Insert for its own completion; dadbod-completion replaces it
vim.g.omni_sql_no_default_maps = 1

return {
  { "vim-dadbod", cmd = "DB", dep_of = { "vim-dadbod-ui", "vim-dadbod-completion" } },
  {
    "vim-dadbod-ui",
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    keys = { { "<leader>D", "<Cmd>DBUIToggle<CR>", desc = "Database UI" } },
    before = function()
      vim.g.db_ui_use_nerd_fonts = require("pxndxs.settings").nerd_font and 1 or 0
    end,
  },
  {
    -- Tables and columns of the connected database in the native completion menu
    "vim-dadbod-completion",
    ft = { "sql", "mysql", "plsql" },
    after = function()
      local function attach(buf)
        -- After the sql ftplugin, which sets its syntax-only omnifunc. Sources: dadbod (tables and columns
        -- before reserved words) and this buffer. No LSP omnifunc: dadbod waits on the DB synchronously and
        -- an LSP reply landing meanwhile breaks the menu (E565). nosort keeps dadbod's order (fuzzy would
        -- rank the short keywords first).
        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(buf) then
            return
          end
          if vim.bo[buf].omnifunc == "sqlcomplete#Complete" then
            vim.bo[buf].omnifunc = ""
          end
          vim.bo[buf].complete = "Fv:lua.require'pxndxs.completion'.dadbod,."
          if not vim.bo[buf].completeopt:find("nosort", 1, true) then
            vim.bo[buf].completeopt = vim.o.completeopt .. ",nosort"
          end
        end)
      end
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("pxndxs.dadbod", {}),
        pattern = { "sql", "mysql", "plsql" },
        callback = function(ev)
          attach(ev.buf)
        end,
      })
      attach(vim.api.nvim_get_current_buf())
    end,
  },
  { "nui.nvim", dep_of = "hurl.nvim" },
  {
    "hurl.nvim",
    ft = "hurl",
    after = function()
      -- Response in a split on the right, JSON through jq
      require("hurl").setup({ mode = "split" })
      local function keys(buf)
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buf = buf, desc = desc })
        end
        map("n", "<leader>rs", "<Cmd>HurlRunnerAt<CR>", "Run request under cursor")
        map("x", "<leader>rs", ":HurlRunner<CR>", "Run selected requests")
        map("n", "<leader>ra", "<Cmd>HurlRunner<CR>", "Run all requests in file")
        map("n", "<leader>rv", "<Cmd>HurlVerbose<CR>", "Run request (verbose)")
        map("n", "<leader>rm", "<Cmd>HurlToggleMode<CR>", "Toggle split / popup")
        map("n", "<leader>re", "<Cmd>HurlSelectEnvFile<CR>", "Select env file")
      end
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("pxndxs.hurl", {}),
        pattern = "hurl",
        callback = function(ev)
          keys(ev.buf)
        end,
      })
      keys(vim.api.nvim_get_current_buf())
    end,
  },
  {
    -- Versions, features and upgrades in Cargo.toml as an LSP client: native completion, hover, code actions
    "crates.nvim",
    event = "BufRead Cargo.toml",
    after = function()
      require("crates").setup({
        lsp = { enabled = true, actions = true, completion = true, hover = true },
      })
    end,
  },
}
