-- Lua nvim config
-- borrowed from brentyi as usual

--------------------------------------------------------
------            FEATURE FLAGS                  -------
--------------------------------------------------------
local ENABLE_IMAGE_SUPPORT = false

local ok, local_config = pcall(require, "local_config")
if ok and local_config.ENABLE_IMAGE_SUPPORT ~= nil then
	ENABLE_IMAGE_SUPPORT = local_config.ENABLE_IMAGE_SUPPORT
end

--------------------------------------------------------
------            SETTINGS/COMMANDS              -------
--------------------------------------------------------

vim.g.mapleader = ","

-- vim visual
vim.wo.relativenumber = true
vim.wo.number = true
vim.opt.termguicolors = true
vim.opt.showmode = false
vim.opt.scrolloff = 10

-- colorscheme options
vim.g.sonokai_style = "espresso"
vim.g.sonokai_better_performance = 1
vim.g.sonokai_spell_foreground = "colored"

-- Use current file's parent as cwd.
vim.opt.autochdir = true

-- Disable netrw.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Display tabs as 4 spaces. Indentation settings will usually be overridden by guess-indent.nvim.
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.opt.smarttab = true
vim.opt.expandtab = true

-- Latex globals
vim.g.tex_flavor = "latex"
vim.g.gutentags_resolve_symlinks = 0
vim.opt.iskeyword:append("-")
vim.opt.tagcase = "match"

-- Matchup settings
vim.g.matchup_surround_enabled = 1
vim.g.matchup_transmute_enabled = 1

-- Wildignore
vim.opt.wildignore = { "*.swp", "*.o", "*.pyc", "*.pb", "*.a", "__pycache__" }
vim.opt.wildignore:append({ ".venv/*", "site-packages/*", "*.pdb" })
vim.opt.wildignore:append({ ".git/*", ".hg/*", ".svn/*" })
vim.opt.wildignore:append({ "_site/*", ".jekyll-cache/*" })
vim.opt.wildignore:append({ "node_modules/*" })
vim.opt.wildignore:append({ "*.bak", "tags", "*.tar.*" })
vim.opt.wildignore:append({ "*.pdf", "*.synctex.gz", "*.dvi", "*.fls", "*.blg" })
vim.opt.wildignore:append({ "*.bbl", "*.toc", "*.aux", "*.out", "*.fdb_latexmk" })
if vim.fn.has("macunix") then
	vim.o.wildignorecase = true
end

-- clipboard
vim.o.clipboard = "unnamedplus"

-- spell check
vim.keymap.set("n", "<F7>", ":setlocal spell! spelllang=en_us<CR>", { noremap = true, silent = true })

-- terminal shortcuts
vim.keymap.set("n", "<Leader>ot", ":split term://bash<CR>", { noremap = true, silent = true })
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]])

-- hotkey to close quickfix menus
vim.keymap.set("n", "<Leader>cc", function()
	vim.cmd("cclose")
	local view = require("trouble").close()
	while view do
		view = require("trouble").close()
	end
end, { noremap = true, silent = true })

-- navigation commands
vim.keymap.set("n", "<Leader>b", ":buffer <C-z><S-Tab>", { noremap = true })
vim.keymap.set("n", "<Leader>q", ":bp|bd #<CR>", { noremap = true })
vim.keymap.set("n", "<Leader>B", ":sbuffer <C-z><S-Tab>", { noremap = true })
vim.keymap.set("n", "<Leader>gb", ":bnext<CR>", { noremap = true })
vim.keymap.set("n", "<Leader>gB", ":bprevious<CR>", { noremap = true })
vim.keymap.set("n", "<Leader>w", "<C-W>w", { noremap = true })
vim.keymap.set("n", "<Leader>W", "<C-W>W", { noremap = true })

-- highlight search
vim.o.hlsearch = true
vim.keymap.set("n", "<F9>", ":noh<CR>", { noremap = true, silent = true })

-- case-insensitive search
vim.o.ignorecase = true
vim.o.smartcase = true

-- folding (using ufo)
vim.o.foldcolumn = "1"
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true

-- text wrapping in certain buffers
vim.api.nvim_create_autocmd("FileType", {
	pattern = "tex",
	callback = function()
		vim.opt.formatoptions:append({ "t" })
		vim.o.textwidth = 80
	end,
})
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.opt.formatoptions:append({ "t" })
		vim.o.textwidth = 80
	end,
})
vim.api.nvim_create_autocmd("FileType", {
	pattern = "quarto",
	callback = function()
		vim.o.textwidth = 88
		vim.opt_local.iskeyword = "@,48-57,_,192-255,-"
		vim.defer_fn(function()
			vim.opt_local.tabstop = 4
			vim.opt_local.shiftwidth = 4
			vim.opt_local.expandtab = true
		end, 100)
	end,
})
vim.api.nvim_create_autocmd("FileType", {
	pattern = "python",
	callback = function()
		vim.opt_local.textwidth = 0
		vim.opt_local.formatoptions:remove("t")
		vim.opt_local.tabstop = 2
		vim.opt_local.shiftwidth = 2
		vim.opt_local.expandtab = true
	end,
})

