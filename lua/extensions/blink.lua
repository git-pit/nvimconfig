local M = {}

function M.setup()
	vim.pack.add({ { src = 'https://github.com/saghen/blink.lib' } })
	vim.pack.add({ { src = 'https://github.com/saghen/blink.cmp' } })
	require("blink.cmp").setup({
		keymap = {
			preset = "default",
			['<C-n>'] = {
				function(cmp)
					cmp.show()
				end,
				'select_next'
			},
		},
		fuzzy = { implementation = 'lua' }, 
		completion = { 
			menu = { auto_show = false },
		},
	})
end

M.setup()

return M
