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
    -- USB 자동 마운트, 관리자 권한 비밀번호 창 (packages.extra; 설치돼 있을 때만)
    hl.exec_cmd("sh -c 'command -v udiskie >/dev/null && exec udiskie --no-tray'")
    hl.exec_cmd("sh -c 'a=/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1; [ -x $a ] && exec $a'")
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
        -- Windows처럼: 창 테두리를 잡고 끌어 크기 조절, 끌다가 화면/다른 창 가장자리에 붙음
        resize_on_border = true, extend_border_grab_area = 14, hover_icon_on_border = true,
        snap = { enabled = true },
    },
    decoration = { rounding = 10 },
    -- 한/영 키가 오른쪽 Alt로 들어오는 자판에서도 항상 Hangul 키로 보낸다. Alt로 들어오면 fcitx5가 키를 뗄 때에야
    -- 한/영을 바꾸고(늦게 반영), 그 사이 Alt가 앱으로 새서 엉뚱한 단축키가 눌렸다. 오른쪽 Ctrl = 한자.
    input = { kb_layout = "us", kb_options = "korean:ralt_hangul,korean:rctrl_hanja" },
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

-- Windows처럼 모든 창이 떠 있는 창: 제목 표시줄을 끌어 옮기고, 테두리로 크기를 바꾸고, 누른 창이 맨 앞으로 온다.
-- (타일 창은 항상 떠 있는 창 밑에 깔려서 설정 창이 크롬·디스코드 위에 고정돼 보였다.) 타일로 되돌리려면 이 한 줄을 지운다.
hl.window_rule({ name = "windows-like-float", match = { class = ".*" }, float = true, center = true })

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
    hl.window_rule({ name = "hyprbars-no-settings", ["hyprbars:no_bar"] = true, match = { title = "^설정 · 싯딤의 상자$" } })
end

local mod = "SUPER"
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(mod .. " + Space", hl.dsp.exec_cmd("quickshell ipc call launcher toggle"))
hl.bind(mod .. " + L", hl.dsp.exec_cmd("quickshell ipc call lock lock"))
hl.bind(mod .. " + I", hl.dsp.exec_cmd("quickshell ipc call settings toggle"))
hl.bind(mod .. " + A", hl.dsp.exec_cmd("quickshell ipc call chat toggle"))
-- 스크린샷: ~/사진/스크린샷 에 저장 + 클립보드 (~/.local/bin/shittim-shot)
hl.bind("Print", hl.dsp.exec_cmd("shittim-shot region"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("shittim-shot region"))
hl.bind(mod .. " + Print", hl.dsp.exec_cmd("shittim-shot full"))
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + E", hl.dsp.exec_cmd("hyprctl dispatch 'hl.dsp.exit()'"))

-- ---------- Windows식 창 조작 ----------
-- 윈도우 키만 눌렀다 떼면 오른쪽 위 ≡ 메뉴
hl.bind(mod .. " + Super_L", hl.dsp.exec_cmd("quickshell ipc call menu toggle"), { release = true })
-- Super + 왼쪽/오른쪽 버튼 끌기 = 창 옮기기 / 크기 바꾸기 (제목 표시줄이 없는 창도)
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
-- Super + ←/→ = 화면 반쪽에 붙이기, Super + ↑ = 최대화/복원
local function half(right)
    return function()
        local w, m = hl.get_active_window(), hl.get_active_monitor()
        if not w or not m then return end
        local r, g = m.reserved, 12          -- reserved.top / .bottom ...: 상단 바와 독이 차지한 자리
        local L, T, R, B = r.left or 0, r.top or 0, r.right or 0, r.bottom or 0
        local x, y = m.x + L + g, m.y + T + g
        local fw, fh = m.width - L - R - g * 2, m.height - T - B - g * 2
        local hw = math.floor((fw - g) / 2)
        hl.dispatch(hl.dsp.window.resize({ x = hw, y = fh }))
        hl.dispatch(hl.dsp.window.move({ x = right and (x + hw + g) or x, y = y }))
    end
end
hl.bind(mod .. " + left",  half(false))
hl.bind(mod .. " + right", half(true))
hl.bind(mod .. " + up", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind("ALT + F4", hl.dsp.window.close())
hl.bind("ALT + Tab", function() hl.dispatch(hl.dsp.window.cycle_next()); hl.dispatch(hl.dsp.window.bring_to_top()) end)
-- Super + D = 바탕화면 보기 (빈 작업 공간 9로 갔다가 다시 누르면 돌아옴)
hl.bind(mod .. " + D", function()
    local ws = hl.get_active_workspace()
    hl.dispatch(hl.dsp.focus({ workspace = (ws and ws.id == 9) and 1 or 9 }))
end)
-- Super + V = 클립보드 기록 (cliphist + fuzzel)
hl.bind(mod .. " + V", hl.dsp.exec_cmd("sh -c 'cliphist list | fuzzel --dmenu | cliphist decode | wl-copy'"))

-- 소리·밝기·미디어 키
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
