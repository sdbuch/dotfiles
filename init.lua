-- Lua nvim config
-- borrowed from brentyi as usual

--------------------------------------------------------
------            SETTINGS/COMMANDS              -------
--------------------------------------------------------

-- Leader config
vim.g.mapleader = ","

-- turn off mouse
vim.o.mouse = ""

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

-- Display tabs as 4 spaces. Indentation settings will usually be overridden
-- guess-indent.nvim.
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.opt.smarttab = true
vim.opt.expandtab = true

-- Latex globals
vim.g.tex_flavor = "latex"
vim.g.gutentags_resolve_symlinks = 0

-- Matchup settings
vim.g.matchup_surround_enabled = 1 -- surround support (ds% and cs%)
vim.g.matchup_transmute_enabled = 1 -- change matching tags as one's edited

-- Wildignore
vim.opt.wildignore = { "*.swp", "*.o", "*.pyc", "*.pb", "*.a", "__pycache__" } -- python
vim.opt.wildignore:append({ ".venv/*", "site-packages/*", "*.pdb" }) -- python
vim.opt.wildignore:append({ ".git/*", ".hg/*", ".svn/*" }) -- versioning
vim.opt.wildignore:append({ "_site/*", ".jekyll-cache/*" }) -- jekyll
vim.opt.wildignore:append({ "node_modules/*" }) -- node
vim.opt.wildignore:append({ "*.bak", "tags", "*.tar.*" }) -- etc
vim.opt.wildignore:append({ "*.pdf", "*.synctex.gz", "*.dvi", "*.fls", "*.blg" }) -- tex
vim.opt.wildignore:append({ "*.bbl", "*.toc", "*.aux", "*.out", "*.fdb_latexmk" }) -- tex
if vim.fn.has("macunix") then
	vim.o.wildignorecase = true
end

-- clipboard
-- vim.opt.clipboard:append({ "unnamed", "unnamedplus" })
vim.o.clipboard = "unnamedplus"

-- spell check
vim.keymap.set("n", "<F7>", ":setlocal spell! spelllang=en_us<CR>", { noremap = true, silent = true })

-- terminal shortcuts
vim.keymap.set("n", "<Leader>ot", ":split term://bash<CR>", { noremap = true, silent = true })
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]])

-- hotkey to close quickfix menus
-- vim.keymap.set("n", "<Leader>cc", ":cclose<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<Leader>cc", function()
	-- First close the quickfix window
	vim.cmd("cclose")

	-- Then close trouble windows
	local view = require("trouble").close()
	while view do
		view = require("trouble").close()
	end
end, { noremap = true, silent = true })

-- navigation commands
-- buffer
vim.keymap.set("n", "<Leader>b", ":buffer <C-z><S-Tab>", { noremap = true })
vim.keymap.set("n", "<Leader>q", ":bp|bd #<CR>", { noremap = true })
vim.keymap.set("n", "<Leader>B", ":sbuffer <C-z><S-Tab>", { noremap = true })
vim.keymap.set("n", "<Leader>gb", ":bnext<CR>", { noremap = true })
vim.keymap.set("n", "<Leader>gB", ":bprevious<CR>", { noremap = true })
-- window
vim.keymap.set("n", "<Leader>w", "<C-W>w", { noremap = true })
vim.keymap.set("n", "<Leader>W", "<C-W>W", { noremap = true })

-- highlight search
vim.o.hlsearch = true
vim.keymap.set("n", "<F9>", ":noh<CR>", { noremap = true, silent = true })

-- case-insensitive search
vim.o.ignorecase = true
vim.o.smartcase = true

-- folding
-- -- use ufo for this... downloaded below
-- vim.opt.foldmethod = expr
-- vim.opt.foldexpr = nvim_treesitter#foldexpr()
-- set foldlevelstart=99
vim.o.foldcolumn = "1" -- '0' is not bad
vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true

-- vim-doge
-- disable default mappings
vim.g.doge_enable_mappings = 0

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
-- vim.api.nvim_create_autocmd('FileType', {
-- 	pattern = 'python',
-- 	callback = function ()
-- 		vim.opt.formatoptions:append({ 't' })
-- 		vim.o.textwidth = 88
-- 	end
-- })

-- template commands (python, tex stubs)
vim.api.nvim_create_user_command("Article", ":r ~/.vim/article_base.txt", {})
vim.api.nvim_create_user_command("Figure", ":r ~/.vim/figure_base.txt", {})
vim.api.nvim_create_user_command("Subfigure", ":r ~/.vim/subfigure_base.txt", {})
vim.api.nvim_create_user_command("Beamer", ":r ~/.vim/beamer_base.txt", {})
vim.api.nvim_create_user_command("Poster", ":r ~/.vim/poster_base.txt", {})
vim.api.nvim_create_user_command("Tikz", ":r ~/.vim/tikz_base.txt", {})
vim.api.nvim_create_user_command("Python", ":r ~/.vim/python_skeleton.py", {})
vim.api.nvim_create_user_command("Listings", ":r ~/.vim/listings_base.txt", {})

