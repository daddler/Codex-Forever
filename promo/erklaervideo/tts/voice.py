import numpy as np, sherpa_onnx, wave
from piper import PiperVoice, SynthesisConfig
VOICE = PiperVoice.load("vits-piper-de_DE-thorsten-high/de_DE-thorsten-high.onnx")
SR = VOICE.config.sample_rate
# Aussprache auf Lautschrift-Ebene (IPA), nach espeak: was espeak falsch
# betont oder dehnt, wird hier ersetzt.
IPA_FIX = [
    ("bˈoːt", "bˈɔt"),              # Bot  (nicht "Boot")
    ("fˈoːreːvɜ", "fəɾˈɛvɐ"),       # Forever
    ("nˈoːtiːts", "noːtˈiːts"),     # Notiz
    ("kvˈɛst", "kwˈɛst"),           # Quest
]
def ipa(text):
    out = []
    for sent in VOICE.phonemize(text):
        s = "".join(sent)
        for a, b in IPA_FIX:
            s = s.replace(a, b)
        out.append(s)
    return out
def say(text, length=1.0, noise=0.6, noise_w=0.8):
    cfg = SynthesisConfig(length_scale=length, noise_scale=noise, noise_w_scale=noise_w)
    parts = []
    for s in ipa(text):
        parts.append(VOICE.phoneme_ids_to_audio(VOICE.phonemes_to_ids(list(s)), cfg))
        parts.append(np.zeros(int(SR * 0.12), dtype=np.float32))
    return np.concatenate(parts).astype(np.float32)
_rec = None
def hear(x, sr=SR):
    global _rec
    if _rec is None:
        d = "sherpa-onnx-whisper-turbo"
        _rec = sherpa_onnx.OfflineRecognizer.from_whisper(encoder=f"{d}/turbo-encoder.int8.onnx", decoder=f"{d}/turbo-decoder.int8.onnx", tokens=f"{d}/turbo-tokens.txt", language="de", task="transcribe", num_threads=4)
    s = _rec.create_stream(); s.accept_waveform(sr, np.concatenate([np.zeros(sr//4), x, np.zeros(sr//2)]).astype(np.float32)); _rec.decode_stream(s); return s.result.text.strip()
if __name__ == "__main__":
    import sys
    for line in sys.argv[1:]:
        x = say(line); print(f"{len(x)/SR:5.2f}s | {line}\n      -> {hear(x)}")
