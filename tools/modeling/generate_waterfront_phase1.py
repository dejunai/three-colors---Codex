"""Build the bounded Phase 1 waterfront art slice.

Run with Blender, not system Python:
  blender --background --python tools/modeling/generate_waterfront_phase1.py

The generated GLB is visual-only. Godot's existing waterfront primitives retain
collision, route, schedule and interaction authority.
"""

from __future__ import annotations

import math
import random
from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parents[2]
MODEL_DIR = ROOT / "assets" / "models"
MODEL_DIR.mkdir(parents=True, exist_ok=True)
ATLAS_PATH = MODEL_DIR / "waterfront_phase1_atlas.png"
GLB_PATH = MODEL_DIR / "waterfront_phase1.glb"

TILES = {
    "stone": (0, 1), "timber": (1, 1), "paint": (2, 1), "slate": (3, 1),
    "tar": (0, 0), "metal": (1, 0), "glass": (2, 0), "rope": (3, 0),
}
COLORS = {
    "stone": (0.25, 0.31, 0.28), "timber": (0.32, 0.25, 0.17),
    "paint": (0.34, 0.39, 0.34), "slate": (0.10, 0.16, 0.17),
    "tar": (0.035, 0.045, 0.045), "metal": (0.19, 0.20, 0.17),
    "glass": (0.20, 0.34, 0.34), "rope": (0.45, 0.39, 0.25),
}


def reset() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for blocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.images):
        for block in list(blocks):
            blocks.remove(block)