-- template commands (python, tex stubs)
vim.api.nvim_create_user_command("Article", ":r ~/.vim/article_base.txt", {})
vim.api.nvim_create_user_command("Figure", ":r ~/.vim/figure_base.txt", {})
vim.api.nvim_create_user_command("Subfigure", ":r ~/.vim/subfigure_base.txt", {})
vim.api.nvim_create_user_command("Beamer", ":r ~/.vim/beamer_base.txt", {})
vim.api.nvim_create_user_command("Poster", ":r ~/.vim/poster_base.txt", {})
vim.api.nvim_create_user_command("Tikz", ":r ~/.vim/tikz_base.txt", {})
vim.api.nvim_create_user_command("Python", ":r ~/.vim/python_skeleton.py", {})
vim.api.nvim_create_user_command("Listings", ":r ~/.vim/listings_base.txt", {})

-- overleaf push command (uses fugitive)
vim.api.nvim_create_user_command("Overleaf", ":Git add . | Git commit -m asdf | Git push", {})

-- New file templates
vim.api.nvim_create_autocmd("BufNewFile", {
	pattern = "*.qmd",
	callback = function()
		vim.cmd("0r ~/.vim/quarto_skeleton.qmd")
	end,
})

-- Neotree commands
vim.keymap.set("n", "\\", "<cmd>Neotree toggle current reveal_force_cwd<CR>", { silent = true })
vim.keymap.set("n", "<F6>", "<cmd>Neotree toggle<CR>", { silent = true })
vim.keymap.set("n", "<leader>gs", "<cmd>Neotree float git_status<CR>", { silent = true })
vim.keymap.set("n", "<leader>sb", "<cmd>Neotree toggle show buffers right<CR>", { silent = true })
vim.keymap.set("n", "<leader>of", "<cmd>Neotree float reveal_file=<cfile> reveal_force_cwd<CR>", { silent = true })

-- Texlab LSP commands (Neovim 0.11+)
vim.keymap.set("n", "<Leader>ll", "<cmd>LspTexlabBuild<CR>", { silent = true })
vim.keymap.set("n", "<Leader>lc", "<cmd>LspTexlabCleanArtifacts<CR>", { silent = true })
vim.keymap.set("n", "<Leader>lv", "<cmd>LspTexlabForward<CR>", { silent = true })

--------------------------------------------------------
------                  PLUGINS                  -------
--------------------------------------------------------

-- Install lazy.nvim (plugin manager)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Helper for making sure a package is installed via Mason.
local function ensure_installed(filetype, package_name)
	vim.api.nvim_create_autocmd("FileType", {
		pattern = filetype,
		callback = function()
			local registry = require("mason-registry")
			local notify = function(message, level, opts)
				return require("notify").notify(message, level, opts)
			end

			if not registry.is_installed(package_name) then
				local spinner_frames = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" }

				registry.refresh()
				local install_handle = registry.get_package(package_name):install()
				local notif_id = notify("", "info", {}).id
				while not install_handle:is_closed() do
					---@diagnostic disable-next-line: missing-parameter
					local spinner_index = (math.floor(vim.fn.reltimefloat(vim.fn.reltime()) * 10.0)) % #spinner_frames
						+ 1
					notif_id = notify("Installing " .. package_name .. "...", 2, {
						title = "Setup",
						icon = spinner_frames[spinner_index],
						replace = notif_id,
					}).id
					vim.wait(100)
					vim.cmd("redraw")
				end

				if registry.is_installed(package_name) then
					---@diagnostic disable-next-line: missing-fields
					notify("Installed " .. package_name, 2, {
						title = "Setup",
						icon = "✓",
						replace = notif_id,
					})
				else
					---@diagnostic disable-next-line: missing-fields
					notify("Failed to install " .. package_name, "error", {
						title = "Setup",
						icon = "𐄂",
						replace = notif_id,
					})
				end
			end
		end,
	})
end

