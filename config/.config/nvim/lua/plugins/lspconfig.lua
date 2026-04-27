-- LSP Configuration (Neovim 0.11+ compatible)
return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function()
    -- Global Diagnostic Config
    vim.diagnostic.config({
      virtual_text = { prefix = "●", spacing = 2 },
      signs = false,
      update_in_insert = false,
      underline = true,
      severity_sort = true,
      float = { border = "rounded", source = "always" },
    })

    -- Custom Diagnostic Icons
    local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
    end

    -- Mappings & Inlay Hints
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
      callback = function(ev)
        local opts = { buffer = ev.buf, silent = true }
        if vim.lsp.inlay_hint then
          vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
        end
        vim.keymap.set("n", "gD", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gd", vim.lsp.buf.declaration, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
      end,
    })

    -- Servers configuration using the new vim.lsp API where available
    local capabilities = require("cmp_nvim_lsp").default_capabilities()
    
    -- Helper to setup servers
    local function setup(server, opts)
      opts = vim.tbl_deep_extend("force", { capabilities = capabilities }, opts or {})
      if vim.lsp.config then
        vim.lsp.config[server] = opts
        vim.lsp.enable(server)
      else
        require("lspconfig")[server].setup(opts)
      end
    end

    -- Setup basic servers
    setup("bashls")
    setup("cmake")

    -- Setup Clangd with custom options
    setup("clangd", {
      filetypes = { "c", "cpp", "cc", "cxx", "objc", "objcpp", "cuda", "h", "hh", "hpp", "hxx" },
      cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--clang-tidy-checks=*",
        "--header-insertion=iwyu",
        "--completion-style=detailed",
        "--function-arg-placeholders",
        "--all-scopes-completion",
      },
      settings = {
        clangd = { diagnostics = { warningsAsErrors = false } }
      }
    })

    -- Clang-tidy warning adjustment
    local notify = vim.lsp.handlers["textDocument/publishDiagnostics"]
    vim.lsp.handlers["textDocument/publishDiagnostics"] = function(_, result, ctx, config)
      for _, diagnostic in ipairs(result.diagnostics) do
        if diagnostic.source == "clang-tidy" then
          diagnostic.severity = vim.diagnostic.severity.WARN
        end
      end
      notify(_, result, ctx, config)
    end
  end,
}
