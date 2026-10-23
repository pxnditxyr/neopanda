-- Only maps not covered by nightly defaults (gr*, [q/]q, [<Space>, an/in, al/il, ZR, Q, ...).
local map = vim.keymap.set

-- Search
map("n", "<Esc>", "<Cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "n", "nzzzv", { desc = "Next match (centered)" })
map("n", "N", "Nzzzv", { desc = "Previous match (centered)" })

-- Editing
map("n", "J", function()
  local pos = vim.api.nvim_win_get_cursor(0)
  vim.cmd("normal! " .. vim.v.count1 .. "J")
  vim.api.nvim_win_set_cursor(0, pos)
end, { desc = "Join lines (keep cursor)" })
map("x", "<", "<gv", { desc = "Indent left (keep selection)" })
map("x", ">", ">gv", { desc = "Indent right (keep selection)" })

-- Move lines
map("n", "<A-j>", "<Cmd>execute 'move .+' . v:count1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", "<Cmd>execute 'move .-' . (v:count1 + 1)<CR>==", { desc = "Move line up" })
map("x", "<A-j>", ":move '>+1<CR>gv=gv", { silent = true, desc = "Move selection down" })
map("x", "<A-k>", ":move '<-2<CR>gv=gv", { silent = true, desc = "Move selection up" })

-- Files
map("n", "<leader>w", "<Cmd>write<CR>", { desc = "Write" })
map("n", "<leader>z", "<Cmd>quit<CR>", { desc = "Close window" })

-- Windows (<C-l> stays native: nohlsearch + diffupdate + clear multicursors; use <C-w>l)
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-Up>", "<Cmd>resize +5<CR>", { desc = "Increase height" })
map("n", "<C-Down>", "<Cmd>resize -5<CR>", { desc = "Decrease height" })
map("n", "<C-Left>", "<Cmd>vertical resize -5<CR>", { desc = "Decrease width" })
map("n", "<C-Right>", "<Cmd>vertical resize +5<CR>", { desc = "Increase width" })

-- Tabs (gt/gT to switch)
map("n", "<leader>tn", "<Cmd>tabnew<CR>", { desc = "New tab" })
