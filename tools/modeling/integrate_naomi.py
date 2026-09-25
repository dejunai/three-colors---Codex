from __future__ import annotations

import os
from pathlib import Path
import math
import mathutils
import bpy

ROOT = Path(__file__).resolve().parents[2]
ASSETS_DIR = ROOT / "assets" / "models"
ASSETS_DIR.mkdir(parents=True, exist_ok=True)
ARCHIVE_DIR = ROOT / "archive"
ARCHIVE_DIR.mkdir(parents=True, exist_ok=True)

SOURCE_NAME = "Meshy_Naomi_and_Son-textured.glb"
TARGET_NAME = "covered_body.glb"


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


def process_covered_body() -> None:
    reset()
    src_path = ROOT / SOURCE_NAME
    if not src_path.exists():
        src_path = ARCHIVE_DIR / SOURCE_NAME
    if not src_path.exists():
        raise FileNotFoundError(f"Source file not found: {src_path}")

    print(f"Importing {src_path}...")
    bpy.ops.import_scene.gltf(filepath=str(src_path))

    mesh_objs = [o for o in bpy.data.objects if o.type == "MESH"]
    if not mesh_objs:
        raise RuntimeError("No mesh object found in GLB")
    obj = mesh_objs[0]
    mesh = obj.data

    # Downsample textures to 1024x1024
    for img in bpy.data.images:
        print(f"Image {img.name}: {img.size[0]}x{img.size[1]}")
        if img.size[0] > 1024 or img.size[1] > 1024:
            print(f"Scaling {img.name} to 1024x1024")
            img.scale(1024, 1024)

    # Ground the mesh (min Z = 0)
    min_z = min(v.co.z for v in mesh.vertices)
    for v in mesh.vertices:
        v.co.z -= min_z

    # Rotate -90 degrees around Z axis so Head (-X) goes to +Y (glTF -Z / forward in Godot)
    rot = mathutils.Matrix.Rotation(-math.pi / 2, 4, "Z")
    mesh.transform(rot)

    # Center horizontally on X and Y
    min_x = min(v.co.x for v in mesh.vertices)
    max_x = max(v.co.x for v in mesh.vertices)
    min_y = min(v.co.y for v in mesh.vertices)
    max_y = max(v.co.y for v in mesh.vertices)
    center_x = (min_x + max_x) / 2.0
    center_y = (min_y + max_y) / 2.0

    for v in mesh.vertices:
        v.co.x -= center_x
        v.co.y -= center_y

    obj.name = "CoveredBodyMesh"
    mesh.name = "CoveredBodyMesh"

    root = bpy.data.objects.new("CoveredBody", None)
    root.empty_display_type = "PLAIN_AXES"
    bpy.context.collection.objects.link(root)
    obj.parent = root

    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = root

    out_path = ASSETS_DIR / TARGET_NAME
    print(f"Exporting to {out_path}...")
    bpy.ops.export_scene.gltf(
        filepath=str(out_path),
        export_format="GLB",
        use_selection=True,
        export_animations=False,
        export_morph=False,
        export_yup=True,
    )
    size_mb = out_path.stat().st_size / (1024 * 1024)
    print(f"Export complete: {out_path.name} ({size_mb:.2f} MB)")


if __name__ == "__main__":
    process_covered_body()
