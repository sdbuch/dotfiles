local M = {}

function M.setup()
	vim.g.molten_image_provider = "image.nvim"
	vim.g.molten_output_win_max_height = 40
	vim.g.molten_auto_open_output = false
	vim.g.molten_wrap_output = true
	vim.g.molten_virt_text_output = true
	vim.g.molten_virt_lines_off_by_1 = true
	vim.g.molten_image_location = "float"
	vim.g.molten_auto_init_behavior = "raise"

	vim.keymap.set("n", "<leader>e", ":MoltenEvaluateOperator<CR>", { desc = "evaluate operator", silent = true })
	vim.keymap.set(
		"n",
		"<leader>oo",
		":noautocmd MoltenEnterOutput<CR>",
		{ desc = "open output window", silent = true }
	)
	vim.keymap.set("n", "<leader>re", ":MoltenReevaluateCell<CR>", { desc = "re-eval cell", silent = true })
	vim.keymap.set(
		"v",
		"<leader>ve",
		":<C-u>MoltenEvaluateVisual<CR>gv",
		{ desc = "execute visual selection", silent = true }
	)
	vim.keymap.set("n", "<leader>oc", ":MoltenHideOutput<CR>", { desc = "close output window", silent = true })
	vim.keymap.set("n", "<C-BS>", ":MoltenDelete<CR>", { desc = "delete Molten cell", silent = true })
	vim.keymap.set("n", "<leader>mk", ":MoltenInterrupt<CR>", { desc = "interrupt running Molten cell", silent = true })
	vim.keymap.set("n", "<leader>mi", ":MoltenInit<CR>", { desc = "Initialize Molten kernel", silent = true })

	vim.keymap.set("n", "<leader>mj", function()
		local host = vim.fn.input("Enter host node: ")
		if host and host ~= "" then
			print("Getting token for host: " .. host .. "...")

			local cmd = "source ~/.aliases && gtjtoken -q " .. vim.fn.shellescape(host)
			local token_result = vim.fn.system(cmd)
			local token = vim.trim(token_result)

			if vim.v.shell_error ~= 0 or token == "" then
				print("Failed to get token for host: " .. host)
				print("Command output: " .. token_result)
				return
			end

			local url = "http://127.0.0.1:8888/lab?token=" .. token
			print("Connecting to Jupyter kernel at " .. host .. "...")
			local success, err = pcall(vim.cmd, "MoltenInit " .. url)
			if success then
				print("Successfully connected to Jupyter kernel on " .. host .. "!")
			else
				print("Failed to connect to Jupyter kernel: " .. tostring(err))
			end
		else
			print("Connection cancelled - no host provided")
		end
	end, { desc = "Connect to remote Jupyter kernel via host", silent = false })

	local function paste_molten_output()
		local temp_file = vim.fn.tempname() .. ".json"

		local save_success, save_error = pcall(function()
			local original_notify = vim.notify
			vim.notify = function(msg, level, opts)
				if type(msg) == "string" and msg:match("^%[Molten%]") then
					return
				end
				return original_notify(msg, level, opts)
			end

			vim.cmd("MoltenSave " .. temp_file)
			vim.wait(50)
			vim.notify = original_notify
		end)

		if not save_success then
			print("Failed to save Molten outputs: " .. tostring(save_error))
			return
		end

		local file = io.open(temp_file, "r")
		if not file then
			print("Failed to read temp file: " .. temp_file)
			return
		end

		local json_content = file:read("*all")
		file:close()
		os.remove(temp_file)

		local ok, data = pcall(vim.fn.json_decode, json_content)
		if not ok or not data or not data.cells then
			print("Failed to parse JSON or no cells found")
			return
		end

		local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
		local closest_cell = nil
		local min_distance = math.huge

		for _, cell in ipairs(data.cells) do
			if cell.span and cell.span.begin and cell.span.begin.lineno then
				local cell_line = cell.span.begin.lineno + 1
				local distance = math.abs(cursor_line - cell_line)
				if distance < min_distance then
					min_distance = distance
					closest_cell = cell
				end
			end
		end

		if not closest_cell or not closest_cell.chunks then
			print("No suitable cell found near cursor")
			return
		end

		local function strip_ansi(text)
			return text:gsub("\27%[[0-9;]*m", "")
		end

		local output_lines = {}
		for _, chunk in ipairs(closest_cell.chunks) do
			if chunk.data and chunk.data["text/plain"] then
				local content = strip_ansi(chunk.data["text/plain"])
				for line in content:gmatch("[^\n]*") do
					if line ~= "" then
						table.insert(output_lines, line)
					end
				end
			end
		end

		if #output_lines == 0 then
			print("No text output found in closest cell")
			return
		end

		local formatted_content = { "```", "Output:" }
		for _, line in ipairs(output_lines) do
			table.insert(formatted_content, line)
		end
		table.insert(formatted_content, "```")

		local current_line = vim.api.nvim_win_get_cursor(0)[1]
		vim.api.nvim_buf_set_lines(0, current_line - 1, current_line - 1, false, formatted_content)

		print("Pasted output from cell at line " .. (closest_cell.span.begin.lineno + 1))
	end

	vim.keymap.set(
		"n",
		"<leader>op",
		paste_molten_output,
		{ desc = "Paste closest Molten output at cursor", silent = false }
	)
	vim.keymap.set("n", "<leader>ob", ":MoltenOpenInBrowser<CR>", { desc = "open output in browser", silent = true })
end

return M
