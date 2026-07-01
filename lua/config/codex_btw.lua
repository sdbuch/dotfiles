local M = {}

local defaults = {
	codex_cmd = "codex",
	codex_args = {},
	focus = true,
	map = true,
	pane_percent = 40,
	popup_height = "80%",
	popup_width = "80%",
	split = "h",
	state_file = vim.fn.stdpath("state") .. "/codex-btw-panes.json",
}

local config = vim.deepcopy(defaults)
local state = { panes = {} }
local state_loaded = false

local function notify(message, level)
	vim.notify(message, level or vim.log.levels.INFO, { title = "codex btw" })
end

local function system(args)
	local out = vim.fn.systemlist(args)
	if vim.v.shell_error ~= 0 then
		return nil, table.concat(out, "\n")
	end
	return out
end

local function shell_join(args)
	local parts = {}
	for _, arg in ipairs(args) do
		table.insert(parts, vim.fn.shellescape(tostring(arg)))
	end
	return table.concat(parts, " ")
end

local function codex_words(extra)
	local words = { config.codex_cmd }
	vim.list_extend(words, config.codex_args or {})
	if extra then
		vim.list_extend(words, extra)
	end
	return words
end

local function load_state()
	if state_loaded then
		return
	end
	state_loaded = true

	local file = io.open(config.state_file, "r")
	if not file then
		return
	end

	local raw = file:read("*a")
	file:close()

	local ok, decoded = pcall(vim.json.decode, raw)
	if ok and type(decoded) == "table" and type(decoded.panes) == "table" then
		state.panes = decoded.panes
	end
end

local function save_state()
	vim.fn.mkdir(vim.fn.fnamemodify(config.state_file, ":h"), "p")
	local file = io.open(config.state_file, "w")
	if not file then
		return
	end
	file:write(vim.json.encode(state))
	file:close()
end

local function buffer_dir()
	local name = vim.api.nvim_buf_get_name(0)
	if name ~= "" then
		return vim.fn.fnamemodify(name, ":p:h")
	end
	return vim.fn.getcwd()
end

local function repo_root()
	local out = vim.fn.systemlist({ "git", "-C", buffer_dir(), "rev-parse", "--show-toplevel" })
	if vim.v.shell_error == 0 and out[1] and out[1] ~= "" then
		return out[1]
	end
	return vim.fn.getcwd()
end

local function current_window_id()
	if not vim.env.TMUX_PANE or vim.env.TMUX_PANE == "" then
		return nil
	end

	local out = vim.fn.systemlist({ "tmux", "display-message", "-p", "-t", vim.env.TMUX_PANE, "#{window_id}" })
	if vim.v.shell_error == 0 and out[1] and out[1] ~= "" then
		return out[1]
	end
	return vim.env.TMUX_PANE
end

local function state_key(root)
	return root .. "\t" .. (current_window_id() or "")
end

local function relative_path(root)
	local name = vim.api.nvim_buf_get_name(0)
	if name == "" then
		return "[No Name]"
	end

	local abs = vim.fn.fnamemodify(name, ":p")
	local ok, rel = pcall(vim.fs.relpath, root, abs)
	if ok and rel and rel ~= "" then
		return rel
	end
	return vim.fn.fnamemodify(abs, ":~:.")
end

local function make_context(opts)
	local root = repo_root()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local line_count = vim.api.nvim_buf_line_count(0)
	local has_range = opts and opts.line1 and opts.line2
	local line1 = has_range and opts.line1 or cursor[1]
	local line2 = has_range and opts.line2 or cursor[1]

	if line2 < line1 then
		line1, line2 = line2, line1
	end

	line1 = math.max(1, math.min(line1, line_count))
	line2 = math.max(line1, math.min(line2, line_count))

	local lines = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)
	local filetype = vim.bo.filetype ~= "" and vim.bo.filetype or "text"
	local path = relative_path(root)
	local location

	if has_range then
		location = string.format("Selection: %s:%d-%d", path, line1, line2)
	else
		location = string.format("Cursor: %s:%d:%d", path, cursor[1], cursor[2] + 1)
	end

	return root, table.concat({
		location,
		"Filetype: " .. filetype,
		"",
		"```" .. filetype,
		table.concat(lines, "\n"),
		"```",
	}, "\n")
end

local function make_query(prompt, context)
	return prompt .. "\n\nContext from Neovim:\n" .. context
