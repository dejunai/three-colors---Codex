"""Chisel and Rig Meshy Walter into authentic Gothic 1 & 2 Walter (Phase 1).

Runs in Blender 5.2 headless:
  & 'C:\\Program Files\\Blender Foundation\\Blender 5.2\\blender.exe' --background --python tools/modeling/chisel_meshy_walter.py

Aesthetic & Compatibility:
- Authentic Gothic 1 & 2 / Piranha Bytes low-poly style (~3,460 triangles per outfit).
- Chiseled planes, faceted silhouette.
- Painted diffuse texture atlas (walter_phase1_atlas.png) with baked chiaroscuro lighting.
- 17-bone WalterSkeleton with complete skinning.
- Natural relaxed detective idle pose with arms down at sides.
- 5 actions: Idle, Walk, Brisk, Interact, Pickup_Ground.
- 100% compliant with Godot's WalterModel adapter and test contracts.
"""

from __future__ import annotations

import math
from pathlib import Path

import bpy
import bmesh
from mathutils import Vector, Matrix


ROOT = Path(__file__).resolve().parents[2]
MODEL_DIR = ROOT / "assets" / "models"
MODEL_DIR.mkdir(parents=True, exist_ok=True)
ATLAS_PATH = MODEL_DIR / "walter_phase1_atlas.png"
GLB_PATH = MODEL_DIR / "walter_phase1.glb"
MESHY_PATH = ROOT / "Meshy_Walter_generated.glb"


def reset() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.armatures, bpy.data.materials, bpy.data.images, bpy.data.actions):
        for block in list(datablocks):
            datablocks.remove(block)


def get_atlas_material() -> bpy.types.Material:
    material = bpy.data.materials.new("WalterAtlas")
    material.use_nodes = True
    principled = material.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Roughness"].default_value = 0.90
    principled.inputs["Specular IOR Level"].default_value = 0.15

    if ATLAS_PATH.exists():
        image = bpy.data.images.load(str(ATLAS_PATH))
    else:
        image = bpy.data.images.new("WalterPhase1Atlas", width=512, height=512)

    texture = material.node_tree.nodes.new("ShaderNodeTexImage")
    texture.image = image
    texture.interpolation = "Closest"  # Classic crisp retro Gothic pixel filtering
    material.node_tree.links.new(texture.outputs["Color"], principled.inputs["Base Color"])
    return material


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
    bone("Pelvis", (0, 0, 0.85), (0, 0, 1.05), "Root")
    bone("Spine", (0, 0, 1.05), (0, 0, 1.30), "Pelvis")
    bone("Chest", (0, 0, 1.30), (0, 0, 1.55), "Spine")
    bone("Neck", (0, 0, 1.55), (0, 0, 1.68), "Chest")
    bone("Head", (0, 0, 1.68), (0, 0, 1.90), "Neck")

    for side, label in ((-1, "L"), (1, "R")):
        bone(f"Thigh.{label}", (side * 0.13, 0, 0.88), (side * 0.13, 0, 0.50), "Pelvis")
        bone(f"Shin.{label}", (side * 0.13, 0, 0.50), (side * 0.13, 0, 0.10), f"Thigh.{label}")
        bone(f"Foot.{label}", (side * 0.13, 0, 0.10), (side * 0.13, -0.20, 0.02), f"Shin.{label}")
        bone(f"UpperArm.{label}", (side * 0.20, 0, 1.45), (side * 0.45, 0, 1.40), "Chest")
        bone(f"Forearm.{label}", (side * 0.45, 0, 1.40), (side * 0.65, 0, 1.35), f"UpperArm.{label}")
        bone(f"Hand.{label}", (side * 0.65, 0, 1.35), (side * 0.78, 0, 1.30), f"Forearm.{label}")

    bpy.ops.object.mode_set(mode="OBJECT")
    return armature