-- overleaf push command
-- uses fugitive
vim.api.nvim_create_user_command("Overleaf", ":Git add . | Git commit -m asdf | Git push", {})

-- New file templates
-- python
vim.api.nvim_create_autocmd("BufNewFile", {
	pattern = "*.py",
	callback = function()
		vim.cmd("0r ~/.vim/python_skeleton.py")
	end,
})
-- quarto
vim.api.nvim_create_autocmd("BufNewFile", {
	pattern = "*.qmd",
	callback = function()
		vim.cmd("0r ~/.vim/quarto_skeleton.qmd")
	end,
})

-- Neotree commands
vim.cmd([[nnoremap <silent> \ :Neotree toggle current reveal_force_cwd<CR>]])
vim.cmd([[nnoremap <silent> <F6> :Neotree toggle<CR>]])
vim.cmd([[nnoremap <silent> <leader>gs :Neotree float git_status<CR>]])
vim.cmd([[nnoremap <silent> <leader>sb :Neotree toggle show buffers right<CR>]])
vim.cmd([[nnoremap <silent> <leader>of :Neotree float reveal_file=<cfile> reveal_force_cwd<CR>]])

-- Texlab LSP commands
vim.cmd([[nnoremap <silent> <Leader>ll  :TexlabBuild<CR>]])
vim.cmd([[nnoremap <silent> <Leader>lc  :TexlabClean<CR>]])
vim.cmd([[nnoremap <silent> <Leader>lv  :TexlabForward<CR>]])

--------------------------------------------------------
------                  PLUGINS                  -------
--------------------------------------------------------

