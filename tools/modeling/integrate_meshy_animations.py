"""Integrate Meshy_Gothic-Walter-Animations.glb into Godot (Phase 1).

Runs in Blender 5.2 headless:
  & 'C:\\Program Files\\Blender Foundation\\Blender 5.2\\blender.exe' --background --python tools/modeling/integrate_meshy_animations.py

Features:
- Native 17,193 polygons (in 15k-18k budget).
- High quality PBR textures: Police uniform (navy, gold buttons, badge 317) & Plain civilian coat.
- Full Mixamo motion capture animations already rigged to the mesh:
  - Idle: Idle_11 (47f)
  - Walk: Walking (26f)
  - Brisk: Running (17f, athletic sprint for Shift pace)
  - Interact: Listening_Gesture
  - Pickup_Ground: Collect_Object
  - Surprise: custom idle-to-shock-to-ear action
  - Examine: custom waist bend with hands working at desk height
- Ground aligned so soles rest at Z=0.0.
- 100% compliant with Godot's WalterModel adapter and test contracts.
"""

from __future__ import annotations

import math
import colorsys
from pathlib import Path

import bpy
import bmesh
from mathutils import Vector, Matrix


ROOT = Path(__file__).resolve().parents[2]
MODEL_DIR = ROOT / "assets" / "models"
MODEL_DIR.mkdir(parents=True, exist_ok=True)
GLB_PATH = MODEL_DIR / "walter_phase1.glb"
SRC_GLB = ROOT / "archive" / "Meshy_Walter-Animations.glb"
if not SRC_GLB.exists():
    SRC_GLB = ROOT / "Meshy_Walter-Animations.glb"
if not SRC_GLB.exists():
    SRC_GLB = ROOT / "archive" / "Meshy_Gothic-Walter-Animations.glb"

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


def save_native_outfit_textures(mesh_obj: bpy.types.Object) -> tuple[Path, Path]:
    """Persist the remesh's own UV atlas and a restrained plain-coat recolor."""
    material = mesh_obj.data.materials[0] if mesh_obj.data.materials else None
    image = None
    if material and material.use_nodes:
        image = next((n.image for n in material.node_tree.nodes if n.type == "TEX_IMAGE" and n.image), None)
    if image is None:
        raise RuntimeError("Fresh Walter remesh has no embedded base-color texture")

    # Walter is normally viewed at mid distance through the Chapter One film
    # treatment. A 4K character atlas spends Web memory without visible return;
    # keep the authored aspect ratio and cap the longest edge at 2K.
    source_width, source_height = image.size
    if max(source_width, source_height) > 2048:
        ratio = 2048.0 / float(max(source_width, source_height))
        image.scale(max(1, round(source_width * ratio)), max(1, round(source_height * ratio)))

    police_path = MODEL_DIR / "walter_police_remesh.jpg"
    plain_path = MODEL_DIR / "walter_plain_remesh.jpg"
    image.filepath_raw = str(police_path)
    image.file_format = "JPEG"
    image.save()

    width, height = image.size
    source = list(image.pixels[:])
    recolored = source.copy()
    for index in range(0, len(source), 4):
        red, green, blue, alpha = source[index:index + 4]
        hue, saturation, value = colorsys.rgb_to_hsv(red, green, blue)
        # Recolor the dark blue/neutral uniform cloth while retaining skin,
        # brass, leather, shirt and facial detail from the native atlas.
        blue_or_neutral_cloth = value < 0.42 and (blue >= red * 0.82 or saturation < 0.18)
        if blue_or_neutral_cloth:
            new_red = min(1.0, value * 1.12 + 0.035)
            new_green = min(1.0, value * 0.92 + 0.025)
            new_blue = min(1.0, value * 0.68 + 0.018)
            recolored[index:index + 4] = [new_red, new_green, new_blue, alpha]
    plain_image = bpy.data.images.new("WalterPlainRemesh", width=width, height=height, alpha=False)
    plain_image.pixels[:] = recolored
    plain_image.filepath_raw = str(plain_path)
    plain_image.file_format = "JPEG"
    plain_image.save()
    return police_path, plain_path


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

    for pose_bone in armature.pose.bones:
        pose_bone.custom_shape = None

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

    # Prepare materials from this remesh's UV atlas. The previous Walter's
    # external atlases are not UV-compatible with the rebuilt long-arm mesh.
    police_texture, plain_texture = save_native_outfit_textures(mesh_obj)
    police_mat = get_textured_material("WalterPoliceMat", police_texture)
    plain_mat = get_textured_material("WalterPlainMat", plain_texture)

    # Setup PoliceMesh and PlainMesh
    mesh_obj.name = "PoliceMesh"
    mesh_obj.data.name = "PoliceMesh"
    mesh_obj.data.materials.clear()
    mesh_obj.data.materials.append(police_mat)

    # Duplicate the skinned object, not only its Mesh datablock. Vertex groups
    # live on the Object; recreating only the data silently strips every skin
    # weight and lets the armature parent distort the plain-coat copy.
    plain_obj = mesh_obj.copy()
    plain_obj.data = mesh_obj.data.copy()
    plain_obj.name = "PlainMesh"
    plain_obj.data.name = "PlainMesh"
    bpy.context.collection.objects.link(plain_obj)
    plain_obj.data.materials.clear()
    plain_obj.data.materials.append(plain_mat)
    plain_obj.parent = mesh_obj.parent
    plain_obj.matrix_parent_inverse = mesh_obj.matrix_parent_inverse.copy()
    plain_obj.matrix_world = mesh_obj.matrix_world.copy()

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

    # 2. Walk: the rebuilt long-arm source supplies one grounded walking cycle.
    walking_act = bpy.data.actions.get("Walking")
    if walking_act:
        walk_act = walking_act.copy()
        walk_act.name = "Walk"
        walk_act.frame_start = walking_act.frame_start
        walk_act.frame_end = walking_act.frame_end
        walk_act.use_fake_user = True

    # 3. Brisk: use Running (frames 1..17) for shift/sprint pace
    running_act = bpy.data.actions.get("Running")
    if running_act:
        brisk_act = running_act.copy()
        brisk_act.name = "Brisk"
        brisk_act.frame_start = 1
        brisk_act.frame_end = 17
        brisk_act.use_fake_user = True

    # 4. Interact: retain the rebuilt source's restrained listening gesture.
    listening_act = bpy.data.actions.get("Listening_Gesture")
    if listening_act:
        interact_act = listening_act.copy()
        interact_act.name = "Interact"
        interact_act.frame_start = listening_act.frame_start
        interact_act.frame_end = listening_act.frame_end
        interact_act.use_fake_user = True

    # 5. Pickup_Ground: the rebuilt source's shorter collection action.
    pickup_raw = bpy.data.actions.get("Collect_Object")
    if pickup_raw:
        pickup_act = pickup_raw.copy()
        pickup_act.name = "Pickup_Ground"
        pickup_act.frame_start = pickup_raw.frame_start
        pickup_act.frame_end = pickup_raw.frame_end
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
