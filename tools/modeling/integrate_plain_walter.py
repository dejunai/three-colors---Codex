"""Prepare Walter's independently modeled plain-clothes variant for Godot.

Runs in Blender 5.2 headless.  The civilian source keeps its own compatible
Mixamo rig because its rest proportions differ slightly from the police model.
Runtime drives both rigs in sync and switches their complete rendered roots.
"""

from pathlib import Path
import bpy

ROOT = Path(r"C:\Users\Dejunai\projects\three colors — Codex")
SOURCE_CANDIDATES = [
    ROOT / "Meshy_Walter-Plain-Clothes-Animations.glb",
    ROOT / "archive" / "Meshy_Walter-Plain-Clothes-Animations.glb",
]
SOURCE = next((p for p in SOURCE_CANDIDATES if p.exists()), None)
if SOURCE is None:
    raise FileNotFoundError("Meshy_Walter-Plain-Clothes-Animations.glb is required at the project root or archive/")

OUT = ROOT / "assets" / "models" / "walter_plain.glb"
TEXTURE_OUT = ROOT / "assets" / "models" / "walter_plain_coat.jpg"

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(SOURCE))

for obj in list(bpy.data.objects):
    if "Icosphere" in obj.name:
        bpy.data.objects.remove(obj, do_unlink=True)

armature = next(o for o in bpy.data.objects if o.type == "ARMATURE")
mesh = next(o for o in bpy.data.objects if o.type == "MESH")
for pose_bone in armature.pose.bones:
    pose_bone.custom_shape = None
armature.name = "PlainWalterSkeleton"
armature.data.name = "PlainWalterSkeleton"
mesh.name = "PlainWalterMesh"
mesh.data.name = "PlainWalterMesh"

# Retain the source material while capping its embedded base color at 2K.
for material in mesh.data.materials:
    if material is None or not material.use_nodes:
        continue
    for node in material.node_tree.nodes:
        if node.type != "TEX_IMAGE" or node.image is None:
            continue
        image = node.image
        width, height = image.size
        if max(width, height) > 2048:
            scale = 2048.0 / float(max(width, height))
            image.scale(max(1, round(width * scale)), max(1, round(height * scale)))
        image.filepath_raw = str(TEXTURE_OUT)
        image.file_format = "JPEG"
        image.save()

# Semantic copies match the established police-model animation contract.
aliases = {
    "Idle_11": "Idle",
    "Walking": "Walk",
    "Running": "Brisk",
    "Listening_Gesture": "Interact",
    "Collect_Object": "Pickup_Ground",
    "01a0c2dc-c106-73a8-b359-a699e575b489": "Surprise",
    "01a0c2de-e825-716d-a1ed-53dcfa00916a": "Examine",
}
for source_name, target_name in aliases.items():
    source = bpy.data.actions.get(source_name)
    if source is None:
        raise RuntimeError(f"Plain Walter source is missing required action {source_name}")
    existing = bpy.data.actions.get(target_name)
    if existing is not None:
        bpy.data.actions.remove(existing)
    action = source.copy()
    action.name = target_name
    action.use_fake_user = True

armature.animation_data_create()
armature.animation_data.action = None
for track in list(armature.animation_data.nla_tracks):
    armature.animation_data.nla_tracks.remove(track)
for action_name in aliases.values():
    action = bpy.data.actions[action_name]
    track = armature.animation_data.nla_tracks.new()
    track.name = action_name
    strip = track.strips.new(action_name, int(action.frame_start), action)
    strip.action_frame_start = action.frame_start
    strip.action_frame_end = action.frame_end
    track.mute = True
armature.animation_data.action = bpy.data.actions["Idle"]
bpy.context.scene.frame_set(1)

root = bpy.data.objects.new("PlainWalter", None)
bpy.context.collection.objects.link(root)

bpy.ops.object.select_all(action="DESELECT")
root.select_set(True)
armature.select_set(True)
for child in armature.children_recursive:
    child.select_set(True)
bpy.context.view_layer.objects.active = armature

bpy.ops.export_scene.gltf(
    filepath=str(OUT),
    export_format="GLB",
    use_selection=True,
    export_animations=True,
    export_nla_strips=True,
    export_def_bones=True,
    export_skins=True,
    export_morph=False,
    export_yup=True,
)
print(f"Exported {OUT}")