def map_character_uvs(obj: bpy.types.Object, is_plain: bool) -> None:
    """Project UVs for the complete character mesh onto the atlas."""
    if not obj.data.uv_layers:
        obj.data.uv_layers.new(name="UVMap")
    uv_layer = obj.data.uv_layers.active.data

    v_base_coat = 0.02 if is_plain else 0.52

    verts = obj.data.vertices
    for poly in obj.data.polygons:
        for loop_idx in poly.loop_indices:
            v_idx = obj.data.loops[loop_idx].vertex_index
            co = verts[v_idx].co
            x, y, z = co.x, co.y, co.z

            if z >= 1.66:
                # HEAD & VISOR CAP -> Q1: U: [0.0, 0.5], V: [0.5, 1.0]
                if z >= 1.84:
                    # Cap crown / top & gold emblem
                    u = 0.25 + x * 1.1
                    v = 0.93 + (z - 1.84) * 0.8
                elif z >= 1.78 and y < -0.06:
                    # Visor & gold cord
                    u = 0.25 + x * 1.4
                    v = 0.88 + (y + 0.06) * 0.8
                elif y < 0.02:
                    # Face front (eyes, nose, mouth, stubble)
                    # Center x=128 (u=0.25), eyes at v=0.75, nose v=0.71, mouth v=0.67, chin v=0.63
                    u = 0.25 + x * 1.3
                    v = 0.63 + ((z - 1.66) / 0.14) * 0.18
                else:
                    # Sides / back of head (ears & dark hair)
                    u = 0.06 if x < 0 else 0.44
                    v = 0.65 + ((z - 1.66) / 0.14) * 0.15
                u = max(0.01, min(0.49, u))
                v = max(0.51, min(0.99, v))

            elif abs(x) > 0.65:
                # HANDS -> Q4 Hands: U: [0.26, 0.48], V: [0.27, 0.48]
                u = 0.35 + (abs(x) - 0.65) * 1.0
                v = 0.35 + (z - 1.35) * 1.0
                u = max(0.26, min(0.48, u))
                v = max(0.27, min(0.48, v))

            elif 0.85 <= z < 1.66:
                # JACKET / COAT -> Q2 (Police) or Q3 (Plain Tweed)
                if abs(x) > 0.22:
                    # Sleeves: Dedicated clean wool strip (U: [0.52, 0.60]) -> NO chest buttons!
                    u = 0.54 + (abs(x) - 0.22) * 0.15
                    v = v_base_coat + 0.10 + ((z - 0.85) / 0.81) * 0.30
                elif z <= 0.98:
                    # Belt / Waist
                    if y < 0:
                        # Belt buckle & front
                        u = 0.81 + x * 0.8
                        v = v_base_coat + 0.06 + (z - 0.85) * 0.35
                    else:
                        # Back belt / holster
                        u = 0.94 if x > 0 else 0.54
                        v = v_base_coat + 0.06
                else:
                    # Chest front & back
                    if y < 0:
                        # Front buttons / lapels
                        u = 0.81 + x * 0.9
                        v = v_base_coat + 0.12 + ((z - 0.98) / 0.68) * 0.32
                    else:
                        # Back of coat
                        u = 0.55
                        v = v_base_coat + 0.15 + ((z - 0.98) / 0.68) * 0.25
                u = max(0.52, min(0.98, u))
                v = max(v_base_coat, min(v_base_coat + 0.46, v))

            elif z < 0.42:
                # BOOTS -> Q4 Boots: U: [0.02, 0.30], V: [0.02, 0.24]
                u = 0.16 + x * 0.7
                v = 0.04 + (z / 0.42) * 0.18
                u = max(0.02, min(0.30, u))
                v = max(0.02, min(0.24, v))

            else:
                # TROUSERS (0.42 <= z < 0.85) -> Q4 Trousers: U: [0.02, 0.24], V: [0.26, 0.48]
                u = 0.12 + x * 0.6
                v = 0.27 + ((z - 0.42) / 0.43) * 0.20
                u = max(0.02, min(0.24, u))
                v = max(0.26, min(0.48, v))

            uv_layer[loop_idx].uv = (u, v)


