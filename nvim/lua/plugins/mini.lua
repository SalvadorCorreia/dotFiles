return { -- Collection of various small independent plugins/modules
	'echasnovski/mini.nvim',
	config = function()
		-- Better Around/Inside textobjects
		--
		-- Examples:
		--  - va)  - [V]isually select [A]round [)]paren
		--  - yinq - [Y]ank [I]nside [N]ext [']quote
		--  - ci'  - [C]hange [I]nside [']quote
		require('mini.ai').setup { n_lines = 500 }

		-- Add/delete/replace surroundings (brackets, quotes, etc.)
		--
		-- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
		-- - sd'   - [S]urround [D]elete [']quotes
		-- - sr)'  - [S]urround [R]eplace [)] [']
		require('mini.surround').setup()

		-- Simple and easy statusline.
		--  You could remove this setup call if you don't like it,
		--  and try some other statusline plugin
		local statusline = require 'mini.statusline'
		-- set use_icons to true if you have a Nerd Font
		statusline.setup { use_icons = vim.g.have_nerd_font }

		-- You can configure sections in the statusline by overriding their
		-- default behavior. For example, here we set the section for
		-- cursor location to LINE:COLUMN
		---@diagnostic disable-next-line: duplicate-set-field
		statusline.section_location = function()
			return '%2l:%-2v'
		end

		-- --- STRIKETHROUGH TOGGLE FOR MARKDOWN START ---
		-- We define this inside the config so it stays out of init.lua
		vim.keymap.set("n", "<leader>x", function()
			-- Only run if we are in a markdown file
			if vim.bo.filetype ~= "markdown" then
				print("Not a markdown file")
				return
			end

			local line = vim.api.nvim_get_current_line()
			-- Check if line starts and ends with ~~ (ignoring whitespace)
			if line:match("^~~.*~~$") then
				local new_line = line:gsub("^~~", ""):gsub("~~$", "")
				vim.api.nvim_set_current_line(new_line)
			else
				vim.api.nvim_set_current_line("~~" .. line .. "~~")
			end
		end, { desc = "[S]trikeout toggle line" })

		-- --- STRIKETHROUGH TOGGLE FOR MARKDOWN END ---

		-- ... and there is more!
		--  Check out: https://github.com/echasnovski/mini.nvim
	end,
}