def make_atlas() -> bpy.types.Image:
    size = 512
    image = bpy.data.images.new("WaterfrontPhase1Atlas", width=size, height=size, alpha=True)
    random.seed(1924)
    pixels = [0.0] * (size * size * 4)
    for tile, (column, row) in TILES.items():
        base = COLORS[tile]
        for y in range(row * 256, (row + 1) * 256):
            for x in range(column * 128, (column + 1) * 128):
                lx, ly = x % 128, y % 256
                noise = random.uniform(-0.035, 0.035)
                detail = 0.0
                if tile == "stone":
                    detail = -0.16 if ly % 42 < 3 or (lx + (21 if (ly // 42) % 2 else 0)) % 42 < 3 else 0.0
                elif tile in ("timber", "tar"):
                    detail = 0.035 * math.sin(lx * 0.32 + math.sin(ly * 0.06))
                    if lx % 32 < 2: detail -= 0.13
                elif tile == "paint":
                    detail = 0.02 * math.sin((lx + ly) * 0.17)
                    if (lx * 3 + ly) % 79 < 2: detail -= 0.10
                elif tile == "slate":
                    detail = -0.12 if ly % 28 < 2 or (lx + (14 if (ly // 28) % 2 else 0)) % 28 < 2 else 0.0
                elif tile == "metal" and random.random() < 0.08:
                    detail -= random.uniform(0.10, 0.24)
                elif tile == "rope":
                    detail = 0.05 * math.sin((lx + ly * 2) * 0.38)
                index = (y * size + x) * 4
                for channel in range(3):
                    pixels[index + channel] = max(0.01, min(1.0, base[channel] + noise + detail))
                pixels[index + 3] = 1.0
    image.pixels.foreach_set(pixels)
    image.filepath_raw = str(ATLAS_PATH)
    image.file_format = "PNG"
    image.save()
    return image


def material(image: bpy.types.Image) -> bpy.types.Material:
    result = bpy.data.materials.new("WaterfrontAtlas")
    result.use_nodes = True
    nodes = result.node_tree.nodes
    principled = nodes.get("Principled BSDF")
    principled.inputs["Roughness"].default_value = 0.91
    texture = nodes.new("ShaderNodeTexImage")
    texture.image = image
    result.node_tree.links.new(texture.outputs["Color"], principled.inputs["Base Color"])
    return result


def remap_uv(obj: bpy.types.Object, tile: str) -> None:
    if not obj.data.uv_layers:
        return
    column, row = TILES[tile]
    for loop in obj.data.uv_layers.active.data:
        loop.uv.x = column / 4.0 + (loop.uv.x % 1.0) * 0.245
        loop.uv.y = row / 2.0 + (loop.uv.y % 1.0) * 0.49


def bevel(obj: bpy.types.Object, width: float = 0.025) -> None:
    modifier = obj.modifiers.new("Worn edges", "BEVEL")
    modifier.width = width
    modifier.segments = 1
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=modifier.name)


def empty(name: str, parent=None) -> bpy.types.Object:
    obj = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(obj)
    obj.parent = parent
    return obj


def cube(name, godot_location, size, tile, mat, parent, rotation=(0.0, 0.0, 0.0), soften=0.025):
    x, y, z = godot_location
    bpy.ops.mesh.primitive_cube_add(location=(x, -z, y), rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.scale = (size[0] / 2.0, size[2] / 2.0, size[1] / 2.0)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if soften:
        bevel(obj, soften)
    obj.data.materials.append(mat)
    remap_uv(obj, tile)
    obj.parent = parent
    return obj


def cylinder(name, godot_location, radius, height, tile, mat, parent, vertices=12, rotation=(0.0, 0.0, 0.0)):
    x, y, z = godot_location
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=height, location=(x, -z, y), rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    bevel(obj, min(0.025, radius * 0.12))
    obj.data.materials.append(mat)
    remap_uv(obj, tile)
    obj.parent = parent
    return obj


def roof(name, x, z, width, depth, eave, rise, tile, mat, parent):
    for side in (-1, 1):
        slab = cube(
            f"{name}_{'L' if side < 0 else 'R'}", (x + side * width * 0.245, eave + rise * 0.5, z),
            (width * 0.56, 0.22, depth + 0.7), tile, mat, parent,
            rotation=(0.0, side * math.atan2(rise, width * 0.5), 0.0), soften=0.018,
        )
        slab.rotation_mode = "XYZ"


def facade(name, x, width, depth, height, tile, mat, parent, upper=False):
    z = 17.0
    cube(f"{name}_Shell", (x, height / 2.0, z), (width, height, depth), tile, mat, parent, soften=0.045)
    roof(f"{name}_Roof", x, z, width + 0.7, depth, height + 0.05, 1.55 if upper else 1.2, "slate", mat, parent)
    cube(f"{name}_Foundation", (x, 0.42, z - depth * 0.5 - 0.08), (width + 0.2, 0.84, 0.22), "stone", mat, parent)
    cube(f"{name}_Door", (x, 1.45, z - depth * 0.5 - 0.14), (1.55, 2.9, 0.25), "tar", mat, parent)
    cube(f"{name}_Lintel", (x, 3.05, z - depth * 0.5 - 0.18), (1.95, 0.24, 0.34), "stone", mat, parent)
    for index, dx in enumerate((-3.5, 3.5)):
        cube(f"{name}_Window{index}", (x + dx, 2.55, z - depth * 0.5 - 0.16), (2.05, 1.65, 0.22), "glass", mat, parent)
        for bar in (-0.67, 0.0, 0.67):
            cube(f"{name}_Window{index}_Mullion{bar}", (x + dx + bar, 2.55, z - depth * 0.5 - 0.31), (0.08, 1.82, 0.09), "timber", mat, parent, soften=0.008)
        cube(f"{name}_Window{index}_Rail", (x + dx, 2.55, z - depth * 0.5 - 0.32), (2.2, 0.09, 0.09), "timber", mat, parent, soften=0.008)
    # Uneven structural braces make the frontage read as authored timberwork.
    for side in (-1, 1):
        brace = cube(f"{name}_Brace{side}", (x + side * (width * 0.5 - 0.55), height * 0.55, z - depth * 0.5 - 0.22), (0.18, height * 0.72, 0.18), "timber", mat, parent, soften=0.01)
        brace.rotation_euler.y = side * math.radians(10)
    if upper:
        for dx in (-2.7, 2.7):
            cube(f"{name}_UpperWindow{dx}", (x + dx, 5.25, z - depth * 0.5 - 0.16), (1.35, 1.35, 0.22), "glass", mat, parent)
    cube(f"{name}_Signboard", (x, 4.25, z - depth * 0.5 - 0.42), (4.7, 0.75, 0.16), "timber", mat, parent)


def boat(mat, parent):
    boat_root = empty("FishingBoat", parent)
    boat_root.rotation_euler.z = math.radians(-3.5)
    # Stepped low-poly hull: readable from the quay without implying boarding.
    cube("BoatHullKeel", (3, -0.75, -18), (2.1, 0.55, 6.8), "tar", mat, boat_root, soften=0.18)
    cube("BoatHullUpper", (3, -0.38, -18), (3.15, 0.42, 5.9), "paint", mat, boat_root, soften=0.20)
    cube("BoatGunwalePort", (1.42, -0.08, -18), (0.16, 0.22, 6.0), "timber", mat, boat_root)
    cube("BoatGunwaleStarboard", (4.58, -0.08, -18), (0.16, 0.22, 6.0), "timber", mat, boat_root)
    cube("BoatCabin", (3, 0.42, -19), (1.7, 1.05, 1.75), "timber", mat, boat_root)
    cube("BoatCabinWindow", (3, 0.55, -18.08), (1.2, 0.45, 0.10), "glass", mat, boat_root)
    cylinder("BoatMast", (3, 2.0, -16.9), 0.09, 4.6, "timber", mat, boat_root, 12)
    cube("BoatBoom", (3, 2.55, -18.1), (0.10, 0.10, 2.55), "timber", mat, boat_root)
    for offset in (-1.0, 1.0):
        cylinder(f"BoatFender{offset}", (3 + offset * 1.65, -0.05, -18.8), 0.16, 0.75, "rope", mat, boat_root, 10)


def props(mat, parent):
    for x in (-27, -15, -3, 9, 21, 29):
        cylinder(f"Bollard{x}", (x, 0.5, -10.5), 0.23, 1.0, "metal", mat, parent, 12)
        cube(f"BollardCap{x}", (x, 0.92, -10.5), (0.9, 0.14, 0.28), "metal", mat, parent)
    for index, (x, z, scale) in enumerate(((18, -3, 1.0), (20, -3, 0.85), (22, -3, 1.1), (-10, 1, 0.8), (-12, 2, 0.65))):
        cube(f"Crate{index}", (x, 0.42 * scale, z), (1.5 * scale, 0.84 * scale, 1.15 * scale), "timber", mat, parent)
        for band in (-0.48, 0.48):
            cube(f"Crate{index}_Band{band}", (x + band * scale, 0.43 * scale, z - 0.59 * scale), (0.09, 0.72 * scale, 0.05), "metal", mat, parent, soften=0.005)
    for index, (x, z) in enumerate(((-24, 0), (-21.5, 0), (25, 1))):
        cylinder(f"Barrel{index}", (x, 0.48, z), 0.38, 0.95, "timber", mat, parent, 12)
        for y in (0.18, 0.77):
            cylinder(f"Barrel{index}_Hoop{y}", (x, y, z), 0.395, 0.055, "metal", mat, parent, 12)
    # Drying-net frame: thick enough to remain legible through Chapter One grading.
    for x in (-25, -21):
        cylinder(f"NetPole{x}", (x, 1.5, 0), 0.08, 3.0, "timber", mat, parent, 10)
    for row, y in enumerate((0.75, 1.05, 1.35, 1.65, 1.95, 2.25)):
        cube(f"NetHorizontal{row}", (-23, y, 0), (4.0, 0.035, 0.04), "rope", mat, parent, soften=0.004)
    for column, x in enumerate((-24.6, -23.8, -23.0, -22.2, -21.4)):
        cube(f"NetVertical{column}", (x, 1.5, 0), (0.035, 1.55, 0.04), "rope", mat, parent, soften=0.004)


def build() -> None:
    reset()
    atlas = make_atlas()
    mat = material(atlas)
    root = empty("WaterfrontPhase1")
    quay = empty("QuayAndSeawall", root)
    buildings = empty("WorkingFrontage", root)
    boat_group = empty("BoatAndMoorings", root)
    prop_group = empty("WorkingProps", root)

    cube("QuayFoundation", (0, -0.46, 8), (64, 0.92, 42), "stone", mat, quay, soften=0.05)
    cube("WaterSurface", (0, -1.35, -53), (190, 0.12, 92), "glass", mat, quay, soften=0.0)
    cube("Seawall", (0, -0.25, -12), (64, 2.25, 1.6), "stone", mat, quay, soften=0.04)
    cube("MooringApron", (0, 0.035, -8), (61, 0.11, 6.0), "timber", mat, quay, soften=0.01)
    for x in range(-29, 30, 2):
        cube(f"ApronSeam{x}", (x, 0.098, -8), (0.035, 0.018, 5.95), "tar", mat, quay, soften=0.002)
    for x in range(-30, 31, 3):
        cube(f"SeawallCap{x}", (x, 0.87, -12), (2.88, 0.24, 1.82), "stone", mat, quay, soften=0.035)

    facade("Chandlery", -22, 12, 9, 6.2, "timber", mat, buildings, upper=True)
    facade("FreightOffice", -7, 12, 9, 5.8, "stone", mat, buildings)
    facade("NetLoft", 8, 12, 9, 6.5, "paint", mat, buildings, upper=True)
    facade("FishStores", 23, 12, 9, 5.9, "stone", mat, buildings)
    cylinder("ChandleryChimney", (-25.5, 8.0, 18.2), 0.35, 3.1, "stone", mat, buildings, 12)
    cylinder("FishStoreVent", (26.5, 7.4, 17), 0.25, 2.2, "metal", mat, buildings, 12)

    boat(mat, boat_group)
    props(mat, prop_group)

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(
        filepath=str(GLB_PATH), export_format="GLB", use_selection=True,
        export_apply=True, export_yup=True, export_materials="EXPORT",
    )
    triangles = sum(len(obj.data.loop_triangles) for obj in bpy.data.objects if obj.type == "MESH" for _ in [obj.data.calc_loop_triangles()])
    print(f"Generated {GLB_PATH} with {triangles} triangles")


if __name__ == "__main__":
    build()