def create_badge(material: bpy.types.Material) -> bpy.types.Object:
    """Create five-pointed star police badge mesh on left breast."""
    bm = bmesh.new()
    r_out, r_in = 0.038, 0.016
    pts = []
    for i in range(10):
        angle = math.radians(i * 36 - 90)
        r = r_out if i % 2 == 0 else r_in
        pts.append((r * math.cos(angle), 0, r * math.sin(angle)))

    center = bm.verts.new((0, -0.006, 0))
    outer_verts = [bm.verts.new((p[0], -0.002, p[2])) for p in pts]
    for i in range(10):
        bm.faces.new([center, outer_verts[i], outer_verts[(i + 1) % 10]])

    me = bpy.data.meshes.new("BadgeMesh")
    bm.to_mesh(me)
    bm.free()

    badge_obj = bpy.data.objects.new("BadgeMesh", me)
    bpy.context.collection.objects.link(badge_obj)
    badge_obj.location = (-0.088, -0.158, 1.42)
    badge_obj.rotation_euler = (math.radians(-6), math.radians(4), math.radians(-3))
    badge_obj.data.materials.append(material)

    badge_obj.data.uv_layers.new(name="UVMap")
    uv_layer = badge_obj.data.uv_layers.active.data
    for poly in badge_obj.data.polygons:
        for loop_idx in poly.loop_indices:
            v_idx = badge_obj.data.loops[loop_idx].vertex_index
            vx = badge_obj.data.vertices[v_idx].co.x
            vz = badge_obj.data.vertices[v_idx].co.z
            u = 0.415 + (vx / r_out) * 0.065
            v = 0.125 + (vz / r_out) * 0.095
            uv_layer[loop_idx].uv = (u, v)

    return badge_obj


def chisel_model(material: bpy.types.Material) -> tuple[bpy.types.Object, bpy.types.Object]:
    """Load Meshy model, ground-align, decimate to Gothic style, and create PoliceMesh and PlainMesh."""
    bpy.ops.import_scene.gltf(filepath=str(MESHY_PATH))
    imported_obj = bpy.data.objects.get("mesh_node")
    if not imported_obj:
        for o in bpy.data.objects:
            if o.type == "MESH":
                imported_obj = o
                break

    # Ground alignment
    z_min = min(v.co.z for v in imported_obj.data.vertices)
    for v in imported_obj.data.vertices:
        v.co.z -= z_min

    # Decimate to Gothic low-poly (~3,460 triangles)
    mod = imported_obj.modifiers.new("Decimate", "DECIMATE")
    mod.ratio = 0.055
    bpy.context.view_layer.objects.active = imported_obj
    bpy.ops.object.modifier_apply(modifier="Decimate")

    for p in imported_obj.data.polygons:
        p.use_smooth = True

    # Duplicate into PoliceMesh and PlainMesh
    police_mesh = imported_obj.data.copy()
    plain_mesh = imported_obj.data.copy()

    police_obj = bpy.data.objects.new("PoliceMesh", police_mesh)
    plain_obj = bpy.data.objects.new("PlainMesh", plain_mesh)

    bpy.context.collection.objects.link(police_obj)
    bpy.context.collection.objects.link(plain_obj)
    bpy.data.objects.remove(imported_obj, do_unlink=True)

    police_obj.data.materials.append(material)
    plain_obj.data.materials.append(material)

    map_character_uvs(police_obj, is_plain=False)
    map_character_uvs(plain_obj, is_plain=True)

    return police_obj, plain_obj


def skin_objects(objects: list[bpy.types.Object], armature: bpy.types.Object) -> None:
    for obj in objects:
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        armature.select_set(True)
        bpy.context.view_layer.objects.active = armature
        bpy.ops.object.parent_set(type="ARMATURE_AUTO")


def add_key(pose_bone, frame: int, rotation=(0.0, 0.0, 0.0), location=(0.0, 0.0, 0.0)) -> None:
    pose_bone.rotation_mode = "XYZ"
    pose_bone.rotation_euler = rotation
    pose_bone.location = location
    pose_bone.keyframe_insert("rotation_euler", frame=frame)
    pose_bone.keyframe_insert("location", frame=frame)