-- Configure plugins.
local lazy_plugins = {
	-- Color scheme.
	{
		"sainnhe/sonokai",
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("sonokai")
		end,
		build = function()
			local plugpath = vim.fn.stdpath("data") .. "/lazy"
			local infile = io.open(plugpath .. "/sonokai/lua/lualine/themes/sonokai.lua", "r")
			local instr = infile:read("*a")
			infile:close()

			local configpath = vim.fn.stdpath("config")
			local outfile = io.open(configpath .. "/lua/lualine/themes/sonokai.lua", "w")
			outfile:write(instr)
			outfile:close()
		end,
	},
	-- Statusline.
	{
		"nvim-lualine/lualine.nvim",
		opts = {
			options = {
				icons_enabled = false,
				theme = "auto",
				component_separators = { left = "|", right = "|" },
				section_separators = { left = "", right = "" },
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "filename" },
				lualine_c = { "diff" },
				lualine_x = {
					{
						function()
							return vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
						end,
						color = { fg = "#777777" },
					},
					"diagnostics",
				},
				lualine_y = { "filetype", "progress" },
				lualine_z = { "location" },
			},
		},
	},
	-- close environments in tex
	{
		"sdbuch/closeb",
		ft = { "tex" },
	},
	-- ctags support for tex
	{
		"ludovicchabant/vim-gutentags",
		ft = "tex",
	},
	-- Notification helper
	{
		"rcarriga/nvim-notify",
		opts = {
			icons = {
				DEBUG = "(!)",
				ERROR = "🅔",
				INFO = "ⓘ ",
				TRACE = "(⋱)",
				WARN = "⚠️ ",
			},
		},
	},
	-- Syntax highlighting.
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			---@diagnostic disable-next-line: missing-fields
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					"c",
					"cpp",
					"cuda",
					"lua",
					"vim",
					"python",
					"html",
					"css",
					"scss",
					"javascript",
					"markdown",
					"markdown_inline",
					"rust",
					"latex",
					"bibtex",
				},
				matchup = {
					enable = true,
					disable = {
						"tex",
						"html",
						"c",
						"ruby",
						"config",
						"liquid",
						"lua",
						"make",
						"plaintex",
						"sh",
						"vim",
						"xml",
					},
				},
				sync_install = false,
				auto_install = true,
				ignore_install = { "perl" },
				highlight = {
					enable = true,
					disable = {},
					additional_vim_regex_highlighting = { "latex" },
				},
				indent = {
					enable = false,
					disable = { "latex" },
				},
			})
		end,
	},
	-- folding
	{
		"kevinhwang91/nvim-ufo",
		dependencies = { "kevinhwang91/promise-async" },
		config = function()
			require("ufo").setup({
				provider_selector = function()
					return { "treesitter", "indent" }
				end,
			})

			vim.keymap.set("n", "zR", require("ufo").openAllFolds)
			vim.keymap.set("n", "zM", require("ufo").closeAllFolds)
			vim.keymap.set("n", "zr", require("ufo").openFoldsExceptKinds)
			vim.keymap.set("n", "zm", require("ufo").closeFoldsWith)
		end,
	},
	-- Show indentation guides.
	{
		"lukas-reineke/indent-blankline.nvim",
		config = function()
			vim.api.nvim_set_hl(0, "IblIndent", { fg = "#573757" })
			vim.api.nvim_set_hl(0, "IblScope", { fg = "#555585" })
			require("ibl").setup({ indent = { char = "·" }, scope = { show_start = false, show_end = false } })
		end,
	},
	-- Fuzzy find (requires ripgrep)
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.4",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("telescope").setup({})

			vim.api.nvim_create_autocmd("BufWinEnter", {
				pattern = "*",
				callback = vim.schedule_wrap(function()
					local root = vim.fs.dirname(vim.fs.find(".git", { upward = true })[1])
					if root ~= nil then
						vim.b["Telescope#repository_root"] = root
					else
						vim.b["Telescope#repository_root"] = "."
					end
				end),
			})

			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<Leader>ff", function()
				builtin.find_files({ cwd = vim.b["Telescope#repository_root"] })
			end)
			vim.keymap.set("n", "<Leader>fg", function()
				builtin.live_grep({ cwd = vim.b["Telescope#repository_root"] })
			end)
			vim.keymap.set("n", "<Leader>fb", builtin.buffers)
			vim.keymap.set("n", "<Leader>fh", builtin.help_tags)
			vim.keymap.set("n", "<Leader>h", builtin.oldfiles)
		end,
	},
	-- Tagbar-style code overview.
	{
		"stevearc/aerial.nvim",
		config = function()
			require("aerial").setup({
				backends = { "treesitter", "lsp", "markdown" },
				filter_kind = {
					["_"] = {
						"Class",
						"Constructor",
						"Enum",
						"Function",
						"Interface",
						"Module",
						"Method",
						"Struct",
					},
					python = {
						"Class",
						"Constructor",
						"Enum",
						"Function",
						"Method",
						"Module",
					},
					markdown = false,
				},
				icons = {
					Class = "C ",
					Constructor = "c ",
					Enum = "E ",
					Function = "f ",
					Interface = "§ ",
					Method = "m ",
					Module = "M ",
					Struct = "S ",
					Variable = "v ",
					Constant = "K ",
				},
				show_guides = true,
				guides = {
					mid_item = "├─",
					last_item = "└─",
					nested_top = "│ ",
					whitespace = "  ",
				},
			})
			vim.keymap.set("n", "<F8>", "<cmd>AerialToggle!<CR>")
		end,
	},
	-- Git helpers.
	{ "tpope/vim-fugitive" },
	{ "lewis6991/gitsigns.nvim", config = true },
	{ "akinsho/git-conflict.nvim", version = "*", config = true },
	-- Comments. By default, bound to `gcc`.
	{ "numToStr/Comment.nvim", config = true },
	-- Motions.
	{ "kylechui/nvim-surround", config = true },
	{ "andymass/vim-matchup" },
	-- Matching Parentheses
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = true,
	},
	-- Persist the cursor position when we close a file.
	{ "farmergreg/vim-lastplace" },
	-- Web-based Markdown preview.
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		ft = { "markdown" },
		build = function()
			vim.fn["mkdp#util#install"]()
		end,
		config = function()
			vim.g.mkdp_theme = "dark"
			vim.g.mkdp_preview_options = {
				sync_scroll_type = "middle",
				disable_sync_scroll = 0,
				hide_yaml_meta = 1,
				mkit = {},
				katex = {},
				mermaid = {},
				disable_filename = 0,
			}
			vim.g.mkdp_combine_preview = 1
			vim.g.mkdp_combine_preview_auto_refresh = 1
			vim.g.mkdp_auto_close = 0

			vim.api.nvim_create_autocmd("FileType", {
				pattern = "markdown",
				callback = function()
					vim.keymap.set("n", "<Leader>mdtp", "<Plug>MarkdownPreviewToggle")
				end,
			})
		end,
	},
	-- Image paste for markdown
	{
		"img-paste-devs/img-paste.vim",
		ft = { "markdown" },
		config = function()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "markdown",
				callback = function()
					vim.keymap.set("n", "<Leader>mdpi", ":call mdip#MarkdownClipboardImage()<CR>")
				end,
			})
		end,
	},
	-- File browser.
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
		},
		opts = {
			default_component_configs = {
				icon = {
					folder_closed = "+",
					folder_open = "-",
					folder_empty = "%",
					default = "",
				},
				git_status = {
					symbols = {
						deleted = "x",
						renamed = "r",
						modified = "m",
						untracked = "u",
						ignored = "i",
						unstaged = "u",
						staged = "s",
						conflict = "c",
					},
				},
				name = {
					use_git_status_colors = true,
				},
			},
			filesystem = {
				bind_to_cwd = false,
				hijack_netrw_behavior = "open_current",
				filtered_items = {
					visible = false,
					hide_dotfiles = false,
					hide_gitignored = false,
					hide_hidden = false,
				},
			},
		},
	},
	-- debugger
	{
		"mfussenegger/nvim-dap",
		config = function()
			vim.keymap.set("n", "<F5>", ":lua require('dap').continue()<CR>")
			vim.keymap.set("n", "<F10>", function()
				require("dap").step_over()
			end)
			vim.keymap.set("n", "<F11>", function()
				require("dap").step_into()
			end)
			vim.keymap.set("n", "<F12>", function()
				require("dap").step_out()
			end)
			vim.keymap.set("n", "<Leader>b", function()
				require("dap").toggle_breakpoint()
			end)
			vim.keymap.set("n", "<Leader>B", function()
				require("dap").set_breakpoint()
			end)
			vim.keymap.set("n", "<Leader>lp", function()
				require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
			end)
			vim.keymap.set("n", "<Leader>cb", function()
				require("dap").clear_breakpoints()
			end)
			vim.keymap.set("n", "<Leader><F5>", function()
				require("dap").run_to_cursor()
			end)
			vim.keymap.set("n", "<Leader>dc", function()
				require("dap").repl.toggle({ height = 20 })
			end)
			vim.keymap.set("n", "<Leader>du", function()
				require("dap").up()
			end)
			vim.keymap.set("n", "<Leader>dd", function()
				require("dap").down()
			end)
			vim.keymap.set("n", "<Leader>dl", function()
				require("dap").run_last()
			end)
			vim.keymap.set({ "n", "v" }, "<Leader>K", function()
				require("dap.ui.widgets").hover()
			end)
			vim.keymap.set({ "n", "v" }, "<Leader>dp", function()
				require("dap").pause()
			end)
			vim.keymap.set("n", "<Leader>df", function()
				local widgets = require("dap.ui.widgets")
				widgets.centered_float(widgets.frames)
			end)
			vim.keymap.set("n", "<Leader>ds", function()
				local widgets = require("dap.ui.widgets")
				widgets.centered_float(widgets.scopes)
			end)
			vim.keymap.set("n", "<Leader>dk", function()
				require("dap").repl.close()
				require("dap").terminate()
			end)
			vim.keymap.set("n", "<Leader>dr", function()
				require("dap").restart()
			end)
			require("dap").defaults.fallback.external_terminal = {
				command = "tmux",
				args = { "split-window", "-v", "-l", "15%" },
			}
			require("dap").defaults.fallback.force_external_terminal = true
		end,
	},
	-- python debugger extension
	{
		"mfussenegger/nvim-dap-python",
		config = function()
			require("dap-python").setup("python", { console = "externalTerminal" })
			require("dap-python").test_runner = "pytest"
			vim.keymap.set("n", "<leader>tf", ":lua require('dap-python').test_method()<CR>")
			vim.keymap.set(
				"n",
				"<leader>tlf",
				":lua require('dap-python').test_method({ config = { justMyCode = false }})<CR>"
			)
			vim.keymap.set("n", "<leader>tc", ":lua require('dap-python').test_class()<CR>")
			vim.keymap.set("n", "<leader>ts", ":lua require('dap-python').debug_selection()<CR>")
		end,
	},
	-- debugger virtual text
	{
		"theHamsta/nvim-dap-virtual-text",
		config = function()
			require("nvim-dap-virtual-text").setup({
				commented = true,
				virt_text_pos = "eol",
			})
		end,
	},
	-- quarto
	{
		"quarto-dev/quarto-nvim",
		dependencies = {
			{
				"sdbuch/otter.nvim",
				branch = "experimental-re",
				opts = {},
			},
			{ "nvim-treesitter/nvim-treesitter" },
		},
		config = function()
			require("config.quarto").setup()
		end,
	},
	-- Automatically set indentation settings.
	{ "NMAC427/guess-indent.nvim", config = true },
	-- Misc visuals from mini.nvim.
	{
		"echasnovski/mini.nvim",
		config = function()
			require("mini.animate").setup({
				cursor = { enable = false },
				scroll = { enable = false },
			})
			require("mini.trailspace").setup()
			local hipatterns = require("mini.hipatterns")
			hipatterns.setup({
				highlighters = {
					hex_color = hipatterns.gen_highlighter.hex_color(),
				},
			})
		end,
	},
	-- TODOs with quickfix support.
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			vim.keymap.set("n", "<leader>t<Tab>", function()
				vim.cmd("silent! m'")
				local root_dir = vim.fs.dirname(vim.fs.find({ "setup.py", "pyproject.toml", ".git" }, {
					upward = true,
					path = vim.fn.getcwd(),
				})[1])
				require("trouble").open({ mode = "todo", cwd = root_dir })
			end)
			vim.keymap.set("n", "<leader>t<S-Tab>", function()
				vim.cmd("silent! m'")
				require("trouble").open({ mode = "todo" })
			end)
			require("todo-comments").setup({
				signs = false,
				keywords = {
					FIX = {
						icon = "x",
						color = "error",
						alt = { "FIXME", "BUG", "FIXIT", "ISSUE" },
					},
					TODO = { icon = "+", color = "info" },
					HACK = { icon = "?", color = "warning", alt = { "CHECK" } },
					WARN = { icon = "-", color = "warning", alt = { "WARNING" } },
					PERF = { icon = "o", color = "default", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
					NOTE = { icon = "~", color = "hint", alt = { "INFO" } },
					TEST = { icon = ".", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
				},
				highlight = {
					multiline = true,
					multiline_pattern = "^.",
					multiline_context = 10,
					before = "",
					keyword = "bg",
					after = "",
					pattern = [[.*<(KEYWORDS)\s*:]],
					comments_only = true,
					max_line_len = 400,
					exclude = {},
				},
				colors = {
					error = { "DiagnosticError", "ErrorMsg", "#DC2626" },
					warning = { "DiagnosticWarn", "WarningMsg", "#FBBF24" },
					info = { "DiagnosticInfo", "#85DAD2" },
					hint = { "DiagnosticHint", "#10B981" },
					default = { "Identifier", "#9FA0E1" },
					test = { "Identifier", "#FF00FF" },
				},
			})
		end,
	},
	-- Split navigation (requires corresponding tmux config)
	{
		"alexghergh/nvim-tmux-navigation",
		config = function()
			local nvim_tmux_nav = require("nvim-tmux-navigation")
			nvim_tmux_nav.setup({
				disable_when_zoomed = true,
			})
			vim.keymap.set("n", "<C-h>", nvim_tmux_nav.NvimTmuxNavigateLeft)
			vim.keymap.set("n", "<C-j>", nvim_tmux_nav.NvimTmuxNavigateDown)
			vim.keymap.set("n", "<C-k>", nvim_tmux_nav.NvimTmuxNavigateUp)
			vim.keymap.set("n", "<C-l>", nvim_tmux_nav.NvimTmuxNavigateRight)
			vim.keymap.set("n", "<C-\\>", nvim_tmux_nav.NvimTmuxNavigateLastActive)
			vim.keymap.set("n", "<C-Space>", nvim_tmux_nav.NvimTmuxNavigateNext)
		end,
	},
	-- Package management.
	{
		"williamboman/mason.nvim",
		opts = {
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		},
	},
	-- Formatting.
	{
		"stevearc/conform.nvim",
		config = function()
			vim.keymap.set("n", "<Leader>cf", function()
				require("conform").format()
			end)

			ensure_installed("lua", "stylua")
			ensure_installed("python", "isort")
			ensure_installed("python", "ruff")
			ensure_installed("typescript,javascript,typescriptreact,javascriptreact", "prettierd")
			ensure_installed("html,css,scss", "prettierd")
			ensure_installed("c,cpp,cuda", "clang-format")
			ensure_installed("markdown", "prettierd")

			require("conform").setup({
				formatters_by_ft = {
					lua = { "stylua" },
					python = { "ruff_format", "ruff_fix", "ruff_organize_imports" },
					typescript = { "prettierd" },
					javascript = { "prettierd" },
					css = { "prettierd" },
					scss = { "prettierd" },
					json = { "prettierd" },
					markdown = { "prettierd" },
					cpp = { "clang-format" },
					tex = { "tex-fmt" },
					quarto = { "injected" },
					["*"] = { "trim_whitespace", "trim_newlines" },
				},
				formatters = {
					ruff_format = {
						args = { "format", "--stdin-filename", "$FILENAME", "-" },
					},
					ruff_fix = {
						args = {
							"check",
							"--fix",
							"--stdin-filename",
							"$FILENAME",
							"--quiet",
							"-",
						},
					},
					ruff_organize_imports = {
						args = { "check", "--select", "I", "--fix", "--stdin-filename", "$FILENAME", "--quiet", "-" },
					},
				},
			})

			require("conform").formatters.injected = {
				options = {
					ignore_errors = false,
					lang_to_ext = {
						bash = "sh",
						c_sharp = "cs",
						elixir = "exs",
						javascript = "js",
						julia = "jl",
						latex = "tex",
						markdown = "md",
						python = "py",
						ruby = "rb",
						rust = "rs",
						teal = "tl",
						r = "r",
						typescript = "ts",
					},
					lang_to_formatters = {},
				},
			}
		end,
	},
	-- Language servers.
	{
		"williamboman/mason-lspconfig.nvim",
	},
	-- Snippets.
	{
		"L3MON4D3/LuaSnip",
		version = "v2.*",
		build = "make install_jsregexp",
		dependencies = { "rafamadriz/friendly-snippets" },
		config = function()
			require("luasnip.loaders.from_vscode").lazy_load({
				paths = { "./luasnip_snippets" },
			})
		end,
	},
	-- Completion sources.
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			{ "hrsh7th/cmp-nvim-lsp" },
			{ "hrsh7th/cmp-buffer" },
			{ "hrsh7th/cmp-path" },
			{ "hrsh7th/cmp-cmdline" },
			{ "hrsh7th/cmp-nvim-lsp-signature-help" },
			{ "hrsh7th/cmp-emoji" },
			{ "saadparwaiz1/cmp_luasnip" },
		},
		config = function()
			local has_words_before = function()
				if vim.bo[0].buftype == "prompt" then
					return false
				end
				local line, col = unpack(vim.api.nvim_win_get_cursor(0))
				return col ~= 0
					and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match("^%s*$") == nil
			end

			local cmp = require("cmp")
			cmp.setup({
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<CR>"] = cmp.mapping.confirm({ select = false }),
					["<Tab>"] = vim.schedule_wrap(function(fallback)
						if cmp.visible() and has_words_before() then
							cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
						else
							fallback()
						end
					end),
					["<S-Tab>"] = function(fallback)
						if cmp.visible() then
							cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
						else
							fallback()
						end
					end,
				}),
				sources = cmp.config.sources({
					{
						name = "nvim_lsp",
						entry_filter = function(entry)
							return require("cmp.types").lsp.CompletionItemKind[entry:get_kind()] ~= "Text"
						end,
					},
					{ name = "nvim_lsp_signature_help" },
					{ name = "emoji" },
					{ name = "path" },
					{ name = "luasnip" },
				}, {
					{ name = "buffer" },
				}),
			})

			cmp.setup.filetype("gitcommit", {
				sources = cmp.config.sources({
					{ name = "emoji" },
				}, {
					{ name = "buffer" },
				}),
			})

			cmp.setup.cmdline({ "/", "?" }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" },
				},
			})

			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
			})
		end,
	},
	-- Configure LSPs
	{
		"neovim/nvim-lspconfig",
		dependencies = { { "folke/lazydev.nvim", ft = "lua", opts = {} } },
		config = function()
			-- Dim LSP errors.
			vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", { fg = "#8c3032" })
			vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn", { fg = "#5a5a30" })
			vim.api.nvim_set_hl(0, "DiagnosticVirtualTextInfo", { fg = "#303f5a" })
			vim.api.nvim_set_hl(0, "DiagnosticVirtualTextHint", { fg = "#305a35" })
			vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#333333", bg = "#a7a7a7" })
			vim.api.nvim_set_hl(0, "CursorLine", { bg = "#333333" })

			ensure_installed("python", "pyright")
			ensure_installed("python", "ty")
			ensure_installed("rust", "rust-analyzer")
			ensure_installed("lua", "lua-language-server")
			ensure_installed("typescript,javascript,typescriptreact,javascriptreact", "typescript-language-server")
			ensure_installed("html", "html-lsp")
			ensure_installed("css,scss", "css-lsp")
			ensure_installed("typescript,javascript,typescriptreact,javascriptreact", "eslint-lsp")
			ensure_installed("tex", "texlab")
			ensure_installed("c,cpp,cuda", "clangd")

			local function buf_dependency_graph(bufnr)
				bufnr = bufnr or vim.api.nvim_get_current_buf()
				local texlab_client = nil
				for _, client in pairs(vim.lsp.get_clients({ bufnr = bufnr, name = "texlab" })) do
					texlab_client = client
					break
				end
				local params = {
					command = "texlab.showDependencyGraph",
				}
				if texlab_client then
					local response = texlab_client.request_sync("workspace/executeCommand", params)
					local lines = vim.split(response["result"], "\n", true)
					local write_ok = pcall(vim.fn.writefile, lines, "./.dependency")
					if write_ok then
						print("Dependency graph written to ./.dependency")
					else
						print("Error writing dependency graph")
					end
				else
					print("method textDocument/clean is not supported by any servers active on the current buffer")
				end
			end

			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			vim.lsp.config("pyright", {
				capabilities = capabilities,
				settings = {
					python = {
						analysis = {
							autoSearchPaths = true,
							useLibraryCodeForTypes = true,
							diagnosticMode = "openFilesOnly",
						},
					},
				},
			})
			vim.lsp.enable("pyright")
			vim.lsp.config("lua_ls", { capabilities = capabilities })
			vim.lsp.enable("lua_ls")
			vim.lsp.config("ts_ls", { capabilities = capabilities })
			vim.lsp.enable("ts_ls")
			vim.lsp.config("html", { capabilities = capabilities })
			vim.lsp.enable("html")
			vim.lsp.config("cssls", { capabilities = capabilities })
			vim.lsp.enable("cssls")
			vim.lsp.config("eslint", { capabilities = capabilities })
			vim.lsp.enable("eslint")
			vim.lsp.config("rust_analyzer", { capabilities = capabilities })
			vim.lsp.enable("rust_analyzer")
			vim.lsp.config("texlab", {
				capabilities = capabilities,
				settings = {
					texlab = {
						build = {
							args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "--shell-escape", "%f" },
							executable = "latexmk",
							forwardSearchAfter = false,
							onSave = true,
						},
						chktex = {
							onEdit = false,
							onOpenAndSave = true,
						},
						forwardSearch = {
							executable = "/Applications/Skim.app/Contents/SharedSupport/displayline",
							args = { "%l", "%p", "%f" },
						},
						experimental = {
							followPackageLinks = true,
						},
					},
				},
				commands = {
					TexlabDependencyGraph = {
						function()
							buf_dependency_graph(0)
						end,
						description = "Write dependency graph to ./.dependency file",
					},
				},
			})
			vim.lsp.enable("texlab")
			vim.lsp.config("clangd", { capabilities = capabilities })
			vim.lsp.enable("clangd")

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", {}),
				callback = function(ev)
					vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

					vim.api.nvim_create_autocmd("CursorHold", {
						buffer = ev.buf,
						callback = function()
							local opts = {
								focusable = false,
								close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
								border = "rounded",
								source = "always",
								prefix = " ",
								scope = "cursor",
							}
							vim.diagnostic.open_float(nil, opts)
						end,
					})
					vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
						border = "rounded",
					})

					vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
						border = "rounded",
					})

					local opts = { buffer = ev.buf }
					vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
					vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
					vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
					vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
					vim.keymap.set("n", "<leader><C-k>", vim.lsp.buf.signature_help, opts)
					vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, opts)
					vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, opts)
					vim.keymap.set("n", "<space>wl", function()
						print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
					end, opts)
					vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, opts)
					vim.keymap.set("n", "<Leader>rn", vim.lsp.buf.rename, opts)
					vim.keymap.set("n", "<Leader>ca", vim.lsp.buf.code_action, opts)
					vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
					vim.keymap.set("n", "<space>cf", function()
						vim.lsp.buf.format({ async = true })
					end, opts)
				end,
			})
		end,
	},
	-- View errors
	{
		"folke/trouble.nvim",
		cmd = "Trouble",
		keys = {
			{
				"<leader><Tab>",
				"<cmd>Trouble cascade toggle<cr>",
				desc = "Diagnostics (Trouble)",
			},
			{
				"<leader><S-Tab>",
				"<cmd>Trouble cascade toggle filter.buf=0<cr>",
				desc = "Buffer Diagnostics (Trouble)",
			},
			{
				"<leader>cs",
				"<cmd>Trouble symbols toggle focus=false<cr>",
				desc = "Symbols (Trouble)",
			},
			{
				"<leader>cl",
				"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
				desc = "LSP Definitions / references / ... (Trouble)",
			},
			{
				"<leader>xL",
				"<cmd>Trouble loclist toggle<cr>",
				desc = "Location List (Trouble)",
			},
			{
				"<leader>xQ",
				"<cmd>Trouble qflist toggle<cr>",
				desc = "Quickfix List (Trouble)",
			},
		},
		opts = {
			modes = {
				cascade = {
					mode = "diagnostics",
					filter = function(items)
						local severity = vim.diagnostic.severity.HINT
						for _, item in ipairs(items) do
							severity = math.min(severity, item.severity)
						end
						return vim.tbl_filter(function(item)
							return item.severity == severity
						end, items)
					end,
				},
			},
			icons = {
				---@type trouble.Indent.symbols
				indent = {
					top = "│ ",
					middle = "├╴",
					last = "└╴",
					fold_open = "˅ ",
					fold_closed = "＾",
					ws = "  ",
				},
				folder_closed = "📁",
				folder_open = "📂",
				kinds = {
					Array = "▦",
					Boolean = "⊭",
					Class = "🏛️",
					Constant = "ℏ",
					Constructor = "🦺",
					Enum = "𑂼",
					EnumMember = "𑂼",
					Event = "🎪",
					Field = "🌾",
					File = "🗄️",
					Function = "⨐",
					Interface = "🚦",
					Key = "🔑",
					Method = "🔣",
					Module = "🏰",
					Namespace = "📇",
					Null = "␀",
					Number = "#",
					Object = "📲",
					Operator = "👷",
					Package = "📦",
					Property = "⅊",
					String = "🪢",
					Struct = "⛩️",
					TypeParameter = "♳",
					Variable = "𖡄",
				},
			},
		},
	},
}

