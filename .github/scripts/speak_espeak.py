import ctypes, sys, wave, struct
import espeakng_loader as e
lib = ctypes.CDLL(e.get_library_path())
rate = lib.espeak_Initialize(2, 0, e.get_data_path().encode(), 0)  # SYNCHRONOUS
buf = []
CB = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.POINTER(ctypes.c_short), ctypes.c_int, ctypes.c_void_p)
def cb(wav, n, ev):
    if wav and n > 0: buf.extend(wav[:n])
    return 0
cbf = CB(cb); lib.espeak_SetSynthCallback(cbf)
lib.espeak_SetVoiceByName(sys.argv[1].encode())
lib.espeak_SetParameter(1, int(sys.argv[3]), 0)  # rate wpm
lib.espeak_SetParameter(3, 55, 0)  # pitch
for word, out in zip(sys.argv[4::2], sys.argv[5::2]):
    buf.clear()
    t = word.encode()
    lib.espeak_Synth(t, len(t) + 1, 0, 0, 0, 0, None, None)
    with wave.open(out, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(rate); w.writeframes(struct.pack("<%dh" % len(buf), *buf))
    print(out, len(buf) / rate)
