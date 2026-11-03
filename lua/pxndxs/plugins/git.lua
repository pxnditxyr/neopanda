-- Git plugins, only where Neovim has no native equivalent. Native: lazygit float and open in browser
-- (lua/pxndxs/git.lua), diff mode ]c/[c, mini.extra git pickers (plugins/ui.lua).
return {
  {
    "gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    after = function()
      local gs = require("gitsigns")
      -- Without a Nerd Font: the statusline marks (+1 ~1 -1), staged ones in the dimmer Staged groups
      local ascii = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "-" },
        topdelete = { text = "-" },
        changedelete = { text = "~" },
        untracked = { text = "?" },
      }
      local nf = require("pxndxs.settings").nerd_font
      gs.setup({
        signs = nf and {
          add = { text = "\u{f1779}" },
          change = { text = "\u{f47f}" },
          delete = { text = "\u{f10a7}" },
          topdelete = { text = "✎" },
          changedelete = { text = "\u{f443}" },
          untracked = { text = "❓" },
        } or ascii,
        signs_staged = nf and {
          add = { text = "✚" },
          change = { text = "🖌️" },
          delete = { text = "✖" },
          topdelete = { text = "⌃" },
          changedelete = { text = "✌" },
          untracked = { text = "❓" },
        } or ascii,
        -- Also fills vim.b.gitsigns_head/gitsigns_status for the statusline
        on_attach = function(buf)
          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buf = buf, desc = desc })
          end
          local function range()
            return { vim.fn.line("."), vim.fn.line("v") }
          end
          map("n", "]h", function()
            gs.nav_hunk("next")
          end, "Next hunk")
          map("n", "[h", function()
            gs.nav_hunk("prev")
          end, "Prev hunk")
          map("n", "]H", function()
            gs.nav_hunk("last")
          end, "Last hunk")
          map("n", "[H", function()
            gs.nav_hunk("first")
          end, "First hunk")
          map({ "o", "x" }, "ih", gs.select_hunk, "Hunk")
          -- stage_hunk on a staged hunk unstages it
          map("n", "<leader>gs", gs.stage_hunk, "Stage/unstage hunk")
          map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
          map("x", "<leader>gs", function()
            gs.stage_hunk(range())
          end, "Stage/unstage lines")
          map("x", "<leader>gr", function()
            gs.reset_hunk(range())
          end, "Reset lines")
          map("n", "<leader>gS", gs.stage_buffer, "Stage buffer")
          map("n", "<leader>gR", gs.reset_buffer, "Reset buffer")
          map("n", "<leader>gp", gs.preview_hunk_inline, "Preview hunk")
          map("n", "<leader>gb", function()
            gs.blame_line({ full = true })
          end, "Blame line")
          map("n", "<leader>gd", gs.diffthis, "Diff this file")
          map("n", "<leader>ub", gs.toggle_current_line_blame, "Toggle line blame")
          map("n", "<leader>uw", gs.toggle_word_diff, "Toggle word diff")
        end,
      })
    end,
  },
}