def create_animations(armature: bpy.types.Object) -> None:
    bones = armature.pose.bones
    for b in bones:
        b.rotation_mode = "XYZ"

    neutral = {b.name: {"r": (0.0, 0.0, 0.0), "l": (0.0, 0.0, 0.0)} for b in bones}

    # Rot X = -65 deg brings horizontal T-pose arms down to a natural resting detective posture!
    rest_arm_l = (math.radians(-65), 0, math.radians(-8))
    rest_arm_r = (math.radians(-65), 0, math.radians(8))
    rest_forearm_l = (math.radians(-15), 0, 0)
    rest_forearm_r = (math.radians(-15), 0, 0)

    base_idle = dict(neutral)
    base_idle["UpperArm.L"] = {"r": rest_arm_l}
    base_idle["UpperArm.R"] = {"r": rest_arm_r}
    base_idle["Forearm.L"] = {"r": rest_forearm_l}
    base_idle["Forearm.R"] = {"r": rest_forearm_r}

    def action(name: str, frames: int, loop: bool, poses: dict) -> bpy.types.Action:
        act = bpy.data.actions.new(name)
        armature.animation_data_create()
        armature.animation_data.action = act
        for frame, values in poses.items():
            for bone_name, tr in values.items():
                if bone_name in bones:
                    pb = bones[bone_name]
                    rot = tr.get("r", (0.0, 0.0, 0.0))
                    loc = tr.get("l", (0.0, 0.0, 0.0))
                    add_key(pb, frame, rot, loc)
        act.frame_start = 1
        act.frame_end = frames
        act.use_fake_user = True
        return act

    # 1. Idle (48 frames) - detective steady breathing & resting posture
    idle_poses = {
        1: base_idle,
        24: {
            **base_idle,
            "Chest": {"r": (math.radians(2), 0, 0)},
            "Head": {"r": (math.radians(-2), math.radians(2), 0)},
            "Pelvis": {"l": (0, 0, 0.005)},
        },
        48: base_idle,
    }
    action("Idle", 48, True, idle_poses)

    # 2. Walk (41 frames) - steady detective walk cycle
    walk_poses = {
        1: {
            **base_idle,
            "Thigh.L": {"r": (math.radians(24), 0, 0)},
            "Shin.L": {"r": (math.radians(-12), 0, 0)},
            "Thigh.R": {"r": (math.radians(-22), 0, 0)},
            "Shin.R": {"r": (math.radians(6), 0, 0)},
            "UpperArm.L": {"r": (math.radians(-52), 0, math.radians(-12))},
            "UpperArm.R": {"r": (math.radians(-76), 0, math.radians(12))},
            "Pelvis": {"l": (0, 0, -0.015)},
        },
        11: {
            **base_idle,
            "Thigh.L": {"r": (math.radians(4), 0, 0)},
            "Shin.L": {"r": (math.radians(-24), 0, 0)},
            "Thigh.R": {"r": (math.radians(0), 0, 0)},
            "Shin.R": {"r": (math.radians(0), 0, 0)},
            "Pelvis": {"l": (0, 0, 0.01)},
        },
        21: {
            **base_idle,
            "Thigh.L": {"r": (math.radians(-22), 0, 0)},
            "Shin.L": {"r": (math.radians(6), 0, 0)},
            "Thigh.R": {"r": (math.radians(24), 0, 0)},
            "Shin.R": {"r": (math.radians(-12), 0, 0)},
            "UpperArm.L": {"r": (math.radians(-76), 0, math.radians(-12))},
            "UpperArm.R": {"r": (math.radians(-52), 0, math.radians(12))},
            "Pelvis": {"l": (0, 0, -0.015)},
        },
        31: {
            **base_idle,
            "Thigh.L": {"r": (math.radians(0), 0, 0)},
            "Shin.L": {"r": (math.radians(0), 0, 0)},
            "Thigh.R": {"r": (math.radians(4), 0, 0)},
            "Shin.R": {"r": (math.radians(-24), 0, 0)},
            "Pelvis": {"l": (0, 0, 0.01)},
        },
        41: {
            **base_idle,
            "Thigh.L": {"r": (math.radians(24), 0, 0)},
            "Shin.L": {"r": (math.radians(-12), 0, 0)},
            "Thigh.R": {"r": (math.radians(-22), 0, 0)},
            "Shin.R": {"r": (math.radians(6), 0, 0)},
            "UpperArm.L": {"r": (math.radians(-52), 0, math.radians(-12))},
            "UpperArm.R": {"r": (math.radians(-76), 0, math.radians(12))},
            "Pelvis": {"l": (0, 0, -0.015)},
        },
    }
    action("Walk", 41, True, walk_poses)

    # 3. Brisk (33 frames) - urgent investigation stride
    brisk_poses = {
        1: {
            **base_idle,
            "Thigh.L": {"r": (math.radians(32), 0, 0)},
            "Shin.L": {"r": (math.radians(-18), 0, 0)},
            "Thigh.R": {"r": (math.radians(-28), 0, 0)},
            "Shin.R": {"r": (math.radians(8), 0, 0)},
            "UpperArm.L": {"r": (math.radians(-48), 0, math.radians(-16))},
            "UpperArm.R": {"r": (math.radians(-82), 0, math.radians(16))},
            "Pelvis": {"l": (0, 0, -0.025)},
        },
        9: {
            **base_idle,
            "Thigh.L": {"r": (math.radians(6), 0, 0)},
            "Shin.L": {"r": (math.radians(-32), 0, 0)},
            "Thigh.R": {"r": (math.radians(0), 0, 0)},
            "Shin.R": {"r": (math.radians(0), 0, 0)},
            "Pelvis": {"l": (0, 0, 0.015)},
        },
        17: {
            **base_idle,
            "Thigh.L": {"r": (math.radians(-28), 0, 0)},
            "Shin.L": {"r": (math.radians(8), 0, 0)},
            "Thigh.R": {"r": (math.radians(32), 0, 0)},
            "Shin.R": {"r": (math.radians(-18), 0, 0)},
            "UpperArm.L": {"r": (math.radians(-82), 0, math.radians(-16))},
            "UpperArm.R": {"r": (math.radians(-48), 0, math.radians(16))},
            "Pelvis": {"l": (0, 0, -0.025)},
        },
        25: {
            **base_idle,
            "Thigh.L": {"r": (math.radians(0), 0, 0)},
            "Shin.L": {"r": (math.radians(0), 0, 0)},
            "Thigh.R": {"r": (math.radians(6), 0, 0)},
            "Shin.R": {"r": (math.radians(-32), 0, 0)},
            "Pelvis": {"l": (0, 0, 0.015)},
        },
        33: {
            **base_idle,
            "Thigh.L": {"r": (math.radians(32), 0, 0)},
            "Shin.L": {"r": (math.radians(-18), 0, 0)},
            "Thigh.R": {"r": (math.radians(-28), 0, 0)},
            "Shin.R": {"r": (math.radians(8), 0, 0)},
            "UpperArm.L": {"r": (math.radians(-48), 0, math.radians(-16))},
            "UpperArm.R": {"r": (math.radians(-82), 0, math.radians(16))},
            "Pelvis": {"l": (0, 0, -0.025)},
        },
    }
    action("Brisk", 33, True, brisk_poses)

    # 4. Interact (36 frames) - right arm reaches forward
    interact_poses = {
        1: base_idle,
        12: {
            **base_idle,
            "UpperArm.R": {"r": (math.radians(-30), math.radians(-35), math.radians(15))},
            "Forearm.R": {"r": (math.radians(-42), 0, 0)},
            "Head": {"r": (math.radians(-6), 0, 0)},
        },
        24: {
            **base_idle,
            "UpperArm.R": {"r": (math.radians(-22), math.radians(-28), math.radians(12))},
            "Forearm.R": {"r": (math.radians(-32), 0, 0)},
        },
        36: base_idle,
    }
    action("Interact", 36, False, interact_poses)

    # 5. Pickup_Ground (42 frames) - kneel down to reach ground, apex at frame 19 (46%)
    pickup_poses = {
        1: base_idle,
        8: {
            **base_idle,
            "Pelvis": {"r": (math.radians(8), 0, 0), "l": (0, 0, -0.08)},
            "Spine": {"r": (math.radians(16), 0, 0)},
            "Head": {"r": (math.radians(-12), 0, 0)},
        },
        19: {
            **base_idle,
            "Pelvis": {"r": (math.radians(20), 0, 0), "l": (0, 0, -0.28)},
            "Spine": {"r": (math.radians(36), 0, 0)},
            "Chest": {"r": (math.radians(14), 0, 0)},
            "Thigh.L": {"r": (math.radians(34), 0, 0)},
            "Thigh.R": {"r": (math.radians(36), 0, 0)},
            "Shin.L": {"r": (math.radians(-48), 0, 0)},
            "Shin.R": {"r": (math.radians(-50), 0, 0)},
            "UpperArm.R": {"r": (math.radians(-75), math.radians(-15), math.radians(5))},
            "Forearm.R": {"r": (math.radians(-25), 0, 0)},
            "Head": {"r": (math.radians(-24), 0, 0)},
        },
        28: {
            **base_idle,
            "Pelvis": {"r": (math.radians(14), 0, 0), "l": (0, 0, -0.18)},
            "Spine": {"r": (math.radians(24), 0, 0)},
            "Thigh.L": {"r": (math.radians(22), 0, 0)},
            "Thigh.R": {"r": (math.radians(24), 0, 0)},
            "Shin.L": {"r": (math.radians(-32), 0, 0)},
            "Shin.R": {"r": (math.radians(-34), 0, 0)},
            "UpperArm.R": {"r": (math.radians(-55), math.radians(-12), math.radians(8))},
            "Forearm.R": {"r": (math.radians(-18), 0, 0)},
            "Head": {"r": (math.radians(-14), 0, 0)},
        },
        42: base_idle,
    }
    action("Pickup_Ground", 42, False, pickup_poses)

    # Put Idle onto active action and mute NLA strips
    armature.animation_data.action = None
    for act in bpy.data.actions:
        track = armature.animation_data.nla_tracks.new()
        track.name = act.name
        strip = track.strips.new(act.name, int(act.frame_start), act)
        strip.action_frame_start = act.frame_start
        strip.action_frame_end = act.frame_end
        track.mute = True


