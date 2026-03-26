local M = {}

-- Fix Neovim's built-in gc commenting for buffers with treesitter injections.
-- _comment.lua iterates all filetypes for a treesitter language and takes the
-- last non-empty commentstring, which is wrong when spurious filetypes (py,
-- gyp, rmd) have incorrect commentstrings. This hook detects the actual
-- language at the cursor and uses it directly.
local original_get_option = vim.filetype.get_option
vim.filetype.get_option = function(filetype, option)
	if option ~= "commentstring" then
		return original_get_option(filetype, option)
	end

	local ok, parser = pcall(vim.treesitter.get_parser, 0)
	if not ok or not parser or not next(parser:children()) then
		return original_get_option(filetype, option)
	end

	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1] - 1, cursor[2]
	local range = { row, col, row, col + 1 }

	local lang = parser:lang()
	local function find_deepest(tree)
		for _, child in pairs(tree:children()) do
			if child:contains(range) then
				lang = child:lang()
				find_deepest(child)
			end
		end
	end
	find_deepest(parser)

	local cs = original_get_option(lang, "commentstring")
	if cs and cs ~= "" then
		return cs
	end

	return original_get_option(filetype, option)
end

function M.setup()
	-- Kill rmd.vim's CursorMoved autocmd that only detects R code blocks
	-- and sets wrong commentstring for all other languages
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "quarto",
		callback = function()
			pcall(vim.api.nvim_del_augroup_by_name, "RmdCStr")
		end,
	})

	local quarto = require("quarto")
	quarto.setup({
		lspFeatures = {
			enabled = true,
			languages = { "python" },
			chunks = "all",
			diagnostics = {
				enabled = true,
			},
			completion = {
				enabled = true,
			},
		},
		codeRunner = {
			enabled = true,
			default_method = "molten",
		},
	})

	local runner = require("quarto.runner")
	vim.keymap.set({ "n", "i" }, "<C-S-CR>", runner.run_cell, { desc = "run cell", silent = true })
	vim.keymap.set({ "n", "i" }, "<C-CR>", runner.run_above, { desc = "run cell and above", silent = true })
	vim.keymap.set("n", "<leader>rb", runner.run_below, { desc = "run cell and below", silent = true })
	vim.keymap.set("n", "<leader>rA", runner.run_all, { desc = "run all cells", silent = true })
	vim.keymap.set("n", "<leader>rl", runner.run_line, { desc = "run line", silent = true })
	vim.keymap.set("v", "<leader>rv", runner.run_range, { desc = "run visual range", silent = true })
	vim.keymap.set("n", "<leader>RA", function()
		runner.run_all(true)
	end, { desc = "run all cells of all languages", silent = true })

	local function insert_python_code_block()
		local current_line = vim.api.nvim_win_get_cursor(0)[1]
		vim.api.nvim_buf_set_lines(0, current_line - 1, current_line - 1, false, {
			"```{python}",
			"",
			"```",
		})
		vim.api.nvim_win_set_cursor(0, { current_line + 1, 0 })
	end
	vim.keymap.set({ "n", "i" }, "<C-S-o>", insert_python_code_block, { desc = "Insert Python code block" })

	local ok_otter, otterkeeper = pcall(require, "otter.keeper")
	if not ok_otter then
		vim.notify("[chunk_navigation] otter.nvim is required for code chunk navigation.", vim.log.levels.ERROR)
		return
	end

	pcall(require, "quarto.config")
	local config = QuartoConfig or { codeRunner = { never_run = {} } }

	local code_languages = {
		"python",
		"r",
		"julia",
		"bash",
		"sh",
		"javascript",
		"typescript",
		"lua",
		"sql",
		"scala",
		"rust",
		"go",
		"cpp",
		"c",
	}

	local function get_sorted_chunks(buf)
		otterkeeper.sync_raft(buf)
		local raft = otterkeeper.rafts[buf]
		if not raft or not raft.code_chunks then
			vim.notify("[chunk_navigation] Code runner is not initialised for this buffer.", vim.log.levels.WARN)
			return nil
		end

		local chunks = {}
		for lang, lang_chunks in pairs(raft.code_chunks) do
			if
				vim.tbl_contains(code_languages, lang)
				and not vim.tbl_contains(config.codeRunner.never_run or {}, lang)
			then
				for _, cell in ipairs(lang_chunks) do
					table.insert(chunks, cell)
				end
			end
		end

		table.sort(chunks, function(a, b)
			return a.range.from[1] < b.range.from[1]
		end)

		return chunks
	end

	local function jump_to_cell(cell)
		if not cell then
			return
		end
		vim.api.nvim_win_set_cursor(0, { cell.range.from[1] + 1, 0 })
	end

	local function goto_next()
		local buf = vim.api.nvim_get_current_buf()
		local chunks = get_sorted_chunks(buf)
		if not chunks then
			return
		end

		local cur_line = vim.api.nvim_win_get_cursor(0)[1] - 1
		for _, cell in ipairs(chunks) do
			if cell.range.from[1] > cur_line then
				jump_to_cell(cell)
				return
			end
		end
		vim.notify("[chunk_navigation] No next code chunk.", vim.log.levels.INFO)
	end

	local function goto_prev()
		local buf = vim.api.nvim_get_current_buf()
		local chunks = get_sorted_chunks(buf)
		if not chunks then
			return
		end

		local cur_line = vim.api.nvim_win_get_cursor(0)[1] - 1
		for i = #chunks, 1, -1 do
			local cell = chunks[i]
			if cell.range.from[1] < cur_line then
				jump_to_cell(cell)
				return
			end
		end
		vim.notify("[chunk_navigation] No previous code chunk.", vim.log.levels.INFO)
	end

	vim.keymap.set("n", "<C-S-j>", goto_next, { desc = "Jump to next code chunk" })
	vim.keymap.set("n", "<C-S-k>", goto_prev, { desc = "Jump to previous code chunk" })
end

return M
