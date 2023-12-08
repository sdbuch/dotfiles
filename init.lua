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
    -- Sonokai theme requires manual copy
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
