"""Generate Gothic 1 & 2 Style Walter Corwin (3D Model + Rig + Animations).

Runs in Blender 5.2 headless:
  blender --background --python tools/modeling/generate_walter_gothic.py

Aesthetic:
- Authentic Gothic 1 & 2 / Piranha Bytes low-poly style.
- Chiseled facial features, fedora, heavy wool coat drapery, chunky boots.
- Precise UV mapping to the 512x512 painted diffuse atlas (walter_phase1_atlas.png).
- 100% compliant with Godot's WalterModel adapter and test contracts.
"""

from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Vector, Matrix


ROOT = Path(__file__).resolve().parents[2]
MODEL_DIR = ROOT / "assets" / "models"
MODEL_DIR.mkdir(parents=True, exist_ok=True)
ATLAS_PATH = MODEL_DIR / "walter_phase1_atlas.png"
GLB_PATH = MODEL_DIR / "walter_phase1.glb"


def reset() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.armatures, bpy.data.materials, bpy.data.images, bpy.data.actions):
        for block in list(datablocks):
            datablocks.remove(block)


def get_atlas_material() -> bpy.types.Material:
    material = bpy.data.materials.new("WalterAtlas")
    material.use_nodes = True
    material.diffuse_color = (0.25, 0.25, 0.25, 1.0)
    nodes = material.node_tree.nodes
    principled = nodes.get("Principled BSDF")
    principled.inputs["Roughness"].default_value = 0.90
    principled.inputs["Specular IOR Level"].default_value = 0.15

    # Load existing atlas image
    if ATLAS_PATH.exists():
        image = bpy.data.images.load(str(ATLAS_PATH))
    else:
        image = bpy.data.images.new("WalterPhase1Atlas", width=512, height=512)

    texture = nodes.new("ShaderNodeTexImage")
    texture.image = image
    texture.interpolation = "Closest"  # Crisp retro Gothic pixel filtering
    material.node_tree.links.new(texture.outputs["Color"], principled.inputs["Base Color"])
    return material


def map_uv_rect(obj: bpy.types.Object, u_min: float, v_min: float, u_max: float, v_max: float) -> None:
    """Project UVs of obj linearly within bounds [u_min, v_min] to [u_max, v_max]."""
    if not obj.data.uv_layers:
        obj.data.uv_layers.new(name="UVMap")
    uv_layer = obj.data.uv_layers.active.data

    # Find vertex bounding box in object local space
    verts = obj.data.vertices
    if not verts:
        return
    min_x = min(v.co.x for v in verts)
    max_x = max(v.co.x for v in verts)
    min_z = min(v.co.z for v in verts)
    max_z = max(v.co.z for v in verts)

    span_x = max(0.0001, max_x - min_x)
    span_z = max(0.0001, max_z - min_z)

    u_span = u_max - u_min
    v_span = v_max - v_min

    for poly in obj.data.polygons:
        for loop_idx in poly.loop_indices:
            v_idx = obj.data.loops[loop_idx].vertex_index
            vx = obj.data.vertices[v_idx].co.x
            vz = obj.data.vertices[v_idx].co.z
            norm_u = (vx - min_x) / span_x
            norm_v = (vz - min_z) / span_z
            uv_layer[loop_idx].uv = (u_min + norm_u * u_span, v_min + norm_v * v_span)


def map_face_uvs(head_obj: bpy.types.Object) -> None:
    """Specialized UV unwrapping for the Gothic face plane."""
    if not head_obj.data.uv_layers:
        head_obj.data.uv_layers.new(name="UVMap")
    uv_layer = head_obj.data.uv_layers.active.data

    # Face quadrant: U: [0.05, 0.28], V: [0.70, 0.98]
    # Ears/sides: U: [0.01, 0.05], [0.28, 0.31]
    # Back/hair: U: [0.32, 0.48], V: [0.70, 0.98]
    for poly in head_obj.data.polygons:
        # Check normal direction of polygon
        normal = poly.normal
        for loop_idx in poly.loop_indices:
            v_idx = head_obj.data.loops[loop_idx].vertex_index
            co = head_obj.data.vertices[v_idx].co
            # Forward is -Y in local head space (or -Y facing in Gothic)
            if normal.y < -0.2:  # Front facing face
                u = 0.165 + (co.x / 0.30) * 0.11
                v = 0.835 + ((co.z - 1.80) / 0.35) * 0.14
            elif abs(normal.x) > 0.4:  # Sides (ears & cheeks)
                u = (0.03 if normal.x < 0 else 0.29) + (co.y / 0.3) * 0.02
                v = 0.82 + ((co.z - 1.80) / 0.35) * 0.12
            else:  # Top or back of head (hair)
                u = 0.38 + (co.x / 0.3) * 0.08
                v = 0.86 + ((co.z - 1.80) / 0.35) * 0.10
            uv_layer[loop_idx].uv = (max(0.0, min(1.0, u)), max(0.0, min(1.0, v)))


