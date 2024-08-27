-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices
-- Window Settings
config.use_fancy_tab_bar = false
config.enable_scroll_bar = false
config.window_padding = {
  left = '2px',
  right = '2px',
  top = '0px',
  bottom = '0px',
}

-- fonts
config.font_size = 20
config.warn_about_missing_glyphs = true
config.freetype_load_target = 'HorizontalLcd' -- https://wezfurlong.org/wezterm/config/lua/config/freetype_load_target.html
config.freetype_load_target = "Light" -- https://github.com/wez/wezterm/issues/639
config.freetype_load_flags = "NO_HINTING|NO_AUTOHINT"
config.foreground_text_hsb = {
    hue = 1.0,
    saturation = 1.0,
    brightness = 0.9,  -- default is 1.0
}
config.font = wezterm.font("Source Code Pro for Powerline")
config.font_rules = {
  { -- Italic
    intensity = 'Normal',
    italic = true,
    font = wezterm.font({
      family="Monaspace Radon",  -- script style
      -- family='Monaspace Krypton',
      style = 'Italic',
    })
  },

  { -- Bold
    intensity = 'Bold',
    italic = false,
    font = wezterm.font( {
      family='Source Code Pro for Powerline',
      -- weight='ExtraBold',
      weight='Bold',
      })
  },

  { -- Bold Italic
    intensity = 'Bold',
    italic = true,
    font = wezterm.font( {
      family='Source Code Pro for Powerline',
      style='Italic',
      weight='Bold',
      }
    )
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
config.color_scheme = 'Monokai Dark (Gogh)'

-- and finally, return the configuration to wezterm
return config
