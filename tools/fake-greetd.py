#!/usr/bin/env python3
"""로그인 화면(greeter.qml) 시험용 가짜 greetd. 루트도 재부팅도 필요 없다.
  python tools/fake-greetd.py /tmp/g.sock [비밀번호=test1234]  &   GREETD_SOCK=/tmp/g.sock quickshell -p ~/.config/quickshell/greeter.qml
받은 요청을 한 줄씩 찍는다(비밀번호는 맞음/틀림만). 비밀번호가 맞고 start_session 이 오면 세션은 시작하지 않고 끝난다.
greetd IPC: 4바이트 길이(기기 바이트 순서) + JSON."""
import sys, os, json, socket, struct
path, pw = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else "test1234")
if os.path.exists(path): os.unlink(path)
srv = socket.socket(socket.AF_UNIX); srv.bind(path); srv.listen(1)
def recv(c):
    h = c.recv(4, socket.MSG_WAITALL)
    return json.loads(c.recv(struct.unpack("=I", h)[0], socket.MSG_WAITALL)) if len(h) == 4 else None
def send(c, **m): b = json.dumps(m).encode(); c.sendall(struct.pack("=I", len(b)) + b)
while True:
    c, _ = srv.accept(); authed = False
    while (m := recv(c)) is not None:
        t = m.get("type")
        if t == "create_session":
            print("create_session", m.get("username"), flush=True)
            send(c, type="auth_message", auth_message_type="secret", auth_message="Password: ")
        elif t == "post_auth_message_response":
            authed = m.get("response") == pw; print("response", "맞음" if authed else "틀림", flush=True)
            if authed: send(c, type="success")
            else: send(c, type="error", error_type="auth_error", description="pam_authenticate: AUTH_ERR")
        elif t == "cancel_session": print("cancel_session", flush=True); authed = False; send(c, type="success")
        elif t == "start_session":
            print("start_session", m.get("cmd"), m.get("env"), "인증됨" if authed else "인증 안 됨!", flush=True)
            send(c, type="success"); sys.exit(0 if authed else 1)
        else: send(c, type="error", error_type="error", description="unknown request")
