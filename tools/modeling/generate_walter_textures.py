"""Generate high-fidelity Police and Plain Civilian textures for Walter Corwin.

Runs in system Python (requires Pillow, numpy):
    python tools/modeling/generate_walter_textures.py

Outputs:
    assets/models/walter_police_remesh.jpg: Navy uniform with chest badge painted
    over with uniform navy wool so the toggleable 3D Badge mesh leaves an empty spot.
    assets/models/walter_plain_remesh.jpg: Warm 1920s civilian brown tweed wool suit,
    plain civilian cap (badge removed), collar pins removed, dark horn buttons,
    preserving natural facial features, skin, and shirt collar.
"""

from __future__ import annotations

import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
MODEL_DIR = ROOT / "assets" / "models"
MODEL_DIR.mkdir(parents=True, exist_ok=True)
POLICE_OUT = MODEL_DIR / "walter_police_remesh.jpg"
PLAIN_OUT = MODEL_DIR / "walter_plain_remesh.jpg"
POLICE_EXTRACTED = MODEL_DIR / "walter_phase1_walter_police_remesh.jpg"
PLAIN_EXTRACTED = MODEL_DIR / "walter_phase1_walter_plain_remesh.jpg"


def generate_textures(uv_json_path: Path, raw_police_tex_path: Path | None = None) -> tuple[Path, Path]:
    if raw_police_tex_path is None or not raw_police_tex_path.exists():
        raw_police_tex_path = POLICE_OUT
    if not raw_police_tex_path.exists():
        raise FileNotFoundError(f"Source texture not found at {raw_police_tex_path}")

    img = Image.open(raw_police_tex_path).convert("RGB")
    size = img.size[0]  # 2048

    polys = json.loads(uv_json_path.read_text())

    # Build exact masks from 3D model geometry
    mask_chest_badge = Image.new("L", (size, size), 0)
    draw_chest = ImageDraw.Draw(mask_chest_badge)

    mask_cap_badge = Image.new("L", (size, size), 0)
    draw_cap = ImageDraw.Draw(mask_cap_badge)

    for p in polys:
        cx, cy, cz = p["center"]
        uvs = p["uvs"]

        triangles = []
        if len(uvs) == 3:
            triangles.append(uvs)
        elif len(uvs) == 4:
            triangles.append([uvs[0], uvs[1], uvs[2]])
            triangles.append([uvs[0], uvs[2], uvs[3]])
        else:
            for i in range(1, len(uvs) - 1):
                triangles.append([uvs[0], uvs[i], uvs[i + 1]])

        # 1. Exact chest badge volume
        is_chest = (7.0 <= cx <= 13.0 and 123.0 <= cz <= 134.5 and -12.0 <= cy <= -6.0)
        # 2. Cap badge volume
        is_cap = (161 <= cz <= 170 and -4.5 <= cx <= 4.5 and cy <= -8.0)

        for tri in triangles:
            pts = [(int(round(u * size)), int(round((1.0 - v) * size))) for u, v in tri]
            if is_chest:
                draw_chest.polygon(pts, fill=255)
            if is_cap:
                draw_cap.polygon(pts, fill=255)

    mask_chest_badge = mask_chest_badge.filter(ImageFilter.MaxFilter(9))
    mask_cap_badge = mask_cap_badge.filter(ImageFilter.MaxFilter(9))

    # Collar pin rectangles on UV atlas
    mask_collar = Image.new("L", (size, size), 0)
    draw_collar = ImageDraw.Draw(mask_collar)
    draw_collar.rectangle([260, 1050, 390, 1160], fill=255)
    draw_collar.rectangle([0, 1420, 65, 1570], fill=255)
    mask_collar = mask_collar.filter(ImageFilter.MaxFilter(9))

    src_arr = np.array(img).copy()
    r = src_arr[:, :, 0].astype(np.float32) / 255.0
    g = src_arr[:, :, 1].astype(np.float32) / 255.0
    b = src_arr[:, :, 2].astype(np.float32) / 255.0

    maxc = np.maximum(np.maximum(r, g), b)
    minc = np.minimum(np.minimum(r, g), b)
    v = maxc
    deltac = maxc - minc
    s = np.zeros_like(v)
    nonzero_v = v != 0
    s[nonzero_v] = deltac[nonzero_v] / v[nonzero_v]

    rc = np.zeros_like(r)
    gc = np.zeros_like(g)
    bc = np.zeros_like(b)
    nonzero_d = deltac != 0
    rc[nonzero_d] = (maxc[nonzero_d] - r[nonzero_d]) / deltac[nonzero_d]
    gc[nonzero_d] = (maxc[nonzero_d] - g[nonzero_d]) / deltac[nonzero_d]
    bc[nonzero_d] = (maxc[nonzero_d] - b[nonzero_d]) / deltac[nonzero_d]

    h = np.zeros_like(r)
    mask_r = (r == maxc) & nonzero_d
    mask_g = (g == maxc) & nonzero_d & (~mask_r)
    mask_b = (b == maxc) & nonzero_d & (~mask_r) & (~mask_g)
    h[mask_r] = bc[mask_r] - gc[mask_r]
    h[mask_g] = 2.0 + rc[mask_g] - bc[mask_g]
    h[mask_b] = 4.0 + gc[mask_b] - rc[mask_b]
    h = (h / 6.0) % 1.0

    # Masks
    chest_np = np.array(mask_chest_badge) > 0
    cap_np = np.array(mask_cap_badge) > 0
    collar_np = np.array(mask_collar) > 0
    is_insignia = chest_np | cap_np | collar_np

    # Skin definition (strictly preserved face, eyes, neck, hands)
    is_skin = (h >= 0.02) & (h <= 0.13) & (s >= 0.12) & (v >= 0.45) & (~is_insignia)

    # Gold buttons
    is_gold = (r > 0.35) & (g > 0.28) & (b < 0.32) & (r > b + 0.08)

    rng = np.random.RandomState(1924)
    twill = (((np.indices((size, size))[1] + np.indices((size, size))[0] * 2) % 6 < 3).astype(np.float32) * 8.0 - 4.0)[:, :, None]
    weave_noise = rng.randint(-5, 6, size=(size, size, 3)).astype(np.float32)

    # -----------------------------------------------------------------
    # POLICE TEXTURE:
    # Navy wool over chest badge so hiding 3D Badge reveals uniform cloth
    # -----------------------------------------------------------------
    police_arr = src_arr.copy()
    navy_base = np.array([22.0, 27.0, 37.0], dtype=np.float32)
    navy_patch = np.clip(navy_base + weave_noise, 0, 255).astype(np.uint8)
    police_arr[chest_np] = navy_patch[chest_np]

    police_img = Image.fromarray(police_arr)
    police_img.save(POLICE_OUT, quality=94)
    police_img.save(POLICE_EXTRACTED, quality=94)
    print(f"Generated clean police texture: {POLICE_OUT} and {POLICE_EXTRACTED}")

    # -----------------------------------------------------------------
    # PLAIN CIVILIAN TWEED SUIT TEXTURE:
    # -----------------------------------------------------------------
    plain_arr = src_arr.copy()

    # White collar shirt
    is_white_shirt = (v > 0.72) & (s < 0.08) & (~is_insignia)
    # Uniform cloth: any non-skin, non-shirt pixel
    is_cloth = (~is_skin) & (~is_white_shirt) & ((v < 0.45) | is_insignia | is_gold)

    # Normalized value for fabric shading
    v_norm = v.copy()
    v_norm[is_insignia] = 0.14

    # Tweed coat color:
    # Rich warm brown tweed (R: 1.0, G: 0.84, B: 0.68)
    tweed_lum = 0.22 + v_norm * 0.44
    tweed_r = tweed_lum * 255.0
    tweed_g = tweed_lum * 215.0
    tweed_b = tweed_lum * 174.0
    tweed_rgb = np.stack([tweed_r, tweed_g, tweed_b], axis=-1) + twill + weave_noise
    tweed_rgb = np.clip(tweed_rgb, 0, 255).astype(np.uint8)

    # Dark matte horn buttons
    horn_rgb = np.clip(np.array([24, 23, 25]) + rng.randint(-3, 4, size=(size, size, 3)), 0, 255).astype(np.uint8)

    # Plain cap cloth
    cap_rgb = np.clip(np.array([24, 26, 30]) + rng.randint(-3, 4, size=(size, size, 3)), 0, 255).astype(np.uint8)

    # Apply tweed to all cloth
    plain_arr[is_cloth] = tweed_rgb[is_cloth]

    # Cap badge removed -> cap cloth
    plain_arr[cap_np] = cap_rgb[cap_np]

    # Collar pins removed -> tweed
    plain_arr[collar_np] = tweed_rgb[collar_np]

    # Chest badge removed -> tweed
    plain_arr[chest_np] = tweed_rgb[chest_np]

    # Buttons -> dark horn buttons
    plain_arr[is_gold] = horn_rgb[is_gold]

    plain_img = Image.fromarray(plain_arr)
    plain_img.save(PLAIN_OUT, quality=94)
    plain_img.save(PLAIN_EXTRACTED, quality=94)
    print(f"Generated civilian plain coat texture: {PLAIN_OUT} and {PLAIN_EXTRACTED}")

    return POLICE_OUT, PLAIN_OUT


if __name__ == "__main__":
    import sys
    uv_path = ROOT / "tests" / "walter_mesh_uvs.json"
    generate_textures(uv_path)
