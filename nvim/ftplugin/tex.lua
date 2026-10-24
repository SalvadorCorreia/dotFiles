-- Thesis todo-tag annotations (vocabulary defined in thesis_agents/todo-tags.md).
--
-- Select text in visual mode, then <leader>ln<tag-letter>:
--
--  - charwise/blockwise selection (v, Ctrl-V) -- e.g. a couple of words
--    inside a sentence: wraps exactly that span in
--    \highlight[comment={[TAG] }]{...}, from the `changes` package already
--    loaded in Preamble_commands.tex. The words stay fully visible/rendered
--    (this preamble's `markup=underlined` config gives them a wavy
--    underline, not hidden text) and the note is anchored precisely to that
--    span, so it's unambiguous which words the note is about even mid-sentence.
--
--  - linewise selection (V) -- a whole paragraph or heading: appends a
--    plain \todo{[TAG] } right after it. No span-wrap needed here -- the
--    paragraph/heading boundary is already the unambiguous referent.
--
-- Citation-needed (<leader>lnc) always stays a plain `% CITATION NEEDED: `
-- comment, in both selection modes -- per thesis_agents/todo-tags.md it must
-- never become a \todo or any other visible/compiled annotation.

---@param prefix string
---@param suffix string
local function append_after_selection(prefix, suffix)
	local end_pos = vim.fn.getpos("'>")
	local end_line, end_col = end_pos[2], end_pos[3]

	if vim.fn.visualmode() == "V" then
		vim.fn.append(end_line, prefix .. suffix)
		vim.api.nvim_win_set_cursor(0, { end_line + 1, #prefix })
	else
		local line = vim.fn.getline(end_line)
		local col = math.min(end_col, #line)
		local before, after = line:sub(1, col), line:sub(col + 1)
		vim.fn.setline(end_line, before .. prefix .. suffix .. after)
		vim.api.nvim_win_set_cursor(0, { end_line, #before + #prefix })
	end
end

---@param tag string
local function wrap_highlight(tag)
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	local start_line, start_col = start_pos[2], start_pos[3]
	local end_line, end_col = end_pos[2], end_pos[3]

	local prefix = "\\highlight[comment={[" .. tag .. "] "
	local mid = "}]{"
	local suffix = "}"

	if start_line == end_line then
		local line = vim.fn.getline(start_line)
		local sc = math.min(start_col, #line + 1)
		local ec = math.min(end_col, #line)
		local before, selected, after = line:sub(1, sc - 1), line:sub(sc, ec), line:sub(ec + 1)
		vim.fn.setline(start_line, before .. prefix .. mid .. selected .. suffix .. after)
		vim.api.nvim_win_set_cursor(0, { start_line, #before + #prefix })
	else
		-- multi-line charwise selection: edit the end line first so the
		-- start line's column offsets (captured above) stay valid.
		local end_line_text = vim.fn.getline(end_line)
		local ec = math.min(end_col, #end_line_text)
		local ebefore, eafter = end_line_text:sub(1, ec), end_line_text:sub(ec + 1)
		vim.fn.setline(end_line, ebefore .. suffix .. eafter)

		local start_line_text = vim.fn.getline(start_line)
		local sc = math.min(start_col, #start_line_text + 1)
		local sbefore, safter = start_line_text:sub(1, sc - 1), start_line_text:sub(sc)
		vim.fn.setline(start_line, sbefore .. prefix .. mid .. safter)
		vim.api.nvim_win_set_cursor(0, { start_line, #sbefore + #prefix })
	end
end

---@param tag string
local function todo(tag)
	return function()
		if vim.fn.visualmode() == "V" then
			append_after_selection("\\todo{[" .. tag .. "] ", "}")
		else
			wrap_highlight(tag)
		end
		-- Deferred: calling startinsert synchronously here can get silently
		-- overridden once Neovim finishes its own mode-transition bookkeeping
		-- for the visual-mode mapping that triggered this callback.
		vim.defer_fn(function()
			vim.cmd("startinsert")
		end, 0)
	end
end

local function citation()
	append_after_selection("% CITATION NEEDED: ", "")
	vim.defer_fn(function()
		vim.cmd("startinsert")
	end, 0)
end

local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)

local function map(lhs, fn, desc)
	vim.keymap.set("x", lhs, function()
		-- Force a real, synchronous exit from visual mode first: an x-mode
		-- mapping whose rhs is a Lua function does not reliably finalize the
		-- '< / '> marks before the callback runs, so without this, fn() can
		-- see stale or unset marks.
		vim.cmd("normal! " .. esc)
		fn()
	end, { buffer = true, silent = true, desc = desc })
end

map("<leader>lnr", todo("REVIEW"), "todo: [REVIEW]")
map("<leader>lnd", todo("REMOVE"), "todo: [REMOVE]")
map("<leader>lnm", todo("MISSING"), "todo: [MISSING]")
map("<leader>lno", todo("OUTLINE"), "todo: [OUTLINE]")
map("<leader>lnn", todo("NUMBER"), "todo: [NUMBER]")
map("<leader>lnf", todo("FLAGGED"), "todo: [FLAGGED]")
map("<leader>lnc", citation, "citation needed")

local ok, wk = pcall(require, "which-key")
if ok then
	wk.add({ { "<leader>ln", group = "latex todo-note", mode = "x", buffer = 0 } })
end
