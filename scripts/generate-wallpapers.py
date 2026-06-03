#!/usr/bin/env python3
"""Generate 5 minimal Catppuccin Mocha themed wallpapers at 1920x1080."""
from PIL import Image, ImageDraw, ImageFilter
import math, os, random

W, H = 1920, 1080
HERE = os.path.dirname(os.path.abspath(__file__))
DEST = os.path.join(HERE, "wallpapers")
os.makedirs(DEST, exist_ok=True)

print(f"Generating wallpapers in {DEST} ...")

# ── 1. Dark gradient with subtle wave noise ──
img = Image.new("RGB", (W, H))
for y in range(H):
    t = y / H
    r, g, b = int(24*(1-t)+30*t), int(24*(1-t)+30*t), int(37*(1-t)+46*t)
    for x in range(W):
        drift = (math.sin(x/80 + t*4) * 3 + math.sin(y/60 + x/200) * 2)
        img.putpixel((x,y), (
            max(0, min(255, int(r+drift))),
            max(0, min(255, int(g+drift*0.7))),
            max(0, min(255, int(b+drift*0.9)))
        ))
img.save(os.path.join(DEST, "01-dark-gradient.png"))
print("  1. dark gradient")

# ── 2. Soft centered light / glow ──
img = Image.new("RGB", (W, H), (24, 24, 37))
draw = ImageDraw.Draw(img)
for i in range(60, 0, -1):
    r, g, b = int(89-i*0.7), int(180-i*2.0), int(250-i*3.2)
    a = int(15 * (i/60)**0.5)
    draw.ellipse([W/2-i*28, H/2-i*18, W/2+i*28, H/2+i*18], fill=(r,g,b))
img = img.filter(ImageFilter.GaussianBlur(40))
img.save(os.path.join(DEST, "02-soft-glow.png"))
print("  2. soft glow")

# ── 3. Minimal geometric landscape (horizon line) ──
img = Image.new("RGB", (W, H), (30, 30, 46))
draw = ImageDraw.Draw(img)
cx, cy, cr = W*0.65, H*0.45, 180
for i, col in enumerate([(180,190,254),(137,180,250),(108,112,196)]):
    r = cr - i*50
    draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=col)
img = img.filter(ImageFilter.GaussianBlur(8))
draw = ImageDraw.Draw(img)
draw.rectangle([0, H*0.62, W, H], fill=(17,17,27))
for y in range(int(H*0.62), H):
    t = (y - H*0.62) / (H*0.38)
    c = int(17*(1-t) + 24*t)
    draw.line([(0,y), (W,y)], fill=(c, c, int(c*1.13)))
for mx, mh, mw in [(W*0.2, 180, 400), (W*0.5, 250, 500), (W*0.8, 140, 350)]:
    draw.polygon([(mx-mw, H*0.62), (mx, H*0.62-mh), (mx+mw, H*0.62)], fill=(19,19,29))
img.save(os.path.join(DEST, "03-geometric-landscape.png"))
print("  3. geometric landscape")

# ── 4. Pure color with subtle film grain ──
img = Image.new("RGB", (W, H), (30, 30, 46))
random.seed(42)
for y in range(H):
    for x in range(0, W, 3):
        n = random.randint(-3, 3)
        img.putpixel((x,y), (30+n, 30+n, 46+n))
img.save(os.path.join(DEST, "04-grain.png"))
print("  4. grain texture")

# ── 5. Diagonal wave gradient ──
img = Image.new("RGB", (W, H))
for y in range(H):
    for x in range(W):
        t = (x/W + y/H) * 0.5
        wave = math.sin(x/300 + y/200) * 0.08
        t2 = max(0, min(1, t + wave))
        img.putpixel((x,y), (
            int(30*(1-t2) + 24*t2),
            int(30*(1-t2) + 24*t2),
            int(46*(1-t2) + 37*t2)
        ))
img.save(os.path.join(DEST, "05-wave.png"))
print("  5. diagonal wave")

print("\nDone — 5 wallpapers generated.")
for f in sorted(os.listdir(DEST)):
    if f.endswith('.png'):
        sz = os.path.getsize(os.path.join(DEST, f)) / 1024
        print(f"  {f}  ({sz:.0f} KB)")
