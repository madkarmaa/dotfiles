local wezterm = require 'wezterm'
local config = wezterm.config_builder()

local function hex_to_rgba(hex, alpha)
    hex = hex:gsub('#', '')

    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)

    return string.format('rgba(%d, %d, %d, %f)', r, g, b, alpha)
end

local theme_name = 'OneDark (base16)'
local bg_opacity = 0.8

config.color_scheme = theme_name
config.window_background_opacity = bg_opacity

local theme = wezterm.color.get_builtin_schemes()[theme_name]
local matching_tab_bg = hex_to_rgba(theme.background, bg_opacity)

config.default_prog = { 'pwsh.exe', '-NoLogo' }
config.animation_fps = 60

config.window_close_confirmation = 'NeverPrompt'
config.window_decorations = 'RESIZE | INTEGRATED_BUTTONS'
config.use_fancy_tab_bar = false

config.window_frame = {
    active_titlebar_bg = matching_tab_bg,
    inactive_titlebar_bg = matching_tab_bg,
}

config.initial_cols = 125
config.initial_rows = 30
config.window_padding = {
    left = '1cell',
    right = '1cell',
    top = '1cell',
    bottom = '1cell',
}

config.font = wezterm.font('FiraCode Nerd Font Mono', { weight = 'Regular' })
config.font_size = 10.0

config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 550
config.cursor_thickness = 2

config.colors = {
    tab_bar = {
        background = matching_tab_bg,

        active_tab = {
            bg_color = 'rgba(0, 0, 0, 0.75)',
            fg_color = 'white',
            intensity = 'Bold',
            underline = 'None',
            italic = false,
            strikethrough = false,
        },

        inactive_tab = {
            bg_color = matching_tab_bg,
            fg_color = 'white',
        },

        inactive_tab_hover = {
            bg_color = 'rgba(0, 0, 0, 0.5)',
            fg_color = 'white',
            italic = false,
        },

        new_tab = {
            bg_color = matching_tab_bg,
            fg_color = 'white',
        },

        new_tab_hover = {
            bg_color = 'rgba(0, 0, 0, 0.5)',
            fg_color = 'white',
            italic = false,
        },
    },
}

config.tab_bar_style = {
    window_hide = wezterm.format { { Text = ' - ' } },
    window_hide_hover = wezterm.format { { Text = ' - ' } },

    window_maximize = wezterm.format { { Text = ' o ' } },
    window_maximize_hover = wezterm.format { { Text = ' o ' } },

    window_close = wezterm.format { { Text = ' x ', } },
    window_close_hover = wezterm.format { { Text = ' x ' }, },

    new_tab = wezterm.format { { Text = ' + ' } },
    new_tab_hover = wezterm.format { { Text = ' + ' } },
}

config.keys = {
    {
        key = 't',
        mods = 'CTRL',
        action = wezterm.action.SpawnTab 'CurrentPaneDomain',
    },
    {
        key = 'w',
        mods = 'CTRL',
        action = wezterm.action.CloseCurrentTab { confirm = false },
    },

    {
        key = 'UpArrow',
        mods = 'CTRL|ALT',
        action = wezterm.action.SplitPane { direction = 'Up' },
    },
    {
        key = 'UpArrow',
        mods = 'SHIFT|ALT',
        action = wezterm.action.ActivatePaneDirection 'Up',
    },

    {
        key = 'DownArrow',
        mods = 'CTRL|ALT',
        action = wezterm.action.SplitPane { direction = 'Down' },
    },
    {
        key = 'DownArrow',
        mods = 'SHIFT|ALT',
        action = wezterm.action.ActivatePaneDirection 'Down',
    },

    {
        key = 'LeftArrow',
        mods = 'CTRL|ALT',
        action = wezterm.action.SplitPane { direction = 'Left' },
    },
    {
        key = 'LeftArrow',
        mods = 'SHIFT|ALT',
        action = wezterm.action.ActivatePaneDirection 'Left',
    },

    {
        key = 'RightArrow',
        mods = 'CTRL|ALT',
        action = wezterm.action.SplitPane { direction = 'Right' },
    },
    {
        key = 'RightArrow',
        mods = 'SHIFT|ALT',
        action = wezterm.action.ActivatePaneDirection 'Right',
    },
}

return config