#!/usr/bin/env python3
"""아로나/프라나 목소리 학습 (GPT-SoVITS v2ProPlus, CPU).   voice-train.py <arona|plana> [SoVITS 에포크=8] [GPT 에포크=15]
입력: ~/.local/share/shittim-voice/data/<이름>.list  ("wav 경로|이름|ko|대사" 한 줄씩)
결과: GPT-SoVITS/SoVITS_weights_v2ProPlus/<이름>_e*.pth, GPT_weights_v2ProPlus/<이름>-e*.ckpt
webui.py 의 1A~1C 준비 단계와 학습 단계가 하는 일을 그대로 줄로 옮긴 것이다."""
import os, sys, json, subprocess, pathlib, yaml
name, e2, e1 = sys.argv[1], int(sys.argv[2] if len(sys.argv) > 2 else 8), int(sys.argv[3] if len(sys.argv) > 3 else 15)
root = pathlib.Path.home() / ".local/share/shittim-voice"
os.chdir(root / "GPT-SoVITS")
py, V, P = str(root / "venv/bin/python"), "v2ProPlus", "GPT_SoVITS/pretrained_models"
exp = f"logs/{name}"; os.makedirs(exp, exist_ok=True); os.makedirs("TEMP", exist_ok=True)
env = dict(os.environ, version=V, is_half="False", inp_text=str(root / f"data/{name}.list"), inp_wav_dir="", exp_name=name, opt_dir=exp,
           i_part="0", all_parts="1", _CUDA_VISIBLE_DEVICES="", hz="25hz", PYTHONPATH=f"{os.getcwd()}:{os.getcwd()}/GPT_SoVITS",
           bert_pretrained_dir=f"{P}/chinese-roberta-wwm-ext-large", cnhubert_base_dir=f"{P}/chinese-hubert-base",
           sv_path=f"{P}/sv/pretrained_eres2netv2w24s4ep4.ckpt", pretrained_s2G=f"{P}/v2Pro/s2Gv2ProPlus.pth",
           s2config_path=f"GPT_SoVITS/configs/s2{V}.json")
import atexit; busy = root / "busy"; busy.touch(); atexit.register(lambda: busy.unlink(missing_ok=True))   # 학습 중에는 shittim-say 가 합성 데몬을 안 띄운다
subprocess.run(["pkill", "-f", "bin/[s]hittim-voiced"])
def run(*a): print("==", *a, flush=True); subprocess.run([py, "-s", *a], env=env, check=True)
def merge(part, whole, head=""):
    if os.path.exists(part): pathlib.Path(whole).write_text(head + pathlib.Path(part).read_text()); os.remove(part)
if not os.path.exists(f"{exp}/6-name2semantic.tsv"):
    run("GPT_SoVITS/prepare_datasets/1-get-text.py"); merge(f"{exp}/2-name2text-0.txt", f"{exp}/2-name2text.txt")
    run("GPT_SoVITS/prepare_datasets/2-get-hubert-wav32k.py")
    run("GPT_SoVITS/prepare_datasets/2-get-sv.py")
    run("GPT_SoVITS/prepare_datasets/3-get-semantic.py"); merge(f"{exp}/6-name2semantic-0.tsv", f"{exp}/6-name2semantic.tsv", "item_name\tsemantic_audio\n")
# 배치 2: 램 14GB 에서 4 는 7GB 넘게 써서 OOM 으로 죽었다
if e2:
    c = json.load(open(env["s2config_path"]))
    c["train"].update(fp16_run=False, batch_size=2, epochs=e2, text_low_lr_rate=0.4, pretrained_s2G=env["pretrained_s2G"],
                      pretrained_s2D=f"{P}/v2Pro/s2Dv2ProPlus.pth", if_save_latest=True, if_save_every_weights=True,
                      save_every_epoch=4, gpu_numbers="0", grad_ckpt=False, lora_rank=32)
    c["model"]["version"] = c["version"] = V; c["data"]["exp_dir"] = c["s2_ckpt_dir"] = exp
    c["save_weight_dir"] = f"SoVITS_weights_{V}"; c["name"] = name
    os.makedirs(f"{exp}/logs_s2_{V}", exist_ok=True); os.makedirs(c["save_weight_dir"], exist_ok=True)
    json.dump(c, open(f"TEMP/s2-{name}.json", "w")); run("GPT_SoVITS/s2_train.py", "--config", f"TEMP/s2-{name}.json")
if e1:
    c = yaml.safe_load(open("GPT_SoVITS/configs/s1longer-v2.yaml"))
    c["train"].update(precision="32", batch_size=2, epochs=e1, save_every_n_epoch=5, if_save_every_weights=True, if_save_latest=True,
                      if_dpo=False, half_weights_save_dir=f"GPT_weights_{V}", exp_name=name)
    c.update(pretrained_s1=f"{P}/s1v3.ckpt", train_semantic_path=f"{exp}/6-name2semantic.tsv", train_phoneme_path=f"{exp}/2-name2text.txt",
             output_dir=f"{exp}/logs_s1_{V}")
    os.makedirs(c["output_dir"], exist_ok=True); os.makedirs(f"GPT_weights_{V}", exist_ok=True)
    yaml.dump(c, open(f"TEMP/s1-{name}.yaml", "w")); run("GPT_SoVITS/s1_train.py", "--config_file", f"TEMP/s1-{name}.yaml")
print("TRAIN-DONE", name)
