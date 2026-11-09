#!/usr/bin/env python3
"""Karten der neuen Forever-Dungeons (Santiago Reyes - Atlas de Azeroth:
Forever) klein als BLP fuer WeintCodex.

Eingang: die 1024x1024-Bilder (BLP/PNG), wie der Zeichner sie herausgibt -
die Karte steht oben (rund 1024 x 683), darunter ist das Bild leer.
Ausgang: je Ebene zwei BLP2-Dateien mit DXT1 (4 Bit je Bildpunkt, ohne
Mipmaps - Oberflaechenbilder werden nie verkleinert gelesen):
    <name>_a.blp  Zeilen   0-511  (1024 x 512, 256 KB)
    <name>_b.blp  Zeilen 512-767  (1024 x 256, 128 KB)
zusammen 384 KB statt 1,4 MB. Der Inhalt bleibt unveraendert (Wasserzeichen
und Nennung des Zeichners inklusive) - nur verlustbehaftet gepackt.

    python3 -I .github/scripts/make_dungeonmaps.py <Quellordner> <Name>...

Braucht Pillow und numpy. Der Zeichner erlaubt Addons die Nutzung, solange
Wasserzeichen und Nennung bleiben und nichts verkauft wird (siehe
data/dungeonmaps_forever.lua).
"""
import os
import struct
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "media", "dungeonmaps")
PARTS = (("a", 0, 512), ("b", 512, 256))


def to565(c):
    c = np.clip(np.rint(c), 0, 255).astype(np.int32)
    return ((c[..., 0] >> 3) << 11) | ((c[..., 1] >> 2) << 5) | (c[..., 2] >> 3)


def from565(v):
    r = ((v >> 11) & 31) * 255 / 31
    g = ((v >> 5) & 63) * 255 / 63
    b = (v & 31) * 255 / 31
    return np.stack([r, g, b], -1)


def dxt1(rgb):
    """rgb: H x W x 3 (uint8), H und W durch 4 teilbar -> DXT1-Bytes."""
    h, w, _ = rgb.shape
    blocks = rgb.reshape(h // 4, 4, w // 4, 4, 3).transpose(0, 2, 1, 3, 4).reshape(-1, 16, 3).astype(np.float64)
    mean = blocks.mean(1, keepdims=True)
    cen = blocks - mean
    # Hauptachse je Block (Potenzverfahren), Endpunkte entlang der Achse.
    cov = np.einsum("nki,nkj->nij", cen, cen)
    axis = np.ones((len(blocks), 3))
    for _ in range(8):
        axis = np.einsum("nij,nj->ni", cov, axis)
        axis /= np.linalg.norm(axis, axis=1, keepdims=True) + 1e-9
    proj = np.einsum("nki,ni->nk", cen, axis)
    lo = mean[:, 0] + axis * proj.min(1, keepdims=True)
    hi = mean[:, 0] + axis * proj.max(1, keepdims=True)
    c0, c1 = to565(hi), to565(lo)
    swap = c0 < c1
    c0, c1 = np.where(swap, c1, c0), np.where(swap, c0, c1)
    same = c0 == c1
    p0, p1 = from565(c0), from565(c1)
    pal = np.stack([p0, p1, (2 * p0 + p1) / 3, (p0 + 2 * p1) / 3], 1)  # n x 4 x 3
    d = ((blocks[:, :, None, :] - pal[:, None, :, :]) ** 2).sum(-1)    # n x 16 x 4
    idx = d.argmin(-1)
    idx[same] = 0
    bits = (idx << (2 * np.arange(16))).sum(1).astype(np.uint32)
    out = np.zeros(len(blocks), dtype=[("c0", "<u2"), ("c1", "<u2"), ("i", "<u4")])
    out["c0"], out["c1"], out["i"] = c0, c1, bits
    return out.tobytes()


def blp2(rgb):
    h, w, _ = rgb.shape
    data = dxt1(rgb)
    head = b"BLP2" + struct.pack("<IBBBBII", 1, 2, 0, 0, 0, w, h)  # DXT, ohne Alpha, DXT1, ohne Mipmaps
    offsets = [0] * 16
    sizes = [0] * 16
    pre = len(head) + 64 + 64 + 256 * 4
    offsets[0], sizes[0] = pre, len(data)
    return head + struct.pack("<16I", *offsets) + struct.pack("<16I", *sizes) + b"\0" * 1024 + data


def main():
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    src = sys.argv[1]
    os.makedirs(OUT, exist_ok=True)
    for name in sys.argv[2:]:
        path = next(p for p in (os.path.join(src, name + e) for e in (".blp", ".png")) if os.path.exists(p))
        img = np.asarray(Image.open(path).convert("RGB"))
        if img.shape[:2] != (1024, 1024):
            raise SystemExit(f"{name}: erwartet 1024x1024, ist {img.shape[1]}x{img.shape[0]}")
        for suffix, top, height in PARTS:
            blob = blp2(np.ascontiguousarray(img[top:top + height]))
            with open(os.path.join(OUT, f"{name}_{suffix}.blp"), "wb") as f:
                f.write(blob)
        print(name, "fertig")


if __name__ == "__main__":
    main()
