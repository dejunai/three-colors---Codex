"""Integrate Meshy_Gatekeeper-Boy-Animations.glb into Godot.

Runs in Blender 5.2 headless:
  & 'C:\\Program Files\\Blender Foundation\\Blender 5.2\\blender.exe' --background --python tools/modeling/integrate_boy.py
"""

from __future__ import annotations

from pathlib import Path
import bpy

ROOT = Path(__file__).resolve().parents[2]
MODEL_DIR = ROOT / "assets" / "models"
MODEL_DIR.mkdir(parents=True, exist_ok=True)
OUT_GLB = MODEL_DIR / "gatekeeper_boy.glb"

SRC_GLB = ROOT / "archive" / "Meshy_Gatekeeper-Boy-Animations.glb"
if not SRC_GLB.exists():
    SRC_GLB = ROOT / "Meshy_Gatekeeper-Boy-Animations.glb"


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

    mesh_obj = bpy.data.objects.get("char1")
    if not mesh_obj:
        for o in bpy.data.objects:
            if o.type == "MESH":
                mesh_obj = o
                break

    # Ground alignment: find lowest vertex in world space and shift armature + mesh
    lowest_z = min((mesh_obj.matrix_world @ v.co).z for v in mesh_obj.data.vertices)
    print(f"Original lowest Z: {lowest_z:.3f}")
    armature.location.z -= lowest_z

    # Rename armature and mesh for clean Godot hierarchy
    armature.name = "BoySkeleton"
    armature.data.name = "BoySkeleton"
    mesh_obj.name = "BoyMesh"
    mesh_obj.data.name = "BoyMesh"

    # Build root GatekeeperBoy node
    root = bpy.data.objects.new("GatekeeperBoy", None)
    root.empty_display_type = "PLAIN_AXES"
    bpy.context.collection.objects.link(root)
    armature.parent = root

    # =========================================================================
    # ANIMATIONS: Setup NLA tracks
    # =========================================================================
    # 1. Idle (primary): Idle_12 (145 frames, calm on-duty youth stance)
    idle_act = bpy.data.actions.get("Idle_12")
    if idle_act:
        act_idle = idle_act.copy()
        act_idle.name = "Idle"
        act_idle.frame_start = 0
        act_idle.frame_end = 145
        act_idle.use_fake_user = True

    # 2. Idle_Alt: Idle_3 (240 frames, gentle breathing / shifting weight)
    idle3_act = bpy.data.actions.get("Idle_3")
    if idle3_act:
        act_alt = idle3_act.copy()
        act_alt.name = "Idle_Alt"
        act_alt.frame_start = 0
        act_alt.frame_end = 240
        act_alt.use_fake_user = True

    # 3. Listen: Listening_Gesture (225 frames, attentive nods and hand gestures)
    listen_act = bpy.data.actions.get("Listening_Gesture")
    if listen_act:
        act_listen = listen_act.copy()
        act_listen.name = "Listen"
        act_listen.frame_start = 0
        act_listen.frame_end = 225
        act_listen.use_fake_user = True

    target_actions = ["Idle", "Idle_Alt", "Listen"]
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

    # Set Idle as active action at frame 0
    if bpy.data.actions.get("Idle"):
        armature.animation_data.action = bpy.data.actions["Idle"]
        bpy.context.scene.frame_set(0)

    # Count triangles
    depsgraph = bpy.context.evaluated_depsgraph_get()
    mesh_eval = mesh_obj.evaluated_get(depsgraph).to_mesh()
    mesh_eval.calc_loop_triangles()
    tri_count = len(mesh_eval.loop_triangles)
    mesh_obj.evaluated_get(depsgraph).to_mesh_clear()
    print(f"Gatekeeper Boy triangle count: {tri_count}")

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
        filepath=str(OUT_GLB),
        export_format="GLB",
        use_selection=True,
        export_animations=True,
        export_nla_strips=True,
        export_def_bones=True,
        export_skins=True,
        export_morph=False,
        export_yup=True,
    )
    print(f"Successfully exported {OUT_GLB}")


if __name__ == "__main__":
    main()
