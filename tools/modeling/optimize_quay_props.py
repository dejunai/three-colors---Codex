"""Build game-ready quay props from the root-level Meshy remesh exports.

Runs in Blender 5.2 headless. Source files remain untouched. Output assets use
stable names, bottom-center pivots, and at most 2K textures for the Web target.
"""

from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "assets" / "models" / "waterfront"
TEXTURES = ROOT / ".runtime-data" / "modeling" / "quay_textures"
OUTPUT.mkdir(parents=True, exist_ok=True)
TEXTURES.mkdir(parents=True, exist_ok=True)

SOURCES = {
    "boat_frame": "Meshy_AI_boat_frame_remesh_0921154314_texture.glb",
    "cargo_cluster": "Meshy_AI_crates_barrels_remesh_0921154303_texture.glb",
    "dock_crane": "Meshy_AI_dock_crane_remesh_0921154307_texture.glb",
    "dock_shed": "Meshy_AI_dock_shed_remesh_0921154257_texture.glb",
    "fishing_boat": "Meshy_AI_fishing_boat_remesh_0921154310_texture.glb",
}


def reset() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def cap_texture(image: bpy.types.Image, slug: str) -> None:
    width, height = image.size
    if max(width, height) > 2048:
        ratio = 2048.0 / float(max(width, height))
        image.scale(max(1, round(width * ratio)), max(1, round(height * ratio)))
    role = "metallic_roughness" if "metallic" in image.name.lower() or "roughness" in image.name.lower() else "base_color"
    # The GLB owns the asset prefix; keeping the embedded filename role-only
    # lets Godot extract `dock_crane_base_color.jpg` instead of duplicating it.
    path = TEXTURES / f"{role}.jpg"
    # Godot prefixes extracted embedded textures with the GLB filename, so a
    # role-only image name produces e.g. fishing_boat_base_color.jpg instead
    # of repeating the asset slug twice.
    image.name = role
    image.filepath_raw = str(path)
    image.file_format = "JPEG"
    image.save()


def join_and_ground(slug: str) -> bpy.types.Object:
    meshes = [obj for obj in bpy.data.objects if obj.type == "MESH"]
    if not meshes:
        raise RuntimeError(f"{slug}: no mesh found")
    bpy.ops.object.select_all(action="DESELECT")
    for mesh in meshes:
        mesh.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    mesh = bpy.context.view_layer.objects.active
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    low = Vector((min(v.co.x for v in mesh.data.vertices), min(v.co.y for v in mesh.data.vertices), min(v.co.z for v in mesh.data.vertices)))
    high = Vector((max(v.co.x for v in mesh.data.vertices), max(v.co.y for v in mesh.data.vertices), max(v.co.z for v in mesh.data.vertices)))
    offset = Vector((-(low.x + high.x) * 0.5, -(low.y + high.y) * 0.5, -low.z))
    for vertex in mesh.data.vertices:
        vertex.co += offset
    mesh.name = slug
    mesh.data.name = f"{slug}_mesh"
    return mesh


def build(slug: str, filename: str) -> None:
    source = ROOT / filename
    if not source.exists():
        raise FileNotFoundError(source)
    reset()
    bpy.ops.import_scene.gltf(filepath=str(source))
    mesh = join_and_ground(slug)
    for image in list(bpy.data.images):
        if image.size[0] > 0:
            cap_texture(image, slug)
    bpy.ops.object.select_all(action="DESELECT")
    mesh.select_set(True)
    bpy.context.view_layer.objects.active = mesh
    output = OUTPUT / f"{slug}.glb"
    bpy.ops.export_scene.gltf(
        filepath=str(output),
        export_format="GLB",
        use_selection=True,
        export_animations=False,
        export_yup=True,
    )
    print(f"BUILT {slug}: {output.stat().st_size} bytes")


if __name__ == "__main__":
    for asset_slug, source_filename in SOURCES.items():
        build(asset_slug, source_filename)
