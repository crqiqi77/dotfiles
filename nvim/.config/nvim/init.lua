vim.opt.number = true
vim.opt.cursorline = true
vim.opt.listchars = { tab = "→ ", trail = "·" }
vim.opt.list = true
--vim.g.mapleader = " "
--vim.g.maplocalleader = " "
vim.opt.colorcolumn = "80"

vim.pack.add({
	{ src = "https://github.com/folke/tokyonight.nvim" },
	{ src = "https://github.com/nvim-tree/nvim-web-devicons" },
	{ src = "https://github.com/akinsho/bufferline.nvim" },
	{ src = "https://github.com/nvim-lualine/lualine.nvim" },
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = 'https://github.com/nvim-lua/plenary.nvim' },
	{ src = "https://github.com/nvim-telescope/telescope.nvim" },
}, {
	load = true,
})

vim.cmd [[colorscheme tokyonight]]

vim.opt.termguicolors = true
require("bufferline").setup({
})

require('lualine').setup({
	sections = {
		lualine_c = { { "filename", path = 3, symbols = { modified = "[+]", readonly = "[-]", unnamed = "[No Name]", } } }
	}
})

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

--lsp
vim.lsp.enable('lua_ls')
vim.lsp.enable('clangd')

vim.o.autocomplete = true
vim.opt.complete:append('o')
vim.opt.completeopt = {'menuone', 'noselect', 'popup'}
vim.o.pumheight = 5
vim.o.pumborder = 'rounded'

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))
    local opts = { buffer = ev.buf, silent = true }

   vim.keymap.set('n', 'gd', vim.lsp.buf.definition, vim.tbl_extend('force', opts, { desc = '转到定义' }))
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, vim.tbl_extend('force', opts, { desc = '转到声明' }))

    if client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf, {autotrigger = true})
    end
  end,
})
