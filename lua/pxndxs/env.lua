-- Detected environment facts. Never overridden by settings.
local uname = vim.uv.os_uname()

return {
  is_nix = vim.env.NEOPANDA_NIX == "1",
  is_mac = uname.sysname == "Darwin",
  is_linux = uname.sysname == "Linux",
  is_wsl = uname.sysname == "Linux" and uname.release:lower():find("microsoft") ~= nil,
  is_ssh = vim.env.SSH_TTY ~= nil or vim.env.SSH_CONNECTION ~= nil,
}
