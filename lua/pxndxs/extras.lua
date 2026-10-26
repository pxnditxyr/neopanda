-- Native extras: ui2 message UI and opt-in runtime packs. :restart / ZR need nothing.
local settings = require("pxndxs.settings")

-- Experimental message/cmdline UI (internal module). 'cmdheight' stays 1: ui2 + cmdheight=0
-- still hides the :s///c prompt (#42116) and moves the cursor on input prompts (#42496).
if settings.ui2 then
  pcall(function()
    require("vim._core.ui2").enable({})
  end)
end

vim.cmd.packadd("nvim.undotree") -- :Undotree
vim.cmd.packadd("nvim.difftool") -- :DiffTool {left} {right} (files or directories)
vim.cmd.packadd("cfilter") -- :Cfilter / :Lfilter

vim.keymap.set("n", "<leader>uu", "<Cmd>Undotree<CR>", { desc = "Toggle undotree" })
