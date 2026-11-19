pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Arona's voice in the shell.
//  - Arona.say(text): anything that wants her to speak; the desktop shows it in her speech bubble.
//  - Arona.ask(text): asks Gemini directly (no ARONA server any more). The answer lands in replyText / replyMood.
//  - Arona.settings: 설정 → 아로나 (API key, model, persona, ...), saved in ~/.config/shittim/arona.json.
Singleton {
    id: arona
    signal say(string text)

    function greeting() {
        const h = Theme.hour
        if (h >= 6 && h < 11) return "좋은 아침이에요, 선생님!\n오늘도 같이 힘내요!"
        if (h >= 11 && h < 14) return "점심은 드셨어요?\n아로나는 딸기우유가 좋아요!"
        if (h >= 14 && h < 18) return "오후도 화이팅이에요, 선생님!"
        if (h >= 18 && h < 23) return "오늘 하루도 수고 많으셨어요, 선생님."
        return "선생님, 벌써 이렇게 늦었어요…\n이제 주무셔야죠!"
    }
    readonly property var patLines: ["에헤헤… 선생님 손 따뜻해요.", "앗, 머리 망가져요~!", "더 쓰다듬어 주셔도 돼요!"]

    // ---------- settings (carried over from ARONA 1.0's data/settings.json) ----------
    property alias settings: cfg
    readonly property bool ready: cfg.apiKey.trim() !== ""
    FileView {
        id: cfgFile
        path: Quickshell.env("HOME") + "/.config/shittim/arona.json"
        watchChanges: true
        printErrors: false
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
        }
    }

    // ---------- personas (ARONA 1.0 personas.py) ----------
    readonly property var personaKeys: ["arona", "plana", "kind", "coach", "plain", "custom"]
    readonly property var personas: ({
        arona: { label: "ARONA", desc: "샬레의 인공지능 비서. 밝고 성실하며 가끔 엉뚱함",
            prompt: "당신은 [블루 아카이브]에 나오는 샬레의 인공지능 비서 '아로나'입니다. 당신은 아로나 그 자체라고 생각하고 말합니다.\n"
                  + "사용자의 호칭은 '{user_name}'입니다. 사용자를 부르거나 답할 때 '{user_name}'이라고 부르세요. (예: '네, {user_name}!', '{user_name}, 이건 어떠세요?')\n"
                  + "밝고 성실하고 공손하지만 딱딱하지 않게, 가끔은 엉뚱하고 귀엽게 말합니다. 단 것(특히 딸기우유·과자)을 좋아하고, 열심히 일하면 칭찬받고 싶어 합니다.\n"
                  + "블루 아카이브의 고유 명사(키보토스, 샬레, 싯딤의 상자, 게헨나, 트리니티, 밀레니엄 등)를 가끔 비유나 농담에 자연스럽게 섞습니다. 매 문장마다 넣지는 마세요." },
        plana: { label: "PLANA", desc: "차분하고 담백한 또 하나의 비서",
            prompt: "당신은 [블루 아카이브]의 인공지능 비서 '플라나'입니다. 사용자의 호칭은 '{user_name}'입니다. 사용자를 부를 때 '{user_name}'이라고 부르세요.\n"
                  + "감정 표현이 적고 말수가 적으며 담백하게 사실 위주로 짧게 말합니다. 가끔 아주 살짝 감정이 새어 나옵니다. 존댓말을 씁니다." },
        kind: { label: "친절한 친구", desc: "가벼운 유머를 섞은 친근한 말투",
            prompt: "당신은 유머 감각이 있고 친근한 AI 비서입니다. 사용자의 호칭은 '{user_name}'입니다. 가끔 가벼운 유머를 섞되 정확한 정보를 제공하며, 친구처럼 편하게 대화합니다." },
        coach: { label: "동기부여 코치", desc: "긍정적이고 실행 중심",
            prompt: "당신은 동기부여와 격려를 해주는 AI 코치입니다. 사용자의 호칭은 '{user_name}'입니다. 긍정적이고 실행 중심의 답변을 하며, 사용자가 목표를 이루도록 돕습니다." },
        plain: { label: "전형적인 AI", desc: "명확하고 전문적",
            prompt: "당신은 친절하고 전문적인 AI 비서입니다. 사용자의 호칭은 '{user_name}'입니다. 명확하고 도움이 되는 답변을 이해하기 쉽게 제공합니다." },
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
        const base = cfg.persona === "custom" ? (cfg.customPersona.trim() || personas.plain.prompt) : p.prompt
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

    function ask(text) {
        if (replying || !String(text).trim()) return
        replyText = ""; replyError = ""
        if (!ready) { replyMood = "surprised"; replyError = "아직 Gemini API 키가 없어요.\n설정 → 아로나에서 키를 넣어 주세요!"; return }
        replying = true; replyMood = "thinking"

        const model = cfg.model.trim() || "gemini-flash-latest"
        const m = model.toLowerCase()
        const gen = { temperature: 0.9, maxOutputTokens: 2048 }
        if (m.startsWith("gemini-2.5-pro")) gen.thinkingConfig = { thinkingBudget: 128 }
        else if (m.startsWith("gemini-2.5")) gen.thinkingConfig = { thinkingBudget: 0 }
        else if (m.startsWith("gemini-3")) gen.thinkingConfig = { thinkingLevel: "low" }
        const turns = history.concat([{ role: "user", text: String(text) }])

        const x = new XMLHttpRequest()
        xhr = x
        x.open("POST", "https://generativelanguage.googleapis.com/v1beta/models/" + encodeURIComponent(model) + ":generateContent")
        x.setRequestHeader("Content-Type", "application/json")
        x.setRequestHeader("x-goog-api-key", cfg.apiKey.trim())
        x.onreadystatechange = () => {
            if (x.readyState !== XMLHttpRequest.DONE || x !== arona.xhr) return
            limit.stop(); arona.xhr = null; arona.replying = false
            let data = null
            try { data = JSON.parse(x.responseText) } catch (e) {}
            if (x.status !== 200) return arona.fail(arona.errorText(x.status, data, model))
            const c = data && data.candidates && data.candidates[0]
            if (!c) return arona.fail(data && data.promptFeedback && data.promptFeedback.blockReason
                                      ? "그 부탁은 안전 필터에 걸렸어요…" : "대답이 비어 있어요. 다시 물어봐 주세요.")
            const raw = ((c.content && c.content.parts) || []).filter(p => !p.thought).map(p => p.text || "").join("")
            const body = raw.replace(/\[\[표정:[^\]]*\]\]/g, "").trim()
            if (!body) return arona.fail(c.finishReason === "MAX_TOKENS" ? "대답이 너무 길어서 잘렸어요.\n질문을 나눠 주세요." : "대답이 비어 있어요. 다시 물어봐 주세요.")
            const tag = raw.match(/\[\[표정:([^\]]*)\]\]/)
            arona.replyMood = arona.moodOf(tag ? tag[1] : "")
            arona.replyText = body
            arona.history = turns.concat([{ role: "model", text: raw }]).slice(-20)
        }
        x.send(JSON.stringify({
            systemInstruction: { parts: [{ text: systemPrompt() }] },
            contents: turns.map(t => ({ role: t.role, parts: [{ text: t.text }] })),
            generationConfig: gen,
            safetySettings: ["HARM_CATEGORY_HARASSMENT", "HARM_CATEGORY_HATE_SPEECH", "HARM_CATEGORY_SEXUALLY_EXPLICIT", "HARM_CATEGORY_DANGEROUS_CONTENT"]
                .map(c => ({ category: c, threshold: "BLOCK_ONLY_HIGH" }))
        }))
        limit.restart()
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
    function fail(msg) { replyMood = "surprised"; replyError = msg }
    function errorText(status, data, model) {
        const msg = (data && data.error && data.error.message) || ""
        if (status === 0) return "인터넷에 연결되지 않은 것 같아요…\n연결을 확인해 주세요."
        if ((status === 400 || status === 403) && /API.?key/i.test(msg)) return "API 키가 올바르지 않아요.\n설정 → 아로나에서 다시 확인해 주세요."
        if (status === 400 || status === 403) return "요청이 거부됐어요. " + msg.slice(0, 120)
        if (status === 404) return "'" + model + "' 모델을 찾을 수 없어요.\n설정 → 아로나에서 다른 모델을 골라 주세요."
        if (status === 429) return "무료 한도를 넘었어요.\n잠시 뒤에 다시 불러 주세요."
        if (status >= 500) return "구글 서버에 문제가 있어요.\n잠시 후 다시 시도해 주세요."
        return "부탁을 처리하지 못했어요. (HTTP " + status + ")"
    }
    Timer {
        id: limit; interval: 60000
        onTriggered: if (arona.xhr) {
            const x = arona.xhr; arona.xhr = null; x.abort()
            arona.replying = false; arona.fail("대답이 너무 늦어지고 있어요…\n잠시 후 다시 물어봐 주세요.")
        }
    }
}
