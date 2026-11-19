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
    -- GTK 앱이 직접 그리는 제목 표시줄은 ✕ 만: Hyprland가 최대화 상태를 앱에 알려주지 않아 앱의 □ 는 복원이 안 된다
    hl.exec_cmd("gsettings set org.gnome.desktop.wm.preferences button-layout appmenu:close")
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
        match = { class = "^(discord|code|code-oss|org\\.gnome\\.FileRoller|org\\.pulseaudio\\.pavucontrol|org\\.gnome\\.Evince)$" } })
    hl.window_rule({ name = "hyprbars-no-settings", ["hyprbars:no_bar"] = true, match = { title = "^설정 · 싯딤의 상자$" } })
end

local mod = "SUPER"
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(mod .. " + Space", hl.dsp.exec_cmd("quickshell ipc call launcher toggle"))
hl.bind(mod .. " + L", hl.dsp.exec_cmd("quickshell ipc call lock lock"))
hl.bind(mod .. " + I", hl.dsp.exec_cmd("quickshell ipc call settings toggle"))
hl.bind(mod .. " + A", hl.dsp.exec_cmd("quickshell ipc call chat toggle"))
-- 스크린샷·화면 녹화 (~/.local/bin/shittim-shot): 사진은 ~/사진/스크린샷 + 클립보드, 녹화는 ~/비디오/화면 녹화
hl.bind("Print", hl.dsp.exec_cmd("shittim-shot menu"))   -- 사진/녹화 고르기, 녹화 중이면 녹화 끝
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
-- ---------- 창 붙이기 (Windows의 스냅) ----------
-- 자리 이름: left right top(=최대화) tl tr bl br(=화면 1/4).  zone_box = 그 자리의 x, y, 너비, 높이 (상단 바·독은 피한다)
local function zone_box(zone, m)
    local r, g = m.reserved, 12          -- reserved.top / .bottom ...: 상단 바와 독이 차지한 자리
    local L, T, R, B = r.left or 0, r.top or 0, r.right or 0, r.bottom or 0
    local x, y = m.x + L + g, m.y + T + g
    local fw, fh = m.width - L - R - g * 2, m.height - T - B - g * 2
    local hw, hh = math.floor((fw - g) / 2), math.floor((fh - g) / 2)
    if zone == "top" then return x, y, fw, fh end
    local right  = zone == "right" or zone == "tr" or zone == "br"
    local bottom = zone == "bl" or zone == "br"
    local full   = zone == "left" or zone == "right"
    return right and (x + hw + g) or x, bottom and (y + hh + g) or y, hw, full and fh or hh
end
local snapped = {}     -- 붙이기 전의 창 크기 (창 주소 → {w, h}): 붙인 창을 다시 끌어내면 이 크기로 돌아간다
function shittim_snap(zone)   -- 전역: hyprctl로 시험할 수 있게
    local w, m = hl.get_active_window(), hl.get_active_monitor()
    if not w or not m then return end
    if (w.fullscreen or 0) ~= 0 then hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })) end
    if zone == "top" then
        if (w.fullscreen or 0) == 0 then hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })) end
        return
    end
    snapped[w.address] = snapped[w.address] or { w = w.size.x, h = w.size.y }
    local x, y, bw, bh = zone_box(zone, m)
    hl.dispatch(hl.dsp.window.resize({ x = bw, y = bh }))
    hl.dispatch(hl.dsp.window.move({ x = x, y = y }))
end
local function half(right) return function() shittim_snap(right and "right" or "left") end end   -- Super + ←/→

-- 창을 끌다가 마우스가 화면 가장자리에 닿은 채로 놓으면 그 자리에 붙인다: 왼쪽/오른쪽 = 반쪽, 위 = 최대화, 모서리 = 1/4.
-- 끄는 동안에는 놓으면 갈 자리를 미리 보여 준다 (SnapPreview.qml).
-- 끌기 시작/끝 신호가 따로 없어서: 왼쪽 버튼을 누를 때 창 위치를 적어 두고, 그 뒤로 위치가 달라졌으면 끄는 중으로 본다.
local press, drag_watch = nil, nil
local function zone_at(c, m)
    local C = 60                                    -- 모서리로 치는 범위
    local l, r = c.x <= m.x + 1, c.x >= m.x + m.width - 2
    local t, b = c.y <= m.y + 1, c.y >= m.y + m.height - 2
    local nl, nr = c.x <= m.x + C, c.x >= m.x + m.width - C
    local nt, nb = c.y <= m.y + C, c.y >= m.y + m.height - C
    if (l and nt) or (t and nl) then return "tl" end
    if (r and nt) or (t and nr) then return "tr" end
    if (l and nb) or (b and nl) then return "bl" end
    if (r and nb) or (b and nr) then return "br" end
    return l and "left" or r and "right" or t and "top" or nil
