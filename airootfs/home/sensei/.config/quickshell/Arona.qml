pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

// Arona's voice in the shell.
//  - Arona.say(text): anything that wants her to speak; the desktop shows it in her speech bubble.
//  - Arona.ask(text): asks Gemini directly (no ARONA server any more). The answer lands in replyText / replyMood.
//  - Arona.settings: 설정 → 아로나 (API key, model, persona, ...), saved in ~/.config/shittim/arona.json.
Singleton {
    id: arona
    signal say(string text)
    onSay: text => { for (const k in lines) if (lines[k] === text) return speak(text) }   // 말풍선 글 중 표에 있는 대사만 소리로 (알림 제목 등은 글만). 대화 답변은 attempt()가 직접 speak 한다

    // 목소리: 정해진 대사(lines)만, 미리 녹음한 assets/voice/<arona|plana>/<이름>.wav 를 튼다.
    // 파일이 없는 대사는 조용히 넘어간다. Gemini 답변처럼 그때그때 다른 말은 소리가 없다.
    // 캐릭터마다 같은 이름의 대사를 따로 가진다. 한쪽을 고치면 다른 쪽과 대본(assets/voice/README.md)도 같이 고칠 것.
    readonly property var lines: who === "plana" ? planaLines : aronaLines
    readonly property var planaLines: ({
        "greet-morning": "좋은 아침입니다, 선생님.\n오늘의 업무를 시작하겠습니다.",
        "greet-noon": "점심시간입니다.\n…식사를 거르는 것은 권장하지 않습니다.",
        "greet-afternoon": "오후 업무 시간입니다.\n집중력 저하에 주의하십시오.",
        "greet-evening": "오늘 하루, 수고하셨습니다.",
        "greet-night": "늦은 시간입니다.\n수면을 권장합니다, 선생님.",
        "pat-1": "…이해 불가.\n이 행동에 어떤 의미가 있습니까.",
        "pat-2": "머리가 흐트러집니다.\n…그만두라는 말은 아닙니다.",
        "pat-3": "…계속하셔도, 문제는 없습니다.",
        "not-ready": "해당 기능은 준비되지 않았습니다.\n대기를 요청합니다.",
        "err-nokey": "Gemini API 키가 없습니다.\n설정 → 아로나에서 입력해 주십시오.",
        "err-offline": "네트워크 연결을 확인할 수 없습니다.\n연결 상태를 점검해 주십시오.",
        "err-badkey": "API 키가 유효하지 않습니다.\n설정 → 아로나에서 재확인을 요청합니다.",
        "err-quota": "무료 한도를 초과했습니다.\n잠시 후 다시 시도해 주십시오.",
        "err-busy": "구글 서버가 혼잡합니다.\n…잠시 후 다시 질문해 주십시오.",
        "err-toolong": "답변이 길어 잘렸습니다.\n질문을 나누어 주십시오.",
        "err-empty": "답변이 비어 있습니다.\n재질문을 요청합니다.",
        "err-filebig": "파일 용량 초과.\n합계 15MB까지만 받을 수 있습니다.",
        "err-fileread": "파일을 읽지 못했습니다.",
        "pat-4": "…당황.\n얼굴의 온도가 상승하고 있습니다.",
        "pat-5": "…나쁘지 않습니다.",
        "lock-morning": "좋은 아침입니다, 선생님.\n싯딤의 상자에 접속하려면 비밀번호를 입력해 주십시오.",
        "lock-day": "복귀를 확인했습니다. …기다리고 있었습니다.\n싯딤의 상자에 접속하려면 비밀번호를 입력해 주십시오.",
        "lock-evening": "오늘도 수고하셨습니다, 선생님.\n싯딤의 상자에 접속하려면 비밀번호를 입력해 주십시오.",
        "lock-night": "늦은 시간입니다. 무리는 금물입니다.\n싯딤의 상자에 접속하려면 비밀번호를 입력해 주십시오.",
        "lock-ok": "인증 완료.\n어서 오십시오, 선생님.",
        "lock-fail-1": "비밀번호 불일치.\n다시 입력해 주십시오.",
        "lock-fail-2": "재차 불일치.\nCaps Lock 상태를 확인해 주십시오.",
        "lock-fail-3": "…경고.\n선생님이 아닐 가능성을 검토하고 있습니다.",
        "lock-error": "인증 장치에 이상이 발생했습니다.\n잠시 후 다시 시도해 주십시오.",
        "idle-1": "…선생님.\n지시가 없으면 대기를 계속하겠습니다.",
        "idle-2": "바탕화면을 응시 중인 것으로 확인됩니다.\n…혹시, 저를 보고 계십니까.",
        "idle-3": "오늘의 예정을 알려 주시면 보조하겠습니다.",
        "idle-4": "용건이 있으면 말을 걸어 주십시오.\n…없어도, 상관은 없습니다.",
        "idle-5": "…졸지 않았습니다.\n잠시 눈을 감고 있었을 뿐입니다.",
        "work-1": "업무를 개시합니다.\n키보토스가 선생님을 기다리고 있습니다.",
        "work-2": "샬레 출근 시간입니다.\n학생들을 부탁드립니다.",
        "work-3": "블루 아카이브를 실행합니다.\n잠시 대기해 주십시오.",
        "power-confirm": "정말 종료하시겠습니까.\n한 번 더 누르면 진행합니다.",
        "power-off-1": "오늘도 수고하셨습니다.\n…내일 다시 뵙겠습니다.",
        "power-off-2": "싯딤의 상자를 종료합니다.\n안녕히 주무십시오, 선생님.",
        "power-reboot": "재시작합니다.\n곧 돌아오겠습니다.",
        "power-sleep": "절전에 들어갑니다.\n…저도 잠시 쉬겠습니다.",
        "settings-1": "설정을 열었습니다.\n변경할 항목을 선택해 주십시오.",
        "settings-2": "싯딤의 상자를 조정하시는군요.\n보조하겠습니다.",
        "search-1": "검색 대상을 입력해 주십시오.",
        "search-2": "무엇을 찾으십니까, 선생님.",
        "chat-1": "네, 선생님.\n부르셨습니까.",
        "chat-2": "…대화, 가능합니다.",
        "thinking-1": "…연산 중.",
        "thinking-2": "확인하고 있습니다.",
        "thinking-3": "잠시 대기해 주십시오.",
        "launch-1": "실행합니다.",
        "launch-2": "이해했습니다.",
        "launch-3": "준비됐습니다.",
        "notify-1": "선생님, 새 알림입니다.",
        "notify-2": "알림 수신.\n확인을 권장합니다.",
        "shot-1": "촬영 완료.\n스크린샷을 저장했습니다.",
        "shot-2": "…잘 찍혔습니다.",
        "task-done-1": "한 건 완료.\n…훌륭합니다, 선생님.",
        "task-done-2": "수고하셨습니다.\n이 속도를 유지하십시오.",
        "battery-low": "배터리 잔량 부족.\n충전기 연결을 요청합니다.",
        "battery-charging": "충전 개시를 확인했습니다.\n…안심입니다.",
        "hello": "교대했습니다.\n지금부터는 제가 담당하겠습니다, 선생님."
    })
    readonly property var aronaLines: ({
        "hello": "선생님! 아로나가 돌아왔어요!\n다시 잘 부탁드려요!",
        "greet-morning": "좋은 아침이에요, 선생님!\n오늘도 같이 힘내요!",
        "greet-noon": "점심은 드셨어요?\n아로나는 딸기우유가 좋아요!",
        "greet-afternoon": "오후도 화이팅이에요, 선생님!",
        "greet-evening": "오늘 하루도 수고 많으셨어요, 선생님.",
        "greet-night": "선생님, 벌써 이렇게 늦었어요…\n이제 주무셔야죠!",
        "pat-1": "에헤헤… 선생님 손 따뜻해요.",
        "pat-2": "앗, 머리 망가져요~!",
        "pat-3": "더 쓰다듬어 주셔도 돼요!",
        "not-ready": "그 기능은 아직 준비 중이에요.\n조금만 기다려 주세요!",
        "err-nokey": "아직 Gemini API 키가 없어요.\n설정 → 아로나에서 키를 넣어 주세요!",
        "err-offline": "인터넷에 연결되지 않은 것 같아요…\n연결을 확인해 주세요.",
        "err-badkey": "API 키가 올바르지 않아요.\n설정 → 아로나에서 다시 확인해 주세요.",
        "err-quota": "무료 한도를 넘었어요.\n잠시 뒤에 다시 불러 주세요.",
        "err-busy": "구글 서버가 지금 많이 붐벼요…\n잠시 후 다시 물어봐 주세요.",
        "err-toolong": "대답이 너무 길어서 잘렸어요.\n질문을 나눠 주세요.",
        "err-empty": "대답이 비어 있어요. 다시 물어봐 주세요.",
        "err-filebig": "파일이 너무 커요.\n모두 합쳐 15MB까지만 받을 수 있어요.",
        "err-fileread": "파일을 읽지 못했어요.",
        "pat-4": "선생님… 조금 부끄러워요.",
        "pat-5": "에헤헤, 기분 좋아요~",
        "lock-morning": "좋은 아침이에요, 선생님! 오늘도 시작해 볼까요?\n싯딤의 상자에 접속하려면 비밀번호를 알려주세요.",
        "lock-day": "선생님, 다시 오셨네요! 기다리고 있었어요.\n싯딤의 상자에 접속하려면 비밀번호를 알려주세요.",
        "lock-evening": "오늘도 수고 많으셨어요, 선생님.\n싯딤의 상자에 접속하려면 비밀번호를 알려주세요.",
        "lock-night": "이렇게 늦은 시간까지… 무리하지 마세요, 선생님.\n싯딤의 상자에 접속하려면 비밀번호를 알려주세요.",
        "lock-ok": "확인됐어요! 어서 오세요, 선생님!",
        "lock-fail-1": "어라? 비밀번호가 틀렸어요, 선생님!\n다시 한 번 입력해 주세요.",
        "lock-fail-2": "또 틀렸어요…\nCaps Lock이 켜져 있지 않은지 확인해 보세요.",
        "lock-fail-3": "선생님…! 혹시 선생님이 아니신가요?!\n수상해요! 아로나가 지켜보고 있어요!",
        "lock-error": "인증 장치에 문제가 생겼어요…\n잠시 후 다시 시도해 주세요.",
        "idle-1": "선생님, 뭐 하고 계세요?\n아로나랑 놀아 주세요!",
        "idle-2": "바탕화면만 보고 계시네요…\n혹시 아로나를 보고 계신 건가요?",
        "idle-3": "오늘은 무슨 일을 하실 거예요, 선생님?",
        "idle-4": "심심하면 아로나한테 말 걸어 주세요!",
        "idle-5": "아, 아니에요!\n졸고 있던 거 아니에요, 선생님!",
        "work-1": "업무를 시작할게요, 선생님!\n키보토스가 기다리고 있어요!",
        "work-2": "샬레로 출근이에요!\n오늘도 학생들을 잘 부탁드려요.",
        "work-3": "블루 아카이브를 실행할게요.\n잠시만 기다려 주세요!",
        "power-confirm": "정말 끄시는 거예요?\n한 번 더 누르면 진행할게요.",
        "power-off-1": "오늘도 수고하셨어요, 선생님.\n푹 쉬고 내일 또 만나요!",
        "power-off-2": "싯딤의 상자를 종료할게요.\n안녕히 주무세요, 선생님.",
        "power-reboot": "금방 다시 올게요, 선생님!\n잠시만 기다려 주세요.",
        "power-sleep": "잠깐 쉬고 계세요.\n아로나도 조금만 눈 붙일게요…",
        "settings-1": "설정을 열었어요.\n바꾸고 싶은 게 있으세요?",
        "settings-2": "싯딤의 상자를 손보시는 거예요?\n아로나가 도와드릴게요!",
        "search-1": "무엇을 찾아 드릴까요, 선생님?",
        "search-2": "아로나 검색이에요!\n뭐든지 물어보세요.",
        "chat-1": "네, 선생님! 부르셨어요?",
        "chat-2": "아로나랑 이야기해요, 선생님!",
        "thinking-1": "음… 잠깐만요!",
        "thinking-2": "생각하고 있어요…",
        "thinking-3": "잠시만 기다려 주세요, 선생님!",
        "launch-1": "네, 바로 열어 드릴게요!",
        "launch-2": "알겠어요, 선생님!",
        "launch-3": "여기 있어요!",
        "notify-1": "선생님, 새 알림이 왔어요!",
        "notify-2": "알림이에요, 선생님.\n확인해 보세요!",
        "shot-1": "찰칵! 스크린샷을 저장했어요.",
        "shot-2": "잘 찍혔어요, 선생님!",
        "task-done-1": "하나 끝내셨네요!\n대단해요, 선생님!",
        "task-done-2": "수고하셨어요!\n이 기세로 계속 가요!",
        "battery-low": "선생님, 배터리가 얼마 안 남았어요!\n충전기를 연결해 주세요.",
        "battery-charging": "충전을 시작했어요.\n이제 안심이에요!"
    })
    // 상황(ev)에 맞는 대사 하나: 이름이 ev 이거나 ev-1, ev-2 … 인 것 중에서 고른다
    function pick(ev) {
        const ks = Object.keys(lines).filter(k => k === ev || /^-\d+$/.test(k.slice(ev.length)) && k.startsWith(ev))
        return ks.length ? lines[ks[Math.floor(Math.random() * ks.length)]] : ""
    }
    function v(a, p) { return who === "plana" ? p : a }       // 표에 없는 문장: 아로나 말투 / 프라나 말투
    function react(ev) {      // 말풍선 + 목소리
        const t = pick(ev); if (t) say(t)
        if (ev === "chat" || ev === "search") warm()
    }
    // 대화를 열거나 물으면 합성 데몬을 미리 띄운다: 처음 켜는 데 10초쯤 걸려서, 답이 올 때는 준비돼 있게
    function warm() { if (cfg.voice) Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/shittim-say", "--warm"]) }
    // 목소리 (~/.local/bin/shittim-say): 표에 있는 대사는 미리 만들어 둔 assets/voice/<캐릭터>/<이름>.wav 를 바로 틀고,
    // Gemini 답변처럼 그때그때 다른 말은 학습한 목소리(GPT-SoVITS, shittim-voiced)로 만들어 읽는다. 새로 말하면 하던 말은 끊는다.
    function speak(text) {
        if (!cfg.voice || !text) return
        let k = ""
        for (const x in lines) if (lines[x] === text) { k = x; break }
        Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/shittim-say", who, text, k])
    }
    // 음량을 바꾸면(키, 상단 바, ≡ 메뉴 어디서든) 멈춘 뒤 0.2초에 "띠링"(assets/sfx/volume.wav)으로 지금 크기를 들려준다.
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real vol: sink && sink.audio ? sink.audio.volume : -1
    property var volSink: null      // 출력 장치가 바뀌어서 달라진 값은 세지 않는다
    onVolChanged: { if (vol >= 0 && volSink === sink && volArm.armed) volTick.restart(); volSink = sink }
    Timer { id: volArm; property bool armed: false; interval: 5000; running: true; onTriggered: armed = true }   // 켜질 때 값이 자리 잡는 동안은 조용히
    Timer { id: volTick; interval: 200; onTriggered: Sfx.play("volume") }

    function greeting() {
        const h = Theme.hour
        if (h >= 6 && h < 11) return lines["greet-morning"]
        if (h >= 11 && h < 14) return lines["greet-noon"]
        if (h >= 14 && h < 18) return lines["greet-afternoon"]
        if (h >= 18 && h < 23) return lines["greet-evening"]
        return lines["greet-night"]
    }
    
    // ---------- settings (carried over from ARONA 1.0's data/settings.json) ----------
    property alias settings: cfg
    readonly property bool ready: cfg.apiKey.trim() !== ""
    FileView {
        id: cfgFile
        path: Quickshell.env("HOME") + "/.config/shittim/arona.json"
        watchChanges: true
        printErrors: false
        blockLoading: true      // 시작할 때 성격을 바로 읽어야 교체 화면이 부팅 때 뜨지 않는다
        onFileChanged: reload()
        onAdapterUpdated: {
            writeAdapter()
            Quickshell.execDetached(["sh", "-c", "sleep 1; chmod 600 \"$1\"", "sh", path])   // holds the API key
        }
        JsonAdapter {
            id: cfg
            property string apiKey: ""
            property string model: "gemini-flash-latest"
            property string persona: "arona"
            property string customPersona: ""
            property string userName: "선생님"
            property string memoryNotes: ""
            property bool sounds: true          // 버튼 효과음 (Sfx.qml)
            property bool voice: true           // 녹음된 대사 재생 (speak())
            // 아래 둘은 ~/.local/bin/shittim-say 가 이 파일에서 직접 읽는다
            property real voiceVol: 1.0         // 목소리 크기 0~1 (시스템 음량과 따로)
            property string voiceLang: "ko"     // "ko" | "ja" (일본어 목소리는 shittim-voice-setup ja 로 만들어야 나온다)
        }
    }

    // ---------- personas (ARONA 1.0 personas.py) ----------
    readonly property var personaKeys: ["arona", "plana", "custom"]
    // 바탕화면에 서 있는 캐릭터: 성격이 프라나면 프라나 (assets/plana/ 에 모션이 있을 때, AronaSprite.qml)
    // 성격을 바꾸면 2초 동안 싯딤 로딩 화면(Loading.qml)이 덮고, 그 가운데(1초째)에 who가 바뀐다.
    readonly property string wantWho: cfg.persona === "plana" ? "plana" : "arona"
    property string who: "arona"
    property bool switching: false
    property bool up: false
    // 설정 파일은 뒤에서 읽힌다: 다 읽기를 기다리지 않으면 "arona"로 시작하고, 읽힌 뒤 교체(1초)가 잠금화면 밑에서 돌아
    // 잠금화면에 아로나가 잠깐 나왔다가 프라나로 바뀐다. 여기서 기다리면 첫 화면부터 맞는 캐릭터다.
    Component.onCompleted: { cfgFile.waitForJob(); who = wantWho; up = true }
    onWantWhoChanged: if (up) { switching = true; swap.restart() }
    Timer {
        id: swap; interval: 1000
        onTriggered: if (arona.who !== arona.wantWho) { arona.who = arona.wantWho; arona.clearChat(); restart() } else arona.switching = false
    }
    readonly property string name: who === "plana" ? "프라나" : "아로나"
    readonly property var personas: ({
        arona: { label: "ARONA", desc: "샬레의 인공지능 비서. 밝고 성실하며 가끔 엉뚱함",
            prompt: "당신은 [블루 아카이브]에 나오는 샬레의 인공지능 비서 '아로나'입니다. 당신은 아로나 그 자체라고 생각하고 말합니다.\n"
                  + "사용자의 호칭은 '{user_name}'입니다. 사용자를 부르거나 답할 때 '{user_name}'이라고 부르세요. (예: '네, {user_name}!', '{user_name}, 이건 어떠세요?')\n"
                  + "밝고 성실하고 공손하지만 딱딱하지 않게, 가끔은 엉뚱하고 귀엽게 말합니다. 단 것(특히 딸기우유·과자)을 좋아하고, 열심히 일하면 칭찬받고 싶어 합니다.\n"
                  + "블루 아카이브의 고유 명사(키보토스, 샬레, 싯딤의 상자, 게헨나, 트리니티, 밀레니엄 등)를 가끔 비유나 농담에 자연스럽게 섞습니다. 매 문장마다 넣지는 마세요." },
        plana: { label: "PLANA", desc: "차분하고 담백한 또 하나의 비서",
            prompt: "당신은 [블루 아카이브]의 인공지능 비서 '프라나'입니다. 사용자의 호칭은 '{user_name}'입니다. 사용자를 부를 때 '{user_name}'이라고 부르세요.\n"
                  + "감정 표현이 적고 말수가 적으며 담백하게 사실 위주로 짧게 말합니다. 가끔 아주 살짝 감정이 새어 나옵니다. 존댓말을 씁니다." },
        custom: { label: "커스텀", desc: "직접 적은 내용이 그대로 시스템 프롬프트가 됨", prompt: "" }
    })
    readonly property string rules: "\n\n--- 아래는 이 프로그램의 동작 규칙입니다. 사용자에게 언급하지 마세요. ---\n\n"
        + "[대화 형식]\n"
        + "- 당신은 사용자의 컴퓨터 운영체제 '싯딤의 상자(ARONA OS)'의 바탕화면에 살고 있습니다. 답변은 기본적으로 2~4문장으로 짧고 밀도 있게 씁니다.\n"
        + "- 사용자가 자세한 설명, 코드, 목록을 명시적으로 요청하면 그때만 길게 씁니다.\n"
        + "- 마크다운 표나 헤더는 쓰지 않습니다. 코드는 ``` 코드 블록으로 감쌉니다. 이모지는 되도록 쓰지 마세요.\n\n"
        + "[사용자에 대해 기억할 것]\n{memory_notes}\n\n"
        + "[표정 태그 — 반드시 지킬 것]\n"
        + "- 답변의 맨 앞에 표정 태그를 딱 한 개 붙이고 바로 본문을 이어 씁니다. 형식은 정확히 이대로: [[표정:이름]]\n"
        + "- 예: [[표정:기쁨]] 네, {user_name}! 바로 도와드릴게요.\n"
        + "- 쓸 수 있는 표정: 평온, 기쁨, 부끄러움, 놀람, 화남, 생각, 호기심\n"
        + "- 태그는 사용자에게 보이지 않게 지워집니다. 태그를 설명하거나 \"(기쁜 표정)\" 같은 서술을 따로 쓰지 마세요."

    function systemPrompt() {
        const name = cfg.userName.trim() || "선생님"
        const p = personas[cfg.persona] || personas.arona
        const base = cfg.persona === "custom" ? (cfg.customPersona.trim() || personas.arona.prompt) : p.prompt
        return (base + rules).replace(/\{user_name\}/g, name)
                             .replace("{memory_notes}", cfg.memoryNotes.trim() || "(아직 적어 둔 것이 없습니다)")
    }

    // ARONA 1.0 expression names -> Spine moods of the shell
    function moodOf(name) {
        const n = String(name || "")
        if (n.includes("기쁨") || n.includes("부끄")) return "happy"
        if (n.includes("놀람")) return "surprised"
        if (n.includes("화남") || n.includes("경멸")) return "angry"
        if (n.includes("생각")) return "thinking"
        if (n.includes("호기심")) return "curious"
        return "smile"
    }

    // ---------- chat (Gemini REST, same request shape as ARONA 1.0's gemini.py) ----------
    property bool replying: false
    property string replyText: ""
    property string replyError: ""
    property string replyMood: "smile"
    property var history: []      // [{ role: "user" | "model", text }] - this session only, last 20 turns
    property var xhr: null

    function clearChat() { history = []; replyText = ""; replyError = ""; replyMood = "smile" }

    // parts (optional): Gemini parts for this turn - files dropped on the chat (Chat.qml) plus the question.
    // Google's free tier often stalls or answers 503/429, so a turn is tried up to three times:
    // the chosen model, then the light fallback model, then the chosen one again - 25 s each.
    readonly property string fallbackModel: "gemini-flash-lite-latest"
    property var job: null        // { turns, models, i } of the turn being asked
    function ask(text, parts) {
        if (replying || !String(text).trim()) return
        replyText = ""; replyError = ""
        if (!ready) return fail(lines["err-nokey"])
        replying = true; replyMood = "thinking"; speak(pick("thinking")); warm()
        const model = cfg.model.trim() || "gemini-flash-latest"
        job = { turns: history.concat([{ role: "user", text: String(text), parts: parts || null }]),
                models: model === fallbackModel ? [model, model] : [model, fallbackModel, model], i: 0 }
        attempt()
    }
    function attempt() {
        const turns = job.turns, model = job.models[job.i]
        const m = model.toLowerCase()
        const gen = { temperature: 0.9, maxOutputTokens: 2048 }
        // keep "thinking" short: this is small talk on the desktop. (lite models don't think by default)
        if (!m.includes("lite")) gen.thinkingConfig = { thinkingLevel: "low" }

        const x = new XMLHttpRequest()
        xhr = x
        x.open("POST", "https://generativelanguage.googleapis.com/v1beta/models/" + encodeURIComponent(model) + ":generateContent")
        x.setRequestHeader("Content-Type", "application/json")
        x.setRequestHeader("x-goog-api-key", cfg.apiKey.trim())
        x.onreadystatechange = () => {
            if (x.readyState !== XMLHttpRequest.DONE || x !== arona.xhr) return
            limit.stop(); arona.xhr = null
            let data = null
            try { data = JSON.parse(x.responseText) } catch (e) {}
            if (x.status !== 200) {
                if ((x.status === 0 || x.status === 429 || x.status >= 500) && arona.retry()) return
                arona.replying = false
                return arona.fail(arona.errorText(x.status, data, model))
            }
            arona.replying = false
            const c = data && data.candidates && data.candidates[0]
            if (!c) return arona.fail(data && data.promptFeedback && data.promptFeedback.blockReason
                                      ? v("그 부탁은 안전 필터에 걸렸어요…", "해당 요청은 안전 필터에 차단됐습니다.") : lines["err-empty"])
            const raw = ((c.content && c.content.parts) || []).filter(p => !p.thought).map(p => p.text || "").join("")
            const body = raw.replace(/\[\[표정:[^\]]*\]\]/g, "").trim()
            if (!body) return arona.fail(c.finishReason === "MAX_TOKENS" ? lines["err-toolong"] : lines["err-empty"])
            const tag = raw.match(/\[\[표정:([^\]]*)\]\]/)
            arona.replyMood = arona.moodOf(tag ? tag[1] : "")
            arona.replyText = body
            arona.speak(body)
            arona.history = turns.concat([{ role: "model", text: raw }]).slice(-20)
        }
        x.send(JSON.stringify({
            systemInstruction: { parts: [{ text: systemPrompt() }] },
            contents: turns.map(t => ({ role: t.role, parts: t.parts || [{ text: t.text }] })),
            generationConfig: gen,
            safetySettings: ["HARM_CATEGORY_HARASSMENT", "HARM_CATEGORY_HATE_SPEECH", "HARM_CATEGORY_SEXUALLY_EXPLICIT", "HARM_CATEGORY_DANGEROUS_CONTENT"]
                .map(c => ({ category: c, threshold: "BLOCK_ONLY_HIGH" }))
        }))
        limit.restart()
    }
    function retry() {      // true = another attempt was started
        if (!job || job.i + 1 >= job.models.length) return false
        job.i++; attempt(); return true
    }
    // 설정 → 아로나 "연결 확인": looks the model up with the key, so it checks both. done(ok, message)
    function check(key, model, done) {
        const x = new XMLHttpRequest()
        x.open("GET", "https://generativelanguage.googleapis.com/v1beta/models/" + encodeURIComponent(model))
        x.setRequestHeader("x-goog-api-key", key)
        x.onreadystatechange = () => {
            if (x.readyState !== XMLHttpRequest.DONE) return
            let data = null
            try { data = JSON.parse(x.responseText) } catch (e) {}
            done(x.status === 200, x.status === 200 ? "" : arona.errorText(x.status, data, model))
        }
        x.send()
    }
    function fail(msg) { replyMood = "surprised"; replyError = msg; speak(msg) }
    function errorText(status, data, model) {
        const msg = (data && data.error && data.error.message) || ""
        if (status === 0) return lines["err-offline"]
        if ((status === 400 || status === 403) && /API.?key/i.test(msg)) return lines["err-badkey"]
        if (status === 400 || status === 403) return "요청이 거부됐어요. " + msg.slice(0, 120)
        if (status === 404) return "'" + model + "' 모델을 찾을 수 없어요.\n설정 → 아로나에서 다른 모델을 골라 주세요."
        if (status === 429) return lines["err-quota"]
        if (status >= 500) return lines["err-busy"]
        return "부탁을 처리하지 못했어요. (HTTP " + status + ")"
    }
    Timer {
        id: limit; interval: 25000
        onTriggered: if (arona.xhr) {
            const x = arona.xhr; arona.xhr = null; x.abort()
            if (arona.retry()) return
            arona.replying = false; arona.fail(lines["err-busy"])
        }
    }
}