-- Install lazy.nvim. (plugin manager)
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
ENSURE_INSTALLED = function(filetype, package_name)
	vim.api.nvim_create_autocmd("FileType", {
		pattern = filetype,
		callback = function()
			local registry = require("mason-registry")
			-- Notification wrapper that suppresses some type errors. We call
			-- notify.notify() instead of notify() to make sure that a
			-- notification handle is returned; the latter sometimes only
			-- schedules a notification and returns nil.
			local notify = function(message, level, opts)
				return require("notify").notify(message, level, opts)
			end

			-- Is the package installed yet?
			if not registry.is_installed(package_name) then
				-- We'll make a spinner to show that something is happening.
				local spinner_frames = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" }

				-- Try to install!
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

				-- Did installation succeed?
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
		cond = function()
			return not vim.g.vscode
		end,
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("sonokai")
		end,
		build = function()
			-- maybe this is not needed...
			-- it's copying the theme for lualine, following help page for sonokai
			-- but seems lualine doesn't have any problem to find the theme...
			local plugpath = vim.fn.stdpath("data") .. "/lazy"
			infile = io.open(plugpath .. "/sonokai/lua/lualine/themes/sonokai.lua", "r")
			instr = infile:read("*a")
			infile:close()

			local configpath = vim.fn.stdpath("config")
			outfile = io.open(configpath .. "/lua/lualine/themes/sonokai.lua", "w")
			outfile:write(instr)
			outfile:close()
		end,
	},
	-- Statusline.
	{
		"nvim-lualine/lualine.nvim",
		cond = function()
			return not vim.g.vscode
		end,
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
						function(name, context) -- Filepath.
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
		cond = function()
			return not vim.g.vscode
		end,
		ft = { "tex" },
	},
	-- ctags support for tex
	{
		"ludovicchabant/vim-gutentags",
		cond = function()
			return not vim.g.vscode
		end,
		ft = "tex",
	},
	-- Notification helper!
	{
		"rcarriga/nvim-notify",
		cond = function()
			return not vim.g.vscode
		end,
		opts = {
			icons = {
				DEBUG = "(!)",
				ERROR = "🅔",
				INFO = "ⓘ ", -- "ⓘ",
				TRACE = "(⋱)",
				WARN = "⚠️ ",
			},
		},
	},
	-- Syntax highlighting.
	{
		"nvim-treesitter/nvim-treesitter",
		cond = function()
			return not vim.g.vscode
		end,
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
					enable = true, -- mandatory, false will disable the whole extension
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
					}, -- optional, list of language that will be disabled
					-- [options]
				},
				sync_install = false,
				auto_install = true,
				ignore_install = { "perl" },
				highlight = {
					-- `false` will disable the whole extension
					enable = true,

					-- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
					-- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
					-- the name of the parser)
					-- list of language that will be disabled
					disable = {},

					-- Setting this to true will run `:h syntax` and tree-sitter at the same time.
					-- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
					-- Using this option may slow down your editor, and you may see some duplicate highlights.
					-- Instead of true it can also be a list of languages
					-- sam: adding this for latex, since current latex grammar (or treesitter?)
					-- causes issues with matching $ ... $ math environments...
					additional_vim_regex_highlighting = { "latex" },
				},

				indent = {
					enable = false,
					disable = { "latex" },
					-- disable = { },
				},
			})
		end,
	},
	-- folding
	{
		"kevinhwang91/nvim-ufo",
		cond = function()
			return not vim.g.vscode
		end,
		dependencies = { "kevinhwang91/promise-async" },

		config = function()
			-- -- Option 2: nvim lsp as LSP client
			-- -- Tell the server the capability of foldingRange,
			-- -- Neovim hasn't added foldingRange to default capabilities, users must add it manually
			-- local capabilities = vim.lsp.protocol.make_client_capabilities()
			-- capabilities.textDocument.foldingRange = {
			-- 	dynamicRegistration = false,
			-- 	lineFoldingOnly = true
			-- }
			-- local language_servers = require("lspconfig").util.available_servers() -- or list servers manually like {'gopls', 'clangd'}
			-- for _, ls in ipairs(language_servers) do
			-- 	require('lspconfig')[ls].setup({
			-- 		capabilities = capabilities
			-- 		-- you can add other fields for setting up lsp server in this table
			-- 	})
			-- end
			-- require('ufo').setup()

			-- Option 3: treesitter as a main provider instead
			-- Only depend on `nvim-treesitter/queries/filetype/folds.scm`,
			-- performance and stability are better than `foldmethod=nvim_treesitter#foldexpr()`
			require("ufo").setup({
				provider_selector = function(bufnr, filetype, buftype)
					return { "treesitter", "indent" }
				end,
			})

			-- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
			vim.keymap.set("n", "zR", require("ufo").openAllFolds)
			vim.keymap.set("n", "zM", require("ufo").closeAllFolds)
			vim.keymap.set("n", "zr", require("ufo").openFoldsExceptKinds)
			vim.keymap.set("n", "zm", require("ufo").closeFoldsWith) -- closeAllFolds == closeFoldsWith(0)
		end,
	},
	-- Show indentation guides.
	{
		"lukas-reineke/indent-blankline.nvim",
		cond = function()
			return not vim.g.vscode
		end,
		config = function()
			vim.api.nvim_set_hl(0, "IblIndent", { fg = "#573757" })
			vim.api.nvim_set_hl(0, "IblScope", { fg = "#555585" })
			require("ibl").setup({ indent = { char = "·" }, scope = { show_start = false, show_end = false } })
		end,
	},
	-- Fuzzy find.
	-- requires ripgrep (brew install ripgrep)
	{
		"nvim-telescope/telescope.nvim",
		cond = function()
			return not vim.g.vscode
		end,
		tag = "0.1.4",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("telescope").setup({})

			-- Use repository root as cwd for Telescope.
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

			-- Bindings.
			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<C-p>", function()
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
		cond = function()
			return not vim.g.vscode
		end,
		config = function()
			require("aerial").setup()
			vim.keymap.set("n", "<F8>", "<cmd>AerialToggle!<CR>")
		end,
	},
	-- Git helpers.
	{ "tpope/vim-fugitive" },
	{ "lewis6991/gitsigns.nvim", config = true },
	{ "sindrets/diffview.nvim" },
	-- Comments. By default, bound to `gcc`.
	{ "numToStr/Comment.nvim", config = true },
	-- Motions.
	{ "kylechui/nvim-surround", config = true },
	{ "andymass/vim-matchup" },
	-- Persist the cursor position when we close a file.
	{ "farmergreg/vim-lastplace" },
	-- Web-based Markdown preview.
	{
		"iamcco/markdown-preview.nvim",
		cond = function()
			return not vim.g.vscode
		end,
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		ft = { "markdown" },
		build = function()
			vim.fn["mkdp#util#install"]()
		end,
		config = function()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "markdown",
				callback = function()
					vim.keymap.set("n", "<Leader>mdtp", "<Plug>MarkdownPreviewToggle")
				end,
			})
		end,
	},
	-- File browser.
	{
		"nvim-neo-tree/neo-tree.nvim",
		cond = function()
			return not vim.g.vscode
		end,
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
				-- hijack_netrw_behavior = "open_current",
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
		cond = function()
			return not vim.g.vscode
		end,
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
				-- args = { "split-window", "-v", "-e", "remain-on-exit=on" },
				-- args = { "split-window", "-v", "set-option", "-p", "remain-on-exit", "on" },
				args = { "split-window", "-v", "-l", "15%" },
			}
			require("dap").defaults.fallback.force_external_terminal = true
		end,
	},
	-- python debugger extension
	{
		"mfussenegger/nvim-dap-python",
		cond = function()
			return not vim.g.vscode
		end,
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
		cond = function()
			return not vim.g.vscode
		end,
		config = function()
			require("nvim-dap-virtual-text").setup({
				commented = true,
				virt_text_pos = "eol",
			})
		end,
	},
	-- python repl integration
	{
		"jpalardy/vim-slime",
		cond = function()
			return not vim.g.vscode
		end,
		ft = { "python", "quarto" },
		init = function()
			vim.g.slime_target = "tmux"
			vim.g.slime_default_config = { socket_name = "default", target_pane = "0" }
			-- vim.g.slime_python_ipython = 1
			vim.g.slime_bracketed_paste = 1
			vim.g.slime_preserve_curpos = 1
		end,
	},
	-- inline images (requires imagemagick)
	{
		"3rd/image.nvim",
		cond = function()
			return not vim.g.vscode
		end,
		opts = {
			backend = "kitty",
			integrations = {
				markdown = {
					filetypes = { "markdown", "vimwiki", "quarto" },
				},
			},
			max_width = 100, -- tweak to preference
			max_height = 12, -- ^
			max_height_window_percentage = math.huge, -- this is necessary for a good experience
			max_width_window_percentage = math.huge,
			window_overlap_clear_enabled = true,
			window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
		},
		-- This is on a preview branch...
		-- config = function()
		-- 	vim.keymap.set("n", "<leader>it", function()
		-- 		if require("image").is_enabled() then
		-- 			require("image").disable()
		-- 		else
		-- 			require("image").enable()
		-- 		end
		-- 	end)
		-- end,
	},
	-- ipynb-like experience
	{
		"benlubas/molten-nvim",
		cond = function()
			return not vim.g.vscode
		end,
		version = "^1.0.0", -- use version <2.0.0 to avoid breaking changes
		dependencies = { "3rd/image.nvim" },
		build = ":UpdateRemotePlugins",
		init = function()
			-- these are examples, not defaults. Please see the readme
			vim.g.molten_image_provider = "image.nvim"
			vim.g.molten_output_win_max_height = 20
			vim.g.molten_auto_open_output = false
			vim.g.molten_wrap_output = true
			vim.g.molten_virt_text_output = true
			vim.g.molten_virt_lines_off_by_1 = true
			vim.g.molten_image_location = "float"
			vim.g.molten_auto_init_behavior = "raise" -- quarto integration will try to start 10+ kernels for some reason

			vim.keymap.set(
				"n",
				"<leader>e",
				":MoltenEvaluateOperator<CR>",
				{ desc = "evaluate operator", silent = true }
			)
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
			vim.keymap.set("n", "<leader>md", ":MoltenDelete<CR>", { desc = "delete Molten cell", silent = true })
			vim.keymap.set(
				"n",
				"<leader>mk",
				":MoltenInterrupt<CR>",
				{ desc = "interrupt running Molten cell", silent = true }
			)
			vim.keymap.set("n", "<leader>mi", ":MoltenInit<CR>", { desc = "Initialize Molten kernel", silent = true })

			-- if you work with html outputs:
			vim.keymap.set(
				"n",
				"<leader>ob",
				":MoltenOpenInBrowser<CR>",
				{ desc = "open output in browser", silent = true }
			)
		end,
	},
	-- quarto
	{
		"quarto-dev/quarto-nvim",
		cond = function()
			return not vim.g.vscode
		end,
		dependencies = {
			{
				"jmbuhr/otter.nvim",
				config = function()
					require("otter").setup({
						lsp = { diagnostic_update_events = { "BufWritePost", "InsertLeave", "TextChanged" } },
					})
				end,
			},
			{ "nvim-treesitter/nvim-treesitter" },
		},
		config = function()
			local quarto = require("quarto")
			quarto.setup({
				lspFeatures = {
					languages = { "python" },
					chunks = "all",
					diagnostics = { -- Need to configure options here for otter (above)
						enabled = true,
					},
					completion = {
						enabled = true,
					},
				},
				codeRunner = {
					enabled = true,
					default_method = "molten",
					-- ft_runners = { python = "molten" },
					-- never_run = { "markdown", "yaml" },
				},
			})

			-- NOTE: A weird behavior of these is that they run all cells *matching the language of the current cell*
			-- So they'll try to "run" markdown cells unless you run in a python cell always
			local runner = require("quarto.runner")
			vim.keymap.set("n", "<leader>rc", runner.run_cell, { desc = "run cell", silent = true })
			vim.keymap.set("n", "<leader>ra", runner.run_above, { desc = "run cell and above", silent = true })
			vim.keymap.set("n", "<leader>rA", runner.run_all, { desc = "run all cells", silent = true })
			vim.keymap.set("n", "<leader>rl", runner.run_line, { desc = "run line", silent = true })
			vim.keymap.set("v", "<leader>rv", runner.run_range, { desc = "run visual range", silent = true })
			vim.keymap.set("n", "<leader>RA", function()
				runner.run_all(true)
			end, { desc = "run all cells of all languages", silent = true })
		end,
	},
	-- automatic docstring printing
	{
		"kkoomen/vim-doge",
		cond = function()
			return not vim.g.vscode
		end,
		build = ":call doge#install()",
		config = function()
			-- pnemonic: (p)rint (d)oc (s)tring
			vim.keymap.set("n", "<Leader>pds", "<Plug>(doge-generate)")

			-- Interactive mode comment todo-jumping
			vim.keymap.set("n", "<TAB>", "<Plug>(doge-comment-jump-forward)")
			vim.keymap.set("n", "<S-TAB>", "<Plug>(doge-comment-jump-backward)")
			vim.keymap.set("i", "<TAB>", "<Plug>(doge-comment-jump-forward)")
			vim.keymap.set("i", "<S-TAB>", "<Plug>(doge-comment-jump-backward)")
			vim.keymap.set("x", "<TAB>", "<Plug>(doge-comment-jump-forward)")
			vim.keymap.set("x", "<S-TAB>", "<Plug>(doge-comment-jump-backward)")
		end,
	},
	-- Automatically set indentation settings.
	{ "NMAC427/guess-indent.nvim", config = true },
	-- Misc visuals from mini.nvim.
	{
		"echasnovski/mini.nvim",
		cond = function()
			return not vim.g.vscode
		end,
		config = function()
			require("mini.animate").setup({
				cursor = { enable = false },
				scroll = { enable = false },
			})
			-- require("mini.cursorword").setup()
			require("mini.trailspace").setup()
			local hipatterns = require("mini.hipatterns")
			hipatterns.setup({
				highlighters = {
					-- Highlight hex colors
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
				-- Command to (attempt to) find project root, then toggle todos on this directory.
				-- Todo only searches on subdirectories (and calls by default on cwd)
				vim.cmd("silent! m'") -- This will fail if we're in (say) trouble window. So silent!
				local root_dir = vim.fs.dirname(vim.fs.find({ "setup.py", "pyproject.toml", ".git" }, {
					upward = true,
					path = vim.fn.getcwd(),
				})[1])
				require("trouble").open({ mode = "todo", cwd = root_dir })
			end)
			vim.keymap.set("n", "<leader>t<S-Tab>", function()
				-- This variant runs the default call to todo
				-- Todo only searches on subdirectories (and calls by default on cwd)
				vim.cmd("silent! m'") -- This will fail if we're in (say) trouble window. So silent!
				require("trouble").open({ mode = "todo" })
			end)
			require("todo-comments").setup({
				signs = false,
				keywords = {
					FIX = {
						icon = "x", -- icon used for the sign, and in search results
						color = "error", -- can be a hex color, or a named color (see below)
						alt = { "FIXME", "BUG", "FIXIT", "ISSUE" }, -- a set of other keywords that all map to this FIX keywords
						-- signs = false, -- configure signs for some keywords individually
					},
					TODO = { icon = "+", color = "info" },
					HACK = { icon = "?", color = "warning", alt = { "CHECK" } },
					WARN = { icon = "-", color = "warning", alt = { "WARNING" } },
					PERF = { icon = "o", color = "default", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
					NOTE = { icon = "~", color = "hint", alt = { "INFO" } },
					TEST = { icon = ".", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
				},
				highlight = {
					multiline = true, -- enable multine todo comments
					multiline_pattern = "^.", -- lua pattern to match the next multiline from the start of the matched keyword
					multiline_context = 10, -- extra lines that will be re-evaluated when changing a line
					before = "", -- "fg" or "bg" or empty
					keyword = "bg", -- "fg", "bg", "wide", "wide_bg", "wide_fg" or empty. (wide and wide_bg is the same as bg, but will also highlight surrounding characters, wide_fg acts accordingly but with fg)
					after = "", -- "fg" or "bg" or empty
					pattern = [[.*<(KEYWORDS)\s*:]], -- pattern or table of patterns, used for highlighting (vim regex)
					comments_only = true, -- uses treesitter to match keywords in comments only
					max_line_len = 400, -- ignore lines longer than this
					exclude = {}, -- list of file types to exclude highlighting
				},
				-- list of named colors where we try to extract the guifg from the
				-- list of highlight groups or use the hex color if hl not found as a fallback
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
	-- Split navigation. Requires corresponding changes to tmux config for tmux
	-- integration.
	-- TODO: probably needs to be debugged + hotkeys
	{
		"alexghergh/nvim-tmux-navigation",
		cond = function()
			return not vim.g.vscode
		end,
		config = function()
			local nvim_tmux_nav = require("nvim-tmux-navigation")
			nvim_tmux_nav.setup({
				disable_when_zoomed = true, -- defaults to false
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
		cond = function()
			return not vim.g.vscode
		end,
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
		cond = function()
			return not vim.g.vscode
		end,
		config = function()
			-- Format keybinding.
			vim.keymap.set("n", "<Leader>cf", function()
				require("conform").format()
			end)

			-- Automatically install formatters via Mason.
			ENSURE_INSTALLED("lua", "stylua")
			ENSURE_INSTALLED("python", "isort")
			ENSURE_INSTALLED("python", "ruff")
			ENSURE_INSTALLED("typescript,javascript,typescriptreact,javascriptreact", "prettierd")
			ENSURE_INSTALLED("html,css,scss", "prettierd")
			ENSURE_INSTALLED("c,cpp,cuda", "clang-format")
			-- NOTE: need to install this via cargo or brew
			-- ENSURE_INSTALLED("tex", "tex-fmt")
			ENSURE_INSTALLED("markdown", "prettierd")

			-- Configure formatters.
			require("conform").setup({
				formatters_by_ft = {
					lua = { "stylua" },
					python = { "ruff_format", "isort" },
					typescript = { "prettierd" },
					javascript = { "prettierd" },
					css = { "prettierd" },
					scss = { "prettierd" },
					markdown = { "prettierd" },
					cpp = { "clang-format" },
					tex = { "tex-fmt" },
					quarto = { "injected" }, -- TODO: would like to format markdown-parts with prettierd; hard to get it to recognize parser...
					["*"] = { "trim_whitespace", "trim_newlines" },

					-- You can customize some of the format options for the filetype (:help conform.format)
					-- rust = { "rustfmt", lsp_format = "fallback" },
					-- Conform will run the first available formatter
					-- javascript = { "prettierd", "prettier", stop_after_first = true },
				},
			})

			-- Customize the "injected" formatter
			require("conform").formatters.injected = {
				-- Set the options field
				options = {
					-- Set to true to ignore errors
					ignore_errors = false,
					-- Map of treesitter language to file extension
					-- A temporary file name with this extension will be generated during formatting
					-- because some formatters care about the filename.
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
					-- Map of treesitter language to formatters to use
					-- (defaults to the value from formatters_by_ft)
					lang_to_formatters = {},
				},
			}
		end,
	},
	-- Language servers.
	{
		"williamboman/mason-lspconfig.nvim",
		cond = function()
			return not vim.g.vscode
		end,
		config = true,
	},
	-- Snippets.
	-- TODO: Need to port some of these
	{
		"L3MON4D3/LuaSnip",
		cond = function()
			return not vim.g.vscode
		end,
		-- follow latest release.
		version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
		-- install jsregexp (optional!).
		build = "make install_jsregexp",
		dependencies = { "rafamadriz/friendly-snippets" },
		config = function()
			require("luasnip.loaders.from_vscode").lazy_load({
				paths = { "./luasnip_snippets" },
			})
		end,
	},
	{
		"smjonas/snippet-converter.nvim",
		cond = function()
			return not vim.g.vscode
		end,
		-- SnippetConverter uses semantic versioning. Example: use version = "1.*" to avoid breaking changes on version 1.
		-- Uncomment the next line to follow stable releases only.
		-- tag = "*",
		config = function()
			local template = {
				-- name = "t1", (optionally give your template a name to refer to it in the `ConvertSnippets` command)
				sources = {
					vsnip = {
						vim.fn.stdpath("config") .. "/snippets",
					},
				},
				output = {
					-- Specify the output formats and paths
					vscode_luasnip = {
						vim.fn.stdpath("config") .. "/luasnip_snippets",
					},
				},
			}

			require("snippet_converter").setup({
				templates = { template },
				-- To change the default settings (see configuration section in the documentation)
				-- settings = {},
			})
		end,
	},
	-- Completion sources.
	{
		"zbirenbaum/copilot.lua",
		cond = function()
			return not vim.g.vscode
		end,
		config = function()
			require("copilot").setup({
				suggestion = { enabled = false },
				panel = {
					enabled = false,
				},
				filetypes = {
					markdown = true, -- overrides default
				},
			})
			vim.keymap.set("n", "<Leader>C", ":Copilot panel<CR>", {})
		end,
	},
	{
		"zbirenbaum/copilot-cmp",
		cond = function()
			return not vim.g.vscode
		end,
		config = true,
	},
	{
		"hrsh7th/nvim-cmp",
		cond = function()
			return not vim.g.vscode
		end,
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
				if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then
					return false
				end
				local line, col = unpack(vim.api.nvim_win_get_cursor(0))
				return col ~= 0
					and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match("^%s*$") == nil
			end

			-- Set up nvim-cmp.
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			cmp.setup({
				-- Need to set a snippet engine up, even if we don't care about snippets.
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
					["<CR>"] = cmp.mapping.confirm({ select = false }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
					-- ["<CR>"] = cmp.mapping(function(fallback)
					-- 	if cmp.visible() then
					-- 		if luasnip.expandable() then
					-- 			luasnip.expand()
					-- 		else
					-- 			cmp.confirm({
					-- 				select = true,
					-- 			})
					-- 		end
					-- 	else
					-- 		fallback()
					-- 	end
					-- end),
					["<Tab>"] = vim.schedule_wrap(function(fallback)
						if cmp.visible() and has_words_before() then
							cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
						else
							fallback()
						end
					end),
					-- ["<Tab>"] = cmp.mapping(function(fallback)
					-- 	if cmp.visible() then
					-- 		cmp.select_next_item()
					-- 	elseif luasnip.locally_jumpable(1) then
					-- 		luasnip.jump(1)
					-- 	else
					-- 		fallback()
					-- 	end
					-- end, { "i", "s" }),
					["<S-Tab>"] = function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						else
							fallback()
						end
					end,
					-- ["<S-Tab>"] = cmp.mapping(function(fallback)
					-- 	if cmp.visible() then
					-- 		cmp.select_prev_item()
					-- 	elseif luasnip.locally_jumpable(-1) then
					-- 		luasnip.jump(-1)
					-- 	else
					-- 		fallback()
					-- 	end
					-- end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{
						name = "nvim_lsp",
						entry_filter = function(entry, ctx)
							return require("cmp.types").lsp.CompletionItemKind[entry:get_kind()] ~= "Text"
						end,
					},
					{ name = "nvim_lsp_signature_help" },
					{ name = "emoji" },
					{ name = "path" },
					{ name = "luasnip" }, -- For luasnip users.
				}, {
					{ name = "buffer" },
					-- { name = "copilot" },
				}),
				-- {
				-- 	{ name = "buffer" },
				-- }),
			})

			-- Set configuration for specific filetype.
			cmp.setup.filetype("gitcommit", {
				sources = cmp.config.sources({
					{ name = "emoji" },
				}, {
					{ name = "buffer" },
				}),
			})

			-- LaTeX: disable copilot
			function table.shallow_copy(t)
				local t2 = {}
				for k, v in pairs(t) do
					t2[k] = v
				end
				return t2
			end
			local sources = table.shallow_copy(cmp.get_config().sources)
			for i = #sources, 1, -1 do
				if sources[i].name == "copilot" then
					table.remove(sources, i)
				end
			end
			cmp.setup.filetype("tex", { sources = sources })

			-- command to toggle copilot.
			_G.toggle_buffer_source = function()
				local sources = cmp.get_config().sources
				local buffer_enabled = false

				-- Check if buffer source is enabled
				for _, source in ipairs(sources) do
					if source.name == "copilot" then
						buffer_enabled = true
						break
					end
				end

				if buffer_enabled then
					-- Disable buffer source
					cmp.setup({
						sources = vim.tbl_filter(function(source)
							return source.name ~= "copilot"
						end, sources),
					})
					print("Copilot disabled.")
				else
					-- Enable buffer source
					table.insert(sources, { name = "copilot" })
					cmp.setup({ sources = sources })
					print("Copilot enabled.")
				end
			end
			-- Map the copilot toggle function to <leader>ct
			vim.keymap.set("n", "<leader>ct", ":lua toggle_buffer_source()<CR>", { noremap = true, silent = true })

			-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
			cmp.setup.cmdline({ "/", "?" }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" },
				},
			})

			-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
			})
		end,
	},
	-- Configure LSPs
	{
		"neovim/nvim-lspconfig",
		cond = function()
			return not vim.g.vscode
		end,
		dependencies = { { "folke/neodev.nvim", config = true } },
		config = function()
			-- Dim LSP errors.
			vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", { fg = "#8c3032" })
			vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn", { fg = "#5a5a30" })
			vim.api.nvim_set_hl(0, "DiagnosticVirtualTextInfo", { fg = "#303f5a" })
			vim.api.nvim_set_hl(0, "DiagnosticVirtualTextHint", { fg = "#305a35" })
			vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#333333", bg = "#a7a7a7" })
			vim.api.nvim_set_hl(0, "CursorLine", { bg = "#333333" })

			-- Automatically install language servers via Mason.
			-- TODO: some of these failing (wrong LSP identifiers?)
			ENSURE_INSTALLED("python", "pyright")
			ENSURE_INSTALLED("rust", "rust-analyzer")
			-- ENSURE_INSTALLED("python", "ruff-lsp")
			ENSURE_INSTALLED("lua", "lua-language-server")
			ENSURE_INSTALLED("typescript,javascript,typescriptreact,javascriptreact", "typescript-language-server")
			ENSURE_INSTALLED("html", "html-lsp")
			ENSURE_INSTALLED("css,scss", "css-lsp")
			-- ENSURE_INSTALLED("markdown", "marksman")
			ENSURE_INSTALLED("typescript,javascript,typescriptreact,javascriptreact", "eslint-lsp")
			ENSURE_INSTALLED("tex", "texlab")
			ENSURE_INSTALLED("c,cpp,cuda", "clangd")
			-- ENSURE_INSTALLED("quarto", "marksman")

			-- TODO: Need to debug texlab diagnostics...
			-- Texlab supports a clean command.
			-- Patch in a function that implements this, and add it to config below
			local util = require("lspconfig.util")
			local function buf_clean(bufnr)
				bufnr = util.validate_bufnr(bufnr)
				local texlab_client = util.get_active_client_by_name(bufnr, "texlab")
				local params = {
					command = "texlab.cleanArtifacts",
					arguments = { { uri = vim.uri_from_bufnr(bufnr) } },
				}
				if texlab_client then
					texlab_client.request("workspace/executeCommand", params)
					print("Clean Success")
				else
					print("method textDocument/clean is not supported by any servers active on the current buffer")
				end
			end
			local function buf_dependency_graph(bufnr)
				bufnr = util.validate_bufnr(bufnr)
				local texlab_client = util.get_active_client_by_name(bufnr, "texlab")
				local params = {
					command = "texlab.showDependencyGraph",
				}
				if texlab_client then
					local response = texlab_client.request_sync("workspace/executeCommand", params)
					local lines = vim.split(response["result"], "\n", true)
					local ok, result = pcall(vim.fn.writefile, lines, "./.dependency")
					if ok then
						print("Dependency graph written to ./.dependency")
					else
						print("Error writing dependency graph")
					end
					-- print(response["result"])
				else
					print("method textDocument/clean is not supported by any servers active on the current buffer")
				end
			end

			-- Set up lspconfig.
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			require("lspconfig").pyright.setup({
				capabilities = capabilities,
				settings = {
					python = {
						analysis = {
							autoSearchPaths = true,
							useLibraryCodeForTypes = true,
							diagnosticMode = "openFilesOnly",
							-- diagnosticMode = "workspace",
						},
					},
				},
			})
			-- -- Custom setup for ruff-lsp
			-- local on_attach = function(client, bufnr)
			-- 	-- Disable hover in favor of Pyright
			-- 	client.server_capabilities.hoverProvider = false
			-- end
			-- require("lspconfig").ruff_lsp.setup({
			-- 	capabilities = capabilities,
			-- 	on_attach = on_attach,
			-- })
			require("lspconfig").lua_ls.setup({ capabilities = capabilities })
			require("lspconfig").ts_ls.setup({ capabilities = capabilities })
			-- require("lspconfig").marksman.setup({
			-- 	capabilities = capabilities,
			-- 	filetypes = { "quarto" },
			-- 	root_dir = require("lspconfig.util").root_pattern(".git", ".marksman.toml", "_quarto.yml"),
			-- })
			require("lspconfig").html.setup({ capabilities = capabilities })
			require("lspconfig").cssls.setup({ capabilities = capabilities })
			require("lspconfig").eslint.setup({ capabilities = capabilities })
			require("lspconfig").rust_analyzer.setup({ capabilities = capabilities })
			require("lspconfig").texlab.setup({
				-- cmd = { 'texlab', '-vvvv', '--log-file', '/Users/sdbuch/.local/state/nvim/texlab.log' },
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
					TexlabClean = {
						function()
							buf_clean(0)
						end,
						description = "Clean files in project in current buffer",
					},
					TexlabDependencyGraph = {
						function()
							buf_dependency_graph(0)
						end,
						description = "Print dependency graph for current project",
					},
				},
			})
			require("lspconfig").clangd.setup({ capabilities = capabilities })

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", {}),
				callback = function(ev)
					-- Enable completion triggered by <c-x><c-o>
					vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

					vim.api.nvim_create_autocmd("CursorHold", {
						buffer = bufnr,
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

					-- Buffer local mappings.
					-- See `:help vim.lsp.*` for documentation on any of the below functions
					local opts = { buffer = ev.buf }
					vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
					vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
					vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
					vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
					-- vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
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
		cond = function()
			return not vim.g.vscode
		end,
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
					mode = "diagnostics", -- inherit from diagnostics mode
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
					-- last          = "-╴",
					-- last       = "╰╴", -- rounded
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
		}, -- for default options, refer to the configuration section for custom setup.
	},
}

require("lazy").setup({
	spec = lazy_plugins,
	ui = {
		-- We don't want to install custom fonts, so we'll switch to Unicode icons.
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
	-- for image.nvim + imagemagick luarocks install
	rocks = {
		hererocks = true, -- recommended if you do not have global installation of Lua 5.1.
	},
})
