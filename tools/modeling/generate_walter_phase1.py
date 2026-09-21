"""Build Walter's first rendered model and animation library.

Run with Blender, not system Python:
  blender --background --python tools/modeling/generate_walter_phase1.py

The file is intentionally procedural so the committed GLB can be reproduced
without depending on an undocumented local .blend file.
"""

from __future__ import annotations

import math
import random
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
MODEL_DIR = ROOT / "assets" / "models"
MODEL_DIR.mkdir(parents=True, exist_ok=True)
ATLAS_PATH = MODEL_DIR / "walter_phase1_atlas.png"
GLB_PATH = MODEL_DIR / "walter_phase1.glb"

TILES = {
    "police": (0, 1),
    "plain": (1, 1),
    "trouser": (2, 1),
    "leather": (3, 1),
    "skin": (0, 0),
    "shirt": (1, 0),
    "brass": (2, 0),
    "dark": (3, 0),
}

COLORS = {
    "police": (0.075, 0.105, 0.14),
    "plain": (0.25, 0.225, 0.175),
    "trouser": (0.09, 0.105, 0.11),
    "leather": (0.055, 0.04, 0.032),
    "skin": (0.56, 0.43, 0.34),
    "shirt": (0.69, 0.68, 0.60),
    "brass": (0.55, 0.42, 0.13),
    "dark": (0.035, 0.04, 0.045),
}


def reset() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.armatures, bpy.data.materials, bpy.data.images):
        for block in list(datablocks):
            datablocks.remove(block)


def make_atlas() -> bpy.types.Image:
    size = 512
    image = bpy.data.images.new("WalterPhase1Atlas", width=size, height=size, alpha=True)
    random.seed(1924)
    pixels = [0.0] * (size * size * 4)
    for tile_name, (column, row) in TILES.items():
        base = COLORS[tile_name]
        for y in range(row * 256, (row + 1) * 256):
            for x in range(column * 128, (column + 1) * 128):
                local_x = x - column * 128
                local_y = y - row * 256
                noise = random.uniform(-0.035, 0.035)
                weave = (0.014 if local_x % 7 == 0 else 0.0) + (0.01 if local_y % 11 == 0 else 0.0)
                if tile_name in ("leather", "brass", "skin"):
                    weave *= 0.25
                index = (y * size + x) * 4
                for channel in range(3):
                    pixels[index + channel] = max(0.0, min(1.0, base[channel] + noise + weave))
                pixels[index + 3] = 1.0
    image.pixels.foreach_set(pixels)
    image.filepath_raw = str(ATLAS_PATH)
    image.file_format = "PNG"
    image.save()
    return image


def atlas_material(image: bpy.types.Image) -> bpy.types.Material:
    material = bpy.data.materials.new("WalterAtlas")
    material.use_nodes = True
    material.diffuse_color = (0.25, 0.25, 0.25, 1.0)
    nodes = material.node_tree.nodes
    principled = nodes.get("Principled BSDF")
    principled.inputs["Roughness"].default_value = 0.86
    texture = nodes.new("ShaderNodeTexImage")
    texture.image = image
    texture.interpolation = "Linear"
    material.node_tree.links.new(texture.outputs["Color"], principled.inputs["Base Color"])
    return material


def remap_uv(obj: bpy.types.Object, tile: str) -> None:
    if not obj.data.uv_layers:
        return
    column, row = TILES[tile]
    layer = obj.data.uv_layers.active.data
    for loop in layer:
        loop.uv.x = column / 4.0 + (loop.uv.x % 1.0) * 0.245
        loop.uv.y = row / 2.0 + (loop.uv.y % 1.0) * 0.49


def bevel(obj: bpy.types.Object, width: float = 0.015, segments: int = 1) -> None:
    modifier = obj.modifiers.new("Edge softness", "BEVEL")
    modifier.width = width
    modifier.segments = segments
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=modifier.name)


def cube(name: str, location, scale, tile: str, material, soften: float = 0.012) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if soften > 0.0:
        bevel(obj, soften)
    obj.data.materials.append(material)
    remap_uv(obj, tile)
    return obj


