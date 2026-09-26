import bpy
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GLB_PATH = ROOT / "assets" / "models" / "walter_phase1.glb"

def render_outfit(plain: bool, badge_visible: bool, angle_name: str, cam_loc, cam_rot, out_filename: str):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(GLB_PATH))

    # Toggle outfit matching Godot WalterModel.set_outfit contract
    for o in bpy.data.objects:
        if o.name.startswith("Police"):
            o.hide_render = plain
            o.hide_viewport = plain
        elif o.name.startswith("Plain"):
            o.hide_render = not plain
            o.hide_viewport = not plain
        elif o.name.startswith("Badge"):
            o.hide_render = not badge_visible
            o.hide_viewport = not badge_visible

    # Play Idle animation at frame 1 so arms are in natural resting pose
    arm = bpy.data.objects.get("WalterSkeleton")
    if arm and bpy.data.actions.get("Idle"):
        arm.animation_data.action = bpy.data.actions["Idle"]
        bpy.context.scene.frame_set(1)

    # Camera
    cam_data = bpy.data.cameras.new("Camera")
    cam = bpy.data.objects.new("Camera", cam_data)
    bpy.context.scene.collection.objects.link(cam)
    cam.location = cam_loc
    cam.rotation_euler = cam_rot
    bpy.context.scene.camera = cam

    # Key light
    l1_data = bpy.data.lights.new("KeyLight", "SUN")
    l1_data.energy = 3.5
    l1 = bpy.data.objects.new("KeyLight", l1_data)
    bpy.context.collection.objects.link(l1)
    l1.rotation_euler = (0.8, 0.4, 0.2)

    # Fill light
    l2_data = bpy.data.lights.new("FillLight", "SUN")
    l2_data.energy = 1.8
    l2 = bpy.data.objects.new("FillLight", l2_data)
    bpy.context.collection.objects.link(l2)
    l2.rotation_euler = (0.5, -0.6, -0.4)

    scene = bpy.context.scene
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    out_path = ROOT / "archive" / "tests" / out_filename
    scene.render.filepath = str(out_path)
    bpy.ops.render.render(write_still=True)
    print(f"Rendered {out_filename}")

# 1. Render Police Front with Badge
render_outfit(
    plain=False,
    badge_visible=True,
    angle_name="police_front",
    cam_loc=(0, -2.5, 1.05),
    cam_rot=(1.5708, 0, 0),
    out_filename="walter_police_render.png"
)

# 2. Render Police Badge Lost (narrative state: Walter lost badge in tunnel)
render_outfit(
    plain=False,
    badge_visible=False,
    angle_name="police_no_badge",
    cam_loc=(0, -2.5, 1.05),
    cam_rot=(1.5708, 0, 0),
    out_filename="walter_badge_lost_render.png"
)

# 3. Render Plain Civilian Wool Coat Front
render_outfit(
    plain=True,
    badge_visible=False,
    angle_name="plain_front",
    cam_loc=(0, -2.5, 1.05),
    cam_rot=(1.5708, 0, 0),
    out_filename="walter_plain_render.png"
)
