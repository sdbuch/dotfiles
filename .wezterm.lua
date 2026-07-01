-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

local home = os.getenv("HOME")
if home then
	config.font_dirs = { home .. "/Library/Fonts" }
end

local tmux_new_session = {
	"/usr/bin/env",
	"-u",
	"TMUX",
	"/bin/zsh",
	"-lc",
	'exec "$(command -v tmux)" new-session -A -s "agent-$(/bin/date +%Y%m%d-%H%M%S)-$$"',
}

-- This is where you actually apply your config choices
-- Window Settings
config.use_fancy_tab_bar = false
config.enable_scroll_bar = false
config.window_padding = {
	left = "2px",
	right = "2px",
	top = "0px",
	bottom = "0px",
}

config.audible_bell = "SystemBeep"
-- config.visual_bell = {
-- 	fade_in_function = "EaseIn",
-- 	fade_in_duration_ms = 150,
-- 	fade_out_function = "EaseOut",
-- 	fade_out_duration_ms = 150,
-- }

-- key remappings
config.keys = {
	{
		key = "t",
		mods = "CMD",
		action = wezterm.action.SpawnCommandInNewTab({
			args = tmux_new_session,
		}),
	},
	{
		key = "Enter",
		mods = "CTRL",
		action = wezterm.action.SendString("\x1b[13;5u"),
	},
	{
		key = "Enter",
		mods = "SHIFT",
		action = wezterm.action.SendString("\x1b\r"),
	},
	{
		key = "Enter",
		mods = "CTRL|SHIFT",
		action = wezterm.action.SendString("\x1b[13;6u"),
	},
	{
		key = "k",
		mods = "CTRL|SHIFT",
		action = wezterm.action.SendString("\x1b[75;6u"),
	},
	{
		key = "j",
		mods = "CTRL|SHIFT",
		action = wezterm.action.SendString("\x1b[74;6u"),
	},
	{
		key = "o",
		mods = "CTRL|SHIFT",
		action = wezterm.action.SendString("\x1b[79;6u"),
	},
	{
		key = "Backspace",
		mods = "CTRL",
		action = wezterm.action.SendString("\x1b[127;5u"),
	},
	{
		key = "Z",
		mods = "CTRL|SHIFT",
		action = wezterm.action.PromptInputLine({
			description = "Enter new name for tab",
			action = wezterm.action_callback(function(window, _pane, line)
				if line ~= nil then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},
}

local status_title_prefixes = {
	"⠁",
	"⠂",
	"⠄",
	"⠈",
	"⠋",
	"⠙",
	"⠹",
	"⠸",
	"⠼",
	"⠴",
	"⠦",
	"⠧",
	"⠇",
	"⠏",
	"⠐",
	"⠠",
	"⡀",
	"⢀",
	"✳",
	"✶",
	"✻",
	"✢",
	"✽",
	"✺",
}

local function starts_with(value, prefix)
	return value:sub(1, #prefix) == prefix
end

local function split_leading_status_marker(value)
	local marker, rest = value:match("^(%[%s*[!?.]+%s*%])%s*(.*)$")
	if marker == nil then
		return nil, value
	end

	return "[" .. marker:sub(2, -2):gsub("%s+", "") .. "]", rest
end

local function split_status_indicators(title)
	if title == nil then
		return "", ""
	end

	local indicators = {}
	local rest = title
	local found = true

	while found do
		found = false

		for _, prefix in ipairs(status_title_prefixes) do
			if starts_with(rest, prefix .. " ") then
				table.insert(indicators, prefix)
				rest = rest:sub(#prefix + 2)
				found = true
				break
			end
		end

		if not found then
			local marker, marker_rest = split_leading_status_marker(rest)
			if marker ~= nil then
				table.insert(indicators, marker)
				rest = marker_rest
				found = true
			end
		end
	end

	if #indicators == 0 then
		return "", title
	end

	return table.concat(indicators, " "), rest
end

wezterm.on("format-tab-title", function(tab, _tabs, _panes, _config, _hover, max_width)
	local pane_title = tab.active_pane and tab.active_pane.title or ""
	local status_indicators, pane_title_without_status = split_status_indicators(pane_title)
	local title = tab.tab_title
	local tab_number = tostring((tab.tab_index or 0) + 1)

	if title == nil or title == "" then
		title = pane_title_without_status
	end
	if title == nil or title == "" then
		title = "tab"
	end
	if status_indicators ~= "" then
		title = status_indicators .. " " .. title
	end
	title = tab_number .. ": " .. title
	if max_width and max_width > 2 then
		title = wezterm.truncate_right(title, max_width - 2)
	end

	return " " .. title .. " "
end)

-- fonts
config.font_size = 26   -- Optimized for 3840x2160
config.warn_about_missing_glyphs = true
config.freetype_load_target = "HorizontalLcd" -- https://wezfurlong.org/wezterm/config/lua/config/freetype_load_target.html
config.freetype_load_target = "Light" -- https://github.com/wez/wezterm/issues/639
config.freetype_load_flags = "NO_HINTING|NO_AUTOHINT"
config.foreground_text_hsb = {
	hue = 1.0,
	saturation = 1.0,
	brightness = 0.9, -- default is 1.0
}
config.font = wezterm.font("Source Code Pro for Powerline")
config.font_rules = {
	{ -- Italic
		intensity = "Normal",
		italic = true,
		font = wezterm.font({
			family = "Monaspace Radon", -- script style
			-- family='Monaspace Krypton',
			style = "Italic",
		}),
	},

	{ -- Bold
		intensity = "Bold",
		italic = false,
		font = wezterm.font({
			family = "Source Code Pro for Powerline",
			-- weight='ExtraBold',
			weight = "Bold",
		}),
	},

	{ -- Bold Italic
		intensity = "Bold",
		italic = true,
		font = wezterm.font({
			family = "Source Code Pro for Powerline",
			style = "Italic",
			weight = "Bold",
		}),
	},
}

-- -- Monaspace:  https://monaspace.githubnext.com/
-- -- https://github.com/HaleTom/dotfiles/blob/a2049913a35676eb4c449ebaff09f65abe055f62/wezterm/.config/wezterm/wezterm.lua#L93
-- config.font = wezterm.font(
--   { -- Normal text
--   family='Monaspace Neon',
--   harfbuzz_features={ 'calt', 'liga', 'dlig', 'ss01', 'ss02', 'ss03', 'ss04', 'ss05', 'ss06', 'ss07', 'ss08' },
--   stretch='UltraCondensed', -- This doesn't seem to do anything
-- })
--
-- config.font_rules = {
--   { -- Italic
--     intensity = 'Normal',
--     italic = true,
--     font = wezterm.font({
--       family="Monaspace Argon",  -- script style
--       -- family='Monaspace Krypton',
--       style = 'Italic',
--     })
--   },
--
--   { -- Bold
--     intensity = 'Bold',
--     italic = false,
--     font = wezterm.font( {
--       family='Monaspace Krypton',
--       -- weight='ExtraBold',
--       weight='Bold',
--       })
--   },
--
--   { -- Bold Italic
--     intensity = 'Bold',
--     italic = true,
--     font = wezterm.font( {
--       family='Monaspace Krypton',
--       style='Italic',
--       weight='Bold',
--       }
--     )
--   },
-- }

-- Color scheme:
-- config.color_scheme = 'Monokai Pro Ristretto (Gogh)'
config.color_scheme = "Monokai Dark (Gogh)"

-- and finally, return the configuration to wezterm
return config
