import bpy
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC_GLB = ROOT / "archive" / "Meshy_Gatekeeper-Boy-Animations.glb"

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(SRC_GLB))

print("=== OBJECTS ===")
for o in bpy.data.objects:
    print(f"  {o.name} (type: {o.type})")

print("=== MATERIALS ===")
for m in bpy.data.materials:
    print(f"  {m.name}")

print("=== ACTIONS / ANIMATIONS ===")
for a in bpy.data.actions:
    print(f"  {a.name} (frames: {a.frame_range[0]}..{a.frame_range[1]})")

meshes = [o for o in bpy.data.objects if o.type == "MESH"]
for m in meshes:
    depsgraph = bpy.context.evaluated_depsgraph_get()
    eval_m = m.evaluated_get(depsgraph).to_mesh()
    eval_m.calc_loop_triangles()
    print(f"Mesh: {m.name}, verts: {len(m.data.vertices)}, triangles: {len(eval_m.loop_triangles)}")
    m.evaluated_get(depsgraph).to_mesh_clear()

    coords = [(m.matrix_world @ v.co) for v in m.data.vertices]
    min_x, max_x = min(c.x for c in coords), max(c.x for c in coords)
    min_y, max_y = min(c.y for c in coords), max(c.y for c in coords)
    min_z, max_z = min(c.z for c in coords), max(c.z for c in coords)
    print(f"  Bounds: X=[{min_x:.3f}..{max_x:.3f}] width={max_x-min_x:.3f}")
    print(f"          Y=[{min_y:.3f}..{max_y:.3f}] depth={max_y-min_y:.3f}")
    print(f"          Z=[{min_z:.3f}..{max_z:.3f}] height={max_z-min_z:.3f}")
