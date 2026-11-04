-- UI plugins, only where Neovim has no native equivalent. Native: statusline (lua/pxndxs/statusline.lua),
-- breadcrumbs (lua/pxndxs/breadcrumbs.lua), ui2 messages and progress, LSP/treesitter folds.
return {
  {
    "catppuccin",
    lazy = false,
    after = function()
      -- Integrations are detected from the installed plugins (vim.pack)
      require("catppuccin").setup({ flavour = "mocha" })
      -- After setup: the remembered theme can be this one
      require("pxndxs.theme").apply()
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
    -- Start screen with no file and no restored session (the session restore runs first, on VimEnter).
    -- Not lazy: its autoopen is a VimEnter autocmd. Type an item's first letter to run it.
    "mini.starter",
    lazy = false,
    after = function()
      local starter = require("mini.starter")
      local dashboard = require("pxndxs.dashboard")
      -- The picker loads on DeferredUIEnter; load it now if a key comes first
      local function pick(fn)
        return function()
          require("lze").trigger_load("mini.pick")
          fn()
        end
      end
      local items = {
        { "Find file", pick(function()
          MiniPick.builtin.files()
        end) },
        {
          "Explorer",
          function()
            require("lze").trigger_load("oil.nvim")
            require("oil").open(vim.fn.getcwd()) -- without a dir, from the starter it opens the native directory buffer
          end,
        },
        { "New file", "enew | startinsert" },
        { "Grep text", pick(function()
          MiniPick.builtin.grep_live()
        end) },
        { "Recent files", pick(function()
          MiniExtra.pickers.oldfiles()
        end) },
        {
          "Config",
          pick(function()
            MiniPick.builtin.files(nil, { source = { cwd = require("pxndxs.env").config } })
          end),
        },
        { "Themes", pick(require("pxndxs.theme").pick) },
        { "Session restore", require("pxndxs.session").load },
        { "Update plugins", "packupdate" },
        { "Quit", "qall" },
      }
      -- From the first line of init.lua to the first draw; frozen (the footer is redrawn on resize)
      local started
      starter.setup({
        evaluate_single = true,
        silent = true, -- no "Query:" echo; one letter runs the item
        header = dashboard.header,
        items = vim.tbl_map(function(i)
          return { name = i[1], action = i[2], section = "" }
        end, items),
        footer = function()
          started = started or (vim.uv.hrtime() - vim.g.pxndxs_start) / 1e6
          local v = vim.version()
          local branch = dashboard.branch()
          local glyph = require("pxndxs.settings").nerd_font and "\u{e0a0} " or ""
          local footer = ("⚡ %d ms · %d plugins%s · NVIM v%d.%d.%d"):format(
            started,
            #vim.pack.get(nil, { info = false }),
            branch and " · " .. glyph .. branch or "",
            v.major,
            v.minor,
            v.patch
          )
          return dashboard.pad(footer) .. footer
        end,
        content_hooks = {
          dashboard.gradient,
          -- Items centered under the art, like the footer
          starter.gen_hook.adding_bullet(dashboard.pad("░ Session restore") .. "░ ", false),
          starter.gen_hook.aligning("center", "center"),
        },
      })
      local group = vim.api.nvim_create_augroup("pxndxs.starter", {})
      -- scrolloff + scrolloffpad would scroll the art away near the last item; setlocal: only this buffer
      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "MiniStarterOpened",
        callback = function()
          vim.wo[0][0].scrolloff = 0
        end,
      })
      -- After starter re-centers on resize, scroll back to the top (the view keeps the old cursor line)
      vim.api.nvim_create_autocmd("VimResized", {
        group = group,
        callback = vim.schedule_wrap(function()
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "ministarter" then
              vim.api.nvim_win_call(win, function()
                vim.fn.winrestview({ topline = 1 })
              end)
            end
          end
        end),
      })
    end,
  },
  {
    "mini.extra",
    dep_of = "mini.pick",
    after = function()
      require("mini.extra").setup() -- the global the start screen items use
    end,
  },
  {
    "mini.pick",
    event = "DeferredUIEnter",
    after = function()
      local pick = require("mini.pick")
      local extra = require("mini.extra")
      pick.setup({
        options = { content_from_bottom = true }, -- prompt in the bottom border, best match next to it
        window = {
          -- Centered modal, recomputed on resize. Keeps clear of the statusline and command line.
          config = function()
            local lines = vim.o.lines - vim.o.cmdheight - 1
            local height = math.max(1, math.floor(0.9 * lines) - 2) -- 2: the border
            local width = math.max(1, math.floor(0.8 * vim.o.columns) - 2)
            return {
              anchor = "NW",
              height = height,
              width = width,
              row = math.floor(0.5 * (lines - height - 2)),
              col = math.floor(0.5 * (vim.o.columns - width - 2)),
            }
          end,
        },
      })
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
      map("<leader>uc", require("pxndxs.theme").pick, "Themes")
      map("<leader>gl", extra.pickers.git_commits, "Commits")
      map("<leader>gL", function()
        extra.pickers.git_commits({ path = vim.fn.expand("%") })
      end, "Commits (file)")
      map("<leader>gh", extra.pickers.git_hunks, "Hunks")
      map("<leader>gc", extra.pickers.git_branches, "Branches")
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
    before = function()
      -- Read when the plugin loads: the first hover loads it and renders right away, an after setup() comes too late
      vim.g.render_markdown_config = {
        overrides = {
          buftype = {
            -- Hover and other floats: code takes the float's background, so glass reaches it
            nofile = { code = { highlight = "NormalFloat", highlight_border = false } },
          },
        },
      }
    end,
  },
}
