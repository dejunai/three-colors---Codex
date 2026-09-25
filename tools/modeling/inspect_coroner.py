import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='Meshy_Coroner-Animations.glb')
print('=== OBJECTS ===')
for o in bpy.data.objects:
    print(o.name, o.type)
print('=== ACTIONS ===')
for a in bpy.data.actions:
    print(a.name, a.frame_range)
objs = [o for o in bpy.data.objects if o.type=='MESH']
for o in objs:
    poly_count = len(o.data.polygons)
    tri_count = sum([len(p.vertices) - 2 for p in o.data.polygons])
    print(f'MESH {o.name}: {poly_count} polys, ~{tri_count} tris')
