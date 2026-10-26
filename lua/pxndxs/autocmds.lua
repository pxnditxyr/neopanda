local autocmd = vim.api.nvim_create_autocmd

local function augroup(name)
  return vim.api.nvim_create_augroup("pxndxs." .. name, {})
end

-- Highlight yanked and put text (TextPutPost is 0.13+)
local hl_events = { "TextYankPost" }
if vim.fn.exists("##TextPutPost") == 1 then
  table.insert(hl_events, "TextPutPost")
end
autocmd(hl_events, {
  group = augroup("highlight_op"),
  desc = "Highlight yanked and put text",
  callback = function()
    vim.hl.hl_op()
  end,
})

-- Restore the last cursor position (:h last-position-jump)
local restore_group = augroup("restore_cursor")
autocmd("BufReadPre", {
  group = restore_group,
  desc = "Restore last cursor position",
  callback = function(args)
    autocmd("FileType", {
      group = restore_group,
      buf = args.buf,
      once = true,
      callback = function()
        local ft = vim.bo[args.buf].filetype
        if ft:find("commit") or ft == "gitrebase" or ft == "xxd" or vim.wo.diff then
          return
        end
        local line = vim.api.nvim_buf_get_mark(args.buf, '"')[1]
        if line >= 1 and line <= vim.api.nvim_buf_line_count(args.buf) then
          vim.cmd('normal! g`"zv')
        end
      end,
    })
  end,
})

-- Close helper windows with q (checkhealth, man, ui2 pager and LSP floats already do)
autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = { "help", "qf" },
  desc = "Close with q",
  callback = function(args)
    vim.bo[args.buf].buflisted = false
    vim.keymap.set("n", "q", "<Cmd>close<CR>", { buf = args.buf, desc = "Close window" })
  end,
})

-- Strip CRs, trailing whitespace and trailing blank lines on save, keeping the view
local skip_strip = { markdown = true, diff = true }
autocmd("BufWritePre", {
  group = augroup("strip_on_save"),
  desc = "Strip trailing whitespace",
  callback = function(args)
    if skip_strip[vim.bo[args.buf].filetype] or vim.bo[args.buf].binary then
      return
    end
    vim.api.nvim_buf_call(args.buf, function()
      local view = vim.fn.winsaveview()
      vim.cmd([[keeppatterns silent! %s/\r$//e]])
      vim.cmd([[keeppatterns silent! %s/\s\+$//e]])
      vim.cmd([[keeppatterns silent! %s/\($\n\s*\)\+\%$//e]])
      vim.fn.winrestview(view)
    end)
  end,
})

autocmd("BufWritePre", {
  group = augroup("mkdir_on_save"),
  desc = "Create parent directories",
  callback = function(args)
    if args.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(args.match) or args.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- Prose: spell and soft wrap; markdown also conceals markup
autocmd("FileType", {
  group = augroup("prose"),
  pattern = { "markdown", "text", "gitcommit" },
  desc = "Spell and wrap for prose",
  callback = function(args)
    local wo = vim.wo[0][0] -- :setlocal
    wo.spell = true
    wo.wrap = true
    if args.match == "markdown" then
      wo.conceallevel = 2
    end
  end,
})

autocmd("VimResized", {
  group = augroup("equalize_splits"),
  desc = "Equalize splits",
  callback = function()
    local tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. tab)
  end,
})