local lazy_config = {
	spec = lazy_plugins,
	ui = {
		icons = {
			cmd = "⌘",
			config = "🛠",
			event = "📅",
			ft = "📂",
			init = "⚙",
			keys = "🗝",
			plugin = "🔌",
			runtime = "💻",
			require = "🌙",
			source = "📄",
			start = "🚀",
			task = "📌",
			lazy = "💤 ",
		},
	},
}

-- Add conditional plugins based on feature flags
if ENABLE_IMAGE_SUPPORT then
	table.insert(lazy_plugins, {
		"3rd/image.nvim",
		opts = {
			backend = "kitty",
			integrations = {
				markdown = {
					filetypes = { "vimwiki", "quarto", "markdown" },
				},
			},
			max_width = 100,
			max_height = 12,
			max_height_window_percentage = math.huge,
			max_width_window_percentage = math.huge,
			window_overlap_clear_enabled = true,
			window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
			hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.webp", "*.svg" },
		},
	})

	table.insert(lazy_plugins, {
		"benlubas/molten-nvim",
		version = "^1.0.0",
		dependencies = { "3rd/image.nvim" },
		build = ":UpdateRemotePlugins",
		init = function()
			require("config.molten").setup()
		end,
	})

	lazy_config.rocks = {
		hererocks = true,
	}
end

require("lazy").setup(lazy_config)
