"""Batch optimize all character and quay textures to strictly conform to 1K limit (max 1024x1024, props/roughness 512x512).
"""
import os
from PIL import Image

def resize_image(path: str, max_dim: int, quality: int = 88) -> None:
    if not os.path.exists(path):
        print(f"Warning: {path} not found")
        return
    orig_sz = os.path.getsize(path)
    with Image.open(path) as img:
        w, h = img.size
        if w <= max_dim and h <= max_dim:
            print(f"Already within bounds: {path} ({w}x{h})")
            return
        
        # Calculate new dimensions maintaining aspect ratio
        if w >= h:
            new_w = max_dim
            new_h = int(round(h * (max_dim / w)))
        else:
            new_h = max_dim
            new_w = int(round(w * (max_dim / h)))
        
        print(f"Resizing {path}: ({w}x{h}) -> ({new_w}x{new_h})...")
        resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
        
        fmt = img.format if img.format else ("PNG" if path.lower().endswith(".png") else "JPEG")
        if fmt == "JPEG":
            resized.convert("RGB").save(path, "JPEG", quality=quality, optimize=True)
        elif fmt == "PNG":
            resized.save(path, "PNG", optimize=True)
        else:
            resized.save(path)
            
    new_sz = os.path.getsize(path)
    print(f"  {orig_sz/1024/1024:.2f} MB -> {new_sz/1024/1024:.2f} MB")

def main():
    # 1. Custom NPC textures (2K -> 1K)
    npc_textures_1k = [
        "assets/models/coroner_texture_0.png",
        "assets/models/father_behan_texture_0.png",
        "assets/models/gatekeeper_boy_texture_0.png",
        "assets/models/steward_texture_0.png",
        "assets/models/captain_odell_Image_0.jpg",
        "assets/models/captain_odell_Image_1.jpg",
        "assets/models/captain_odell_Image_2.jpg",
        "assets/models/walter_phase1_walter_plain_remesh.jpg",
        "assets/models/walter_phase1_walter_police_remesh.jpg",
    ]
    for p in npc_textures_1k:
        resize_image(p, 1024)

    # 2. Waterfront Quay base color (2K -> 1K)
    waterfront_base_1k = [
        "assets/models/waterfront/boat_frame_base_color.jpg",
        "assets/models/waterfront/cargo_cluster_base_color.jpg",
        "assets/models/waterfront/dock_crane_base_color.jpg",
        "assets/models/waterfront/dock_shed_base_color.jpg",
        "assets/models/waterfront/fishing_boat_base_color.jpg",
    ]
    for p in waterfront_base_1k:
        resize_image(p, 1024)

    # 3. Waterfront Quay metallic roughness (2K -> 512)
    waterfront_mr_512 = [
        "assets/models/waterfront/boat_frame_metallic_roughness.jpg",
        "assets/models/waterfront/cargo_cluster_metallic_roughness.jpg",
        "assets/models/waterfront/dock_crane_metallic_roughness.jpg",
        "assets/models/waterfront/dock_shed_metallic_roughness.jpg",
        "assets/models/waterfront/fishing_boat_metallic_roughness.jpg",
    ]
    for p in waterfront_mr_512:
        resize_image(p, 512)

    # 4. Cast and victim metallic roughness (1K -> 512)
    mr_maps_512 = [
        "assets/models/cast_lower_man_texture_0_metallic_roughness.png",
        "assets/models/cast_lower_woman_texture_0_metallic_roughness.png",
        "assets/models/cast_observer_man_texture_0_metallic_roughness.png",
        "assets/models/cast_observer_woman_texture_0_metallic_roughness.png",
        "assets/models/cast_upper_man_texture_0_metallic_roughness.png",
        "assets/models/cast_upper_woman_texture_0_metallic_roughness.png",
        "assets/models/covered_body_texture_0_metallic_roughness.png",
        "assets/models/murder_victim_texture_0_metallic_roughness.png",
    ]
    for p in mr_maps_512:
        resize_image(p, 512)

    print("\nTexture optimization completed successfully.")

if __name__ == "__main__":
    main()
