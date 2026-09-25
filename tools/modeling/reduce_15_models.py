from __future__ import annotations

import os
from pathlib import Path
import bpy

ROOT = Path(__file__).resolve().parents[2]
MODELS_DIR = ROOT / "assets" / "models"
EXTERIORS_DIR = MODELS_DIR / "exteriors"
PROPS_DIR = MODELS_DIR / "props"
ARCHIVE_DIR = ROOT / "archive"

EXTERIORS_DIR.mkdir(parents=True, exist_ok=True)
PROPS_DIR.mkdir(parents=True, exist_ok=True)
ARCHIVE_DIR.mkdir(parents=True, exist_ok=True)

MODELS = [
    # 12 Exteriors
    ("Meshy_AI_estate_house_textured_0921204825_texture.glb", EXTERIORS_DIR / "estate_house.glb", "EstateHouse"),
    ("Meshy_AI_pickman_house_1_textu_0921204733_texture.glb", EXTERIORS_DIR / "pickman_house_1.glb", "PickmanHouse1"),
    ("Meshy_AI_pickman_house_2_textu_0921204805_texture.glb", EXTERIORS_DIR / "pickman_house_2.glb", "PickmanHouse2"),
    ("Meshy_AI_pickman_house_3_textu_0921204716_texture.glb", EXTERIORS_DIR / "pickman_house_3.glb", "PickmanHouse3"),
    ("Meshy_AI_police_precinct_textu_0921204810_texture.glb", EXTERIORS_DIR / "police_precinct.glb", "PolicePrecinct"),
    ("Meshy_AI_schoolhouse_textured_0921204759_texture.glb", EXTERIORS_DIR / "schoolhouse.glb", "Schoolhouse"),
    ("Meshy_AI_storefront_1_textured_0921204754_texture.glb", EXTERIORS_DIR / "storefront_1.glb", "Storefront1"),
    ("Meshy_AI_storefront_2_textured_0921204722_texture.glb", EXTERIORS_DIR / "storefront_2.glb", "Storefront2"),
    ("Meshy_AI_storefront_3_textured_0921204819_texture.glb", EXTERIORS_DIR / "storefront_3.glb", "Storefront3"),
    ("Meshy_AI_upper_house_1_texture_0921204739_texture.glb", EXTERIORS_DIR / "upper_house_1.glb", "UpperHouse1"),
    ("Meshy_AI_upper_house_2_texture_0921204726_texture.glb", EXTERIORS_DIR / "upper_house_2.glb", "UpperHouse2"),
    ("Meshy_AI_upper_house_3_texture_0921204814_texture.glb", EXTERIORS_DIR / "upper_house_3.glb", "UpperHouse3"),
    # 3 Props
    ("Meshy_AI_prop_fence_gate_textu_0921204748_texture.glb", PROPS_DIR / "prop_fence_gate.glb", "PropFenceGate"),
    ("Meshy_AI_prop_hedge_textured_0921204830_texture.glb", PROPS_DIR / "prop_hedge.glb", "PropHedge"),
    ("Meshy_AI_prop_tree_bush_textur_0921204802_texture.glb", PROPS_DIR / "prop_tree_bush.glb", "PropTreeBush"),
]


def reset() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (
        bpy.data.meshes,
        bpy.data.curves,
        bpy.data.armatures,
        bpy.data.materials,
        bpy.data.images,
        bpy.data.actions,
    ):
        for block in list(datablocks):
            datablocks.remove(block)


def process_model(src_filename: str, out_path: Path, node_name: str, max_tex_size: int = 1024) -> None:
    reset()
    src_path = ROOT / src_filename
    if not src_path.exists():
        src_path = ARCHIVE_DIR / src_filename
    if not src_path.exists():
        print(f"WARNING: {src_filename} not found in root or archive, skipping.")
        return

    print(f"\nProcessing {src_filename} -> {out_path.name}...")
    bpy.ops.import_scene.gltf(filepath=str(src_path))

    # Downscale all textures to 1024x1024
    for img in bpy.data.images:
        w, h = img.size
        if w > max_tex_size or h > max_tex_size:
            print(f"  Scaling {img.name} from {w}x{h} to {max_tex_size}x{max_tex_size}")
            img.scale(max_tex_size, max_tex_size)

    mesh_objs = [o for o in bpy.data.objects if o.type == "MESH"]
    if not mesh_objs:
        print(f"ERROR: No mesh found in {src_filename}")
        return

    # Center horizontally and ground base at Z=0
    all_verts = []
    for obj in mesh_objs:
        all_verts.extend(v.co for v in obj.data.vertices)

    min_z = min(co.z for co in all_verts)
    min_x = min(co.x for co in all_verts)
    max_x = max(co.x for co in all_verts)
    min_y = min(co.y for co in all_verts)
    max_y = max(co.y for co in all_verts)
    center_x = (min_x + max_x) / 2.0
    center_y = (min_y + max_y) / 2.0

    for obj in mesh_objs:
        for v in obj.data.vertices:
            v.co.x -= center_x
            v.co.y -= center_y
            v.co.z -= min_z
        obj.name = f"{node_name}Mesh"
        obj.data.name = f"{node_name}Mesh"

    root = bpy.data.objects.new(node_name, None)
    root.empty_display_type = "PLAIN_AXES"
    bpy.context.collection.objects.link(root)
    for obj in mesh_objs:
        obj.parent = root

    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for obj in mesh_objs:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = root

    print(f"  Exporting to {out_path}...")
    bpy.ops.export_scene.gltf(
        filepath=str(out_path),
        export_format="GLB",
        use_selection=True,
        export_animations=False,
        export_morph=False,
        export_yup=True,
    )
    sz_mb = out_path.stat().st_size / (1024 * 1024)
    print(f"  Completed: {out_path.name} ({sz_mb:.2f} MB)")


def main() -> None:
    for src, out, name in MODELS:
        process_model(src, out, name, max_tex_size=1024)

    print("\n--- Texture reduction complete for all 15 models! ---")


if __name__ == "__main__":
    main()