def cylinder(name: str, location, radius: float, depth: float, tile: str, material, vertices: int = 12, radius_top: float | None = None) -> bpy.types.Object:
    if radius_top is None or abs(radius_top - radius) < 0.0001:
        bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location)
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius, radius2=radius_top, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    bevel(obj, min(0.012, radius * 0.08))
    obj.data.materials.append(material)
    remap_uv(obj, tile)
    return obj


def sphere(name: str, location, scale, tile: str, material, segments: int = 16, rings: int = 8) -> bpy.types.Object:
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    remap_uv(obj, tile)
    return obj


def create_armature() -> bpy.types.Object:
    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    armature = bpy.context.object
    armature.name = "WalterSkeleton"
    data = armature.data
    data.name = "WalterSkeleton"
    first = data.edit_bones[0]
    data.edit_bones.remove(first)

    def bone(name, head, tail, parent=None):
        item = data.edit_bones.new(name)
        item.head = head
        item.tail = tail
        if parent:
            item.parent = data.edit_bones[parent]
            item.use_connect = False
        return item

    bone("Root", (0, 0, 0.02), (0, 0, 0.18))
    bone("Pelvis", (0, 0, 0.78), (0, 0, 1.02), "Root")
    bone("Spine", (0, 0, 1.02), (0, 0, 1.34), "Pelvis")
    bone("Chest", (0, 0, 1.34), (0, 0, 1.57), "Spine")
    bone("Neck", (0, 0, 1.57), (0, 0, 1.70), "Chest")
    bone("Head", (0, 0, 1.70), (0, 0, 1.96), "Neck")
    for side, label in ((-1, "L"), (1, "R")):
        bone(f"Thigh.{label}", (side * 0.14, 0, 0.88), (side * 0.14, 0, 0.50), "Pelvis")
        bone(f"Shin.{label}", (side * 0.14, 0, 0.50), (side * 0.14, 0, 0.14), f"Thigh.{label}")
        bone(f"Foot.{label}", (side * 0.14, 0, 0.14), (side * 0.14, -0.24, 0.08), f"Shin.{label}")
        bone(f"UpperArm.{label}", (side * 0.32, 0, 1.49), (side * 0.32, 0, 1.16), "Chest")
        bone(f"Forearm.{label}", (side * 0.32, 0, 1.16), (side * 0.32, 0, 0.86), f"UpperArm.{label}")
        bone(f"Hand.{label}", (side * 0.32, 0, 0.86), (side * 0.32, -0.02, 0.70), f"Forearm.{label}")
    bpy.ops.object.mode_set(mode="OBJECT")
    return armature


def empty(name: str, parent: bpy.types.Object) -> bpy.types.Object:
    result = bpy.data.objects.new(name, None)
    result.empty_display_type = "PLAIN_AXES"
    result.parent = parent
    bpy.context.collection.objects.link(result)
    return result


def skin_rigid(obj: bpy.types.Object, armature: bpy.types.Object, bone: str, group: bpy.types.Object) -> None:
    world = obj.matrix_world.copy()
    # glTF requires the armature to be the direct parent of skinned meshes.
    # Outfit membership is retained in the authored mesh-name prefix so Godot
    # can toggle Police*/Plain*/Badge* geometry without breaking the skin.
    obj.parent = armature
    obj.matrix_world = world
    vertex_group = obj.vertex_groups.new(name=bone)
    vertex_group.add(range(len(obj.data.vertices)), 1.0, "REPLACE")
    modifier = obj.modifiers.new("WalterSkeleton", "ARMATURE")
    modifier.object = armature


