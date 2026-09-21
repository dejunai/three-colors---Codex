import bpy
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GLB_PATH = ROOT / "assets" / "models" / "walter_phase1.glb"

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(GLB_PATH))

for o in bpy.data.objects:
    if "Plain" in o.name:
        o.hide_render = True
    if "Police" in o.name:
        o.hide_render = False

arm = bpy.data.objects.get("WalterSkeleton")
cam_data = bpy.data.cameras.new("Camera")
cam = bpy.data.objects.new("Camera", cam_data)
bpy.context.scene.collection.objects.link(cam)
cam.location = (0, 2.5, 1.05)
cam.rotation_euler = (1.5708, 0, 3.14159)
bpy.context.scene.camera = cam

l = bpy.data.lights.new("Light", "SUN")
l.energy = 3.5
lo = bpy.data.objects.new("Light", l)
bpy.context.scene.collection.objects.link(lo)
lo.rotation_euler = (-0.8, 0.4, 0)

bpy.context.scene.render.resolution_x = 384
bpy.context.scene.render.resolution_y = 384

arm.animation_data.action = bpy.data.actions.get("Walk")
bpy.context.scene.frame_set(25)
out_file = ROOT / "tests" / "new_walk_stride.png"
bpy.context.scene.render.filepath = str(out_file)
bpy.ops.render.render(write_still=True)
print("Rendered new_walk_stride.png")
