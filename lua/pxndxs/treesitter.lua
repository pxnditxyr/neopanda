-- Native treesitter for every filetype with an installed parser (bundled: c, diff, lua, markdown,
-- query, vim, vimdoc). Indent stays regex. Native visual maps: an in ]n [n ]N [N.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("pxndxs.treesitter", {}),
  desc = "Start treesitter",
  callback = function(args)
    local buf = args.buf
    -- lua, markdown, help and query ftplugins already start it
    if not vim.treesitter.highlighter.active[buf] then
      local lang = vim.treesitter.language.get_lang(args.match) or args.match
      if not pcall(vim.treesitter.start, buf, lang) then
        return -- no parser: regex syntax stays
      end
    end

    -- Treesitter folds for this window, unless LSP folding is already set (LspAttach overrides it)
    local win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_get_buf(win) == buf and not vim.wo[win].foldexpr:find("lsp") then
      vim.wo[win][0].foldmethod = "expr"
      vim.wo[win][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
    end
  end,
})