def make_model(armature: bpy.types.Object, material: bpy.types.Material) -> bpy.types.Object:
    root = empty("WalterPhase1", armature)
    body = empty("Body", root)
    police = empty("PoliceCoat", root)
    plain = empty("PlainCoat", root)
    badge = empty("Badge", root)

    pieces: list[tuple[bpy.types.Object, str, bpy.types.Object]] = []

    def add(obj, bone, group=body):
        pieces.append((obj, bone, group))
        return obj

    # Head, features, shirt and tie.
    add(sphere("HeadMesh", (0, -0.005, 1.80), (0.155, 0.14, 0.19), "skin", material), "Head")
    add(cylinder("NeckMesh", (0, 0, 1.62), 0.09, 0.16, "skin", material, 12), "Neck")
    add(cube("Nose", (0, -0.142, 1.80), (0.035, 0.035, 0.045), "skin", material, 0.008), "Head")
    for side in (-1, 1):
        add(sphere(f"Ear.{side}", (side * 0.155, 0, 1.81), (0.028, 0.018, 0.045), "skin", material, 10, 5), "Head")
        add(cube(f"Brow.{side}", (side * 0.055, -0.132, 1.85), (0.045, 0.008, 0.009), "dark", material, 0.004), "Head")
    add(cube("Mouth", (0, -0.145, 1.745), (0.045, 0.006, 0.008), "dark", material, 0.003), "Head")
    add(sphere("HairCap", (0, 0.018, 1.88), (0.16, 0.14, 0.10), "dark", material, 16, 6), "Head")
    add(cylinder("HatBrim", (0, 0, 1.98), 0.265, 0.035, "dark", material, 16), "Head")
    hat_crown = add(cylinder("HatCrown", (0, 0.02, 2.055), 0.185, 0.14, "police", material, 12, 0.155), "Head")
    add(cube("HatBand", (0, -0.162, 2.025), (0.17, 0.018, 0.025), "leather", material, 0.006), "Head")

    add(cylinder("ShirtTorso", (0, 0, 1.30), 0.245, 0.62, "shirt", material, 10, 0.205), "Spine")
    add(cube("Tie", (0, -0.215, 1.37), (0.035, 0.018, 0.22), "dark", material, 0.006), "Chest")
    add(cube("Belt", (0, -0.005, 1.02), (0.285, 0.225, 0.045), "leather", material, 0.008), "Pelvis")
    add(cube("Buckle", (0, -0.235, 1.02), (0.045, 0.018, 0.035), "brass", material, 0.006), "Pelvis")

    # Trousers, boots and hands.
    for side, label in ((-1, "L"), (1, "R")):
        add(cylinder(f"ThighMesh.{label}", (side * 0.14, 0, 0.69), 0.12, 0.40, "trouser", material, 10, 0.105), f"Thigh.{label}")
        add(cylinder(f"ShinMesh.{label}", (side * 0.14, 0, 0.32), 0.095, 0.36, "trouser", material, 10, 0.085), f"Shin.{label}")
        add(cube(f"Boot.{label}", (side * 0.14, -0.055, 0.09), (0.115, 0.19, 0.085), "leather", material, 0.018), f"Foot.{label}")
        add(sphere(f"HandMesh.{label}", (side * 0.32, -0.01, 0.76), (0.075, 0.065, 0.10), "skin", material, 12, 6), f"Hand.{label}")

    # Two complete coat shells occupy the same rest pose; runtime shows one.
    for coat_group, tile, prefix in ((police, "police", "Police"), (plain, "plain", "Plain")):
        add(cylinder(f"{prefix}CoatTorso", (0, 0, 1.34), 0.31, 0.72, tile, material, 10, 0.245), "Spine", coat_group)
        add(cylinder(f"{prefix}CoatSkirt", (0, 0.025, 0.99), 0.34, 0.38, tile, material, 10, 0.29), "Pelvis", coat_group)
        for side, label in ((-1, "L"), (1, "R")):
            upper = cylinder(f"{prefix}UpperSleeve.{label}", (side * 0.32, 0, 1.31), 0.105, 0.38, tile, material, 10, 0.09)
            add(upper, f"UpperArm.{label}", coat_group)
            lower = cylinder(f"{prefix}LowerSleeve.{label}", (side * 0.32, 0, 1.00), 0.09, 0.32, tile, material, 10, 0.075)
            add(lower, f"Forearm.{label}", coat_group)
        for side in (-1, 1):
            lapel = cube(f"{prefix}Lapel.{side}", (side * 0.09, -0.255, 1.46), (0.075, 0.018, 0.19), tile, material, 0.006)
            lapel.rotation_euler.y = side * math.radians(12)
            add(lapel, "Chest", coat_group)
        for z in (1.17, 1.31, 1.45):
            add(sphere(f"{prefix}Button.{z}", (0, -0.295, z), (0.022, 0.014, 0.022), "brass" if prefix == "Police" else "dark", material, 10, 5), "Spine", coat_group)
        for side in (-1, 1):
            add(cube(f"{prefix}Pocket.{side}", (side * 0.18, -0.278, 1.05), (0.10, 0.012, 0.055), tile, material, 0.004), "Pelvis", coat_group)

    # Badge and holster are separate runtime-addressable groups.
    add(sphere("BadgeShield", (-0.14, -0.30, 1.48), (0.047, 0.014, 0.06), "brass", material, 10, 5), "Chest", badge)
    add(cube("PoliceHolster", (0.265, -0.08, 0.98), (0.07, 0.065, 0.14), "leather", material, 0.012), "Pelvis", police)

    for obj, bone, group in pieces:
        skin_rigid(obj, armature, bone, group)

    # Both coat shells must be present in the exported scene. Godot enforces
    # their visibility from CaseState immediately after instantiation.
    return root


