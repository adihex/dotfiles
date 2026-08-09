local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Peaksea 3.4: https://github.com/calincru/peaksea.vim
-- Vim defines GUI highlight groups, not a canonical terminal palette. The ANSI
-- slots therefore follow the closest semantic groups in each Peaksea branch.
local palettes = {
  dark = {
    colors = {
      foreground = '#d0d0d0',
      background = '#202020',
      cursor_fg = '#000000',
      cursor_bg = '#00f000',
      cursor_border = '#00f000',
      selection_fg = '#000000',
      selection_bg = '#a6caf0',
      scrollbar_thumb = '#444444',
      split = '#9098a0',
      ansi = {
        '#202020',
        '#800000',
        '#008000',
        '#d0d090',
        '#6098b0',
        '#800080',
        '#a6caf0',
        '#d0d0d0',
      },
      brights = {
        '#333333',
        '#f08060',
        '#60f080',
        '#e0c060',
        '#70a0b8',
        '#f0c0f0',
        '#c0d8f8',
        '#ffffff',
      },
      tab_bar = {
        background = '#111111',
        active_tab = {
          bg_color = '#d0d0d0',
          fg_color = '#202020',
          intensity = 'Bold',
        },
        inactive_tab = {
          bg_color = '#888888',
          fg_color = '#000000',
        },
        inactive_tab_hover = {
          bg_color = '#a6caf0',
          fg_color = '#000000',
        },
        new_tab = {
          bg_color = '#111111',
          fg_color = '#9098a0',
        },
        new_tab_hover = {
          bg_color = '#a6caf0',
          fg_color = '#000000',
        },
      },
    },
    window_frame = {
      active_titlebar_bg = '#202020',
      inactive_titlebar_bg = '#111111',
      button_fg = '#d0d0d0',
      button_bg = '#202020',
      button_hover_fg = '#000000',
      button_hover_bg = '#a6caf0',
    },
  },
  light = {
    colors = {
      foreground = '#000000',
      background = '#e0e0e0',
      cursor_fg = '#f0f0f0',
      cursor_bg = '#008000',
      cursor_border = '#008000',
      selection_fg = '#000000',
      selection_bg = '#a6caf0',
      scrollbar_thumb = '#a0a0a0',
      split = '#c0c0c0',
      ansi = {
        '#000000',
        '#800000',
        '#489000',
        '#907000',
        '#2060a8',
        '#a030a0',
        '#007068',
        '#c0c0c0',
      },
      brights = {
        '#686868',
        '#c03000',
        '#009030',
        '#d0d090',
        '#1050a0',
        '#6a5acd',
        '#a6caf0',
        '#f0f0f0',
      },
      tab_bar = {
        background = '#d0d0d0',
        active_tab = {
          bg_color = '#e0e0e0',
          fg_color = '#000000',
          intensity = 'Bold',
        },
        inactive_tab = {
          bg_color = '#c0c0c0',
          fg_color = '#000000',
        },
        inactive_tab_hover = {
          bg_color = '#a6caf0',
          fg_color = '#000000',
        },
        new_tab = {
          bg_color = '#d0d0d0',
          fg_color = '#686868',
        },
        new_tab_hover = {
          bg_color = '#a6caf0',
          fg_color = '#000000',
        },
      },
    },
    window_frame = {
      active_titlebar_bg = '#e0e0e0',
      inactive_titlebar_bg = '#d0d0d0',
      button_fg = '#000000',
      button_bg = '#e0e0e0',
      button_hover_fg = '#000000',
      button_hover_bg = '#a6caf0',
    },
  },
}

local function mode_for_appearance(appearance)
  return appearance:find 'Dark' and 'dark' or 'light'
end

