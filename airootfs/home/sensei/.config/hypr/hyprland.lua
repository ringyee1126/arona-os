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
        snap = { enabled = true, window_gap = 6, monitor_gap = 6 },   -- 6 = 아래 창 붙이기의 STICK
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
-- suppress_event: 앱이 스스로 청하는 최대화는 무시한다. 최대화는 아래 shittim_snap("max") 하나로만 한다 (이유는 거기에).
hl.window_rule({ name = "windows-like-float", match = { class = ".*" }, float = true, center = true, suppress_event = "maximize" })

-- Title bar with □ ✕ on every app window (mockups/windows.html ④): the hyprbars plugin. build.sh compiles it;
-- a pacman hook (shittim-hyprbars-rebuild) recompiles it whenever Hyprland is updated.
hl.plugin.load("/usr/lib/hyprland-plugins/hyprbars.so")
-- 제목 표시줄을 직접 그려서 hyprbars 를 안 쓰는 앱 (창 붙이기도 이 표를 본다)
local BAR, NO_BAR, SETTINGS = 38, { "code", "code-oss", "org.gnome.FileRoller", "org.pulseaudio.pavucontrol", "org.gnome.Evince" }, "설정 · 싯딤의 상자"
local function has_bar(w)
    if not hl.plugin.hyprbars or w.title == SETTINGS then return false end
    for _, c in ipairs(NO_BAR) do if w.class == c then return false end end
    return true
