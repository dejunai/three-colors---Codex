"""Batch extraction and optimization for 6 cast placeholder character models.

Runs in Blender 5.2 headless:
  & 'C:\\Program Files\\Blender Foundation\\Blender 5.2\\blender.exe' --background --python tools/modeling/integrate_cast_placeholders.py
"""

from __future__ import annotations

import os
from pathlib import Path
import bpy

ROOT = Path(__file__).resolve().parents[2]
MODEL_DIR = ROOT / "assets" / "models"
MODEL_DIR.mkdir(parents=True, exist_ok=True)
ARCHIVE_DIR = ROOT / "archive"

MODELS = [
    ("Meshy_1923_Business_Man-textured.glb", "cast_upper_man.glb", "CastUpperMan"),
    ("Meshy_1923_Upper_Class_Woman-textured.glb", "cast_upper_woman.glb", "CastUpperWoman"),
    ("Meshy_1923_Lower_Class_Man-textured.glb", "cast_lower_man.glb", "CastLowerMan"),
    ("Meshy_1923_Lower_Class_Woman-textured.glb", "cast_lower_woman.glb", "CastLowerWoman"),
    ("Meshy_Observer_Man-textured.glb", "cast_observer_man.glb", "CastObserverMan"),
    ("Meshy_Observer_Woman-textured.glb", "cast_observer_woman.glb", "CastObserverWoman"),
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


def process_model(src_filename: str, out_filename: str, node_name: str) -> None:
    reset()
    src_path = ARCHIVE_DIR / src_filename
    if not src_path.exists():
        src_path = ROOT / src_filename
    out_path = MODEL_DIR / out_filename

    print(f"\n--- Processing {src_filename} -> {out_filename} ---")
    bpy.ops.import_scene.gltf(filepath=str(src_path))

    for o in list(bpy.data.objects):
        if "Icosphere" in o.name:
            bpy.data.objects.remove(o, do_unlink=True)

    mesh_objs = [o for o in bpy.data.objects if o.type == "MESH"]
    if not mesh_objs:
        print(f"ERROR: No mesh found in {src_filename}")
        return
    mesh_obj = mesh_objs[0]

    # Downsample textures to 1024x1024 to keep package lightweight
    for img in bpy.data.images:
        if img.size[0] > 1024 or img.size[1] > 1024:
            img.scale(1024, 1024)

    # Horizontal centering and ground soles at Z=0
    verts = mesh_obj.data.vertices
    min_x = min((mesh_obj.matrix_world @ v.co).x for v in verts)
    max_x = max((mesh_obj.matrix_world @ v.co).x for v in verts)
    min_y = min((mesh_obj.matrix_world @ v.co).y for v in verts)
    max_y = max((mesh_obj.matrix_world @ v.co).y for v in verts)
    min_z = min((mesh_obj.matrix_world @ v.co).z for v in verts)
    max_z = max((mesh_obj.matrix_world @ v.co).z for v in verts)

    center_x = (min_x + max_x) / 2.0
    center_y = (min_y + max_y) / 2.0
    height = max_z - min_z

    mesh_obj.location.x -= center_x
    mesh_obj.location.y -= center_y
    mesh_obj.location.z -= min_z

    mesh_obj.name = node_name + "Mesh"
    mesh_obj.data.name = node_name + "Mesh"

    # Build root Empty node
    root = bpy.data.objects.new(node_name, None)
    root.empty_display_type = "PLAIN_AXES"
    bpy.context.collection.objects.link(root)
    mesh_obj.parent = root

    print(f"{node_name}: height={height:.3f}m, grounded at Z=0, centered at (0,0)")

    # Export
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    mesh_obj.select_set(True)
    for child in root.children_recursive:
        child.select_set(True)

    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(
        filepath=str(out_path),
        export_format="GLB",
        use_selection=True,
        export_animations=False,
        export_morph=False,
        export_yup=True,
    )
    out_size = os.path.getsize(out_path)
    print(f"Successfully exported {out_path} ({out_size:,} bytes, {out_size / 1024 / 1024:.2f} MB)")


def main() -> None:
    for src, out, name in MODELS:
        process_model(src, out, name)
    print("\nAll 6 cast models extracted and optimized successfully.")


if __name__ == "__main__":
    main()
