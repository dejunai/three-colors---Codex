import bpy
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "archive" / "Meshy_Gatekeeper-Boy-Animations.glb"

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(SRC))

for o in list(bpy.data.objects):
    if "Icosphere" in o.name:
        bpy.data.objects.remove(o, do_unlink=True)

arm = [o for o in bpy.context.scene.objects if o.type == "ARMATURE"][0]
if bpy.data.actions.get("Idle_12"):
    arm.animation_data.action = bpy.data.actions["Idle_12"]
    bpy.context.scene.frame_set(1)

cam_data = bpy.data.cameras.new("Camera")
cam = bpy.data.objects.new("Camera", cam_data)
bpy.context.scene.collection.objects.link(cam)
cam.location = (0, -2.5, 1.05)
cam.rotation_euler = (1.5708, 0, 0)
bpy.context.scene.camera = cam

l1 = bpy.data.lights.new("Key", "SUN")
l1.energy = 3.5
lo1 = bpy.data.objects.new("Key", l1)
bpy.context.collection.objects.link(lo1)
lo1.rotation_euler = (0.8, 0.4, 0.2)

l2 = bpy.data.lights.new("Fill", "SUN")
l2.energy = 1.8
lo2 = bpy.data.objects.new("Fill", l2)
bpy.context.collection.objects.link(lo2)
lo2.rotation_euler = (0.5, -0.6, -0.4)

bpy.context.scene.render.resolution_x = 512
bpy.context.scene.render.resolution_y = 512
out_path = Path("C:/Users/Dejunai/.gemini/antigravity/brain/174bb2e4-fa3a-4c53-a3df-f26cbf6e32d7/boy_preview.png")
bpy.context.scene.render.filepath = str(out_path)
bpy.ops.render.render(write_still=True)
print(f"Rendered {out_path}")
