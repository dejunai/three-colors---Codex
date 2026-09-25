from PIL import Image
import numpy as np
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC_IMG = ROOT / "Meshy_Gothic-Walter-with-texture_0.jpg"
OUT_IMG = ROOT / "assets" / "models" / "walter_plain_texture.jpg"
OUT_IMG.parent.mkdir(parents=True, exist_ok=True)

img = Image.open(SRC_IMG).convert("RGB")
arr = np.array(img, dtype=np.float32)

r = arr[:, :, 0]
g = arr[:, :, 1]
b = arr[:, :, 2]

# Detect navy police uniform: blue dominant or dark slate blue
# Navy in this texture: b > r and b > 25 and r < 90
navy_mask = (b > (r + 4)) & (b > 22) & (r < 85)

# Tweed/warm wool replacement color: warm brownish-grey (r~82, g~70, b~58)
# We preserve the lightness/shading from the original blue channel
lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
lum_factor = np.clip(lum * 2.2, 0.4, 1.6)

new_r = np.clip(84.0 * lum_factor, 0, 255)
new_g = np.clip(72.0 * lum_factor, 0, 255)
new_b = np.clip(58.0 * lum_factor, 0, 255)

arr[navy_mask, 0] = new_r[navy_mask]
arr[navy_mask, 1] = new_g[navy_mask]
arr[navy_mask, 2] = new_b[navy_mask]

plain_img = Image.fromarray(np.uint8(arr))
# Resize to 2048x2048 for optimal web performance
plain_img = plain_img.resize((2048, 2048), Image.Resampling.LANCZOS)
plain_img.save(OUT_IMG, quality=92)
print(f"Created plain coat texture: {OUT_IMG} (2048x2048)")
