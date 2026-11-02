-- UI plugins, only where Neovim has no native equivalent. Native: statusline (lua/pxndxs/statusline.lua),
-- breadcrumbs (lua/pxndxs/breadcrumbs.lua), ui2 messages and progress, LSP/treesitter folds.
return {
  {
    "catppuccin",
    lazy = false,
    after = function()
      -- Integrations are detected from the installed plugins (vim.pack)
      require("catppuccin").setup({ flavour = "mocha" })
      vim.cmd.colorscheme("catppuccin-mocha")
    end,
  },
  {
    "mini.icons",
    lazy = false,
    after = function()
      require("mini.icons").setup()
      -- oil and others ask nvim-web-devicons; mini.icons answers (and caches)
      MiniIcons.mock_nvim_web_devicons()
    end,
  },
  {
    "mini.extra",
    dep_of = "mini.pick",
  },
  {
    "mini.pick",
    event = "DeferredUIEnter",
    after = function()
      local pick = require("mini.pick")
      local extra = require("mini.extra")
      pick.setup()
      -- z=, :tselect, :browse oldfiles and plugins that ask to choose use the picker too
      vim.ui.select = pick.ui_select

      local function map(lhs, rhs, desc, mode)
        vim.keymap.set(mode or "n", lhs, rhs, { desc = desc })
      end
      map("<leader><leader>", pick.builtin.files, "Find files")
      map("<leader>ff", pick.builtin.files, "Files")
      map("<leader>fr", extra.pickers.oldfiles, "Recent files")
      map("<leader>fb", pick.builtin.buffers, "Buffers")
      map("<leader>sg", pick.builtin.grep_live, "Grep (live)")
      map("<leader>sw", function()
        pick.builtin.grep({ pattern = vim.fn.expand("<cword>") })
      end, "Grep word under cursor")
      map("<leader>sb", extra.pickers.buf_lines, "Lines in buffers")
      map("<leader>sh", pick.builtin.help, "Help")
      map("<leader>sk", extra.pickers.keymaps, "Keymaps")
      map("<leader>sd", extra.pickers.diagnostic, "Diagnostics")
      map("<leader>ss", function()
        extra.pickers.lsp({ scope = "document_symbol" })
      end, "Symbols (file)")
      map("<leader>sS", function()
        extra.pickers.lsp({ scope = "workspace_symbol" })
      end, "Symbols (workspace)")
      map("<leader>sR", pick.builtin.resume, "Resume last picker")
    end,
  },
  {
    "mini.indentscope",
    event = { "BufReadPost", "BufNewFile" },
    after = function()
      require("mini.indentscope").setup({ symbol = "│", options = { try_as_border = true } })
      -- No scope line in helper buffers
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("pxndxs.indentscope", {}),
        callback = function(ev)
          if vim.bo[ev.buf].buftype ~= "" then
            vim.b[ev.buf].miniindentscope_disable = true
          end
        end,
      })
    end,
  },
  {
    "render-markdown.nvim",
    ft = "markdown",
    after = function()
      require("render-markdown").setup({})
    end,
  },
}