end

local function write_temp(text)
	local path = vim.fn.tempname()
	local file, err = io.open(path, "w")
	if not file then
		return nil, err
	end
	file:write(text)
	file:close()
	return path
end

local function ensure_ready()
	if vim.fn.executable("tmux") ~= 1 then
		notify("tmux is not executable", vim.log.levels.ERROR)
		return false
	end
	if not vim.env.TMUX or vim.env.TMUX == "" then
		notify("Neovim is not running inside tmux", vim.log.levels.WARN)
		return false
	end
	if vim.fn.executable(config.codex_cmd) ~= 1 then
		notify(config.codex_cmd .. " is not executable", vim.log.levels.ERROR)
		return false
	end
	return true
end

local function pane_alive(pane_id)
	if not pane_id or pane_id == "" then
		return false
	end

	local out = vim.fn.systemlist({ "tmux", "display-message", "-p", "-t", pane_id, "#{pane_id}" })
	return vim.v.shell_error == 0 and out[1] == pane_id
end

local function ensure_pane(root, fresh, initial_query)
	load_state()

	local key = state_key(root)
	if fresh then
		state.panes[key] = nil
		save_state()
	end

	local pane_id = state.panes[key]
	if pane_alive(pane_id) then
		return pane_id, false
	end

	local codex_extra = {}
	if initial_query and initial_query ~= "" then
		table.insert(codex_extra, initial_query)
	end

	local args = {
		"tmux",
		"split-window",
		config.split == "v" and "-v" or "-h",
		"-d",
		"-p",
		tostring(config.pane_percent),
		"-P",
		"-F",
		"#{pane_id}",
		"-c",
		root,
		shell_join(codex_words(codex_extra)),
	}

	if vim.env.TMUX_PANE and vim.env.TMUX_PANE ~= "" then
		table.insert(args, 3, "-t")
		table.insert(args, 4, vim.env.TMUX_PANE)
	end

	local out, err = system(args)
	if not out then
		notify("tmux split failed: " .. err, vim.log.levels.ERROR)
		return nil
	end

	pane_id = vim.trim(table.concat(out, "\n"))
	if pane_id == "" then
		notify("tmux did not return a pane id", vim.log.levels.ERROR)
		return nil
	end

	state.panes[key] = pane_id
	save_state()
	return pane_id, true
end

local function send_to_pane(pane_id, text)
	local tmp, err = write_temp(text)
	if not tmp then
		notify("could not write prompt: " .. err, vim.log.levels.ERROR)
		return false
	end

	local _, load_err = system({ "tmux", "load-buffer", "-b", "nvim-btw", tmp })
	os.remove(tmp)
	if load_err then
		notify("tmux load-buffer failed: " .. load_err, vim.log.levels.ERROR)
		return false
	end

	local _, paste_err = system({ "tmux", "paste-buffer", "-b", "nvim-btw", "-t", pane_id, "-p", "-d" })
	if paste_err then
		notify("tmux paste-buffer failed: " .. paste_err, vim.log.levels.ERROR)
		return false
	end

	local _, send_err = system({ "tmux", "send-keys", "-t", pane_id, "Enter" })
	if send_err then
		notify("tmux send-keys failed: " .. send_err, vim.log.levels.ERROR)
		return false
	end

	return true
end

local function submit_to_pane(root, query, opts)
	local pane_id, created = ensure_pane(root, opts and opts.fresh, query)
	if not pane_id then
		return
	end

	if created or send_to_pane(pane_id, query) then
		if config.focus then
			system({ "tmux", "select-pane", "-t", pane_id })
		end
	end
end

local function display_popup(root, title, shell_cmd)
	local args = {
		"tmux",
		"display-popup",
		"-E",
		"-w",
		config.popup_width,
		"-h",
		config.popup_height,
		"-T",
		title,
		"-d",
		root,
		shell_cmd,
	}

	if vim.env.TMUX_PANE and vim.env.TMUX_PANE ~= "" then
		table.insert(args, 3, "-t")
		table.insert(args, 4, vim.env.TMUX_PANE)
	end

	local _, popup_err = system(args)
	if popup_err then
		notify("tmux display-popup failed: " .. popup_err, vim.log.levels.ERROR)
		return false
	end

	return true
end

local function submit_to_popup(root, query)
	display_popup(root, "codex btw", shell_join(codex_words({ query })))