end
if hl.plugin.hyprbars then
    local maximize = [[hyprctl dispatch 'hl.dsp.exec_cmd((function() shittim_snap("max") return "true" end)())']]
    hl.config({ plugin = { hyprbars = {
        bar_color = "rgb(1e3a52)", ["col.text"] = "rgb(ffffff)", inactive_button_color = "rgb(3d5a74)",
        bar_height = BAR, bar_padding = 14, bar_button_padding = 8, bar_precedence_over_border = true,
        bar_text_font = "Pretendard Variable", bar_text_size = 12, bar_text_weight = "bold", bar_text_align = "left",
        on_double_click = maximize,
    } } })
    -- buttons are placed right to left
    hl.plugin.hyprbars.add_button({ bg_color = "rgb(ff6b81)", fg_color = "rgb(ffffff)", size = 25, icon = "✕",
                                    action = "hyprctl dispatch 'hl.dsp.window.close()'" })
    hl.plugin.hyprbars.add_button({ bg_color = "rgb(2fa8e1)", fg_color = "rgb(ffffff)", size = 25, icon = "□", action = maximize })
    -- − = 숨기기: 안 보이는 작업 공간 special:min 으로 보낸다. 다시 꺼내기 = Alt+Tab 에서 고르거나 독의 그 앱 버튼 (shittim-unmin)
    hl.plugin.hyprbars.add_button({ bg_color = "rgb(3d5a74)", fg_color = "rgb(ffffff)", size = 25, icon = "−",
                                    action = "hyprctl dispatch 'hl.dsp.window.move({ workspace = \"special:min\", follow = false })'" })
    -- apps that draw their own buttons (Chromium's tab strip, VS Code, GTK4 apps, KakaoTalk) and dialogs keep
    -- only theirs. Chromium app windows (chrome-*, e.g. the Claude app) draw none, so they do get the bar.
    hl.window_rule({ name = "hyprbars-own-buttons", ["hyprbars:no_bar"] = true,
        match = { class = "^(" .. table.concat(NO_BAR, "|"):gsub("%.", "\\.") .. ")$" } })
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
-- 떼는 순간에 거는 단축키(SUPER + Super_L, release)는 가상 키보드에서는 되는데 노트북 키보드에서는 불리지 않는다(원인 미확인).
-- 그래서 Alt+Tab처럼 키 상태를 직접 본다: 누르고 있는 동안 다른 키도 마우스 끌기도 없었으면 뗄 때 메뉴.
local super = nil   -- 윈도우 키가 눌려 있는 동안 { solo = 아직 혼자 눌렸나, geo = 직전 틱의 활성 창 자리 }
local function geo()   -- 마우스 버튼은 is_key_down으로 못 본다. Super + 끌기는 창이 움직이거나 커지는 것으로 안다
    local w = hl.get_active_window()
    return w and { a = w.address, s = w.at.x .. " " .. w.at.y .. " " .. w.size.x .. " " .. w.size.y }
end
hl.timer(function()
    local down = hl.is_key_down("Super_L")
    if down and not super then
        super = { solo = true, geo = geo() }
    elseif down and super.solo then
        local g, l = geo(), super.geo
        super.geo = g
        if g and l and g.a == l.a and g.s ~= l.s then super.solo = false end
        for code = 9, 255 do   -- 133 = 윈도우 키 자신
            if code ~= 133 and hl.is_key_down(code) then super.solo = false break end
        end
    elseif not down and super then
        if super.solo then hl.dispatch(hl.dsp.exec_cmd("quickshell ipc call menu toggle")) end
        super = nil
    end
end, { timeout = 20, type = "repeat" })
-- Super + 왼쪽/오른쪽 버튼 끌기 = 창 옮기기 / 크기 바꾸기 (제목 표시줄이 없는 창도)
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
-- ---------- 창 붙이기 (Windows의 스냅) ----------
-- 자리 이름: left right top(=최대화) tl tr bl br(=화면 1/4).  zone_box = 그 자리의 x, y, 너비, 높이 (상단 바·독은 피한다)
local function zone_box(zone, m)
    local r, g = m.reserved, zone == "max" and 2 or 12   -- reserved.top / .bottom ...: 상단 바와 독이 차지한 자리
    local L, T, R, B = r.left or 0, r.top or 0, r.right or 0, r.bottom or 0
    local x, y = m.x + L + g, m.y + T + g
    local fw, fh = m.width - L - R - g * 2, m.height - T - B - g * 2
    local hw, hh = math.floor((fw - g) / 2), math.floor((fh - g) / 2)
    if zone == "top" or zone == "max" then return x, y, fw, fh end
    local right  = zone == "right" or zone == "tr" or zone == "br"
    local bottom = zone == "bl" or zone == "br"
    local full   = zone == "left" or zone == "right"
    return right and (x + hw + g) or x, bottom and (y + hh + g) or y, hw, full and fh or hh
end
-- 최대화("top"/"max")도 그냥 화면 가득한 크기·자리다. Hyprland의 최대화 상태는 쓰지 않는다: 그 상태의 창은 위에 떠 있는
-- 다른 창보다 클릭을 먼저 가져가서(보이기는 위 창이 앞) 큰 창 안의 작은 창이 눌리지 않았다.
local snapped = {}     -- 붙이기 전의 창 (창 주소 → {w, h, x, y, max}): 다시 끌어내거나 최대화를 풀면 이 크기로 돌아간다
function shittim_snap(zone, w)   -- 전역: hyprctl로 시험할 수 있게.  w 없으면 활성 창
    w = w or hl.get_active_window()
    local m = w and (w.monitor or hl.get_active_monitor())
    if not w or not m then return end
    if zone == "top" then zone = "max" end
    local sel, o = "address:" .. w.address, snapped[w.address]
    if (w.fullscreen or 0) ~= 0 then hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle", window = sel })) end
    if zone == "max" and o and o.max then    -- 최대화된 창을 한 번 더 = 원래대로
        snapped[w.address] = nil
        hl.dispatch(hl.dsp.window.resize({ x = o.w, y = o.h, window = sel }))
        return hl.dispatch(hl.dsp.window.move({ x = o.x, y = o.y, window = sel }))
    end
    o = o or { w = w.size.x, h = w.size.y, x = w.at.x, y = w.at.y }
    o.max = zone == "max"
    snapped[w.address] = o
    local x, y, bw, bh = zone_box(zone, m)
    local bar = has_bar(w) and BAR or 0      -- 제목 표시줄은 창 위쪽에 따로 붙는다: 그만큼 내려서 상단 바 밑으로 안 들어가게
    hl.dispatch(hl.dsp.window.resize({ x = bw, y = bh - bar, window = sel }))
    hl.dispatch(hl.dsp.window.move({ x = x, y = y + bar, window = sel }))
end
-- 전체 화면 창(게임)도 같은 문제다: 누르면 클릭 순서로는 맨 위로 올라오는데 화면에는 그 위에 뜬 창(설정 등)이 계속 보여서,
-- 보이는 창을 눌러도 게임이 받는다. 전체 화면 창은 활성이 되거나 눌릴 때마다 맨 밑으로 내려 보이는 순서와 맞춘다.
local function sink_now()
    for _, w in ipairs(hl.get_windows()) do
        if (w.fullscreen or 0) ~= 0 then hl.dispatch(hl.dsp.window.alter_zorder({ mode = "bottom", window = "address:" .. w.address })) end
    end
end
-- 지금 한 번, 조금 뒤에 두 번 더: 누르는 순간 올라온 것(0.12초)과 한글 복구가 포커스를 돌린 뒤(1초)까지 잡는다.
-- 뗌 단축키만으로는 모자랐다: 실제 터치패드·마우스에서는 뗌 단축키가 안 불릴 때가 있어, 게임을 연달아 누르면 게임이 위에 남았다.
local sink_t = {}
local function sink()
    sink_now()
    for i, ms in ipairs({ 120, 1000 }) do
        if sink_t[i] then sink_t[i]:set_enabled(false) end
        local t; t = hl.timer(function() t:set_enabled(false); pcall(sink_now) end, { timeout = ms, type = "repeat" }); sink_t[i] = t
    end
end
hl.on("window.active", sink)
hl.on("window.open", sink)
-- 카톡 한글 자동 복구: 포커스가 kitty 를 스쳐 X 창으로 오면 Wayland 입력기가 켜진 채 남아 한글만 사라진다 (CLAUDE.md).
-- 창이 활성이 되고 0.3초 뒤(kitty 의 늦은 enable 이 도착한 뒤)에 보고 고친다. flock: 복구 중의 포커스 이동이 또 부르므로 겹치지 않게.
hl.on("window.active", function() hl.dispatch(hl.dsp.exec_cmd("sleep 0.3; flock -n /tmp/shittim-ime-heal.lock shittim-ime-heal --auto")) end)
for _, b in ipairs({ "mouse:272", "mouse:273" }) do   -- 이미 활성인 창을 또 눌러도 올라온다: 누를 때와 뗄 때 다시 내린다
    hl.bind(b, sink, { non_consuming = true, ignore_mods = true })
    hl.bind(b, sink, { release = true, non_consuming = true, ignore_mods = true })
end
local function half(right) return function() shittim_snap(right and "right" or "left") end end   -- Super + ←/→

-- 창을 끌다가 마우스가 화면 가장자리에 닿은 채로 놓으면 그 자리에 붙인다: 왼쪽/오른쪽 = 반쪽, 위 = 최대화, 모서리 = 1/4.
-- 끄는 동안에는 놓으면 갈 자리를 미리 보여 준다 (SnapPreview.qml).
-- 마우스 버튼 신호는 쓸 수 없다: 제목 표시줄(hyprbars)이 누름/뗌을 먼저 삼켜서 단축키까지 오지 않는다.
-- 그래서 50ms마다 창과 마우스 위치만 본다. 창이 마우스와 같이 움직이면 끄는 중이고,
-- 그 뒤 마우스만 움직이고 창은 그대로면 놓은 것이다 (놓고 마우스를 조금 움직이는 순간 붙는다).
local STICK = 6        -- general.snap 이 창을 다른 창·화면 끝에 붙들어 두는 거리: 그동안은 끄는 중에도 창이 안 움직인다
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
local drag, last = nil, nil     -- drag = 끄는 중인 창 {zone, cx, cy(창이 마지막으로 움직였을 때의 마우스)},  last = 직전 틱
local function drop(snap)
    local d = drag
    drag = nil
    if not (d and d.zone) then return end
    preview(nil)
    if snap then shittim_snap(d.zone) end
end
hl.timer(function()
    local w, c, l = hl.get_active_window(), hl.get_cursor_pos(), last
    last = (w and c and w.floating) and { a = w.address, x = w.at.x, y = w.at.y, w = w.size.x, h = w.size.y, cx = c.x, cy = c.y } or nil
    local n = last
    if not (n and l) or n.a ~= l.a then return drop(false) end
    local dx, dy, dcx, dcy = n.x - l.x, n.y - l.y, n.cx - l.cx, n.cy - l.cy
    local m = hl.get_monitor_at_cursor()
    local z = m and zone_at(c, m)
    -- 끄는 중: 창이 크기는 그대로인 채 마우스가 간 만큼 움직였다 (크기 조절·붙이기 애니메이션은 여기에 안 걸린다)
    if (dx ~= 0 or dy ~= 0) and n.w == l.w and n.h == l.h and (dcx ~= 0 or dcy ~= 0)
       and math.abs(dx - dcx) <= STICK * 4 and math.abs(dy - dcy) <= STICK * 4 then
        if not drag then
            drag = {}
            local o = snapped[n.a]                                -- 붙여 둔 창을 끌어냈다: 원래 크기로
            if o and (w.fullscreen or 0) == 0 then hl.dispatch(hl.dsp.window.resize({ x = o.w, y = o.h })) end
            snapped[n.a] = nil
        end
        drag.cx, drag.cy = n.cx, n.cy
    elseif not drag then return
    elseif math.abs(n.cx - drag.cx) > STICK * 2 + 2 or math.abs(n.cy - drag.cy) > STICK * 2 + 2 then
        return drop(true)                                         -- 마우스만 움직였다 = 놓았다
    elseif not z then return end                                  -- 놓은 뒤 가장자리를 벗어나는 중일 수 있다: 자리는 그대로
    if z ~= drag.zone then drag.zone = z; preview(z, m) end
end, { timeout = 50, type = "repeat" })
hl.bind(mod .. " + left",  half(false))
hl.bind(mod .. " + right", half(true))
hl.bind(mod .. " + up", function() shittim_snap("max") end)
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
-- Proton(Steam) 게임의 트레이 창은 class가 게임과 같아서(steam_app_<id>) 위 규칙에 안 걸린다: 크기(160x20)까지 보고 치운다
-- 새로 뜬 창의 제목 표시줄이 상단 바 밑·화면 위로 나가지 않게 내린다 (화면보다 큰 창을 가운데에 놓으면 위가 잘렸다).
-- 창이 뜰 때에만 본다: 사용자가 나중에 위로 올리는 것은 막지 않는다. 제목 없는 X11 창(메뉴·툴팁)은 건드리지 않는다.
local function keep_top(w)
    if not (w.mapped and w.floating) or (w.fullscreen or 0) ~= 0 or (w.xwayland and w.title == "") then return end
    local m = w.monitor
    if not m then return end
    -- 쓸 수 있는 자리(상단 바 ~ 독 사이)보다 크게 뜨는 창(VS Code 가 지난 크기 1920x1080 을 기억)은 최대화 자리로 맞춘다: 아래가 독 밑으로 잘렸다. 게임은 그대로.
    local bar = has_bar(w) and BAR or 0
    if not snapped[w.address] and not w.class:match("^steam_app_")
       and (w.size.x > m.width or w.size.y + bar > m.height - (m.reserved.top or 0) - (m.reserved.bottom or 0)) then
        return shittim_snap("max", w)
    end
    local top = m.y + (m.reserved.top or 0) + bar + 6
    if w.at.y < top then hl.dispatch(hl.dsp.window.move({ x = w.at.x, y = top, window = "address:" .. w.address })) end
end
hl.on("window.open", function(w)
    if w.title == "" and w.class:match("^steam_app_%d+$") and w.size.x == 160 and w.size.y == 20 then
        return hl.dispatch(hl.dsp.window.move({ workspace = "special:winetray", follow = false, window = "address:" .. w.address }))
    end
    keep_top(w)
    -- 뜬 직후에 스스로 크기를 키우는 앱이 있어서 0.4초 뒤에 한 번 더 본다 (그 사이 닫힌 창이면 pcall이 넘긴다)
    -- LibreOffice 는 1초쯤 뒤에야 지난 크기로 커져서 1.5초에도 한 번
    for _, ms in ipairs({ 400, 1500 }) do
        local again
        again = hl.timer(function() again:set_enabled(false); pcall(keep_top, hl.get_window("address:" .. w.address) or w) end, { timeout = ms, type = "repeat" })
    end
end)
-- 한/영 키는 Hyprland가 받아서 입력기를 직접 바꾼다. 앱을 거치면(특히 Wine 카카오톡: 글 칸에 입력기가 안 붙은 순간)
-- 키가 입력기까지 못 가서 씹혔다. 오른쪽 Alt도 위의 kb_options 때문에 Hangul 로 들어온다.
-- shittim-ime-heal: 카카오톡이 X 입력 포커스를 잃어 영어만 쳐질 때 한/영 키를 누르면 포커스를 되살린다
hl.bind("Hangul", hl.dsp.exec_cmd("fcitx5-remote -t; shittim-ime-heal"))
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
