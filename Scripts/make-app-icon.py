#!/usr/bin/env python3
"""Regenerate the Rounds app icon — a boxing glove (boxing + strength / training).
Flat, bold, minimal so it reads at any size. Warm terracotta on near-black,
full-bleed 1024, no alpha (Apple masks the corners itself).

    pip install Pillow
    python3 Scripts/make-app-icon.py

Writes Rounds/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png.
"""
import os
from PIL import Image, ImageDraw

S = 4096  # supersample, downscaled to 1024
def p(v): return int(round(v / 1024 * S))

BG    = (23, 22, 20)     # #171614  app background
GLOVE = (226, 139, 74)   # #E28B4A  accent
SEAM  = (176, 99, 52)    # #B06334  stitching / form

img = Image.new("RGB", (S, S), BG)
d = ImageDraw.Draw(img)

def rrect(b, rad, fill):
    d.rounded_rectangle([p(b[0]), p(b[1]), p(b[2]), p(b[3])], radius=p(rad), fill=fill)
def ellipse(b, fill):
    d.ellipse([p(b[0]), p(b[1]), p(b[2]), p(b[3])], fill=fill)
def arc(b, a0, a1, fill, w):
    d.arc([p(b[0]), p(b[1]), p(b[2]), p(b[3])], a0, a1, fill=fill, width=p(w))

# thumb bump (left) — part of the glove, separated only by a seam
ellipse((150, 430, 430, 690), GLOVE)

# cuff / wrist
rrect((356, 706, 668, 902), 40, SEAM)
rrect((356, 648, 668, 812), 44, GLOVE)
d.line([p(356), p(742), p(668), p(742)], fill=SEAM, width=p(12))

# main mitt: rounded body + domed knuckles
rrect((246, 330, 778, 720), 170, GLOVE)
ellipse((246, 150, 778, 560), GLOVE)

# stitching
arc((300, 300, 560, 720), 120, 210, SEAM, 24)   # thumb seam
arc((300, 250, 724, 690), 202, 338, SEAM, 26)   # knuckle crease

out = os.path.join(os.path.dirname(__file__), os.pardir,
                   "Rounds/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")
img.resize((1024, 1024), Image.LANCZOS).save(os.path.abspath(out), "PNG")
print("wrote", os.path.abspath(out))