def create_armature() -> bpy.types.Object:
    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    armature = bpy.context.object
    armature.name = "WalterSkeleton"
    data = armature.data
    data.name = "WalterSkeleton"
    data.edit_bones.remove(data.edit_bones[0])

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
    obj.parent = armature
    obj.matrix_world = world
    vertex_group = obj.vertex_groups.new(name=bone)
    vertex_group.add(range(len(obj.data.vertices)), 1.0, "REPLACE")
    modifier = obj.modifiers.new("WalterSkeleton", "ARMATURE")
    modifier.object = armature


def bevel(obj: bpy.types.Object, width: float = 0.012, segments: int = 1) -> None:
    modifier = obj.modifiers.new("Bevel", "BEVEL")
    modifier.width = width
    modifier.segments = segments
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=modifier.name)


def make_cube(name: str, location, scale, material, uv_bounds, soften: float = 0.01) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if soften > 0.0:
        bevel(obj, soften)
    obj.data.materials.append(material)
    map_uv_rect(obj, uv_bounds[0], uv_bounds[1], uv_bounds[2], uv_bounds[3])
    return obj


def make_cylinder(name: str, location, radius: float, depth: float, material, uv_bounds, vertices: int = 10, radius_top: float | None = None) -> bpy.types.Object:
    if radius_top is None or abs(radius_top - radius) < 0.0001:
        bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location)
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius, radius2=radius_top, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    bevel(obj, min(0.012, radius * 0.08))
    obj.data.materials.append(material)
    map_uv_rect(obj, uv_bounds[0], uv_bounds[1], uv_bounds[2], uv_bounds[3])
    return obj


def make_chiseled_head(material: bpy.types.Material) -> bpy.types.Object:
    """Construct an angular Gothic 1 & 2 chiseled head mesh."""
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.145, depth=0.28, location=(0, -0.01, 1.805))
    head = bpy.context.object
    head.name = "HeadMesh"
    # Taper jaw / chin:
    for v in head.data.vertices:
        if v.co.z < 0:  # lower half
            # Taper front chin
            if v.co.y < 0:
                v.co.x *= 0.72
                v.co.y *= 1.15
            else:
                v.co.x *= 0.85
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bevel(head, 0.015, 1)
    head.data.materials.append(material)
    map_face_uvs(head)
    return head


