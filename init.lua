-- Lua nvim config
-- borrowed from brentyi as usual


--------------------------------------------------------
------            SETTINGS/COMMANDS              -------
--------------------------------------------------------

-- Leader config
vim.g.mapleader = ","

-- turn off mouse
vim.o.mouse = ''

-- vim visual
vim.wo.relativenumber = true
vim.wo.number = true
vim.opt.termguicolors = true
vim.opt.showmode = false
vim.opt.scrolloff = 10

-- colorscheme options
vim.g.sonokai_style = 'espresso'
vim.g.sonokai_better_performance = 1
vim.g.sonokai_spell_foreground = 'colored'

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
vim.g.tex_flavor = 'latex'

-- Matchup settings
vim.g.matchup_surround_enabled = 1  -- surround support (ds% and cs%)
vim.g.matchup_transmute_enabled = 1  -- change matching tags as one's edited

-- Wildignore
vim.opt.wildignore = { '*.swp', '*.o', '*.pyc', '*.pb', '*.a', '__pycache__' } -- python
vim.opt.wildignore:append { '.venv/*', 'site-packages/*', '*.pdb' }            -- python
vim.opt.wildignore:append { '.git/*', '.hg/*', '.svn/*' }                  -- versioning
vim.opt.wildignore:append { '_site/*', '.jekyll-cache/*' }                     -- jekyll
vim.opt.wildignore:append { 'node_modules/*' }                                   -- node
vim.opt.wildignore:append { '*.bak', 'tags', '*.tar.*' }                          -- etc
vim.opt.wildignore:append { '*.pdf', '*.synctex.gz', '*.dvi', '*.fls', '*.blg' }  -- tex
vim.opt.wildignore:append { '*.bbl', '*.toc', '*.aux', '*.out', '*.fdb_latexmk' } -- tex
if vim.fn.has('macunix') then
    vim.o.wildignorecase = true
end

-- clipboard
vim.opt.clipboard:append { 'unnamed', 'unnamedplus' }

-- spell check
vim.keymap.set('n', '<F7>', ':setlocal spell! spelllang=en_us<CR>', { noremap = true, silent = true})

-- terminal shortcuts
vim.keymap.set('n', '<Leader>ot', ':split term://bash<CR>', { noremap = true, silent = true})
vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]])

-- navigation commands
-- buffer
vim.keymap.set('n', '<Leader>b', ':buffer <C-z><S-Tab>', { noremap = true})
vim.keymap.set('n', '<Leader>q', ':bp|bd #<CR>', { noremap = true})
vim.keymap.set('n', '<Leader>B', ':sbuffer <C-z><S-Tab>', { noremap = true})
vim.keymap.set('n', '<Leader>gb', ':bnext<CR>', { noremap = true })
vim.keymap.set('n', '<Leader>gB', ':bprevious<CR>', { noremap = true })
-- window
vim.keymap.set('n', '<Leader>w', '<C-W>w', { noremap = true })
vim.keymap.set('n', '<Leader>W', '<C-W>W', { noremap = true })

-- highlight search
vim.o.hlsearch = true
vim.keymap.set('n', '<F9>', ':noh<CR>', { noremap = true, silent = true})

-- case-insensitive search
vim.o.ignorecase = true
vim.o.smartcase = true

-- folding
-- -- use ufo for this
-- vim.opt.foldmethod = expr
-- vim.opt.foldexpr = nvim_treesitter#foldexpr()
-- set foldlevelstart=99

-- text wrapping in certain buffers
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'tex',
    callback = function ()
        vim.opt.formatoptions:append({ 't' })
        vim.o.textwidth = 80
    end
})
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'python',
    callback = function ()
        vim.opt.formatoptions:append({ 't' })
        vim.o.textwidth = 88
    end
})

-- template commands (python, tex stubs)
vim.api.nvim_create_user_command('Article', ':r ~/.vim/article_base.txt', {}) 
vim.api.nvim_create_user_command('Figure', ':r ~/.vim/figure_base.txt', {}) 
vim.api.nvim_create_user_command('Subfigure', ':r ~/.vim/subfigure_base.txt', {}) 
vim.api.nvim_create_user_command('Beamer', ':r ~/.vim/beamer_base.txt', {}) 
vim.api.nvim_create_user_command('Poster', ':r ~/.vim/poster_base.txt', {}) 
vim.api.nvim_create_user_command('Tikz', ':r ~/.vim/tikz_base.txt', {}) 
vim.api.nvim_create_user_command('Python', ':r ~/.vim/python_skeleton.py', {}) 
vim.api.nvim_create_user_command('Listings', ':r ~/.vim/listings_base.txt', {}) 