end
local function preview(zone, m)
    if not zone then return hl.dispatch(hl.dsp.exec_cmd("quickshell ipc call snap hide")) end
    local x, y, bw, bh = zone_box(zone, m)
    hl.dispatch(hl.dsp.exec_cmd(string.format("quickshell ipc call snap box %d %d %d %d", x, y, bw, bh)))
end
local function drag_end()
    if drag_watch then drag_watch:set_enabled(false) end
    if press and press.zone then preview(nil) end
    press = nil
end
drag_watch = hl.timer(function()
    local p, w, c, m = press, hl.get_active_window(), hl.get_cursor_pos(), hl.get_monitor_at_cursor()
    if not (p and w and c and m) or w.address ~= p.address or not w.floating then return drag_end() end
    p.ticks = p.ticks + 1
    if p.ticks > 1200 then return drag_end() end                 -- 버튼을 뗀 신호를 놓쳤을 때 (1분)
    if not p.dragging then
        if w.at.x == p.x and w.at.y == p.y then return end        -- 아직 안 끌었다
        p.dragging = true
        local o = snapped[w.address]                              -- 붙여 둔 창을 끌어냈다: 원래 크기로
        if o and (w.fullscreen or 0) == 0 then hl.dispatch(hl.dsp.window.resize({ x = o.w, y = o.h })) end
        snapped[w.address] = nil
    end
    local z = zone_at(c, m)
    if z ~= p.zone then p.zone = z; preview(z, m) end
end, { timeout = 50, type = "repeat" })
drag_watch:set_enabled(false)
hl.bind("mouse:272", function()
    local w = hl.get_active_window()
    if not w then return end
    press = { address = w.address, x = w.at.x, y = w.at.y, ticks = 0 }
    drag_watch:set_enabled(true)
end, { non_consuming = true })
hl.bind("mouse:272", function()
    local p, w, c, m = press, hl.get_active_window(), hl.get_cursor_pos(), hl.get_monitor_at_cursor()
    local dragged = p and w and w.address == p.address and w.floating and (p.dragging or w.at.x ~= p.x or w.at.y ~= p.y)
    drag_end()
    if dragged and c and m then local z = zone_at(c, m); if z then shittim_snap(z) end end
end, { release = true, non_consuming = true })
hl.bind(mod .. " + left",  half(false))
hl.bind(mod .. " + right", half(true))
hl.bind(mod .. " + up", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind("ALT + F4", hl.dsp.window.close())
-- Alt+Tab: 창 목록(Switcher.qml)을 보여주며 고르고, Alt를 떼면 목록을 닫고 그 창을 맨 앞으로.
-- Alt를 뗀 것은 타이머로 확인한다: 떼는 순간에 거는 단축키(release)는 그 사이 Alt+Tab이 눌렸으면 Hyprland가 실행하지 않는다.
local alt_watch
alt_watch = hl.timer(function()
    if hl.is_key_down("Alt_L") then return end
    alt_watch:set_enabled(false)
    hl.dispatch(hl.dsp.exec_cmd("quickshell ipc call switcher commit"))
end, { timeout = 40, type = "repeat" })
function shittim_switcher(dir)   -- 전역: hyprctl로 시험할 수 있게
    return function()
        hl.dispatch(hl.dsp.exec_cmd("quickshell ipc call switcher " .. dir))
        alt_watch:set_enabled(true)
    end
end
hl.bind("ALT + Tab", shittim_switcher("next"), { repeating = true })
hl.bind("ALT + SHIFT + Tab", shittim_switcher("prev"), { repeating = true })
hl.bind("ALT + Escape", hl.dsp.exec_cmd("quickshell ipc call switcher cancel"))   -- 목록 취소
-- Wine/Proton이 띄우는 빈 "시스템 트레이" 창(explorer.exe, 160x20; 카카오톡·블루 아카이브를 켤 때)을 안 보이는 곳으로
hl.window_rule({ name = "wine-tray", match = { class = "^explorer\\.exe$", title = "^$" },
                 workspace = "special:winetray silent", no_focus = true, no_initial_focus = true })
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
