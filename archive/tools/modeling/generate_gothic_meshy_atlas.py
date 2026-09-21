"""Generate a 512x512 painted diffuse texture atlas for Gothic 1 & 2 Walter.

Aesthetic:
- Authentic Gothic 1 & 2 / Piranha Bytes low-poly style.
- Baked chiaroscuro lighting, painted ambient occlusion, fabric weaves, and leather scuffs.
- Includes weathered detective face with stubble, peaked police cap with visor & gold emblem,
  midnight navy police uniform with brass buttons and leather holster,
  civilian herringbone tweed coat with horn buttons,
  charcoal trousers, and scuffed laced leather boots.
"""

from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
MODEL_DIR = ROOT / "assets" / "models"
MODEL_DIR.mkdir(parents=True, exist_ok=True)
ATLAS_PATH = MODEL_DIR / "walter_phase1_atlas.png"


def create_atlas() -> Image.Image:
    # 512x512 RGBA atlas
    img = Image.new("RGBA", (512, 512), (32, 30, 28, 255))
    draw = ImageDraw.Draw(img)

    def v_gradient(box, c_top, c_bot):
        x0, y0, x1, y1 = box
        h = max(1, y1 - y0)
        for y in range(y0, y1):
            t = (y - y0) / h
            r = int(c_top[0] * (1 - t) + c_bot[0] * t)
            g = int(c_top[1] * (1 - t) + c_bot[1] * t)
            b = int(c_top[2] * (1 - t) + c_bot[2] * t)
            draw.line([(x0, y), (x1, y)], fill=(r, g, b, 255))

    # =========================================================================
    # QUADRANT 1: TOP-LEFT [0..256, 0..256] -> HEAD, FACE & VISOR CAP
    # =========================================================================
    # Face skin base
    v_gradient((0, 0, 256, 256), (155, 125, 105), (110, 85, 70))

    # Sides of head & hair (ears/neck)
    for hx_box in [(0, 60, 50, 256), (206, 60, 256, 256)]:
        v_gradient(hx_box, (55, 42, 35), (28, 22, 18))
        # Hair texture strands
        for hy in range(60, 256, 4):
            draw.line([(hx_box[0], hy), (hx_box[2], hy)], fill=(20, 16, 14, 120), width=1)

    # Center face features (x: 50..206)
    # Forehead tone under cap
    v_gradient((50, 60, 206, 110), (75, 58, 48), (145, 116, 96))

    # Deep shaded eye sockets
    for ex in (88, 168):
        # Heavy dark detective brow
        draw.polygon([(ex - 26, 112), (ex + 22, 108), (ex + 18, 118), (ex - 24, 120)], fill=(42, 34, 28, 255))
        # Socket hollow
        draw.ellipse([ex - 20, 118, ex + 18, 140], fill=(85, 64, 52, 255))
        # Eye white
        draw.ellipse([ex - 15, 122, ex + 13, 134], fill=(195, 192, 185, 255))
        # Iris (steely grey-blue)
        draw.ellipse([ex - 8, 122, ex + 6, 134], fill=(65, 88, 102, 255))
        # Pupil & highlight
        draw.ellipse([ex - 4, 125, ex + 2, 131], fill=(16, 20, 24, 255))
        draw.point((ex + 1, 126), fill=(245, 245, 245, 255))
        # Under-eye fatigue hollow
        draw.arc([ex - 18, 128, ex + 16, 144], 0, 180, fill=(62, 45, 36, 255), width=2)

    # Chiseled nose ridge & nostrils (center x=128)
    draw.polygon([(122, 114), (134, 114), (137, 162), (119, 162)], fill=(155, 122, 102, 255))
    draw.line([(120, 116), (120, 160)], fill=(80, 58, 46, 255), width=2)
    draw.line([(136, 116), (136, 160)], fill=(185, 150, 130, 255), width=2)
    draw.ellipse([117, 154, 139, 166], fill=(140, 106, 88, 255))
    draw.ellipse([119, 159, 125, 164], fill=(38, 28, 22, 255))
    draw.ellipse([131, 159, 137, 164], fill=(38, 28, 22, 255))

    # Heavy detective 5 o'clock shadow across jaw & upper lip
    for sy in range(162, 245):
        for sx in range(50, 206):
            dx = abs(sx - 128)
            dy = sy - 162
            if dx < (72 - dy * 0.22):
                if (sx * 19 + sy * 37) % 6 < 2:
                    draw.point((sx, sy), fill=(48, 40, 34, 210))

    # Mouth line
    draw.line([(108, 182), (148, 182)], fill=(42, 28, 24, 255), width=3)
    draw.line([(110, 179), (146, 179)], fill=(120, 75, 65, 255), width=2)
    draw.line([(114, 186), (142, 186)], fill=(138, 88, 76, 255), width=2)
    draw.arc([114, 192, 142, 202], 0, 180, fill=(62, 46, 36, 255), width=2)  # chin cleft

    # Visor Cap (top band: y=0..62)
    # Dark navy cap crown
    v_gradient((0, 0, 256, 44), (24, 32, 48), (14, 18, 28))
    draw.line([(0, 44), (256, 44)], fill=(10, 12, 18, 255), width=2)
    # Gold cap braid / cord
    for bx in range(8, 248, 5):
        draw.ellipse([bx, 46, bx + 4, 53], fill=(210, 170, 60, 255), outline=(130, 95, 25, 255))
    # Gold officer cap emblem
    draw.polygon([(128, 10), (138, 20), (134, 36), (122, 36), (118, 20)], fill=(225, 188, 70, 255), outline=(140, 105, 30, 255))
    draw.polygon([(128, 16), (134, 22), (131, 32), (125, 32), (122, 22)], fill=(245, 215, 100, 255))
    # Glossy black visor edge
    v_gradient((0, 54, 256, 62), (48, 48, 52), (12, 12, 14))
    draw.line([(0, 55), (256, 55)], fill=(130, 130, 140, 255), width=1)

    # =========================================================================
    # QUADRANT 2: TOP-RIGHT [256..512, 0..256] -> POLICE UNIFORM COAT
    # =========================================================================
    # 2.1 Left Strip [256..315, 0..256]: DEDICATED SLEEVE WOOL (No buttons!)
    v_gradient((256, 0, 315, 256), (26, 36, 50), (16, 22, 32))
    for py in range(0, 256, 4):
        draw.line([(256, py), (315, py)], fill=(20, 28, 40, 80), width=1)
    draw.line([(315, 0), (315, 256)], fill=(12, 16, 24, 255), width=2)

    # 2.2 Torso Area [316..512, 0..256]: Front Chest with Double-Breasted Buttons & Belt
    v_gradient((316, 0, 512, 256), (28, 38, 54), (16, 22, 34))
    for py in range(0, 256, 4):
        draw.line([(316, py), (512, py)], fill=(22, 30, 44, 80), width=1)

    # High stand collar
    draw.rectangle((325, 4, 503, 34), fill=(18, 24, 36, 255), outline=(10, 14, 20, 255), width=2)
    # Gold collar pins
    for cpx in (350, 478):
        draw.polygon([(cpx, 12), (cpx + 10, 18), (cpx + 7, 26), (cpx - 7, 26), (cpx - 10, 18)], fill=(215, 175, 55, 255))

    # Double-breasted brass buttons (two columns: x=380, x=448; y=55, 95, 135, 175)
    for by in (55, 95, 135, 175):
        for bx in (380, 448):
            draw.ellipse([bx - 8, by - 8, bx + 8, by + 8], fill=(120, 90, 22, 255))
            draw.ellipse([bx - 7, by - 7, bx + 6, by + 6], fill=(215, 175, 55, 255))
            draw.ellipse([bx - 4, by - 4, bx - 1, by - 1], fill=(255, 240, 160, 255))

    # Breast pocket flaps (y=65..95)
    for pkx in (335, 458):
        draw.polygon([(pkx, 65), (pkx + 40, 65), (pkx + 40, 84), (pkx + 20, 92), (pkx, 84)], fill=(16, 22, 34, 255), outline=(10, 14, 20, 255), width=2)
        draw.ellipse([pkx + 16, 72, pkx + 24, 80], fill=(200, 160, 50, 255), outline=(110, 80, 20, 255))

    # Police Duty Belt & Brass Buckle (y=205..256)
    v_gradient((316, 205, 512, 238), (35, 28, 22), (18, 14, 10))
    draw.line([(316, 205), (512, 205)], fill=(12, 10, 8, 255), width=2)
    draw.line([(316, 238), (512, 238)], fill=(12, 10, 8, 255), width=2)
    # Brass Buckle (center: x=414)
    draw.rectangle([398, 208, 430, 235], fill=(215, 175, 55, 255), outline=(125, 95, 25, 255), width=2)
    draw.rectangle([404, 214, 424, 229], fill=(22, 16, 12, 255))
    draw.line([(414, 208), (414, 235)], fill=(215, 175, 55, 255), width=3)
    # Holster & pouch
    draw.rectangle([470, 212, 506, 252], fill=(24, 18, 14, 255), outline=(10, 8, 6, 255), width=2)

    # =========================================================================
    # QUADRANT 3: BOTTOM-RIGHT [256..512, 256..512] -> PLAIN TWEED COAT
    # =========================================================================
    # 3.1 Left Strip [256..315, 256..512]: DEDICATED SLEEVE TWEED (No buttons!)
    v_gradient((256, 256, 315, 512), (98, 84, 70), (65, 54, 44))
    for hx in range(256, 315, 10):
        for hy in range(256, 512, 14):
            draw.line([(hx, hy), (hx + 5, hy + 7)], fill=(120, 105, 90, 70), width=1)
            draw.line([(hx + 5, hy + 7), (hx, hy + 14)], fill=(45, 36, 28, 70), width=1)
    draw.line([(315, 256), (315, 512)], fill=(35, 28, 22, 255), width=2)

    # 3.2 Torso Area [316..512, 256..512]: Front Chest with Lapels and Horn Buttons
    v_gradient((316, 256, 512, 512), (102, 88, 74), (68, 56, 46))
    for hx in range(316, 512, 10):
        for hy in range(256, 512, 14):
            draw.line([(hx, hy), (hx + 5, hy + 7)], fill=(125, 110, 95, 75), width=1)
            draw.line([(hx + 5, hy + 7), (hx, hy + 14)], fill=(48, 38, 30, 75), width=1)

    # Notched tweed lapels
    for lx, l_dir in ((340, 1), (488, -1)):
        draw.polygon([(lx, 260), (lx + l_dir * 42, 285), (lx + l_dir * 32, 360), (lx, 340)], fill=(86, 72, 60, 255), outline=(40, 32, 26, 255), width=2)

    # Horn buttons down center (x=414; y=295, 345, 395, 445)
    for by in (295, 345, 395, 445):
        draw.ellipse([406, by - 8, 422, by + 8], fill=(26, 20, 16, 255))
        draw.ellipse([407, by - 7, 421, by + 7], fill=(75, 55, 40, 255))
        draw.ellipse([410, by - 4, 418, by + 4], fill=(105, 78, 55, 255))

    # Pockets
    for px in (335, 460):
        draw.polygon([(px, 415), (px + 45, 420), (px + 43, 438), (px - 2, 433)], fill=(72, 60, 48, 255), outline=(35, 28, 22, 255), width=2)

    # =========================================================================
    # QUADRANT 4: BOTTOM-LEFT [0..256, 256..512] -> TROUSERS, BOOTS, HANDS & BADGE
    # =========================================================================
    # 4.1 Charcoal Trousers (left strip: x=0..120, y=256..390)
    v_gradient((0, 256, 120, 390), (45, 48, 52), (26, 28, 32))
    draw.line([(60, 256), (60, 390)], fill=(60, 64, 70, 255), width=2)
    for ty in range(256, 390, 3):
        draw.line([(0, ty), (120, ty)], fill=(20, 22, 26, 80), width=1)

    # 4.2 Laced Leather Officer Boots (bottom strip: x=0..160, y=390..512)
    v_gradient((0, 390, 160, 512), (28, 24, 22), (12, 10, 10))
    draw.line([(80, 390), (80, 512)], fill=(10, 8, 8, 255), width=2)
    for ly in range(405, 480, 10):
        draw.ellipse([70, ly, 75, ly + 5], fill=(160, 130, 60, 255), outline=(60, 45, 15, 255))
        draw.ellipse([85, ly, 90, ly + 5], fill=(160, 130, 60, 255), outline=(60, 45, 15, 255))
        draw.line([(74, ly + 2), (86, ly + 7)], fill=(45, 38, 32, 255), width=2)
        draw.line([(86, ly + 2), (74, ly + 7)], fill=(45, 38, 32, 255), width=2)
    draw.arc([20, 475, 140, 505], 180, 360, fill=(75, 65, 58, 255), width=2)
    draw.rectangle([0, 502, 160, 512], fill=(18, 16, 16, 255), outline=(8, 6, 6, 255), width=1)
    for tx in range(6, 155, 10):
        draw.rectangle([tx, 504, tx + 5, 511], fill=(8, 6, 6, 255))

    # 4.3 Detective Hands (top-right of Q4: x=125..256, y=256..380)
    v_gradient((125, 256, 256, 380), (148, 118, 98), (112, 85, 70))
    for fy in range(275, 360, 20):
        draw.arc([145, fy - 6, 235, fy + 12], 180, 360, fill=(80, 58, 46, 255), width=2)
        draw.line([(145, fy + 4), (235, fy + 4)], fill=(172, 138, 118, 255), width=1)
    for nx in (150, 175, 200, 225):
        draw.ellipse([nx, 362, nx + 14, 375], fill=(180, 148, 132, 255), outline=(92, 68, 56, 255))

    # 4.4 Five-Pointed Gold Police Star Badge (bottom-right of Q4: x=165..256, y=390..512)
    draw.rectangle([165, 390, 256, 512], fill=(22, 20, 18, 255))
    draw.ellipse([175, 410, 245, 480], fill=(160, 120, 35, 255), outline=(100, 75, 20, 255), width=3)
    draw.ellipse([182, 417, 238, 473], fill=(215, 175, 55, 255))

    cx, cy, r_outer, r_inner = 210, 445, 28, 12
    star_pts = []
    for i in range(10):
        angle = math.radians(i * 36 - 90)
        r = r_outer if i % 2 == 0 else r_inner
        star_pts.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
    draw.polygon(star_pts, fill=(255, 230, 120, 255), outline=(130, 95, 25, 255), width=2)
    draw.ellipse([cx - 7, cy - 7, cx + 7, cy + 7], fill=(240, 200, 75, 255), outline=(140, 105, 30, 255))

    img = img.filter(ImageFilter.SMOOTH_MORE)
    img.save(str(ATLAS_PATH), "PNG")
    print(f"Gothic texture atlas successfully created at {ATLAS_PATH} (512x512)")
    return img


if __name__ == "__main__":
    create_atlas()
