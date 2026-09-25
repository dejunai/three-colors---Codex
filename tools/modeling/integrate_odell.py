"""Integrate the animated Meshy Captain Odell into the Chapter One model set.

Runs in Blender 5.2 headless. The source remains archived after a successful
build; the game asset keeps only the character mesh, rig, and three restrained
standing actions used by both of Odell's live appearances.
"""

from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parents[2]
MODEL_DIR = ROOT / "assets" / "models"
OUT_GLB = MODEL_DIR / "captain_odell.glb"
SOURCE_NAME = "Meshy_Captain-ODell-Animations.glb"
SRC_GLB = ROOT / SOURCE_NAME
if not SRC_GLB.exists():
    SRC_GLB = ROOT / "archive" / SOURCE_NAME


def reset() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def copy_action(source_name: str, target_name: str) -> bpy.types.Action:
    source = bpy.data.actions.get(source_name)
    if source is None:
        raise RuntimeError(f"Captain Odell source is missing action {source_name}")
    action = source.copy()
    action.name = target_name
    action.frame_start = source.frame_range[0]
    action.frame_end = source.frame_range[1]
    action.use_fake_user = True
    return action


def main() -> None:
    if not SRC_GLB.exists():
        raise FileNotFoundError(SRC_GLB)
    reset()
    bpy.context.scene.render.fps = 30
    bpy.ops.import_scene.gltf(filepath=str(SRC_GLB))

    for obj in list(bpy.data.objects):
        if "Icosphere" in obj.name:
            bpy.data.objects.remove(obj, do_unlink=True)

    armature = next((obj for obj in bpy.data.objects if obj.type == "ARMATURE"), None)
    mesh_obj = next((obj for obj in bpy.data.objects if obj.type == "MESH"), None)
    if armature is None or mesh_obj is None:
        raise RuntimeError("Captain Odell source must contain one rigged character mesh")

    lowest_z = min((mesh_obj.matrix_world @ vertex.co).z for vertex in mesh_obj.data.vertices)
    armature.location.z -= lowest_z
    armature.name = "OdellSkeleton"
    armature.data.name = "OdellSkeleton"
    mesh_obj.name = "OdellMesh"
    mesh_obj.data.name = "OdellMesh"

    root = bpy.data.objects.new("CaptainOdell", None)
    root.empty_display_type = "PLAIN_AXES"
    bpy.context.collection.objects.link(root)
    armature.parent = root

    # The source contains locomotion, but Odell is stationary in both current
    # appearances. Preserve three quiet standing variants with semantic names.
    idle = copy_action("Idle_11", "Idle")
    idle_alt = copy_action("Idle_3", "Idle_Alt")
    confer = copy_action("Idle_12", "Confer")

    # Blender's glTF exporter can include every compatible source action even
    # when only selected NLA strips are authored. Remove unused locomotion and
    # source-name duplicates so the stationary NPC asset carries exactly its
    # three runtime clips.
    for action in list(bpy.data.actions):
        if action not in [idle, idle_alt, confer]:
            bpy.data.actions.remove(action)

    armature.animation_data_create()
    armature.animation_data.action = idle
    for track in list(armature.animation_data.nla_tracks):
        armature.animation_data.nla_tracks.remove(track)
    for action in [idle, idle_alt, confer]:
        track = armature.animation_data.nla_tracks.new()
        track.name = action.name
        strip = track.strips.new(action.name, int(action.frame_start), action)
        strip.action_frame_start = action.frame_start
        strip.action_frame_end = action.frame_end
        track.mute = True
    bpy.context.scene.frame_set(int(idle.frame_start))

    depsgraph = bpy.context.evaluated_depsgraph_get()
    evaluated = mesh_obj.evaluated_get(depsgraph)
    evaluated_mesh = evaluated.to_mesh()
    evaluated_mesh.calc_loop_triangles()
    print(f"Captain Odell triangle count: {len(evaluated_mesh.loop_triangles)}")
    evaluated.to_mesh_clear()

    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    armature.select_set(True)
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