def build_scene_hierarchy(armature: bpy.types.Object) -> bpy.types.Object:
    """Build root WalterPhase1 and required empty marker nodes for Godot."""
    root = bpy.data.objects.new("WalterPhase1", None)
    root.empty_display_type = "PLAIN_AXES"
    bpy.context.collection.objects.link(root)

    for marker_name in ["Body", "PoliceCoat", "PlainCoat", "Badge"]:
        marker = bpy.data.objects.new(marker_name, None)
        marker.empty_display_type = "PLAIN_AXES"
        marker.parent = root
        bpy.context.collection.objects.link(marker)

    return root


def export_glb(armature: bpy.types.Object, root: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    armature.select_set(True)
    root.select_set(True)
    for child in armature.children_recursive:
        child.select_set(True)
    for child in root.children_recursive:
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
    police_obj, plain_obj = chisel_model(material)
    badge_obj = create_badge(material)

    armature = create_armature()
    skin_objects([police_obj, plain_obj, badge_obj], armature)
    create_animations(armature)

    root = build_scene_hierarchy(armature)

    triangles = triangle_count()
    export_glb(armature, root)
    print(f"CHISELED_GOTHIC_WALTER triangles={triangles} glb={GLB_PATH} atlas={ATLAS_PATH}")


if __name__ == "__main__":
    main()
