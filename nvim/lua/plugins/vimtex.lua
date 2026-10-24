return {
	"lervag/vimtex",
	lazy = false,
	init = function()
		vim.g.vimtex_view_method = "zathura"
		vim.g.vimtex_compiler_method = "latexmk"
		-- Zathura watches a copy of the PDF that only updates once a compile
		-- fully succeeds, rather than main.pdf itself (which latexmk truncates
		-- and rewrites on every internal pass while this thesis's minitoc +
		-- glossaries + longtable cross-references converge).
		vim.g.vimtex_view_use_temp_files = 1
	end,
	config = function()
		-- Before starting a new continuous-compile (`latexmk -pvc`) job, sweep
		-- away any orphaned one left over from a crashed/force-killed Neovim
		-- session for the SAME project. Only processes reparented to init
		-- (ppid == 1) with a matching cwd are killed, so a legitimately
		-- running compiler from another live Neovim session is never touched.
		local function kill_orphaned_latexmk(root)
			if not root or root == "" then
				return
			end
			local script = string.format(
				[[
				for pid in $(pgrep -f 'latexmk.*-pvc' 2>/dev/null); do
					ppid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
					cwd=$(readlink -f "/proc/$pid/cwd" 2>/dev/null)
					if [ "$ppid" = "1" ] && [ "$cwd" = %s ]; then
						kill "$pid" 2>/dev/null
					fi
				done
				]],
				vim.fn.shellescape(root)
			)
			vim.fn.system({ "sh", "-c", script })
		end

		vim.api.nvim_create_autocmd("User", {
			pattern = "VimtexEventCompileStarted",
			callback = function()
				kill_orphaned_latexmk(vim.b.vimtex and vim.b.vimtex.root)
			end,
		})

		-- Zathura's own auto-reload-on-file-change (sc_reload) discards the
		-- live scroll position and reopens at a separately tracked
		-- "remembered page" that's only updated by link-clicks or synctex
		-- jumps, never by normal scrolling -- so during continuous compilation
		-- it repeatedly snaps back to a stale position while reading. That
		-- reload is disabled entirely (`set filemonitor noop` in
		-- ~/.config/zathura/zathurarc) and driven instead by this daemon,
		-- which reasserts the true current page (via GotoPage) immediately
		-- before reloading, so the reload lands correctly instead of falling
		-- back to that stale value.
		local reload_jobs = {}

		local function stop_smart_reload(pdf)
			local job = reload_jobs[pdf]
			if job then
				vim.fn.jobstop(job)
				reload_jobs[pdf] = nil
			end
		end

		local function start_smart_reload(pdf)
			if not pdf or pdf == "" or reload_jobs[pdf] then
				return
			end
			local script = vim.fn.expand("~/.config/nvim/scripts/zathura-smart-reload.sh")
			reload_jobs[pdf] = vim.fn.jobstart({ "bash", script, pdf }, {
				detach = false,
				on_exit = function()
					reload_jobs[pdf] = nil
				end,
			})
		end

		-- VimL dict-functions (like b:vimtex.compiler.get_file) are exposed to
		-- Lua as opaque userdata, not directly callable -- nvim_eval runs the
		-- call in VimL itself, where dict-function calling works normally.
		local function get_watched_pdf()
			local ok, pdf = pcall(vim.api.nvim_eval, "b:vimtex.compiler.get_file('pdf')")
			return (ok and pdf ~= "") and pdf or nil
		end

		vim.api.nvim_create_autocmd("User", {
			pattern = "VimtexEventCompileStarted",
			callback = function()
				start_smart_reload(get_watched_pdf())
			end,
		})

		vim.api.nvim_create_autocmd("User", {
			pattern = "VimtexEventCompileStopped",
			callback = function()
				stop_smart_reload(get_watched_pdf())
			end,
		})
	end,
}
