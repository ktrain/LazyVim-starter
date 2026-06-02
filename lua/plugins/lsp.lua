-- Point the Terraform toolchain at OpenTofu (`tofu`) when it's on PATH.
--
-- LazyVim's terraform extra wires up terraform-ls plus the `terraform_validate`
-- linter and `terraform_fmt` formatter, all of which drive the `terraform`
-- binary by default. With OpenTofu that causes two problems:
--   * terraform-ls keeps prompting to run `terraform init`, because the Terraform
--     CLI doesn't recognize the state `tofu init` produced (OpenTofu installs its
--     providers from registry.opentofu.org and writes its own lockfile).
--   * the failed init/schema probes get retried, which makes the analyzer slow.
-- Redirecting everything to `tofu` (CLI-compatible) fixes both.
local tofu = vim.fn.exepath("tofu")

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        vtsls = { enabled = false },
        tsgo = {},
        -- terraform-ls settings must go through init_options (it doesn't honor
        -- didChangeConfiguration). Leave the extra's default in place if tofu
        -- isn't installed.
        terraformls = tofu ~= "" and {
          init_options = { terraformExecPath = tofu },
        } or nil,
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function()
      if tofu == "" then
        return
      end
      local lint = require("lint")
      local orig = lint.linters.terraform_validate
      lint.linters.terraform_validate = function()
        local cfg = type(orig) == "function" and orig() or orig
        cfg.cmd = tofu
        return cfg
      end
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      if tofu ~= "" then
        opts.formatters = opts.formatters or {}
        opts.formatters.terraform_fmt = { command = tofu }
      end
    end,
  },
}
