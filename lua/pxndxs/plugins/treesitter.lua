-- Parsers and treesitter extras. Highlight and folds are native (lua/pxndxs/treesitter.lua).
return {
  {
    "nvim-treesitter",
    lazy = false, -- does not support lazy-loading
    after = function()
      -- Async and a no-op for installed parsers; bundled ones (c, diff, lua, markdown, query, vim, vimdoc) are skipped
      require("nvim-treesitter").install({
        "astro",
        "bash",
        "css",
        "dart",
        "dockerfile",
        "go",
        "gomod",
        "html",
        "http",
        "hurl",
        "javascript",
        "json",
        "markdown_inline",
        "nix",
        "python",
        "regex",
        "rust",
        "sql",
        "svelte",
        "toml",
        "tsx",
        "typescript",
        "vue",
        "yaml",
      })
    end,
  },
  {
    "nvim-treesitter-textobjects",
    event = "FileType",
    after = function()
      require("nvim-treesitter-textobjects").setup({
        select = { lookahead = true },
        move = { set_jumps = true },
      })

      local function select(query)
        return function()
          require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects")
        end
      end
      for key, obj in pairs({ f = "function", c = "class", a = "parameter" }) do
        vim.keymap.set(
          { "x", "o" },
          "a" .. key,
          select("@" .. obj .. ".outer"),
          { desc = "Around " .. obj }
        )
        vim.keymap.set(
          { "x", "o" },
          "i" .. key,
          select("@" .. obj .. ".inner"),
          { desc = "Inside " .. obj }
        )
      end

      -- ]a/[a replace the native argument-list maps
      local move = require("nvim-treesitter-textobjects.move")
      for key, obj in pairs({ f = "function", a = "parameter" }) do
        local query = "@" .. obj .. ".outer"
        local maps = {
          ["]" .. key] = { move.goto_next_start, "Next " .. obj .. " start" },
          ["[" .. key] = { move.goto_previous_start, "Previous " .. obj .. " start" },
          ["]" .. key:upper()] = { move.goto_next_end, "Next " .. obj .. " end" },
          ["[" .. key:upper()] = { move.goto_previous_end, "Previous " .. obj .. " end" },
        }
        for lhs, map in pairs(maps) do
          vim.keymap.set({ "n", "x", "o" }, lhs, function()
            map[1](query, "textobjects")
          end, { desc = map[2] })
        end
      end
    end,
  },
  {
    "nvim-treesitter-context",
    event = "FileType",
    after = function()
      require("treesitter-context").setup({ max_lines = 3 })
      vim.keymap.set("n", "[x", function()
        require("treesitter-context").go_to_context(vim.v.count1)
      end, { desc = "Go to context" })
    end,
  },
  {
    "rainbow-delimiters.nvim",
    event = "FileType",
  },
  {
    "nvim-ts-autotag",
    ft = { "html", "xml", "javascriptreact", "typescriptreact", "vue", "svelte", "astro" },
    after = function()
      require("nvim-ts-autotag").setup()
    end,
  },
  {
    "treesj",
    keys = { { "<leader>j", desc = "Split/join node" } },
    after = function()
      require("treesj").setup({ use_default_keymaps = false })
      vim.keymap.set("n", "<leader>j", require("treesj").toggle, { desc = "Split/join node" })
    end,
  },
  {
    "ts-comments.nvim",
    event = "DeferredUIEnter",
    after = function()
      require("ts-comments").setup()
    end,
  },
}
