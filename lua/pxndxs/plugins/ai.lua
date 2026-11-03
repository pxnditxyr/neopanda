-- AI plugins, only where Neovim has no native equivalent. Native: Copilot inline suggestions
-- (lsp/copilot.lua, lua/pxndxs/ai.lua). Claude Code: claudecode (<leader>c); other CLIs: sidekick (<leader>a).
return {
  {
    -- Copilot next edit suggestions (NES, <Tab> in Normal) and AI CLIs (claude…) in a native terminal
    "sidekick.nvim",
    event = "DeferredUIEnter",
    after = function()
      require("sidekick").setup({
        cli = {
          -- Buffer/file pickers in the terminal need snacks, telescope or fzf-lua
          -- <C-q> is the global "leave terminal" key (keymaps.lua)
          win = { keys = { buffers = false, files = false, stopinsert = false } },
        },
      })
      local cli = require("sidekick.cli")
      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { desc = desc })
      end
      map({ "n", "x", "i", "t" }, "<C-.>", cli.focus, "AI CLI: focus")
      map("n", "<leader>aa", function()
        cli.toggle({ focus = true })
      end, "AI CLI: toggle")
      map("n", "<leader>as", function()
        cli.select({ focus = true })
      end, "AI CLI: select tool")
      map({ "n", "x" }, "<leader>at", function()
        cli.send({ msg = "{this}" })
      end, "AI CLI: send this")
      map("n", "<leader>af", function()
        cli.send({ msg = "{file}" })
      end, "AI CLI: send file")
      map({ "n", "x" }, "<leader>ap", cli.prompt, "AI CLI: prompt")
    end,
  },
  {
    -- Claude Code IDE integration (same protocol as the VS Code extension): its edits open as native diffs,
    -- it sees the selection. Starts a local server, so `claude` + `/ide` in any terminal connects too.
    "claudecode.nvim",
    event = "DeferredUIEnter",
    after = function()
      require("claudecode").setup({ terminal = { provider = "native" } })
      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { desc = desc })
      end
      map("n", "<leader>cc", "<Cmd>ClaudeCode<CR>", "Claude: toggle")
      map("n", "<leader>cf", "<Cmd>ClaudeCodeFocus<CR>", "Claude: focus")
      map("n", "<leader>cs", "<Cmd>ClaudeCodeAdd %<CR>", "Claude: add file")
      map("x", "<leader>cs", "<Cmd>ClaudeCodeSend<CR>", "Claude: send selection")
      map("n", "<leader>cm", "<Cmd>ClaudeCodeSelectModel<CR>", "Claude: model")
      map("n", "<leader>cy", "<Cmd>ClaudeCodeDiffAccept<CR>", "Claude: accept diff")
      map("n", "<leader>cn", "<Cmd>ClaudeCodeDiffDeny<CR>", "Claude: reject diff")

      -- Claude's diff refuses a buffer with unsaved changes (it would review against a stale disk copy) and the
      -- edit then only shows in the terminal. Ask first: the diff call waits for the answer, so the review goes on.
      -- shortcut: wraps the internal open_diff_blocking, recheck it when claudecode.nvim updates
      local diff = require("claudecode.diff")
      local open_diff = diff.open_diff_blocking
      ---@diagnostic disable-next-line: duplicate-set-field
      diff.open_diff_blocking = function(old_path, ...)
        local path = vim.fs.normalize(old_path)
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.bo[buf].modified and vim.fs.normalize(vim.api.nvim_buf_get_name(buf)) == path then
            local choice = vim.fn.confirm(
              vim.fn.fnamemodify(path, ":~:.")
                .. " has unsaved changes. Claude's proposal starts from the saved file.",
              "&Save and review\n&Discard and review\n&Cancel",
              1
            )
            if choice == 1 or choice == 2 then
              vim.api.nvim_buf_call(buf, function()
                vim.cmd(choice == 1 and "write" or "edit!")
              end)
            end
            break
          end
        end
        return open_diff(old_path, ...)
      end

      -- Label both sides of a proposed edit (colors from lua/pxndxs/ai.lua); the file's own winbar
      -- (breadcrumbs) comes back when the diff closes
      local saved = {} ---@type table<string, [integer, string]>
      local group = vim.api.nvim_create_augroup("pxndxs.claudecode", {})
      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "ClaudeCodeDiffOpened",
        callback = function(ev)
          local d = ev.data
          if vim.api.nvim_win_is_valid(d.target_window) then
            saved[d.tab_name] = { d.target_window, vim.wo[d.target_window].winbar }
            vim.wo[d.target_window].winbar = "%#SidekickDiffDelete# Current %* %t"
          end
          if vim.api.nvim_win_is_valid(d.diff_window) then
            vim.wo[d.diff_window].winbar =
              "%#SidekickDiffAdd# ✻ Claude's proposal %* :w accept · :q reject"
          end
        end,
      })
      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "ClaudeCodeDiffClosed",
        callback = function(ev)
          local s = saved[ev.data.tab_name]
          saved[ev.data.tab_name] = nil
          if s and vim.api.nvim_win_is_valid(s[1]) then
            vim.wo[s[1]].winbar = s[2]
          end
        end,
      })
    end,
  },
}
