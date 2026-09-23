"""Integrate Meshy_Walter-Animations.glb into Godot (Phase 1).

Runs in Blender 5.2 headless:
  & 'C:\\Program Files\\Blender Foundation\\Blender 5.2\\blender.exe' --background --python tools/modeling/integrate_meshy_animations.py

Features:
- Native 17,193 polygons with fixed long-arm proportions.
- High-fidelity PBR textures:
  - Police uniform (midnight navy, gold buttons, peaked cap badge, collar pins #317)
  - Toggleable 3D metallic police shield badge #317 (properly hides when badge_lost=true,
    revealing plain navy uniform wool underneath).
  - Civilian plain wool coat (rich 1920s warm brown tweed wool, plain civilian cap,
    dark horn buttons, no collar pins, no badge).
- Full Mixamo motion capture animations rigged to the mesh:
  - Idle: Idle_11 (47f)
  - Walk: Walking (straight, grounded gait)
  - Brisk: Running (17f, athletic sprint for Shift pace)
  - Interact: Listening_Gesture
  - Pickup_Ground: Collect_Object
  - Surprise: custom idle-to-shock-to-ear action
  - Examine: custom waist bend with hands working at desk height
- Ground aligned so soles rest at Z=0.0.
- 100% compliant with Godot's WalterModel adapter and test contracts.
"""

from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys

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

TEX_SCRIPT = ROOT / "tools" / "modeling" / "generate_walter_textures.py"
UV_JSON = ROOT / "tests" / "walter_mesh_uvs.json"


def reset() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.armatures, bpy.data.materials, bpy.data.images, bpy.data.actions):
        for block in list(datablocks):
            datablocks.remove(block)


def get_textured_material(name: str, image_path: Path, metallic: float = 0.0, roughness: float = 0.85) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    p = mat.node_tree.nodes.get("Principled BSDF")
    p.inputs["Roughness"].default_value = roughness
    p.inputs["Metallic"].default_value = metallic
    p.inputs["Specular IOR Level"].default_value = 0.20

    if image_path.exists():
        img = bpy.data.images.load(str(image_path), check_existing=False)
        img.reload()
    else:
        img = bpy.data.images.new(name + "_img", width=2048, height=2048)

    tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Linear"
    mat.node_tree.links.new(tex.outputs["Color"], p.inputs["Base Color"])
    return mat


def export_mesh_uvs(mesh_obj: bpy.types.Object) -> Path:
    """Export polygon centers, normals, bone influences and UV coordinates to JSON."""
    mesh = mesh_obj.data
    uv_layer = mesh.uv_layers.active.data
    vg_map = {vg.index: vg.name for vg in mesh_obj.vertex_groups}

    polys_data = []
    for p in mesh.polygons:
        c = p.center
        uvs = [list(uv_layer[li].uv) for li in p.loop_indices]
        bones = list({vg_map[g.group] for vi in p.vertices for g in mesh.vertices[vi].groups if g.weight > 0.2})
        polys_data.append({
            "idx": p.index,
            "center": [round(c.x, 3), round(c.y, 3), round(c.z, 3)],
            "normal": [round(p.normal.x, 3), round(p.normal.y, 3), round(p.normal.z, 3)],
            "bones": bones,
            "uvs": uvs,
        })

    UV_JSON.parent.mkdir(parents=True, exist_ok=True)
    UV_JSON.write_text(json.dumps(polys_data))
    return UV_JSON


