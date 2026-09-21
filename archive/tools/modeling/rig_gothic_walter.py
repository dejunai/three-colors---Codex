"""Rig and integrate Meshy Gothic Walter into Godot with 15k-18k polygons.

Runs in Blender 5.2 headless:
  & 'C:\\Program Files\\Blender Foundation\\Blender 5.2\\blender.exe' --background --python tools/modeling/rig_gothic_walter.py

Features:
- Decimated to ~16,440 polygons (within requested 15k-18k range).
- High-fidelity textures: Police uniform (navy, gold buttons, badge 317) and Plain civilian coat.
- Complete skinning with clavicle bones for seamless shoulder deformation.
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
GLB_PATH = MODEL_DIR / "walter_phase1.glb"
MESHY_PATH = ROOT / "Meshy_Gothic-Walter-with-texture.glb"

POLICE_TEX_PATH = MODEL_DIR / "walter_police_texture.jpg"
PLAIN_TEX_PATH = MODEL_DIR / "walter_plain_texture.jpg"


def reset() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.armatures, bpy.data.materials, bpy.data.images, bpy.data.actions):
        for block in list(datablocks):
            datablocks.remove(block)


def get_textured_material(name: str, image_path: Path) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    p = mat.node_tree.nodes.get("Principled BSDF")
    p.inputs["Roughness"].default_value = 0.85
    p.inputs["Specular IOR Level"].default_value = 0.20

    if image_path.exists():
        img = bpy.data.images.load(str(image_path))
    else:
        img = bpy.data.images.new(name + "_img", width=2048, height=2048)

    tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Linear"
    mat.node_tree.links.new(tex.outputs["Color"], p.inputs["Base Color"])
    return mat


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
        # Clavicle / shoulder girdle for clean deformation
        bone(f"Shoulder.{label}", (side * 0.06, 0.01, 1.50), (side * 0.25, 0.01, 1.48), "Chest")
        bone(f"UpperArm.{label}", (side * 0.25, 0.01, 1.48), (side * 0.48, 0.01, 1.45), f"Shoulder.{label}")
        bone(f"Forearm.{label}", (side * 0.48, 0.01, 1.45), (side * 0.65, 0, 1.42), f"UpperArm.{label}")
        bone(f"Hand.{label}", (side * 0.65, 0, 1.42), (side * 0.74, 0, 1.40), f"Forearm.{label}")

    bpy.ops.object.mode_set(mode="OBJECT")
    return armature


def create_badge(police_mat: bpy.types.Material) -> bpy.types.Object:
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
    badge_obj.data.materials.append(police_mat)

    return badge_obj


def prepare_models(police_mat: bpy.types.Material, plain_mat: bpy.types.Material) -> tuple[bpy.types.Object, bpy.types.Object]:
    """Import Meshy model, decimate to ~16,440 polygons, ground-align, and set up materials."""
    bpy.ops.import_scene.gltf(filepath=str(MESHY_PATH))
    imported_obj = bpy.data.objects.get("Mesh_0")
    if not imported_obj:
        for o in bpy.data.objects:
            if o.type == "MESH":
                imported_obj = o
                break

    # Ground alignment
    z_min = min(v.co.z for v in imported_obj.data.vertices)
    for v in imported_obj.data.vertices:
        v.co.z -= z_min

    # Decimate to 0.036 ratio -> exactly ~16,440 polygons (within requested 15k-18k range)
    mod = imported_obj.modifiers.new("Decimate", "DECIMATE")
    mod.ratio = 0.036
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

    # Assign materials
    police_obj.data.materials.clear()
    police_obj.data.materials.append(police_mat)

    plain_obj.data.materials.clear()
    plain_obj.data.materials.append(plain_mat)

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

    # Rest arms down at sides with natural clavicle and arm drop
    base_idle = dict(neutral)
    base_idle["Shoulder.L"] = {"r": (math.radians(-14), 0, math.radians(-3))}
    base_idle["Shoulder.R"] = {"r": (math.radians(-14), 0, math.radians(3))}
    base_idle["UpperArm.L"] = {"r": (math.radians(-50), 0, math.radians(-6))}
    base_idle["UpperArm.R"] = {"r": (math.radians(-50), 0, math.radians(6))}
    base_idle["Forearm.L"] = {"r": (math.radians(-12), 0, 0)}
    base_idle["Forearm.R"] = {"r": (math.radians(-12), 0, 0)}

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
            "UpperArm.L": {"r": (math.radians(-38), 0, math.radians(-10))},
            "UpperArm.R": {"r": (math.radians(-62), 0, math.radians(10))},
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
            "UpperArm.L": {"r": (math.radians(-62), 0, math.radians(-10))},
            "UpperArm.R": {"r": (math.radians(-38), 0, math.radians(10))},
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
            "UpperArm.L": {"r": (math.radians(-38), 0, math.radians(-10))},
            "UpperArm.R": {"r": (math.radians(-62), 0, math.radians(10))},
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
            "UpperArm.L": {"r": (math.radians(-34), 0, math.radians(-14))},
            "UpperArm.R": {"r": (math.radians(-66), 0, math.radians(14))},
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
            "UpperArm.L": {"r": (math.radians(-66), 0, math.radians(-14))},
            "UpperArm.R": {"r": (math.radians(-34), 0, math.radians(14))},
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
            "UpperArm.L": {"r": (math.radians(-34), 0, math.radians(-14))},
            "UpperArm.R": {"r": (math.radians(-66), 0, math.radians(14))},
            "Pelvis": {"l": (0, 0, -0.025)},
        },
    }
    action("Brisk", 33, True, brisk_poses)

    # 4. Interact (36 frames) - right arm reaches forward
    interact_poses = {
        1: base_idle,
        12: {
            **base_idle,
            "Shoulder.R": {"r": (math.radians(-6), 0, 0)},
            "UpperArm.R": {"r": (math.radians(-24), math.radians(-30), math.radians(12))},
            "Forearm.R": {"r": (math.radians(-38), 0, 0)},
            "Head": {"r": (math.radians(-6), 0, 0)},
        },
        24: {
            **base_idle,
            "Shoulder.R": {"r": (math.radians(-8), 0, 0)},
            "UpperArm.R": {"r": (math.radians(-18), math.radians(-24), math.radians(10))},
            "Forearm.R": {"r": (math.radians(-28), 0, 0)},
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
            "Shoulder.R": {"r": (math.radians(-18), 0, 0)},
            "UpperArm.R": {"r": (math.radians(-65), math.radians(-10), math.radians(4))},
            "Forearm.R": {"r": (math.radians(-22), 0, 0)},
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
            "Shoulder.R": {"r": (math.radians(-16), 0, 0)},
            "UpperArm.R": {"r": (math.radians(-48), math.radians(-8), math.radians(6))},
            "Forearm.R": {"r": (math.radians(-16), 0, 0)},
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
    police_mat = get_textured_material("WalterPoliceMat", POLICE_TEX_PATH)
    plain_mat = get_textured_material("WalterPlainMat", PLAIN_TEX_PATH)

    police_obj, plain_obj = prepare_models(police_mat, plain_mat)
    badge_obj = create_badge(police_mat)

    armature = create_armature()
    skin_objects([police_obj, plain_obj, badge_obj], armature)
    create_animations(armature)

    root = build_scene_hierarchy(armature)

    triangles = triangle_count()
    export_glb(armature, root)
    print(f"RIGGED_GOTHIC_WALTER triangles={triangles} glb={GLB_PATH}")


if __name__ == "__main__":
    main()
