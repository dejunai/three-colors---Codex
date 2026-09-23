import struct

with open('build/web/index.pck', 'rb') as f:
    data = f.read(112)
    dir_offset = struct.unpack('<Q', data[32:40])[0]
    f.seek(dir_offset)
    file_count = struct.unpack('<I', f.read(4))[0]
    files = []
    for _ in range(file_count):
        path_len = struct.unpack('<I', f.read(4))[0]
        path = f.read(path_len).decode('utf-8', errors='replace').rstrip('\x00')
        offset, size = struct.unpack('<QQ', f.read(16))
        f.seek(20, 1)
        files.append((size, path))

files.sort(reverse=True)
print(f"Total files: {len(files)}, Total size: {sum(s for s, _ in files)/1024/1024:.2f} MB")
print("Top 30 files:")
for size, path in files[:30]:
    print(f"{size / 1024 / 1024:6.2f} MB : {path}")