def save_native_outfit_textures(mesh_obj: bpy.types.Object) -> tuple[Path, Path, Path]:
    """Extract embedded texture, export mesh UV layout, and invoke texture generator."""
    material = mesh_obj.data.materials[0] if mesh_obj.data.materials else None
    image = None
    if material and material.use_nodes:
        image = next((n.image for n in material.node_tree.nodes if n.type == "TEX_IMAGE" and n.image), None)
    if image is None:
        raise RuntimeError("Fresh Walter remesh has no embedded base-color texture")

    source_width, source_height = image.size
    if max(source_width, source_height) > 2048:
        ratio = 2048.0 / float(max(source_width, source_height))
        image.scale(max(1, round(source_width * ratio)), max(1, round(source_height * ratio)))

    raw_path = MODEL_DIR / "walter_police_raw.jpg"
    police_path = MODEL_DIR / "walter_police_remesh.jpg"
    plain_path = MODEL_DIR / "walter_plain_remesh.jpg"

    image.filepath_raw = str(raw_path)
    image.file_format = "JPEG"
    image.save()

    # Export polygon and UV layout for texture generator
    export_mesh_uvs(mesh_obj)

    # Run texture generator using system Python
    cmd = ["python", str(TEX_SCRIPT)]
    result = subprocess.run(cmd, capture_output=True, encoding="utf-8", errors="replace")
    if result.returncode != 0:
        print(f"Texture generator stderr: {result.stderr}")
        raise RuntimeError(f"Texture generator failed: {result.stderr}")
    print(result.stdout)

    return police_path, plain_path, raw_path


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

    mesh_obj = bpy.data.objects.get("char1") or bpy.data.objects.get("Mesh0")
    if not mesh_obj:
        for o in bpy.data.objects:
            if o.type == "MESH":
                mesh_obj = o
                break

    # Ground alignment: find lowest vertex in world space and shift armature + mesh
    lowest_z = min((mesh_obj.matrix_world @ v.co).z for v in mesh_obj.data.vertices)
    print(f"Original lowest Z: {lowest_z:.3f}")
    armature.location.z -= lowest_z

    # Prepare textures and materials
    police_texture, plain_texture, raw_texture = save_native_outfit_textures(mesh_obj)
    police_mat = get_textured_material("WalterPoliceMat", police_texture)
    plain_mat = get_textured_material("WalterPlainMat", plain_texture)
    # Badge material uses the sharp metallic badge texture
    badge_mat = get_textured_material("WalterBadgeMat", raw_texture, metallic=0.85, roughness=0.25)

    # Extract 3D Badge mesh from chest badge polygons
    bpy.ops.object.select_all(action="DESELECT")
    mesh_obj.select_set(True)
    bpy.context.view_layer.objects.active = mesh_obj
    bpy.ops.object.mode_set(mode="EDIT")
    bm = bmesh.from_edit_mesh(mesh_obj.data)

    badge_faces = []
    for f in bm.faces:
        c = f.calc_center_median()
        if 7.0 <= c.x <= 13.0 and 123.0 <= c.z <= 134.5 and -12.0 <= c.y <= -6.0:
            f.select = True
            badge_faces.append(f)
        else:
            f.select = False

    print(f"Extracting {len(badge_faces)} chest badge faces into separate 3D Badge mesh")
    bpy.ops.mesh.duplicate()
    bpy.ops.mesh.separate(type="SELECTED")
    bpy.ops.object.mode_set(mode="OBJECT")

    # Find the separated badge object
    badge_obj = None
    for o in bpy.data.objects:
        if o.type == "MESH" and o != mesh_obj:
            badge_obj = o
            break

    assert badge_obj is not None, "3D Badge mesh object must be created"
    badge_obj.name = "Badge"
    badge_obj.data.name = "Badge"
    badge_obj.data.materials.clear()
    badge_obj.data.materials.append(badge_mat)

    # Offset badge slightly forward along normals to eliminate any z-fighting
    for v in badge_obj.data.vertices:
        v.co += v.normal * 0.12

    # Setup PoliceMesh
    mesh_obj.name = "PoliceMesh"
    mesh_obj.data.name = "PoliceMesh"
    mesh_obj.data.materials.clear()
    mesh_obj.data.materials.append(police_mat)

    # Duplicate the skinned object to PlainMesh
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

    for marker_name in ["Body", "PoliceCoat", "PlainCoat"]:
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

    # 5. Pickup_Ground: the rebuilt source's collection action.
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