end

local function submit_to_exec_popup(root, query)
	local tmp, err = write_temp(query)
	if not tmp then
		notify("could not write prompt: " .. err, vim.log.levels.ERROR)
		return
	end

	local answer_tmp = vim.fn.tempname()
	local log_tmp = vim.fn.tempname()
	local quoted_tmp = vim.fn.shellescape(tmp)
	local quoted_answer = vim.fn.shellescape(answer_tmp)
	local quoted_log = vim.fn.shellescape(log_tmp)
	local cleanup = table.concat({ "rm -f", quoted_tmp, quoted_answer, quoted_log }, " ")
	local shell_cmd = table.concat({
		"trap " .. vim.fn.shellescape(cleanup) .. " EXIT",
		"printf 'running codex exec...\\n'",
		shell_join(codex_words({ "exec", "--output-last-message", answer_tmp, "-" }))
			.. " < "
			.. quoted_tmp
			.. " > "
			.. quoted_log
			.. " 2>&1",
		"status=$?",
		"clear",
		"if [ -s "
			.. quoted_answer
			.. " ]; then less -R "
			.. quoted_answer
			.. "; else less -R "
			.. quoted_log
			.. "; fi",
		"exit $status",
	}, "; ")

	if not display_popup(root, "codex btw exec", shell_cmd) then
		os.remove(tmp)
		os.remove(answer_tmp)
		os.remove(log_tmp)
	end
end

function M.ask(opts)
	opts = opts or {}

	if not ensure_ready() then
		return
	end

	local root, context = make_context(opts)
	local prompt = vim.trim(opts.prompt or "")

	local function submit(input)
		input = vim.trim(input or "")
		if input == "" then
			return
		end

		local query = make_query(input, context)
		if opts.exec then
			submit_to_exec_popup(root, query)
		elseif opts.popup then
			submit_to_popup(root, query)
		else
			submit_to_pane(root, query, opts)
		end
	end

	if prompt ~= "" then
		submit(prompt)
	else
		local input_prompt = "btw: "
		if opts.exec then
			input_prompt = "btw exec: "
		elseif opts.popup then
			input_prompt = "btw popup: "
		end
		vim.ui.input({ prompt = input_prompt }, submit)
	end
end

function M.setup(opts)
	config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
	state = { panes = {} }
	state_loaded = false

	pcall(vim.api.nvim_del_user_command, "Btw")
	pcall(vim.api.nvim_del_user_command, "BtwExec")
	pcall(vim.api.nvim_del_user_command, "BtwPopup")

	vim.api.nvim_create_user_command("Btw", function(command_opts)
		M.ask({
			fresh = command_opts.bang,
			line1 = command_opts.range > 0 and command_opts.line1 or nil,
			line2 = command_opts.range > 0 and command_opts.line2 or nil,
			prompt = command_opts.args,
		})
	end, { bang = true, desc = "Ask Codex about current Neovim context in a tmux pane", nargs = "*", range = true })

	vim.api.nvim_create_user_command("BtwPopup", function(command_opts)
		M.ask({
			line1 = command_opts.range > 0 and command_opts.line1 or nil,
			line2 = command_opts.range > 0 and command_opts.line2 or nil,
			popup = true,
			prompt = command_opts.args,
		})
	end, { desc = "Ask Codex about current Neovim context in an interactive tmux popup", nargs = "*", range = true })

	vim.api.nvim_create_user_command("BtwExec", function(command_opts)
		M.ask({
			exec = true,
			line1 = command_opts.range > 0 and command_opts.line1 or nil,
			line2 = command_opts.range > 0 and command_opts.line2 or nil,
			prompt = command_opts.args,
		})
	end, { desc = "Ask Codex about current Neovim context with answer-only exec output", nargs = "*", range = true })

	if config.map then
		vim.keymap.set("n", "<Leader>a", "<cmd>Btw<CR>", { desc = "Ask Codex about current line" })
		vim.keymap.set("x", "<Leader>a", ":Btw<CR>", { desc = "Ask Codex about selection", silent = true })
		vim.keymap.set("n", "<Leader>A", "<cmd>BtwPopup<CR>", { desc = "Ask Codex in popup" })
		vim.keymap.set("x", "<Leader>A", ":BtwPopup<CR>", { desc = "Ask Codex popup about selection", silent = true })
	end
end

return M
