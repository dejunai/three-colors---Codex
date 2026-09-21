import os
import bpy

files = [f for f in os.listdir('.') if f.startswith('Meshy_AI_') and f.endswith('.glb')]

for f in sorted(files):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=f)
    imgs = [f"{img.name} ({img.size[0]}x{img.size[1]})" for img in bpy.data.images]
    objs = [f"{o.name} dims=({o.dimensions.x:.2f},{o.dimensions.y:.2f},{o.dimensions.z:.2f})" for o in bpy.data.objects if o.type == 'MESH']
    print(f"FILE: {f}")
    print(f"  Images: {', '.join(imgs)}")
    print(f"  Objects: {', '.join(objs)}")