-- overleaf push command
-- uses fugitive
vim.api.nvim_create_user_command('Overleaf', ':Git add . | Git commit -m asdf | Git push', {})

-- New file templates
-- python
vim.api.nvim_create_autocmd('BufNewFile', {
    pattern = '*.py',
    callback = function ()
        vim.cmd('0r ~/.vim/python_skeleton.py')
    end
})

-- Neotree commands
vim.cmd([[nnoremap <silent> \ :Neotree toggle current reveal_force_cwd<CR>]])
vim.cmd([[nnoremap <silent> <F6> :Neotree reveal<CR>]])
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
        'sainnhe/sonokai',
        priority = 1000,
        config = function()
            vim.cmd.colorscheme("sonokai")
        end,
        build = function()
            -- maybe this is not needed...
            -- it's copying the theme for lualine, following help page for sonokai
            -- but seems lualine doesn't have any problem to find the theme...
            local plugpath = vim.fn.stdpath("data") .. "/lazy"
            infile = io.open(plugpath .. '/sonokai/lua/lualine/themes/sonokai.lua' , 'r')
            instr = infile:read('*a')
            infile:close()

            local configpath = vim.fn.stdpath('config')
            outfile = io.open(configpath .. '/lua/lualine/themes/sonokai.lua', 'w')
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
                theme = 'auto',
                component_separators = { left = "|", right = "|" },
                section_separators = { left = "", right = "" },
            },
        },
    },
	-- Notification helper!
	{
		"rcarriga/nvim-notify",
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
		"sdbuch/nvim-treesitter",
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
                    "javascript",
                    "markdown",
                    "markdown_inline",
                    "rust",
                    "latex",
                    "bibtex",
                },
                matchup = {
                    enable = true,  -- mandatory, false will disable the whole extension
                    disable = { "tex", "html", "c", "ruby", "config", "liquid", "lua", "make", "plaintex", "sh", "vim", "xml" },  -- optional, list of language that will be disabled
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
                    disable = { },

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
    -- Show indentation guides.
	{
		"lukas-reineke/indent-blankline.nvim",
		config = function()
			vim.api.nvim_set_hl(0, "IblIndent", { fg = "#573757" })
			vim.api.nvim_set_hl(0, "IblScope", { fg = "#555585" })
			require("ibl").setup({ indent = { char = "·" } })
		end,
	},
    -- Fuzzy find.
    -- requires ripgrep (brew install ripgrep)
    {
        "nvim-telescope/telescope.nvim",
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
		config = function()
			require("aerial").setup()
			vim.keymap.set("n", "<F8>", "<cmd>AerialToggle!<CR>")
		end,
	},
    -- Git helpers.
	{ "tpope/vim-fugitive" },
	{ "lewis6991/gitsigns.nvim", config = true },
	-- Comments. By default, bound to `gcc`.
	{ "numToStr/Comment.nvim", config = true },
	-- Motions.
	{ "kylechui/nvim-surround", config = true },
    { 'andymass/vim-matchup' },
    -- Persist the cursor position when we close a file.
	{ "vim-scripts/restore_view.vim" },
    -- Web-based Markdown preview.
	{
		"iamcco/markdown-preview.nvim",
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
			},
			filesystem = {
				filtered_items = {
					visible = false,
					hide_dotfiles = false,
					hide_gitignored = false,
					hide_hidden = false,
				},
			},
		},
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
			-- require("mini.cursorword").setup()
			require("mini.trailspace").setup()
			local hipatterns = require("mini.hipatterns")
			hipatterns.setup({
				highlighters = {
					-- Highlight certain strings
					-- These don't seem to be working (maybe sonokai's fault)
					fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
					hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
					todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
					note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
					-- Highlight hex colors
					hex_color = hipatterns.gen_highlighter.hex_color(),
				},
			})
		end,
	},
	-- Split navigation. Requires corresponding changes to tmux config for tmux
	-- integration.
	-- TODO: probably needs to be debugged + hotkeys
	{
		"alexghergh/nvim-tmux-navigation",
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
		"mhartington/formatter.nvim",
		config = function()
			-- Format keybinding.
			vim.keymap.set("n", "<Leader>cf", ":Format<CR>", { noremap = true })

			-- Automatically install formatters via Mason.
			ENSURE_INSTALLED("lua", "stylua")
			ENSURE_INSTALLED("python", "ruff") -- Can replace both black and isort!
			ENSURE_INSTALLED("typescript,javascript,typescriptreact,javascriptreact", "prettier")
			ENSURE_INSTALLED("html,css", "prettier")
			ENSURE_INSTALLED("c,cpp,cuda", "clang-format")

			-- Configure formatters.
			local util = require("formatter.util")
			require("formatter").setup({
				logging = true,
				log_level = vim.log.levels.WARN,
				filetype = {
					-- What's available:
					-- https://github.com/mhartington/formatter.nvim/tree/master/lua/formatter/filetypes
					lua = { require("formatter.filetypes.lua").stylua },
					python = { require("formatter.filetypes.python").ruff },
					typescript = { require("formatter.filetypes.typescript").prettier },
					javascript = { require("formatter.filetypes.javascript").prettier },
					html = { require("formatter.filetypes.html").prettier },
					css = { require("formatter.filetypes.css").prettier },
					markdown = { require("formatter.filetypes.markdown").prettier },
					cpp = { require("formatter.filetypes.cpp").clangformat },
					["*"] = { require("formatter.filetypes.any").remove_trailing_whitespace },
				},
			})
		end,
	},
	-- Language servers.
	{
		"williamboman/mason-lspconfig.nvim",
		config = { true },
	},
	-- Snippets.
	-- TODO: Need to port some of these
	{
		"L3MON4D3/LuaSnip",
		-- follow latest release.
		version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
		-- install jsregexp (optional!).
		build = "make install_jsregexp",
		dependencies = { "rafamadriz/friendly-snippets" },
	},
	-- Completion sources.
	{ "hrsh7th/cmp-nvim-lsp" },
	{ "hrsh7th/cmp-buffer" },
	{ "hrsh7th/cmp-path" },
	{ "hrsh7th/cmp-cmdline" },
	{ "hrsh7th/cmp-nvim-lsp-signature-help" },
	{ "hrsh7th/cmp-emoji" },
	{
		"zbirenbaum/copilot.lua",
		opts = {
			suggestion = { enabled = false },
			panel = { enabled = false },
		},
	},
	{ "zbirenbaum/copilot-cmp", config = true },
	{
		"hrsh7th/nvim-cmp",
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
					["<Tab>"] = vim.schedule_wrap(function(fallback)
						if cmp.visible() and has_words_before() then
							cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
						else
							fallback()
						end
					end),
					["<S-Tab>"] = function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						else
							fallback()
						end
					end,
				}),
				sources = cmp.config.sources({
					{ name = "copilot" },
					{
						name = 'nvim_lsp',
						entry_filter = function(entry, ctx)
							return require('cmp.types').lsp.CompletionItemKind[entry:get_kind()] ~= 'Text'
						end
					},
					{ name = "nvim_lsp_signature_help" },
					{ name = "emoji" },
					{ name = "path" },
					{ name = 'luasnip' }, -- For luasnip users.
				}, {
					{ name = "buffer" },
				}),
			})

			-- Set configuration for specific filetype.
			cmp.setup.filetype("gitcommit", {
				sources = cmp.config.sources({
					{ name = "emoji" },
				}, {
					{ name = "buffer" },
				}),
			})

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
	-- Configure LPSs
	{
		"neovim/nvim-lspconfig",
		dependencies = { {"folke/neodev.nvim", config = true} },
		config = function()
			-- Dim LSP errors.
			vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", { fg = "#8c3032" })
			vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn", { fg = "#5a5a30" })
			vim.api.nvim_set_hl(0, "DiagnosticVirtualTextInfo", { fg = "#303f5a" })
			vim.api.nvim_set_hl(0, "DiagnosticVirtualTextHint", { fg = "#305a35" })
			vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#333333", bg = "#a7a7a7" })
			vim.api.nvim_set_hl(0, "CursorLine", { bg = "#333333" })

			-- Automatically install language servers via Mason.
			ENSURE_INSTALLED("python", "pyright")
			ENSURE_INSTALLED("lua", "lua-language-server")
			ENSURE_INSTALLED("typescript,javascript,typescriptreact,javascriptreact", "typescript-language-server")
			ENSURE_INSTALLED("html", "html-lsp")
			ENSURE_INSTALLED("css", "css-lsp")
			ENSURE_INSTALLED("typescript,javascript,typescriptreact,javascriptreact", "eslint-lsp")
			ENSURE_INSTALLED("tex", "texlab")
			ENSURE_INSTALLED("c,cpp,cuda", "clangd")


			-- Texlab supports a clean command.
			-- Patch in a function that implements this, and add it to config below
			local util = require 'lspconfig.util'
			local function buf_clean(bufnr)
				bufnr = util.validate_bufnr(bufnr)
				local texlab_client = util.get_active_client_by_name(bufnr, 'texlab')
				local params = {
					command = 'texlab.cleanArtifacts',
					arguments = {{ uri = vim.uri_from_bufnr(bufnr)}, },
				}
				if texlab_client then
					texlab_client.request('workspace/executeCommand', params)
					print 'Clean Success'
				else
					print 'method textDocument/clean is not supported by any servers active on the current buffer'
				end
			end

			-- Set up lspconfig.
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			require("lspconfig").pyright.setup({ capabilities = capabilities })
			require("lspconfig").lua_ls.setup({ capabilities = capabilities })
			require("lspconfig").tsserver.setup({ capabilities = capabilities })
			require("lspconfig").html.setup({ capabilities = capabilities })
			require("lspconfig").cssls.setup({ capabilities = capabilities })
			require("lspconfig").eslint.setup({ capabilities = capabilities })
			require("lspconfig").texlab.setup{
				-- cmd = { 'texlab', '-vvvv', '--log-file', '/Users/sdbuch/.local/state/nvim/texlab.log' },
				capabilities = capabilities,
				settings = {
					texlab = {
						build = {
							args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "--shell-escape", "%f" },
							executable = "latexmk",
							forwardSearchAfter = false,
							onSave = true
						},
						chktex = {
							onEdit = false,
							onOpenAndSave = true
						},
						forwardSearch = {
							executable = '/Applications/Skim.app/Contents/SharedSupport/displayline',
							args = { "%l", "%p", "%f" },
						}
					}
				},
				commands = {
					TexlabClean = {
						function()
							buf_clean(0)
						end,
						description = 'Clean files in project in current buffer',
					},
				},
			}
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
					vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, opts)
					vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
					vim.keymap.set("n", "<space>ca", vim.lsp.buf.code_action, opts)
					vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
					vim.keymap.set("n", "<space>lf", function()
						vim.lsp.buf.format({ async = true })
					end, opts)
				end,
			})
		end,
	},
	-- View errors
	{
		"folke/trouble.nvim",
		config = function()
			vim.keymap.set("n", "<Leader><Tab>", ":TroubleToggle<CR>", {})
			require("trouble").setup({
				position = "bottom", -- position of the list can be: bottom, top, left, right
				height = 10, -- height of the trouble list when position is top or bottom
				width = 50, -- width of the list when position is left or right
				icons = false, -- use devicons for filenames
				mode = "workspace_diagnostics", -- "workspace_diagnostics", "document_diagnostics", "quickfix", "lsp_references", "loclist"
				fold_open = "v", -- icon used for open folds
				fold_closed = ">", -- icon used for closed folds
				group = true, -- group results by file
				padding = true, -- add an extra new line on top of the list
				action_keys = { -- key mappings for actions in the trouble list
				-- map to {} to remove a mapping, for example:
				-- close = {},
				close = "q", -- close the list
				cancel = "<esc>", -- cancel the preview and get back to your last window / buffer / cursor
				refresh = "r", -- manually refresh
				jump = { "<cr>", "<tab>" }, -- jump to the diagnostic or open / close folds
				open_split = { "<c-x>" }, -- open buffer in new split
				open_vsplit = { "<c-v>" }, -- open buffer in new vsplit
				open_tab = { "<c-t>" }, -- open buffer in new tab
				jump_close = { "o" }, -- jump to the diagnostic and close the list
				toggle_mode = "m", -- toggle between "workspace" and "document" diagnostics mode
				toggle_preview = "P", -- toggle auto_preview
				hover = "K", -- opens a small popup with the full multiline message
				preview = "p", -- preview the diagnostic location
				close_folds = { "zM", "zm" }, -- close all folds
				open_folds = { "zR", "zr" }, -- open all folds
				toggle_fold = { "zA", "za" }, -- toggle fold of current file
				previous = "k", -- previous item
				next = "j", -- next item
			},
			indent_lines = true, -- add an indent guide below the fold icons
			auto_open = false, -- automatically open the list when you have diagnostics
			auto_close = false, -- automatically close the list when you have no diagnostics
			auto_preview = true, -- automatically preview the location of the diagnostic. <esc> to close preview and go back to last window
			auto_fold = false, -- automatically fold a file trouble list at creation
			auto_jump = { "lsp_definitions" }, -- for the given modes, automatically jump if there is only a single result
			signs = {
				-- icons / text used for a diagnostic
				error = "error",
				warning = "warn ",
				hint = "hint ",
				information = "info ",
			},
			use_diagnostic_signs = false, -- enabling this will use the signs defined in your lsp client
		})
	end,
},
}


local lazy_opts = {
	-- We don't want to install custom fonts, so we'll switch to Unicode icons.
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
require("lazy").setup(lazy_plugins, lazy_opts)
