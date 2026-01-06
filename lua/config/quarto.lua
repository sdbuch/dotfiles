local M = {}

function M.setup()
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
			"```python",
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

	local ok_config, quarto_config = pcall(require, "quarto.config")
	local config = ok_config and quarto_config.config or { codeRunner = { never_run = {} } }

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
