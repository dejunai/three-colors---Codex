"""Generate an authentic Gothic 1 & 2 style painted diffuse texture atlas (512x512) for Walter Corwin.

Piranha Bytes / early-2000s aesthetic:
- Baked chiaroscuro lighting (deep crease shadows, edge highlights, ambient occlusion).
- Rugged, weather-beaten noir detective face (stubble, gaunt cheekbones, tired sunken eyes).
- Tactile material weaves: herringbone tweed, midnight police wool, scuffed leather boots, brass.
"""

import math
import random
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
ATLAS_PATH = ROOT / "assets" / "models" / "walter_phase1_atlas.png"
ATLAS_PATH.parent.mkdir(parents=True, exist_ok=True)

SIZE = 512

def create_gothic_atlas() -> Image.Image:
    # 512x512 RGB canvas
    img = Image.new("RGBA", (SIZE, SIZE), (25, 25, 25, 255))
    draw = ImageDraw.Draw(img)
    rng = random.Random(1923)

    # Helper for noise & grain
    def add_noise(box, base_rgb, variance, grain_step=1):
        x0, y0, x1, y1 = box
        for y in range(y0, y1, grain_step):
            for x in range(x0, x1, grain_step):
                delta = rng.randint(-variance, variance)
                r = max(0, min(255, base_rgb[0] + delta))
                g = max(0, min(255, base_rgb[1] + delta))
                b = max(0, min(255, base_rgb[2] + delta))
                if grain_step == 1:
                    img.putpixel((x, y), (r, g, b, 255))
                else:
                    draw.rectangle([x, y, min(x1-1, x + grain_step - 1), min(y1-1, y + grain_step - 1)], fill=(r, g, b, 255))

    # =========================================================================
    # QUADRANT 1: TOP-LEFT (0..255, 0..255) -> FACE, HAT, HANDS, SHIRT & TIE
    # =========================================================================

    # 1A. FACE & HEAD (0..160, 0..160)
    # Base skin tone with early-2000s Gothic weathered undertone
    skin_base = (185, 148, 125)
    add_noise((0, 0, 160, 160), skin_base, 8)

    # Forehead & Brow shelf shadow
    draw.rectangle([20, 15, 140, 45], fill=(168, 132, 110, 255))
    draw.rectangle([25, 42, 135, 52], fill=(138, 105, 86, 255)) # Brow shadow shelf

    # Heavy furrowed brows
    for bx, by in [(30, 44), (95, 44)]:
        draw.polygon([(bx, by+4), (bx+12, by), (bx+35, by+3), (bx+30, by+8), (bx+10, by+7)], fill=(45, 38, 34, 255))

    # Sunken tired eye sockets
    draw.ellipse([32, 50, 68, 72], fill=(110, 82, 68, 255))
    draw.ellipse([92, 50, 128, 72], fill=(110, 82, 68, 255))
    # Eye whites (slightly bloodshot / dull cream)
    draw.ellipse([38, 55, 62, 67], fill=(210, 205, 195, 255))
    draw.ellipse([98, 55, 122, 67], fill=(210, 205, 195, 255))
    # Steely grey-blue irises + pupils
    draw.ellipse([46, 56, 56, 66], fill=(70, 88, 98, 255))
    draw.ellipse([48, 58, 54, 64], fill=(20, 25, 28, 255))
    draw.point((49, 58), fill=(245, 245, 255, 255)) # Specular catchlight
    draw.ellipse([104, 56, 114, 66], fill=(70, 88, 98, 255))
    draw.ellipse([106, 58, 112, 64], fill=(20, 25, 28, 255))
    draw.point((107, 58), fill=(245, 245, 255, 255)) # Specular catchlight

    # Dark circles / bags under eyes
    draw.arc([34, 62, 66, 75], 0, 180, fill=(95, 70, 58, 255), width=2)
    draw.arc([94, 62, 126, 75], 0, 180, fill=(95, 70, 58, 255), width=2)

    # Chiseled Nose bridge with highlight & shadow
    draw.polygon([(74, 45), (86, 45), (88, 92), (72, 92)], fill=(155, 120, 100, 255))
    draw.line([(78, 48), (78, 90)], fill=(215, 182, 160, 255), width=3) # Nose bridge ridge highlight
    draw.polygon([(68, 90), (74, 98), (86, 98), (92, 90)], fill=(140, 105, 88, 255)) # Nose tip
    draw.ellipse([67, 93, 73, 98], fill=(55, 38, 30, 255)) # Nostril Left
    draw.ellipse([87, 93, 93, 98], fill=(55, 38, 30, 255)) # Nostril Right

    # Gaunt cheek hollows & cheekbone highlights
    draw.line([(22, 68), (55, 78)], fill=(210, 175, 155, 255), width=3) # Left cheekbone
    draw.line([(138, 68), (105, 78)], fill=(210, 175, 155, 255), width=3) # Right cheekbone
    draw.polygon([(25, 85), (55, 105), (35, 125), (18, 105)], fill=(128, 98, 80, 255)) # Cheek hollow L
    draw.polygon([(135, 85), (105, 105), (125, 125), (142, 105)], fill=(128, 98, 80, 255)) # Cheek hollow R

    # Stern Mouth & lips
    draw.line([(62, 114), (98, 114)], fill=(85, 52, 45, 255), width=2) # Mouth crease
    draw.polygon([(66, 112), (80, 109), (94, 112)], fill=(145, 105, 95, 255)) # Upper lip
    draw.polygon([(68, 116), (80, 119), (92, 116)], fill=(170, 128, 115, 255)) # Lower lip

    # Heavy 5 o'clock stubble (jaw, chin, upper lip)
    for _ in range(1200):
        sx = rng.randint(28, 132)
        sy = rng.randint(102, 155)
        # Weight towards jawline, upper lip, chin
        if (sy > 102 and sy < 112 and 62 < sx < 98) or (sy >= 115 and math.hypot((sx-80)*0.8, (sy-132)*0.9) < 40):
            stipple = rng.randint(45, 75)
            img.putpixel((sx, sy), (stipple, stipple + 2, stipple + 5, 255))

    # Firm chin cleft & jawline shadow
    draw.line([(78, 136), (82, 136)], fill=(110, 80, 68, 255), width=2)
    draw.line([(28, 138), (80, 156), (132, 138)], fill=(90, 65, 52, 255), width=3) # Under-jaw shadow

    # Ears (left & right sides of head texture)
    draw.rectangle([2, 58, 18, 105], fill=(160, 125, 105, 255))
    draw.rectangle([6, 68, 14, 95], fill=(115, 82, 68, 255))
    draw.rectangle([142, 58, 158, 105], fill=(160, 125, 105, 255))
    draw.rectangle([146, 68, 154, 95], fill=(115, 82, 68, 255))

    # Neck with Adam's apple & tendon shading
    draw.rectangle([45, 160, 115, 192], fill=(155, 122, 102, 255))
    draw.line([(78, 162), (82, 175), (78, 188)], fill=(185, 150, 128, 255), width=3) # Adam's apple
    draw.line([(55, 160), (62, 190)], fill=(120, 90, 75, 255), width=2)
    draw.line([(105, 160), (98, 190)], fill=(120, 90, 75, 255), width=2)

    # 1B. FEDORA HAT & HAIR (160..255, 0..160)
    # Dark charcoal felt
    hat_base = (38, 38, 42)
    add_noise((160, 0, 255, 160), hat_base, 6)
    # Crown crease and front pinch highlights
    draw.line([(180, 25), (235, 25)], fill=(22, 22, 25, 255), width=5) # Center crease shadow
    draw.line([(175, 20), (185, 45)], fill=(65, 65, 72, 255), width=3) # Left pinch highlight
    draw.line([(240, 20), (230, 45)], fill=(65, 65, 72, 255), width=3) # Right pinch highlight
    # Silk hatband ribbon (dark navy/black with satin highlight)
    draw.rectangle([162, 62, 253, 76], fill=(18, 20, 25, 255))
    draw.line([(162, 65), (253, 65)], fill=(60, 68, 85, 255), width=2)
    # Brim top & underside
    draw.rectangle([162, 85, 253, 120], fill=(42, 42, 46, 255))
    draw.line([(162, 85), (253, 85)], fill=(75, 75, 82, 255), width=2) # Brim edge bevel
    draw.rectangle([162, 122, 253, 158], fill=(20, 20, 22, 255)) # Underside shadow

    # 1C. SHIRT, TIE & BELT (128..255, 160..255)
    # Off-white / cream linen shirt with collar folds
    shirt_base = (205, 202, 192)
    add_noise((128, 160, 200, 255), shirt_base, 8)
    draw.polygon([(135, 165), (160, 195), (164, 165)], fill=(235, 232, 224, 255)) # Collar L
    draw.polygon([(193, 165), (168, 195), (164, 165)], fill=(235, 232, 224, 255)) # Collar R
    draw.line([(135, 165), (160, 195)], fill=(140, 135, 125, 255), width=2)
    draw.line([(193, 165), (168, 195)], fill=(140, 135, 125, 255), width=2)

    # Black / Charcoal knotted tie
    draw.polygon([(158, 190), (170, 190), (172, 205), (156, 205)], fill=(28, 28, 32, 255)) # Knot
    draw.polygon([(157, 205), (171, 205), (176, 252), (164, 255), (152, 252)], fill=(34, 34, 38, 255)) # Tie body
    draw.line([(163, 206), (164, 252)], fill=(58, 58, 65, 255), width=2) # Center specular fold

    # Leather Belt with brass buckle (200..255, 160..255)
    draw.rectangle([202, 162, 253, 205], fill=(35, 28, 22, 255)) # Belt strap
    draw.line([(202, 164), (253, 164)], fill=(75, 60, 48, 255), width=1) # Stitching top
    draw.line([(202, 203), (253, 203)], fill=(75, 60, 48, 255), width=1) # Stitching bot
    # Brass buckle
    draw.rectangle([214, 170, 242, 198], fill=(185, 145, 45, 255))
    draw.rectangle([220, 175, 236, 193], fill=(35, 28, 22, 255))
    draw.line([(227, 172), (227, 196)], fill=(240, 210, 100, 255), width=2) # Buckle prong

    # 1D. HANDS (0..128, 192..255)
    add_noise((0, 192, 128, 255), (175, 140, 118), 8)
    # Knuckle & finger creases
    for hy in [208, 225, 240]:
        draw.line([(10, hy), (118, hy)], fill=(125, 95, 78, 255), width=2)
        draw.line([(10, hy+2), (118, hy+2)], fill=(200, 165, 145, 255), width=1)
    # Palm crease
    draw.line([(20, 200), (80, 245)], fill=(130, 98, 80, 255), width=2)

    # =========================================================================
    # QUADRANT 2: TOP-RIGHT (256..511, 0..255) -> PLAIN WOOL COAT (TWEED)
    # =========================================================================
    tweed_base = (75, 66, 56) # Earthy brown-grey charcoal tweed
    add_noise((256, 0, 512, 255), tweed_base, 10)
    # Herringbone weave pattern
    for y in range(0, 255, 4):
        for x in range(256, 511, 8):
            v = 14 if ((x // 8) + (y // 4)) % 2 == 0 else -14
            draw.line([(x, y), (x+4, y+2)], fill=(max(0, min(255, tweed_base[0]+v)), max(0, min(255, tweed_base[1]+v)), max(0, min(255, tweed_base[2]+v)), 255))

    # Front Torso Lapels & Fold Shadows (256..384, 0..160)
    # Wide notched lapels with heavy drop shadow
    draw.polygon([(270, 10), (320, 90), (280, 95), (265, 40)], fill=(62, 54, 45, 255))
    draw.line([(270, 10), (320, 90)], fill=(105, 95, 82, 255), width=3) # Lapel edge highlight
    draw.polygon([(380, 10), (330, 90), (370, 95), (385, 40)], fill=(62, 54, 45, 255))
    draw.line([(380, 10), (330, 90)], fill=(105, 95, 82, 255), width=3)

    # Deep diagonal body fold shadows (Gothic style baked drapery)
    draw.line([(275, 80), (315, 145)], fill=(38, 32, 26, 255), width=4)
    draw.line([(375, 80), (335, 145)], fill=(38, 32, 26, 255), width=4)
    draw.line([(280, 120), (320, 155)], fill=(42, 36, 30, 255), width=3)
    draw.line([(370, 120), (330, 155)], fill=(42, 36, 30, 255), width=3)

    # Horn buttons (dark brown mottled)
    for by in [70, 105, 140]:
        draw.ellipse([320, by, 332, by+12], fill=(30, 24, 20, 255))
        draw.ellipse([322, by+2, 330, by+10], fill=(55, 45, 38, 255))
        draw.point((324, by+4), fill=(15, 12, 10, 255))
        draw.point((328, by+8), fill=(15, 12, 10, 255))
        # Buttonhole slit on other side
        draw.line([(308, by+6), (318, by+6)], fill=(32, 26, 22, 255), width=2)

    # Pocket flaps with shadow
    draw.rectangle([270, 115, 305, 127], fill=(58, 50, 42, 255))
    draw.line([(270, 127), (305, 127)], fill=(28, 24, 20, 255), width=2)
    draw.rectangle([(345, 115), (380, 127)], fill=(58, 50, 42, 255))
    draw.line([(345, 127), (380, 127)], fill=(28, 24, 20, 255), width=2)

    # Sleeves & Skirts (384..511, 0..255)
    # Elbow creases
    for ey in [60, 75, 90]:
        draw.line([(395, ey), (440, ey+8)], fill=(35, 30, 25, 255), width=3)
        draw.line([(395, ey+2), (440, ey+10)], fill=(95, 84, 72, 255), width=2)
    # Cuff seam & sleeve button
    draw.line([(390, 150), (450, 150)], fill=(30, 26, 22, 255), width=3)
    draw.ellipse([435, 140, 443, 148], fill=(35, 28, 22, 255))

    # Skirt hem dirt / damp salt spray edge
    draw.rectangle([256, 235, 511, 255], fill=(45, 38, 32, 255))
    draw.line([(256, 235), (511, 235)], fill=(32, 28, 24, 255), width=3)

    # =========================================================================
    # QUADRANT 3: BOTTOM-LEFT (0..255, 256..511) -> POLICE UNIFORM & BADGE
    # =========================================================================
    police_base = (24, 32, 45) # Midnight / Officer Navy
    add_noise((0, 256, 255, 511), police_base, 8)

    # Double-breasted brass buttons (two distinct rows)
    for by in [295, 335, 375, 415]:
        for bx in [55, 105]:
            draw.ellipse([bx, by, bx+14, by+14], fill=(70, 52, 18, 255)) # Shadow ring
            draw.ellipse([bx+1, by+1, bx+13, by+13], fill=(195, 155, 50, 255)) # Brass face
            draw.ellipse([bx+3, by+3, bx+8, by+8], fill=(255, 225, 120, 255)) # Specular dome
            # Anchor / star emblem hint in center
            draw.point((bx+7, by+7), fill=(60, 45, 15, 255))

    # Officer peaked lapels with crisp gold piping hint
    draw.polygon([(35, 265), (75, 320), (40, 325), (25, 285)], fill=(18, 24, 35, 255))
    draw.line([(35, 265), (75, 320)], fill=(60, 80, 110, 255), width=2)
    draw.polygon([(125, 265), (85, 320), (120, 325), (135, 285)], fill=(18, 24, 35, 255))
    draw.line([(125, 265), (85, 320)], fill=(60, 80, 110, 255), width=2)

    # Shoulder Epaulets with brass button
    draw.rectangle([10, 262, 45, 276], fill=(16, 22, 32, 255))
    draw.ellipse([35, 265, 43, 273], fill=(210, 170, 55, 255))
    draw.rectangle([115, 262, 150, 276], fill=(16, 22, 32, 255))
    draw.ellipse([117, 265, 125, 273], fill=(210, 170, 55, 255))

    # POLICE STAR / SHIELD BADGE (165..245, 265..345)
    # Gold star shield
    draw.polygon([
        (205, 268), (218, 280), (235, 280), (222, 295),
        (228, 312), (205, 302), (182, 312), (188, 295),
        (175, 280), (192, 280)
    ], fill=(215, 175, 45, 255))
    draw.polygon([
        (205, 274), (214, 284), (226, 284), (216, 294),
        (220, 306), (205, 298), (190, 306), (194, 294),
        (184, 284), (196, 284)
    ], fill=(255, 225, 95, 255))
    draw.ellipse([197, 286, 213, 302], fill=(60, 48, 15, 255)) # Badge center seal
    draw.ellipse([200, 289, 210, 299], fill=(240, 205, 80, 255))

    # Police sleeve creases & dual brass cuff buttons
    draw.line([(175, 380), (240, 380)], fill=(12, 16, 24, 255), width=3)
    draw.ellipse([215, 368, 225, 378], fill=(205, 165, 50, 255))
    draw.ellipse([230, 368, 240, 378], fill=(205, 165, 50, 255))

    # =========================================================================
    # QUADRANT 4: BOTTOM-RIGHT (256..511, 256..511) -> TROUSERS & BOOTS
    # =========================================================================
    # 4A. TROUSERS (256..384, 256..511)
    trouser_base = (30, 34, 38) # Charcoal worsted wool
    add_noise((256, 256, 384, 511), trouser_base, 6)
    # Sharp pressed front crease highlight + shadow
    draw.line([(315, 260), (315, 490)], fill=(48, 54, 60, 255), width=2)
    draw.line([(317, 260), (317, 490)], fill=(18, 20, 24, 255), width=2)
    # Knee fold wrinkles
    for ky in [350, 365, 380]:
        draw.line([(280, ky), (350, ky+6)], fill=(16, 18, 22, 255), width=3)
        draw.line([(280, ky+2), (350, ky+8)], fill=(44, 48, 54, 255), width=2)
    # Trouser hem cuff
    draw.line([(260, 495), (380, 495)], fill=(16, 18, 22, 255), width=3)

    # 4B. LEATHER BOOTS (384..511, 256..511)
    boot_base = (24, 20, 18) # Dark oiled leather
    add_noise((384, 256, 511, 511), boot_base, 6)
    # Toe cap curve & seam
    draw.arc([405, 430, 490, 485], 190, 350, fill=(65, 54, 46, 255), width=3)
    draw.arc([405, 432, 490, 487], 190, 350, fill=(12, 10, 8, 255), width=2)
    # Lacing eyelets & criss-cross leather laces
    for ly in range(300, 430, 18):
        draw.ellipse([432, ly, 438, ly+6], fill=(160, 130, 60, 255)) # Brass eyelet L
        draw.ellipse([458, ly, 464, ly+6], fill=(160, 130, 60, 255)) # Brass eyelet R
        draw.line([(435, ly+3), (461, ly+15)], fill=(15, 12, 10, 255), width=2)
        draw.line([(461, ly+3), (435, ly+15)], fill=(15, 12, 10, 255), width=2)
    # Heavy boot heel & rubber/leather sole welt
    draw.rectangle([390, 490, 505, 508], fill=(14, 12, 10, 255))
    draw.line([(390, 490), (505, 490)], fill=(90, 75, 55, 255), width=2) # Welt stitching line
    # Mud & coastal salt grime at sole rim
    draw.line([(390, 505), (505, 505)], fill=(65, 52, 40, 255), width=3)

    # Subtle overall sharpen for authentic PS1 / Gothic crisp pixel definition
    img = img.filter(ImageFilter.UnsharpMask(radius=1.2, percent=130, threshold=2))
    img.save(ATLAS_PATH, "PNG")
    print(f"Gothic texture atlas successfully created at {ATLAS_PATH} ({SIZE}x{SIZE})")
    return img

if __name__ == "__main__":
    create_gothic_atlas()
