from PIL import Image
import os

images = []
for root, dirs, files in os.walk('.'):
    if '.git' in root or '.godot' in root or 'archive' in root:
        continue
    for f in files:
        if f.lower().endswith(('.png', '.jpg', '.jpeg', '.webp')):
            p = os.path.join(root, f)
            sz = os.path.getsize(p)
            try:
                with Image.open(p) as im:
                    images.append((p, im.size, sz))
            except Exception as e:
                print("Error opening", p, e)

images.sort(key=lambda x: x[1][0] * x[1][1], reverse=True)
print(f"Total images found: {len(images)}")
print("\nImages with dimension > 1024:")
for p, dim, sz in images:
    if dim[0] > 1024 or dim[1] > 1024:
        print(f"{dim}  {sz/1024/1024:5.2f} MB : {p}")
