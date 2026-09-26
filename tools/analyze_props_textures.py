import os, struct, json, io
from PIL import Image

def analyze_glb(path):
    size = os.path.getsize(path)
    with open(path, 'rb') as f:
        magic = f.read(4)
        if magic != b'glTF': return None
        version, length = struct.unpack('<II', f.read(8))
        chunk_len, chunk_type = struct.unpack('<II', f.read(8))
        if chunk_type != 0x4E4F534A: return None
        json_data = json.loads(f.read(chunk_len).decode('utf-8'))
        bin_chunk_len, bin_chunk_type = struct.unpack('<II', f.read(8))
        bin_data = f.read(bin_chunk_len)
        buffer_views = json_data.get('bufferViews', [])
        images = []
        for img in json_data.get('images', []):
            bv_idx = img.get('bufferView')
            if bv_idx is not None:
                bv = buffer_views[bv_idx]
                img_bytes = bin_data[bv['byteOffset']:bv['byteOffset']+bv['byteLength']]
                try:
                    pil_img = Image.open(io.BytesIO(img_bytes))
                    images.append({'name': img.get('name', ''), 'size': pil_img.size, 'format': pil_img.format, 'bytes': len(img_bytes)})
                except Exception as e:
                    images.append({'name': img.get('name', ''), 'size': 'err', 'format': 'err', 'bytes': len(img_bytes)})
        return {'size': size, 'images': images}

results = {}
for root, dirs, files in os.walk('assets'):
    for f in sorted(files):
        if f.lower().endswith('.glb'):
            p = os.path.join(root, f)
            res = analyze_glb(p)
            if res:
                results[p] = res

print('=== 2K TEXTURES (>= 2048) ===')
items_2k = []
for p, res in sorted(results.items(), key=lambda x: x[1]['size'], reverse=True):
    has_2k = any(isinstance(im['size'], tuple) and (im['size'][0] >= 2048 or im['size'][1] >= 2048) for im in res['images'])
    if has_2k:
        items_2k.append((p, res))
for p, res in items_2k:
    img_str = ', '.join([f"{im['size'][0]}x{im['size'][1]} {im['format']} ({im['bytes']//1024}KB)" for im in res['images']])
    print(f"{res['size']/1024/1024:5.2f} MB ({res['size']//1024:5d} KB) | {p} | {img_str}")
print(f"Total 2K assets: {len(items_2k)}")


print('\n=== 1K OR SMALLER TEXTURES (< 2048) ===')
for p, res in sorted(results.items(), key=lambda x: x[1]['size'], reverse=True):
    has_2k = any(isinstance(im['size'], tuple) and (im['size'][0] >= 2048 or im['size'][1] >= 2048) for im in res['images'])
    if not has_2k:
        img_str = ', '.join([f"{im['size'][0]}x{im['size'][1]} {im['format']} ({im['bytes']//1024}KB)" for im in res['images']])
        print(f"{res['size']/1024/1024:5.2f} MB ({res['size']//1024:5d} KB) | {p} | {img_str}")
