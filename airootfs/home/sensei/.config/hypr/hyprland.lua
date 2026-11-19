-- Shittim OS: minimal config for the build-pipeline test. Theme comes after design review.
-- Hyprland 0.57+ reads Lua config. Reference: /usr/share/hypr/hyprland.lua

-- The gram's panel: its native mode. The QEMU test VM (Virtual-1) offers modes up to 5120x2160, so pin it.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
hl.monitor({ output = "Virtual-1", mode = "1600x1000", position = "auto", scale = 1 })

hl.env("XMODIFIERS", "@im=fcitx")
hl.env("QT_IM_MODULE", "fcitx")

hl.env("QT_QPA_PLATFORM", "wayland")
-- No Quickshell crash dialog: a crashed shell is restarted by the loop below and a crashed 설정 window just closes
-- (the stack trace still lands in `coredumpctl`).
hl.env("QS_DISABLE_CRASH_HANDLER", "1")

hl.on("hyprland.start", function()
    hl.exec_cmd("xdg-user-dirs-update")
    hl.exec_cmd("shittim-dev-sync")   -- VM only: live-reloads ~/.config from the Windows project
    hl.exec_cmd("fcitx5 -d")
    hl.exec_cmd("wl-paste --watch cliphist store")
    -- the shell (desktop, dock, Arona, lock screen). If it ever crashes it comes straight back - locked, to be safe.
    hl.exec_cmd([[sh -c 'while :; do quickshell; pgrep -x Hyprland >/dev/null || exit; sleep 1;
        (for i in $(seq 30); do sleep 1; quickshell ipc call lock lock >/dev/null 2>&1 && break; done) & done']])
    -- the lock screen is also the login screen: the session autologs in, then locks once the shell is up
    hl.exec_cmd("sh -c 'for i in $(seq 60); do quickshell ipc call lock lock && break; sleep 1; done'")
end)

hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 12,
        border_size = 2,
        col = { active_border = "rgb(2fa8e1)", inactive_border = "rgba(ffffff40)" },
    },
    decoration = { rounding = 10 },
    input = { kb_layout = "us" },
    -- ponytail: software cursor for QEMU's virtio-gpu; drop once tested on the real gram
    cursor = { no_hardware_cursors = true },
    -- allow_session_lock_restore: if the shell (= lock screen) ever crashes, a restarted shell can take the lock back
    misc = { force_default_wallpaper = 0, disable_hyprland_logo = true, allow_session_lock_restore = true,
             disable_splash_rendering = true },
})

-- Snappy, Windows-like animations. Without these Hyprland's built-in default animates everything over ~0.8 s,
-- which made every window feel slow to open. (speed is in tenths of a second)
hl.curve("snap", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.animation({ leaf = "global",      enabled = true, speed = 3,   bezier = "default" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 2.2, bezier = "snap",    style = "popin 92%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 1.4, bezier = "default", style = "popin 92%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 2.5, bezier = "snap" })
hl.animation({ leaf = "fade",        enabled = true, speed = 2,   bezier = "default" })
hl.animation({ leaf = "layers",      enabled = true, speed = 2,   bezier = "default", style = "fade" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 2.5, bezier = "default", style = "slide" })

-- 설정 (Settings.qml): a floating window that draws its own Shittim title bar
hl.window_rule({ name = "shittim-settings", match = { title = "^설정 · 싯딤의 상자$" }, float = true, center = true })

-- Title bar with □ ✕ on every app window (mockups/windows.html ④): the hyprbars plugin. build.sh compiles it;
-- a pacman hook (shittim-hyprbars-rebuild) recompiles it whenever Hyprland is updated.
hl.plugin.load("/usr/lib/hyprland-plugins/hyprbars.so")
if hl.plugin.hyprbars then
    local maximize = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']]
    hl.config({ plugin = { hyprbars = {
        bar_color = "rgb(1e3a52)", ["col.text"] = "rgb(ffffff)", inactive_button_color = "rgb(3d5a74)",
        bar_height = 38, bar_padding = 14, bar_button_padding = 8, bar_precedence_over_border = true,
        bar_text_font = "Pretendard Variable", bar_text_size = 12, bar_text_weight = "bold", bar_text_align = "left",
        on_double_click = maximize,
    } } })
    -- buttons are placed right to left
    hl.plugin.hyprbars.add_button({ bg_color = "rgb(ff6b81)", fg_color = "rgb(ffffff)", size = 25, icon = "✕",
                                    action = "hyprctl dispatch 'hl.dsp.window.close()'" })
    hl.plugin.hyprbars.add_button({ bg_color = "rgb(2fa8e1)", fg_color = "rgb(ffffff)", size = 25, icon = "□", action = maximize })
    -- apps that draw their own buttons (Chromium's tab strip, Discord, VS Code, GTK4 apps, KakaoTalk) and dialogs keep
    -- only theirs. Chromium app windows (chrome-*, e.g. the Claude app) draw none, so they do get the bar.
    hl.window_rule({ name = "hyprbars-own-buttons", ["hyprbars:no_bar"] = true,
        match = { class = "^(chromium|discord|code|code-oss|org\\.gnome\\.FileRoller|org\\.pulseaudio\\.pavucontrol|org\\.gnome\\.Evince|.*\\.exe)$" } })
    hl.window_rule({ name = "hyprbars-no-dialogs", ["hyprbars:no_bar"] = true, match = { float = true } })
end

local mod = "SUPER"
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(mod .. " + Space", hl.dsp.exec_cmd("quickshell ipc call launcher toggle"))
hl.bind(mod .. " + L", hl.dsp.exec_cmd("quickshell ipc call lock lock"))
hl.bind(mod .. " + I", hl.dsp.exec_cmd("quickshell ipc call settings toggle"))
hl.bind(mod .. " + A", hl.dsp.exec_cmd("quickshell ipc call chat toggle"))
hl.bind("Print", hl.dsp.exec_cmd("sh -c 'grim -g \"$(slurp)\" - | wl-copy'"))
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + E", hl.dsp.exec_cmd("hyprctl dispatch 'hl.dsp.exit()'"))
