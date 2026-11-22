-- 로그인 화면용 Hyprland (greetd → /usr/local/bin/shittim-greeter 가 greeter 사용자로 띄운다).
-- 단축키도 다른 프로그램도 없다: 로그인 화면(greeter.qml) 하나만 띄운다. 아직 아무도 로그인하지 않은 상태다.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QS_DISABLE_CRASH_HANDLER", "1")
hl.config({
    input = { kb_layout = "us" },
    cursor = { no_hardware_cursors = true },     -- 사용자 세션(~/.config/hypr/hyprland.lua)과 같게
    animations = { enabled = false },
    misc = { force_default_wallpaper = 0, disable_hyprland_logo = true, disable_splash_rendering = true },
})
hl.on("hyprland.start", function()
    -- 로그인 화면이 끝나면(로그인 성공, 또는 오류로 죽음) 이 Hyprland 도 끝낸다:
    -- greetd 가 sensei 의 세션을 시작하거나, 로그인 화면을 다시 띄운다.
    hl.exec_cmd("sh -c 'quickshell -p /usr/share/shittim-greeter/greeter.qml; hyprctl dispatch \"hl.dsp.exit()\"'")
end)
