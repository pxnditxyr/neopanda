-- Snippets: mini.snippets loads VS Code JSON (friendly-snippets + snippets/ in this repo) and serves
-- them as an in-process LSP server, so they show up in the native completion menu.
-- Inserted by vim.snippet; jumps in lua/pxndxs/completion.lua.
return {
  {
    "friendly-snippets",
    dep_of = "mini.snippets",
  },
  {
    "mini.snippets",
    event = "DeferredUIEnter",
    after = function()
      local snippets = require("mini.snippets")
      -- Patterns per language: top level, one folder deep or a folder named after it. The default
      -- `**/name.json` also picked friendly-snippets' frameworks/ (Angular in every TypeScript file);
      -- framework snippets stay opt-in, as in friendly-snippets itself: add a lang entry to enable one.
      local function lang(name)
        local patterns = {}
        for _, ext in ipairs({ "json", "lua" }) do
          vim.list_extend(
            patterns,
            { name .. "." .. ext, "*/" .. name .. "." .. ext, name .. "/**/*." .. ext }
          )
        end
        return patterns
      end
      -- Markdown text is the markdown_inline tree-sitter language
      local lang_patterns = setmetatable({
        markdown_inline = lang("markdown"),
      }, {
        __index = function(_, name)
          return name ~= "" and lang(name) or nil
        end,
      })
      snippets.setup({
        snippets = { snippets.gen_loader.from_lang({ lang_patterns = lang_patterns }) },
        -- Only the native menu inserts snippets; keep <C-j> native
        mappings = { expand = "" },
      })
      local completion = require("pxndxs.completion")
      snippets.start_lsp_server({
        match = function(...)
          return completion.snippets and snippets.default_match(...) or {}
        end,
      })
    end,
  },
}
