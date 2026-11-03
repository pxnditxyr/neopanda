-- Editing plugins, only where Neovim has no native equivalent. Native and kept: multicursor (Q, zq, gQ,
-- <C-l>), visual an/in selection, LSP document colors, :move maps (keymaps.lua),
-- directory buffers (- goes up), :grep + :cdo.
return {
  {
    "mini.pairs",
    event = { "InsertEnter", "CmdlineEnter" },
    after = function()
      require("mini.pairs").setup({ modes = { insert = true, command = true, terminal = false } })
    end,
  },
  {
    "mini.surround",
    event = "DeferredUIEnter",
    after = function()
      -- tpope-style keys: ys{motion}{char}, yss (line), ds{char}, cs{old}{new}; S in Visual
      require("mini.surround").setup({
        mappings = {
          add = "ys",
          delete = "ds",
          replace = "cs",
          find = "",
          find_left = "",
          highlight = "",
          update_n_lines = "",
          suffix_last = "",
          suffix_next = "",
        },
        search_method = "cover_or_next",
      })
      vim.keymap.del("x", "ys")
      vim.keymap.set(
        "x",
        "S",
        [[:<C-u>lua MiniSurround.add("visual")<CR>]],
        { silent = true, desc = "Surround selection" }
      )
      vim.keymap.set("n", "yss", "ys_", { remap = true, desc = "Surround line" })
    end,
  },
  {
    "mini.ai",
    event = "DeferredUIEnter",
    after = function()
      -- Brackets, quotes, tags, `?`… that also reach the next match; af/ac/aa come from
      -- nvim-treesitter-textobjects. No next/last maps: native an/in (incremental selection) stay.
      require("mini.ai").setup({
        n_lines = 500,
        mappings = { around_next = "", inside_next = "", around_last = "", inside_last = "" },
      })
    end,
  },
  {
    "mini.hipatterns",
    event = { "BufReadPost", "BufNewFile" },
    after = function()
      local hipatterns = require("mini.hipatterns")
      local function word(name, group)
        return { pattern = "%f[%w]()" .. name .. "()%f[%W]", group = group }
      end
      hipatterns.setup({
        highlighters = {
          fixme = word("FIXME", "MiniHipatternsFixme"),
          hack = word("HACK", "MiniHipatternsHack"),
          todo = word("TODO", "MiniHipatternsTodo"),
          note = word("NOTE", "MiniHipatternsNote"),
          -- #rrggbb where no LSP server colors the buffer (cssls/tailwindcss do it natively)
          hex_color = hipatterns.gen_highlighter.hex_color(),
        },
      })
    end,
  },
  {
    "flash.nvim",
    event = "DeferredUIEnter",
    after = function()
      require("flash").setup({})
      local flash = require("flash")
      vim.keymap.set({ "n", "x", "o" }, "s", flash.jump, { desc = "Flash jump" })
      -- Visual S is surround; native an/in cover treesitter selection there
      vim.keymap.set({ "n", "o" }, "S", flash.treesitter, { desc = "Flash treesitter" })
      vim.keymap.set("o", "r", flash.remote, { desc = "Flash remote" })
    end,
  },
  {
    "mini.clue",
    event = "DeferredUIEnter",
    after = function()
      local clue = require("mini.clue")
      -- Popups only on these prefixes; native keys get their clues from the builtin generators
      local triggers = {}
      for _, t in ipairs({
        { { "n", "x" }, "<Leader>" },
        { { "n", "x" }, "g" },
        { { "n", "x" }, "z" },
        { { "n", "x" }, "[" },
        { { "n", "x" }, "]" },
        { { "n", "x" }, "'" },
        { { "n", "x" }, "`" },
        { { "n", "x" }, '"' },
        { { "i", "c" }, "<C-r>" },
        { "n", "<C-w>" },
        { "i", "<C-x>" },
      }) do
        for _, mode in ipairs(type(t[1]) == "table" and t[1] or { t[1] }) do
          table.insert(triggers, { mode = mode, keys = t[2] })
        end
      end
      clue.setup({
        triggers = triggers,
        clues = {
          { mode = "n", keys = "<Leader>a", desc = "+AI" },
          { mode = "n", keys = "<Leader>c", desc = "+Claude" },
          { mode = "n", keys = "<Leader>d", desc = "+Debug" },
          { mode = "n", keys = "<Leader>f", desc = "+Find" },
          { mode = "n", keys = "<Leader>g", desc = "+Git" },
          { mode = "n", keys = "<Leader>l", desc = "+LSP" },
          { mode = "n", keys = "<Leader>q", desc = "+Session/quit" },
          { mode = "n", keys = "<Leader>r", desc = "+Requests (hurl)" },
          { mode = "n", keys = "<Leader>s", desc = "+Search" },
          { mode = "n", keys = "<Leader>t", desc = "+Test" },
          { mode = "n", keys = "<Leader><Tab>", desc = "+Tabs" },
          { mode = "n", keys = "<Leader>u", desc = "+Toggles" },
          clue.gen_clues.builtin_completion(),
          clue.gen_clues.g(),
          clue.gen_clues.marks(),
          clue.gen_clues.registers(),
          clue.gen_clues.square_brackets(),
          clue.gen_clues.windows(),
          clue.gen_clues.z(),
        },
        window = { delay = 300 },
      })
    end,
  },
  {
    "oil.nvim",
    cmd = "Oil",
    keys = { { "_", "<Cmd>Oil<CR>", desc = "Edit directory (oil)" } },
    after = function()
      -- Native directory buffers keep browsing; oil is for renaming/creating/deleting by editing
      require("oil").setup({ default_file_explorer = false })
    end,
  },
  {
    "grug-far.nvim",
    cmd = { "GrugFar", "GrugFarWithin" },
    keys = {
      {
        "<leader>sr",
        function()
          require("grug-far").open({ transient = true })
        end,
        mode = { "n", "x" },
        desc = "Search and replace",
      },
    },
    after = function()
      require("grug-far").setup({})
    end,
  },
}
