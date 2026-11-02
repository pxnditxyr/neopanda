-- Debugging and tests, only where Neovim has no native equivalent (no DAP client in core).
-- Debug: nvim-dap + nvim-dap-view (<leader>d). Tests: neotest (<leader>t). Rust tests stay native:
-- :compiler cargo + :make test (rust buffers, <leader>tt/tT). Dart adapters come from flutter-tools (plugins/lsp.lua).
local function dap()
  return require("dap")
end

return {
  {
    "nvim-dap",
    on_require = "dap",
    keys = {
      {
        "<leader>db",
        function()
          dap().toggle_breakpoint()
        end,
        desc = "Toggle breakpoint",
      },
      {
        "<leader>dB",
        function()
          vim.ui.input({ prompt = "Condition: " }, function(cond)
            if cond and cond ~= "" then
              dap().set_breakpoint(cond)
            end
          end)
        end,
        desc = "Conditional breakpoint",
      },
      {
        "<leader>dc",
        function()
          dap().continue()
        end,
        desc = "Start / continue",
      },
      {
        "<leader>dC",
        function()
          dap().run_to_cursor()
        end,
        desc = "Run to cursor",
      },
      {
        "<leader>di",
        function()
          dap().step_into()
        end,
        desc = "Step into",
      },
      {
        "<leader>do",
        function()
          dap().step_out()
        end,
        desc = "Step out",
      },
      {
        "<leader>dO",
        function()
          dap().step_over()
        end,
        desc = "Step over",
      },
      {
        "<leader>dl",
        function()
          dap().run_last()
        end,
        desc = "Run last",
      },
      {
        "<leader>dt",
        function()
          dap().terminate()
        end,
        desc = "Terminate",
      },
    },
    after = function()
      local nf = require("pxndxs.settings").nerd_font
      for name, sign in pairs({
        DapBreakpoint = { nf and "\u{f111}" or "●", "DiagnosticError" },
        DapBreakpointCondition = { nf and "\u{f059}" or "◆", "DiagnosticWarn" },
        DapBreakpointRejected = { nf and "\u{f06a}" or "○", "DiagnosticHint" },
        DapLogPoint = { nf and "\u{f075}" or "◉", "DiagnosticInfo" },
        DapStopped = { nf and "\u{f0055}" or "→", "DiagnosticOk" },
      }) do
        vim.fn.sign_define(name, {
          text = sign[1],
          texthl = sign[2],
          linehl = name == "DapStopped" and "Visual" or "",
        })
      end

      local d = dap()
      -- .vscode/launch.json is read natively; its VS Code adapter names map to the ones below

      -- JS/TS: vscode-js-debug's DAP server (Nix: js-debug, Mason: js-debug-adapter)
      local js = vim.fn.executable("js-debug") == 1 and "js-debug" or "js-debug-adapter"
      d.adapters["pwa-node"] = {
        type = "server",
        host = "127.0.0.1",
        port = "${port}",
        executable = { command = js, args = { "${port}", "127.0.0.1" } },
      }
      d.adapters.node = function(cb, config)
        config.type = "pwa-node" -- js-debug only answers to pwa-*
        cb(d.adapters["pwa-node"])
      end
      for _, ft in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
        d.configurations[ft] = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch file",
            program = "${file}",
            cwd = "${workspaceFolder}",
            -- Runs in dap-view's console: output stays readable (internalConsole drops it on quick exits)
            console = "integratedTerminal",
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach to process",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
          },
        }
      end

      -- Go: delve's own DAP server
      d.adapters.go = {
        type = "server",
        port = "${port}",
        executable = { command = "dlv", args = { "dap", "-l", "127.0.0.1:${port}" } },
      }
      d.configurations.go = {
        { type = "go", request = "launch", name = "Debug file", program = "${file}" },
        { type = "go", request = "launch", name = "Debug package", program = "${fileDirname}" },
        {
          type = "go",
          request = "attach",
          name = "Attach to process",
          mode = "local",
          processId = require("dap.utils").pick_process,
        },
      }

      -- Rust (C/C++ too): lldb-dap (Nix on Linux, Xcode on macOS), else codelldb (Mason)
      local lldb = vim.fn.exepath("lldb-dap")
      if lldb == "" and vim.fn.has("mac") == 1 then
        local res = vim.system({ "xcrun", "-f", "lldb-dap" }, { text = true }):wait()
        lldb = res.code == 0 and vim.trim(res.stdout) or ""
      end
      d.adapters.lldb = lldb ~= "" and { type = "executable", command = lldb }
        or {
          type = "server",
          port = "${port}",
          executable = { command = "codelldb", args = { "--port", "${port}" } },
        }
      d.configurations.rust = {
        {
          type = "lldb",
          request = "launch",
          name = "Launch binary",
          program = function()
            return vim.fn.input("Binary: ", vim.fn.getcwd() .. "/target/debug/", "file")
          end,
          cwd = "${workspaceFolder}",
        },
      }
    end,
  },
  {
    -- One panel (scopes, watches, breakpoints, threads, REPL, console) + variable values inline
    "nvim-dap-view",
    on_plugin = "nvim-dap",
    keys = {
      { "<leader>du", "<Cmd>DapViewToggle!<CR>", desc = "Toggle debug view (and console)" },
      { "<leader>dr", "<Cmd>DapViewJump repl<CR>", desc = "REPL" },
      -- ! enters the float: dap-view only closes it on leave (q)
      { "<leader>de", "<Cmd>DapViewHover!<CR>", desc = "Evaluate under cursor" },
      { "<leader>dw", "<Cmd>DapViewWatch<CR>", desc = "Watch under cursor" },
      { "<leader>dw", ":DapViewWatch<CR>", mode = "x", desc = "Watch selection" },
    },
    after = function()
      require("dap-view").setup({
        auto_toggle = "open", -- opens with a session, stays after it ends (output); <leader>du closes
        virtual_text = { enabled = true },
      })
    end,
  },
  { "nvim-nio", dep_of = "neotest" },
  { "neotest-golang", dep_of = "neotest" },
  { "neotest-vitest", dep_of = "neotest" },
  { "neotest-dart", dep_of = "neotest" },
  {
    "neotest",
    on_require = "neotest",
    keys = {
      {
        "<leader>tt",
        function()
          require("neotest").run.run(vim.fn.expand("%"))
        end,
        desc = "Run file",
      },
      {
        "<leader>tT",
        function()
          require("neotest").run.run(vim.uv.cwd())
        end,
        desc = "Run all",
      },
      {
        "<leader>tr",
        function()
          require("neotest").run.run()
        end,
        desc = "Run nearest",
      },
      {
        "<leader>tl",
        function()
          require("neotest").run.run_last()
        end,
        desc = "Run last",
      },
      {
        "<leader>td",
        function()
          require("neotest").run.run({ strategy = "dap" })
        end,
        desc = "Debug nearest",
      },
      {
        "<leader>ts",
        function()
          require("neotest").summary.toggle()
        end,
        desc = "Summary",
      },
      {
        "<leader>to",
        function()
          require("neotest").output.open({ enter = true, auto_close = true })
        end,
        desc = "Output",
      },
      {
        "<leader>tO",
        function()
          require("neotest").output_panel.toggle()
        end,
        desc = "Output panel",
      },
      {
        "<leader>tS",
        function()
          require("neotest").run.stop()
        end,
        desc = "Stop",
      },
      {
        "<leader>tw",
        function()
          require("neotest").watch.toggle(vim.fn.expand("%"))
        end,
        desc = "Watch file",
      },
    },
    after = function()
      require("neotest").setup({
        adapters = {
          require("neotest-golang")({
            dap_mode = "manual", -- the delve adapter above, no nvim-dap-go
            -- A function: neotest-golang appends to this table on every run
            dap_manual_config = function()
              return { type = "go", request = "launch", mode = "test", name = "Debug test" }
            end,
          }),
          require("neotest-vitest"),
          require("neotest-dart"),
        },
      })
    end,
  },
}