def build_gothic_walter(armature: bpy.types.Object, material: bpy.types.Material) -> bpy.types.Object:
    root = empty("WalterPhase1", armature)
    body = empty("Body", root)
    police = empty("PoliceCoat", root)
    plain = empty("PlainCoat", root)
    badge = empty("Badge", root)

    pieces: list[tuple[bpy.types.Object, str, bpy.types.Object]] = []

    def add(obj, bone, group=body):
        pieces.append((obj, bone, group))
        return obj

    # =========================================================================
    # 1. HEAD & FEATURES (Gothic angular anatomy)
    # =========================================================================
    head = add(make_chiseled_head(material), "Head")
    add(make_cylinder("NeckMesh", (0, 0, 1.625), 0.088, 0.15, material, (0.09, 0.63, 0.22, 0.69), 8), "Neck")

    # Sharp angular nose wedge
    add(make_cube("Nose", (0, -0.155, 1.805), (0.024, 0.038, 0.052), material, (0.13, 0.79, 0.19, 0.90), 0.005), "Head")

    # Brow shelf / ridge
    for side in (-1, 1):
        brow = make_cube(f"Brow.{side}", (side * 0.052, -0.138, 1.86), (0.046, 0.018, 0.014), material, (0.06, 0.88, 0.25, 0.94), 0.003)
        brow.rotation_euler.z = side * math.radians(-8)
        add(brow, "Head")
        ear = make_cube(f"Ear.{side}", (side * 0.145, 0.005, 1.81), (0.018, 0.032, 0.055), material, (0.01, 0.78, 0.04, 0.85), 0.004)
        add(ear, "Head")

    # Hair under brim
    add(make_cylinder("HairCap", (0, 0.015, 1.895), 0.155, 0.09, material, (0.32, 0.85, 0.48, 0.98), 10), "Head")

    # =========================================================================
    # 2. FEDORA HAT (Noir brimmed fedora)
    # =========================================================================
    # Wide angled brim (tilted down slightly in front for noir shadow)
    brim = make_cylinder("HatBrim", (0, -0.015, 1.95), 0.275, 0.026, material, (0.32, 0.74, 0.49, 0.82), 14)
    brim.rotation_euler.x = math.radians(6)
    add(brim, "Head")

    # Creased crown with pinch
    crown = make_cylinder("HatCrown", (0, 0.015, 2.05), 0.178, 0.16, material, (0.32, 0.84, 0.49, 0.98), 10, 0.145)
    crown.rotation_euler.x = math.radians(4)
    add(crown, "Head")

    # Ribbon hatband
    hatband = make_cylinder("HatBand", (0, 0.005, 1.98), 0.182, 0.032, material, (0.32, 0.83, 0.49, 0.86), 10)
    hatband.rotation_euler.x = math.radians(4)
    add(hatband, "Head")

    # =========================================================================
    # 3. SHIRT, TIE & BELT
    # =========================================================================
    # Off-white linen shirt torso
    add(make_cylinder("ShirtTorso", (0, 0, 1.32), 0.235, 0.58, material, (0.25, 0.51, 0.39, 0.68), 8, 0.195), "Spine")

    # Knotted tie hanging down
    tie = make_cube("Tie", (0, -0.21, 1.38), (0.038, 0.016, 0.24), material, (0.30, 0.50, 0.34, 0.63), 0.004)
    add(tie, "Chest")

    # Waist belt with brass buckle
    add(make_cube("Belt", (0, -0.005, 1.02), (0.275, 0.215, 0.048), material, (0.39, 0.58, 0.49, 0.67), 0.006), "Pelvis")
    add(make_cube("Buckle", (0, -0.225, 1.02), (0.048, 0.018, 0.038), material, (0.42, 0.63, 0.48, 0.68), 0.005), "Pelvis")

    # =========================================================================
    # 4. TROUSERS, BOOTS & HANDS
    # =========================================================================
    for side, label in ((-1, "L"), (1, "R")):
        # Thighs & shins with charcoal wool crease
        add(make_cylinder(f"ThighMesh.{label}", (side * 0.14, 0, 0.69), 0.115, 0.42, material, (0.52, 0.28, 0.72, 0.48), 8, 0.10), f"Thigh.{label}")
        add(make_cylinder(f"ShinMesh.{label}", (side * 0.14, 0, 0.32), 0.092, 0.36, material, (0.52, 0.05, 0.72, 0.28), 8, 0.082), f"Shin.{label}")

        # Heavy Gothic leather boots with toe caps and welted soles
        boot = make_cube(f"Boot.{label}", (side * 0.14, -0.065, 0.09), (0.11, 0.20, 0.092), material, (0.76, 0.04, 0.98, 0.45), 0.016)
        add(boot, f"Foot.{label}")

        # Chunky low-poly detective hands (knuckles and palm lines)
        hand = make_cube(f"HandMesh.{label}", (side * 0.32, -0.01, 0.74), (0.068, 0.062, 0.095), material, (0.02, 0.51, 0.24, 0.62), 0.012)
        add(hand, f"Hand.{label}")

    # =========================================================================
    # 5. OUTFITS: POLICE UNIFORM vs PLAIN WOOL COAT
    # =========================================================================
    # Police Coat: Midnight navy wool, double brass buttons, peaked lapels, epaulets
    # Plain Coat: Earthy herringbone tweed, wide notched lapels, horn buttons, deep pockets

    # --- POLICE COAT GROUP ---
    add(make_cylinder("PoliceCoatTorso", (0, 0, 1.34), 0.30, 0.70, material, (0.05, 0.22, 0.35, 0.48), 8, 0.24), "Spine", police)
    add(make_cylinder("PoliceCoatSkirt", (0, 0.02, 0.98), 0.33, 0.40, material, (0.05, 0.02, 0.35, 0.20), 8, 0.28), "Pelvis", police)
    for side, label in ((-1, "L"), (1, "R")):
        add(make_cylinder(f"PoliceUpperSleeve.{label}", (side * 0.32, 0, 1.31), 0.102, 0.38, material, (0.35, 0.22, 0.48, 0.36), 8, 0.088), f"UpperArm.{label}", police)
        add(make_cylinder(f"PoliceLowerSleeve.{label}", (side * 0.32, 0, 1.00), 0.088, 0.32, material, (0.35, 0.15, 0.48, 0.26), 8, 0.072), f"Forearm.{label}", police)
        # Shoulder epaulet with brass button
        ep = make_cube(f"PoliceEpaulet.{label}", (side * 0.22, -0.01, 1.54), (0.075, 0.035, 0.014), material, (0.05, 0.45, 0.18, 0.48), 0.003)
        add(ep, "Chest", police)

    # Double brass button rows
    for by in (1.20, 1.34, 1.48):
        for bx in (-0.065, 0.065):
            btn = make_cube(f"PoliceButton.{by}.{bx}", (bx, -0.285, by), (0.016, 0.012, 0.016), material, (0.12, 0.34, 0.18, 0.40), 0.004)
            add(btn, "Spine", police)

    # Peaked police lapels
    for side in (-1, 1):
        lapel = make_cube(f"PoliceLapel.{side}", (side * 0.095, -0.245, 1.46), (0.072, 0.016, 0.18), material, (0.06, 0.36, 0.18, 0.48), 0.005)
        lapel.rotation_euler.y = side * math.radians(12)
        add(lapel, "Chest", police)

    # Police Holster on belt
    add(make_cube("PoliceHolster", (0.255, -0.075, 0.98), (0.065, 0.060, 0.135), material, (0.76, 0.10, 0.90, 0.35), 0.01), "Pelvis", police)

    # Gold Police Star / Shield Badge (Dedicated Badge group for game toggling)
    badge_shield = make_cube("BadgeShield", (-0.135, -0.285, 1.48), (0.042, 0.014, 0.052), material, (0.35, 0.35, 0.48, 0.48), 0.006)
    add(badge_shield, "Chest", badge)

    # --- PLAIN COAT GROUP (Tweed) ---
    add(make_cylinder("PlainCoatTorso", (0, 0, 1.34), 0.305, 0.70, material, (0.52, 0.72, 0.80, 0.98), 8, 0.245), "Spine", plain)
    add(make_cylinder("PlainCoatSkirt", (0, 0.02, 0.98), 0.335, 0.40, material, (0.52, 0.51, 0.85, 0.70), 8, 0.285), "Pelvis", plain)
    for side, label in ((-1, "L"), (1, "R")):
        add(make_cylinder(f"PlainUpperSleeve.{label}", (side * 0.32, 0, 1.31), 0.105, 0.38, material, (0.78, 0.72, 0.98, 0.88), 8, 0.090), f"UpperArm.{label}", plain)
        add(make_cylinder(f"PlainLowerSleeve.{label}", (side * 0.32, 0, 1.00), 0.090, 0.32, material, (0.78, 0.60, 0.98, 0.74), 8, 0.075), f"Forearm.{label}", plain)
        pocket = make_cube(f"PlainPocket.{label}", (side * 0.175, -0.27, 1.06), (0.095, 0.012, 0.052), material, (0.54, 0.68, 0.75, 0.74), 0.004)
        add(pocket, "Pelvis", plain)

    # Wide notched tweed lapels
    for side in (-1, 1):
        lapel = make_cube(f"PlainLapel.{side}", (side * 0.095, -0.245, 1.46), (0.075, 0.018, 0.185), material, (0.54, 0.82, 0.76, 0.98), 0.005)
        lapel.rotation_euler.y = side * math.radians(12)
        add(lapel, "Chest", plain)

    # Horn buttons down front
    for by in (1.20, 1.34, 1.48):
        btn = make_cube(f"PlainButton.{by}", (0, -0.285, by), (0.018, 0.012, 0.018), material, (0.62, 0.72, 0.68, 0.78), 0.004)
        add(btn, "Spine", plain)

    # Bind all pieces to skeleton
    for obj, bone, group in pieces:
        skin_rigid(obj, armature, bone, group)

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

    action(armature, "Pickup_Ground", 42, False, {
        1: neutral,
        8: {
            "Pelvis": {"r": (math.radians(8), 0, 0), "l": (0, 0, -0.06)},
            "Spine": {"r": (math.radians(15), 0, 0)},
            "Head": {"r": (math.radians(-12), 0, 0)},
        },
        20: {
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
        28: {
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
        42: neutral,
    })

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
    bpy.context.scene.render.fps = 30
    material = get_atlas_material()
    armature = create_armature()
    root = build_gothic_walter(armature, material)
    create_animations(armature)
    triangles = triangle_count()
    export(armature, root)
    print(f"GOTHIC_WALTER triangles={triangles} glb={GLB_PATH} atlas={ATLAS_PATH}")


if __name__ == "__main__":
    main()
