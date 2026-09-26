import os
from analyze_props_textures import analyze_glb

props = []
for root, dirs, files in os.walk('assets/models/props'):
    for f in sorted(files):
        if f.lower().endswith('.glb'):
            p = os.path.join(root, f)
            res = analyze_glb(p)
            if not res: continue
            has_2k = any(isinstance(im['size'], tuple) and (im['size'][0] >= 2048 or im['size'][1] >= 2048) for im in res['images'])
            props.append((p, res, has_2k))

print("=== ALL PROPS IN assets/models/props ===")
print(f"Total props: {len(props)}")
props_2k = [p for p in props if p[2]]
props_1k = [p for p in props if not p[2]]
print(f"Props with 2K textures: {len(props_2k)}")
print(f"Props with <=1K textures: {len(props_1k)}")

print("\n--- 2K Props sorted by file size ---")
for p, res, _ in sorted(props_2k, key=lambda x: x[1]['size'], reverse=True):
    img_desc = ', '.join([f"{im['size'][0]}x{im['size'][1]} {im['format']} ({im['bytes']//1024}KB)" for im in res['images']])
    print(f"{res['size']//1024:4d} KB | {p} | {img_desc}")

print("\n--- 1K or smaller Props sorted by file size ---")
for p, res, _ in sorted(props_1k, key=lambda x: x[1]['size'], reverse=True):
    img_desc = ', '.join([f"{im['size'][0]}x{im['size'][1]} {im['format']} ({im['bytes']//1024}KB)" for im in res['images']])
    print(f"{res['size']//1024:4d} KB | {p} | {img_desc}")
