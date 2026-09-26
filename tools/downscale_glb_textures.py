import os, sys, struct, json, io
from PIL import Image

def downscale_image_bytes(img_bytes, max_dim=1024, quality=85):
    pil_img = Image.open(io.BytesIO(img_bytes))
    w, h = pil_img.size
    if w <= max_dim and h <= max_dim:
        return None, pil_img.format, (w, h)
    
    scale = min(max_dim / w, max_dim / h)
    new_w = int(round(w * scale))
    new_h = int(round(h * scale))
    
    # Resize with high quality Lanczos filter
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
            return False, "Not a glTF file"
        version, length = struct.unpack('<II', f.read(8))
        chunk_len, chunk_type = struct.unpack('<II', f.read(8))
        if chunk_type != 0x4E4F534A:
            return False, "Chunk 0 is not JSON"
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
        return False, "No textures > max_dim found"

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

    return True, f"Reduced to {total_len//1024} KB"

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

if __name__ == '__main__':
    target = sys.argv[1] if len(sys.argv) > 1 else 'assets/models/props/common/barrel_side_hd.glb'
    print(f"Testing on {target}...")
    orig_size = os.path.getsize(target)
    ok, msg = downscale_glb(target)
    new_size = os.path.getsize(target)
    print(f"GLB result: {ok}, {msg} (was {orig_size//1024} KB -> now {new_size//1024} KB)")
    
    # Check matching loose images
    dir_name = os.path.dirname(target)
    base_name = os.path.splitext(os.path.basename(target))[0]
    for f in os.listdir(dir_name):
        if f.startswith(base_name) and f.lower().endswith(('.jpg', '.png')) and not f.endswith('.import'):
            img_path = os.path.join(dir_name, f)
            i_orig = os.path.getsize(img_path)
            i_ok, i_msg = downscale_loose_image(img_path)
            i_new = os.path.getsize(img_path)
            print(f"Loose image {f}: {i_ok}, {i_msg} (was {i_orig//1024} KB -> now {i_new//1024} KB)")
