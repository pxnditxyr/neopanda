-- Tools without Nix. Not lazy: Mason advises against deferring setup.
return {
  {
    "mason.nvim",
    enabled = not require("pxndxs.env").is_nix,
    lazy = false,
    after = function()
      require("mason").setup({ PATH = "skip" }) -- lsp.lua already put mason/bin on PATH

      local registry = require("mason-registry")
      registry.refresh(function()
        local installing = {}
        for _, name in ipairs(require("pxndxs.tools")) do
          local ok, pkg = pcall(registry.get_package, name)
          if ok and not pkg:is_installed() and not pkg:is_installing() then
            pkg:install()
            table.insert(installing, name)
          end
        end
        if #installing > 0 then
          vim.notify(
            "Mason: installing "
              .. table.concat(installing, ", ")
              .. " (:Mason to watch, ZR when done)"
          )
        end
      end)
    end,
  },
}
