import os, sys, struct, json, io
from PIL import Image

def downscale_image_bytes(img_bytes, max_dim=1024, quality=85):
    try:
        pil_img = Image.open(io.BytesIO(img_bytes))
    except Exception as e:
        return None, None, None
    w, h = pil_img.size
    if w <= max_dim and h <= max_dim:
        return None, pil_img.format, (w, h)
    
    scale = min(max_dim / w, max_dim / h)
    new_w = int(round(w * scale))
    new_h = int(round(h * scale))
    
    resized_img = pil_img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    out_io = io.BytesIO()
    fmt = pil_img.format if pil_img.format in ('JPEG', 'PNG') else 'JPEG'
    if fmt == 'JPEG':
        if resized_img.mode in ('RGBA', 'LA', 'P'):
            resized_img = resized_img.convert('RGB')
        resized_img.save(out_io, format='JPEG', quality=quality, optimize=True)
    else:
        resized_img.save(out_io, format='PNG', optimize=True)
        
    return out_io.getvalue(), fmt, (new_w, new_h)

def downscale_glb(glb_path, max_dim=1024, quality=85):
    with open(glb_path, 'rb') as f:
        magic = f.read(4)
        if magic != b'glTF':
            return False, "Not a glTF file", 0, 0
        version, length = struct.unpack('<II', f.read(8))
        chunk_len, chunk_type = struct.unpack('<II', f.read(8))
        if chunk_type != 0x4E4F534A:
            return False, "Chunk 0 is not JSON", 0, 0
        json_data = json.loads(f.read(chunk_len).decode('utf-8'))
        bin_chunk_len, bin_chunk_type = struct.unpack('<II', f.read(8))
        bin_data = f.read(bin_chunk_len)

    buffer_views = json_data.get('bufferViews', [])
    images = json_data.get('images', [])

    replacement_data = {}
    modified = False

    for img in images:
        bv_idx = img.get('bufferView')
        if bv_idx is None:
            continue
        bv = buffer_views[bv_idx]
        offset = bv.get('byteOffset', 0)
        length = bv['byteLength']
        img_bytes = bin_data[offset : offset + length]
        new_bytes, fmt, new_size = downscale_image_bytes(img_bytes, max_dim, quality)
        if new_bytes is not None:
            replacement_data[bv_idx] = new_bytes
            modified = True

    if not modified:
        return False, "No textures > max_dim found", length, length

    new_bin = bytearray()
    for i, bv in enumerate(buffer_views):
        while len(new_bin) % 4 != 0:
            new_bin.append(0)
        new_offset = len(new_bin)
        if i in replacement_data:
            data = replacement_data[i]
        else:
            old_offset = bv.get('byteOffset', 0)
            old_len = bv['byteLength']
            data = bin_data[old_offset : old_offset + old_len]
        new_bin.extend(data)
        bv['byteOffset'] = new_offset
        bv['byteLength'] = len(data)

    while len(new_bin) % 4 != 0:
        new_bin.append(0)

    json_data['buffers'][0]['byteLength'] = len(new_bin)

    json_bytes = json.dumps(json_data, separators=(',', ':'), ensure_ascii=False).encode('utf-8')
    while len(json_bytes) % 4 != 0:
        json_bytes += b' '

    total_len = 12 + 8 + len(json_bytes) + 8 + len(new_bin)

    with open(glb_path, 'wb') as f:
        f.write(struct.pack('<III', 0x46546C67, 2, total_len))
        f.write(struct.pack('<II', len(json_bytes), 0x4E4F534A))
        f.write(json_bytes)
        f.write(struct.pack('<II', len(new_bin), 0x004E4942))
        f.write(new_bin)

    return True, f"Reduced to {total_len//1024} KB", length, total_len

def downscale_loose_image(img_path, max_dim=1024, quality=85):
    try:
        with open(img_path, 'rb') as f:
            data = f.read()
        new_bytes, fmt, new_size = downscale_image_bytes(data, max_dim, quality)
        if new_bytes is not None:
            with open(img_path, 'wb') as f:
                f.write(new_bytes)
            return True, f"Resized to {new_size[0]}x{new_size[1]} ({len(new_bytes)//1024} KB)"
    except Exception as e:
        return False, str(e)
    return False, "Not resized"

def main():
    props_dir = os.path.join('assets', 'models', 'props')
    reduced_glbs = []
    skipped_glbs = []
    reduced_loose = []

    print(f"Scanning {props_dir} for props needing texture reduction...")
    
    for root, dirs, files in os.walk(props_dir):
        for f in sorted(files):
            if f.lower().endswith('.glb'):
                glb_path = os.path.join(root, f)
                orig_size = os.path.getsize(glb_path)
                ok, msg, old_len, new_len = downscale_glb(glb_path, max_dim=1024, quality=85)
                if ok:
                    reduced_glbs.append((glb_path, orig_size, new_len))
                    print(f"[REDUCED GLB] {glb_path}: {orig_size//1024} KB -> {new_len//1024} KB")
                else:
                    skipped_glbs.append((glb_path, orig_size, msg))

    # Also scan and reduce all loose images in assets/models/props
    for root, dirs, files in os.walk(props_dir):
        for f in sorted(files):
            if f.lower().endswith(('.jpg', '.png')) and not f.endswith('.import'):
                img_path = os.path.join(root, f)
                orig_size = os.path.getsize(img_path)
                ok, msg = downscale_loose_image(img_path, max_dim=1024, quality=85)
                if ok:
                    new_size = os.path.getsize(img_path)
                    reduced_loose.append((img_path, orig_size, new_size))
                    print(f"[REDUCED IMAGE] {img_path}: {orig_size//1024} KB -> {new_size//1024} KB ({msg})")

    print("\n" + "="*50)
    print(f"SUMMARY:")
    print(f"GLBs reduced: {len(reduced_glbs)}")
    print(f"GLBs kept / already <= 1K: {len(skipped_glbs)}")
    print(f"Loose images reduced: {len(reduced_loose)}")
    total_saved = sum(orig - new for _, orig, new in reduced_glbs) + sum(orig - new for _, orig, new in reduced_loose)
    print(f"Total disk space saved: {total_saved / 1024 / 1024:.2f} MB")

if __name__ == '__main__':
    main()
