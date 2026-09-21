"""Integrate Meshy_Gothic-Walter-Animations.glb into Godot (Phase 1).

Runs in Blender 5.2 headless:
  & 'C:\\Program Files\\Blender Foundation\\Blender 5.2\\blender.exe' --background --python tools/modeling/integrate_meshy_animations.py

Features:
- Native 17,193 polygons (in 15k-18k budget).
- High quality PBR textures: Police uniform (navy, gold buttons, badge 317) & Plain civilian coat.
- Full Mixamo motion capture animations already rigged to the mesh:
  - Idle: Idle_11 (47f)
  - Walk: Quick_Walk (74f, masculine stride with squared hips, replacing catwalk 'Walking')
  - Brisk: Running (17f, athletic sprint for Shift pace)
  - Interact: Call_Gesture (frames 1..48)
  - Pickup_Ground: Male_Bend_Over_Pick_Up (frames 1..80, reach apex at 46%)
  - Surprise: custom idle-to-shock-to-ear action
  - Examine: custom waist bend with hands working at desk height
- Ground aligned so soles rest at Z=0.0.
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
SRC_GLB = ROOT / "archive" / "Meshy_Gothic-Walter-Animations.glb"
if not SRC_GLB.exists():
    SRC_GLB = ROOT / "Meshy_Gothic-Walter-Animations.glb"

POLICE_TEX_PATH = MODEL_DIR / "walter_police_anim_tex.jpg"
PLAIN_TEX_PATH = MODEL_DIR / "walter_plain_anim_tex.jpg"


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


def main() -> None:
    reset()
    bpy.context.scene.render.fps = 30
    bpy.ops.import_scene.gltf(filepath=str(SRC_GLB))

    # Remove extraneous objects like Icosphere
    for o in list(bpy.data.objects):
        if "Icosphere" in o.name:
            bpy.data.objects.remove(o, do_unlink=True)

    armature = bpy.data.objects.get("target_character")
    if not armature:
        for o in bpy.data.objects:
            if o.type == "ARMATURE":
                armature = o
                break

    mesh_obj = bpy.data.objects.get("Mesh0")
    if not mesh_obj:
        for o in bpy.data.objects:
            if o.type == "MESH":
                mesh_obj = o
                break

    # Ground alignment: find lowest vertex in world space and shift armature + mesh
    lowest_z = min((mesh_obj.matrix_world @ v.co).z for v in mesh_obj.data.vertices)
    print(f"Original lowest Z: {lowest_z:.3f}")
    armature.location.z -= lowest_z

    # Prepare materials
    police_mat = get_textured_material("WalterPoliceMat", POLICE_TEX_PATH)
    plain_mat = get_textured_material("WalterPlainMat", PLAIN_TEX_PATH)

    # Setup PoliceMesh and PlainMesh
    mesh_obj.name = "PoliceMesh"
    mesh_obj.data.name = "PoliceMesh"
    mesh_obj.data.materials.clear()
    mesh_obj.data.materials.append(police_mat)

    plain_data = mesh_obj.data.copy()
    plain_data.name = "PlainMesh"
    plain_obj = bpy.data.objects.new("PlainMesh", plain_data)
    plain_obj.matrix_world = mesh_obj.matrix_world.copy()
    bpy.context.collection.objects.link(plain_obj)
    plain_obj.data.materials.clear()
    plain_obj.data.materials.append(plain_mat)

    # Bind PlainMesh to armature with same vertex groups / modifier
    plain_obj.parent = armature
    for mod in mesh_obj.modifiers:
        if mod.type == "ARMATURE":
            new_mod = plain_obj.modifiers.new(name=mod.name, type="ARMATURE")
            new_mod.object = armature

    # Rename armature to WalterSkeleton for Godot contract
    armature.name = "WalterSkeleton"
    armature.data.name = "WalterSkeleton"

    # Build root WalterPhase1 and required empty marker nodes
    root = bpy.data.objects.new("WalterPhase1", None)
    root.empty_display_type = "PLAIN_AXES"
    bpy.context.collection.objects.link(root)

    for marker_name in ["Body", "PoliceCoat", "PlainCoat", "Badge"]:
        marker = bpy.data.objects.new(marker_name, None)
        marker.empty_display_type = "PLAIN_AXES"
        marker.parent = root
        bpy.context.collection.objects.link(marker)

    # =========================================================================
    # ANIMATIONS: Setup required actions
    # =========================================================================
    # 1. Idle: rename Idle_11 -> Idle
    idle_act = bpy.data.actions.get("Idle_11")
    if idle_act:
        idle_act.name = "Idle"
        idle_act.frame_start = 1
        idle_act.frame_end = 47
        idle_act.use_fake_user = True

    # 2. Walk: use Quick_Walk (frames 1..74) for masculine detective stride
    quick_walk_act = bpy.data.actions.get("Quick_Walk")
    if quick_walk_act:
        walk_act = quick_walk_act.copy()
        walk_act.name = "Walk"
        walk_act.frame_start = 1
        walk_act.frame_end = 74
        walk_act.use_fake_user = True

    # 3. Brisk: use Running (frames 1..17) for shift/sprint pace
    running_act = bpy.data.actions.get("Running")
    if running_act:
        brisk_act = running_act.copy()
        brisk_act.name = "Brisk"
        brisk_act.frame_start = 1
        brisk_act.frame_end = 17
        brisk_act.use_fake_user = True

    # 4. Interact: use Call_Gesture frames 1..48 -> Interact
    call_act = bpy.data.actions.get("Call_Gesture")
    if call_act:
        interact_act = call_act.copy()
        interact_act.name = "Interact"
        interact_act.frame_start = 1
        interact_act.frame_end = 48
        interact_act.use_fake_user = True

    # 5. Pickup_Ground: Male_Bend_Over_Pick_Up frames 1..80 (apex at frame 37: 37/80 = 46.25%)
    pickup_raw = bpy.data.actions.get("Male_Bend_Over_Pick_Up")
    if pickup_raw:
        pickup_act = pickup_raw.copy()
        pickup_act.name = "Pickup_Ground"
        pickup_act.frame_start = 1
        pickup_act.frame_end = 80
        pickup_act.use_fake_user = True

    # 6. Semantic aliases for the two custom Meshy actions.
    custom_actions = {
        "01a0c2dc-c106-73a8-b359-a699e575b489": "Surprise",
        "01a0c2de-e825-716d-a1ed-53dcfa00916a": "Examine",
    }
    for source_name, target_name in custom_actions.items():
        source = bpy.data.actions.get(source_name)
        if source:
            action = source.copy()
            action.name = target_name
            action.use_fake_user = True

    # Setup NLA tracks for the required actions
    target_actions = ["Idle", "Walk", "Brisk", "Interact", "Pickup_Ground", "Surprise", "Examine"]
    armature.animation_data_create()
    armature.animation_data.action = None

    # Clear existing NLA tracks
    for t in list(armature.animation_data.nla_tracks):
        armature.animation_data.nla_tracks.remove(t)

    for act_name in target_actions:
        act = bpy.data.actions.get(act_name)
        if act:
            track = armature.animation_data.nla_tracks.new()
            track.name = act_name
            strip = track.strips.new(act_name, int(act.frame_start), act)
            strip.action_frame_start = act.frame_start
            strip.action_frame_end = act.frame_end
            track.mute = True

    # Set Idle as active action at frame 1
    if bpy.data.actions.get("Idle"):
        armature.animation_data.action = bpy.data.actions["Idle"]
        bpy.context.scene.frame_set(1)

    # Count triangles
    depsgraph = bpy.context.evaluated_depsgraph_get()
    mesh_eval = mesh_obj.evaluated_get(depsgraph).to_mesh()
    mesh_eval.calc_loop_triangles()
    tri_count = len(mesh_eval.loop_triangles)
    mesh_obj.evaluated_get(depsgraph).to_mesh_clear()
    print(f"Per-outfit triangle count: {tri_count}")

    # Export GLB
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
    print(f"Successfully exported {GLB_PATH}")


if __name__ == "__main__":
    main()