def add_key(pose_bone, frame: int, rotation=(0.0, 0.0, 0.0), location=(0.0, 0.0, 0.0)) -> None:
    pose_bone.rotation_mode = "XYZ"
    pose_bone.rotation_euler = rotation
    pose_bone.location = location
    pose_bone.keyframe_insert("rotation_euler", frame=frame)
    pose_bone.keyframe_insert("location", frame=frame)


def action(armature: bpy.types.Object, name: str, frames: int, loop: bool, poses) -> bpy.types.Action:
    created = bpy.data.actions.new(name)
    armature.animation_data_create()
    armature.animation_data.action = created
    for frame, values in poses.items():
        for bone_name, transform in values.items():
            add_key(armature.pose.bones[bone_name], frame, transform.get("r", (0, 0, 0)), transform.get("l", (0, 0, 0)))
    created.frame_start = 1
    created.frame_end = frames
    created.use_fake_user = True
    # Blender 5 stores keyed channels in layered action slots rather than the
    # legacy Action.fcurves collection. Looping is set on the imported Godot
    # animation at runtime, so the source action needs no cycles modifier.
    return created


def create_animations(armature: bpy.types.Object) -> None:
    neutral = {name: {"r": (0, 0, 0), "l": (0, 0, 0)} for name in armature.pose.bones.keys()}
    action(armature, "Idle", 48, True, {
        1: neutral,
        24: {"Chest": {"r": (math.radians(1.5), 0, math.radians(-1.0))}, "Head": {"r": (0, 0, math.radians(1.5))}},
        48: neutral,
    })

    walk = {1: neutral, 41: neutral}
    for frame, direction in ((11, 1), (31, -1)):
        walk[frame] = {
            "Thigh.L": {"r": (math.radians(24 * direction), 0, 0)},
            "Thigh.R": {"r": (math.radians(-24 * direction), 0, 0)},
            "Shin.L": {"r": (math.radians(-10 if direction > 0 else 20), 0, 0)},
            "Shin.R": {"r": (math.radians(20 if direction > 0 else -10), 0, 0)},
            "UpperArm.L": {"r": (math.radians(-20 * direction), 0, 0)},
            "UpperArm.R": {"r": (math.radians(20 * direction), 0, 0)},
            "Pelvis": {"l": (0, 0, -0.015)},
        }
    action(armature, "Walk", 41, True, walk)

    brisk = {1: neutral, 33: neutral}
    for frame, direction in ((9, 1), (25, -1)):
        brisk[frame] = {
            "Thigh.L": {"r": (math.radians(34 * direction), 0, 0)},
            "Thigh.R": {"r": (math.radians(-34 * direction), 0, 0)},
            "Shin.L": {"r": (math.radians(-18 if direction > 0 else 30), 0, 0)},
            "Shin.R": {"r": (math.radians(30 if direction > 0 else -18), 0, 0)},
            "UpperArm.L": {"r": (math.radians(-28 * direction), 0, 0)},
            "UpperArm.R": {"r": (math.radians(28 * direction), 0, 0)},
            "Chest": {"r": (math.radians(5), 0, 0)},
            "Pelvis": {"l": (0, 0, -0.025)},
        }
    action(armature, "Brisk", 33, True, brisk)

    action(armature, "Interact", 36, False, {
        1: neutral,
        12: {"UpperArm.R": {"r": (math.radians(-42), 0, math.radians(-8))}, "Forearm.R": {"r": (math.radians(-35), 0, 0)}, "Head": {"r": (math.radians(-5), 0, 0)}},
        24: {"UpperArm.R": {"r": (math.radians(-34), 0, math.radians(-5))}, "Forearm.R": {"r": (math.radians(-28), 0, 0)}},
        36: neutral,
    })

    action(armature, "Pickup_Ground", 54, False, {
        1: neutral,
        10: {
            "Pelvis": {"r": (math.radians(8), 0, 0), "l": (0, 0, -0.06)},
            "Spine": {"r": (math.radians(15), 0, 0)},
            "Head": {"r": (math.radians(-12), 0, 0)},
        },
        25: {
            "Pelvis": {"r": (math.radians(18), 0, 0), "l": (0, 0, -0.23)},
            "Spine": {"r": (math.radians(34), 0, 0)},
            "Chest": {"r": (math.radians(12), 0, 0)},
            "Thigh.L": {"r": (math.radians(28), 0, 0)},
            "Thigh.R": {"r": (math.radians(30), 0, 0)},
            "Shin.L": {"r": (math.radians(-42), 0, 0)},
            "Shin.R": {"r": (math.radians(-44), 0, 0)},
            "UpperArm.R": {"r": (math.radians(-72), 0, math.radians(-8))},
            "Forearm.R": {"r": (math.radians(-18), 0, 0)},
            "UpperArm.L": {"r": (math.radians(-18), 0, math.radians(8))},
            "Head": {"r": (math.radians(-22), 0, 0)},
        },
        34: {
            "Pelvis": {"r": (math.radians(14), 0, 0), "l": (0, 0, -0.18)},
            "Spine": {"r": (math.radians(26), 0, 0)},
            "Thigh.L": {"r": (math.radians(22), 0, 0)},
            "Thigh.R": {"r": (math.radians(24), 0, 0)},
            "Shin.L": {"r": (math.radians(-34), 0, 0)},
            "Shin.R": {"r": (math.radians(-36), 0, 0)},
            "UpperArm.R": {"r": (math.radians(-58), 0, math.radians(-6))},
            "Forearm.R": {"r": (math.radians(-12), 0, 0)},
            "Head": {"r": (math.radians(-16), 0, 0)},
        },
        54: neutral,
    })

    # Export actions as independent NLA tracks. Muting prevents them from
    # combining in Blender while retaining all clips in the glTF.
    armature.animation_data.action = None
    for created in bpy.data.actions:
        track = armature.animation_data.nla_tracks.new()
        track.name = created.name
        strip = track.strips.new(created.name, int(created.frame_start), created)
        strip.action_frame_start = created.frame_start
        strip.action_frame_end = created.frame_end
        track.mute = True


def export(armature: bpy.types.Object, root: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    armature.select_set(True)
    root.select_set(True)
    for child in armature.children_recursive:
        child.select_set(True)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.export_scene.gltf(
        filepath=str(GLB_PATH),
        export_format="GLB",
        use_selection=True,
        export_animations=True,
        export_nla_strips=True,
        export_def_bones=True,
        export_skins=True,
        export_morph=False,
        export_yup=True,
    )


def triangle_count() -> int:
    total = 0
    depsgraph = bpy.context.evaluated_depsgraph_get()
    for obj in bpy.context.scene.objects:
        if obj.type != "MESH":
            continue
        evaluated = obj.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh()
        mesh.calc_loop_triangles()
        total += len(mesh.loop_triangles)
        evaluated.to_mesh_clear()
    return total


def main() -> None:
    reset()
    image = make_atlas()
    material = atlas_material(image)
    armature = create_armature()
    root = make_model(armature, material)
    create_animations(armature)
    triangles = triangle_count()
    export(armature, root)
    print(f"WALTER_PHASE1 triangles={triangles} glb={GLB_PATH} atlas={ATLAS_PATH}")


if __name__ == "__main__":
    main()