-- The mux server has no GUI, so dark remains the safe fallback there.
local initial_mode = wezterm.gui and mode_for_appearance(wezterm.gui.get_appearance()) or 'dark'
config.colors = palettes[initial_mode].colors
config.font = wezterm.font_with_fallback {
  { family = 'JetBrains Mono', weight = 'Regular' },
  'Symbols Nerd Font Mono',
  'Apple Color Emoji',
  'Apple Symbols',
  'Menlo',
}
config.font_size = 13
config.line_height = 1.10
config.default_cursor_style = 'SteadyBar'

config.window_background_opacity = 0.97
config.macos_window_background_blur = 20
config.window_padding = {
  left = 12,
  right = 12,
  top = 10,
  bottom = 10,
}
config.inactive_pane_hsb = {
  saturation = 0.90,
  brightness = 0.82,
}

-- Effectively infinite scrollback (RAM cost only for panes that actually fill it).
config.scrollback_lines = 1000000

-- Complements
config.enable_scroll_bar = true

-- Tab bar at the bottom with fancy styling.
config.tab_bar_at_bottom = true
config.tab_max_width = 100
config.use_fancy_tab_bar = true
config.show_new_tab_button_in_tab_bar = false
config.window_frame = {
  font = wezterm.font { family = 'JetBrains Mono', weight = 'DemiBold' },
  font_size = 12,
}
for key, value in pairs(palettes[initial_mode].window_frame) do
  config.window_frame[key] = value
end

-- Don't let a font-size change ask macOS to resize the window. When the window is
-- already clamped by the screen, WezTerm keeps the old row count while the pixels
-- no longer fit -- rows are then drawn below the visible edge. Suspected (not
-- proven) contributor to the stale-tab-layout bug.
config.adjust_window_size_when_changing_font_size = false

config.keys = {
  -- Don't nuke scrollback by accident (default macOS CMD+K clears scrollback+viewport).
  { key = 'K', mods = 'CMD', action = wezterm.action.DisableDefaultAssignment },

  -- Toggle Peaksea light/dark for this window without disturbing other overrides.
  {
    key = 'phys:L',
    mods = 'CMD|SHIFT',
    action = wezterm.action_callback(function(window, _pane)
      local overrides = window:get_config_overrides() or {}
      local current_background = overrides.colors and overrides.colors.background
      local current_mode
      if current_background == palettes.light.colors.background then
        current_mode = 'light'
      elseif current_background == palettes.dark.colors.background then
        current_mode = 'dark'
      else
        current_mode = mode_for_appearance(window:get_appearance())
      end

      local next_mode = current_mode == 'dark' and 'light' or 'dark'
      overrides.colors = overrides.colors or {}
      for key, value in pairs(palettes[next_mode].colors) do
        overrides.colors[key] = value
      end
      overrides.window_frame = overrides.window_frame or {}
      for key, value in pairs(palettes[next_mode].window_frame) do
        overrides.window_frame[key] = value
      end
      window:set_config_overrides(overrides)
    end),
  },

  -- CMD+SHIFT+R: force a full re-layout of every tab in this window.
  --
  -- Escape hatch for the bug where a tab keeps a row total larger than the window
  -- can display, hiding the bottom rows (e.g. an agent's prompt input). Neither
  -- zoom/unzoom nor adjust-pane-size repairs it -- adjust-pane-size only
  -- redistributes rows within a total that stays pinned. Only a genuine
  -- window-level resize recomputes it, and no `wezterm cli` subcommand issues one.
  --
  -- The 1px nudge is load-bearing: setting the size to its current value is a
  -- no-op that emits no resize event.
  {
    key = 'R',
    mods = 'CMD|SHIFT',
    action = wezterm.action_callback(function(window, _pane)
      local dims = window:get_dimensions()
      if not dims then
        return
      end
      window:set_inner_size(dims.pixel_width, dims.pixel_height - 1)
      window:set_inner_size(dims.pixel_width, dims.pixel_height)
      wezterm.log_info(
        ('re-layout forced at %dx%d px'):format(dims.pixel_width, dims.pixel_height)
      )
    end),
  },
}

return config
