"""Optional asset preview: blender -b --python scripts/render-mechanic.py.

Renders the actual mechanic stand and scaled robot blueprints exported with:
    luau scripts/export-blueprints.luau > build/blueprints.json
This is an asset render, not a Roblox Studio runtime screenshot.
"""
from pathlib import Path
import json
import math
import bpy
from mathutils import Vector, Matrix

ROOT = Path(__file__).resolve().parents[1]
DATA = json.loads((ROOT / 'build/blueprints.json').read_text())
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'
scene.cycles.samples = 48
scene.cycles.use_denoising = False
scene.render.resolution_x = 1400
scene.render.resolution_y = 1000
scene.render.resolution_percentage = 100
scene.world.color = (0.25, 0.30, 0.38)
scene.view_settings.view_transform = 'AgX'


def material(name, rgb, glow=False, ghost=False):
    mat = bpy.data.materials.new(name)
    srgb = [v / 255 for v in rgb]
    linear = [v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4 for v in srgb]
    mat.diffuse_color = (*linear, 1)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = mat.diffuse_color
    bsdf.inputs['Metallic'].default_value = 0.5 if not ghost else 0.1
    bsdf.inputs['Roughness'].default_value = 0.42
    if glow or ghost:
        bsdf.inputs['Emission Color'].default_value = mat.diffuse_color
        bsdf.inputs['Emission Strength'].default_value = 2 if not ghost else 0.15
    if ghost:
        bsdf.inputs['Alpha'].default_value = 0.12
    return mat


palette = {key: material(key, rgb, key == 'energy') for key, rgb in DATA['palette'].items()}
palette['accent'] = material('accent', DATA['accent'], True)
ghost = material('blueprint ghost', [80, 205, 215], True, True)


def xyz(point):
    return (point[0], point[2], point[1])


def geometry(name, size, position, mat, shape='Block', yaw=0):
    if shape == 'RawCylinder':
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=.5, depth=1)
        obj=bpy.context.object
        A=Matrix(((1,0,0,0),(0,0,1,0),(0,1,0,0),(0,0,0,1)))
        obj.matrix_world=Matrix.Translation(Vector(xyz(position)))@A@Matrix.Rotation(math.radians(yaw),4,'Y')@Matrix.Diagonal((*size,1))@Matrix.Rotation(math.pi/2,4,'Y')
    elif shape == 'Ball':
        bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, location=xyz(position))
        obj = bpy.context.object
        obj.scale = (size[0] / 2, size[2] / 2, size[1] / 2)
    elif shape == 'Cylinder':
        # All preview cylinders are the platform discs, with vertical thickness size[1].
        bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=size[0] / 2, depth=size[1], location=xyz(position))
        obj = bpy.context.object
    else:
        bpy.ops.mesh.primitive_cube_add(size=1, location=xyz(position))
        obj = bpy.context.object
        obj.scale = (size[0], size[2], size[1])
        obj.rotation_euler[2] = -math.radians(yaw)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        bevel = obj.modifiers.new('edge highlight', 'BEVEL')
        bevel.width = 0.055
        bevel.segments = 1
        obj.modifiers.new('weighted normals', 'WEIGHTED_NORMAL')
    obj.name = name
    obj.data.materials.append(mat)
    return obj


font_path = Path('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf')
font = bpy.data.fonts.load(str(font_path)) if font_path.is_file() else None


def label(text, position, size, mat):
    bpy.ops.object.text_add(location=xyz(position))
    obj = bpy.context.object
    obj.rotation_euler = (math.pi / 2, 0, math.pi)
    obj.data.body = text
    obj.data.align_x = 'CENTER'
    obj.data.align_y = 'CENTER'
    obj.data.size = size
    obj.data.extrude = 0.002
    if font:
        obj.data.font = font
    obj.data.materials.append(mat)
    return obj


for piece in DATA['mechanic']:
    geometry(piece['name'],piece['size'],piece['position'],palette[piece['palette']])
for piece in DATA['robot']:
    position=[piece['position'][0]*.72,piece['position'][1]*.72+.6,piece['position'][2]*.72-1]
    geometry(piece['name'],[n*.72 for n in piece['size']],position,palette[piece['palette']],'RawCylinder' if piece['shape']=='Cylinder' else piece['shape'],piece.get('yaw',0))
label('MILO THE MECHANIC', [0,12,1],1.2,palette['amber'])
label('SPEED + STRENGTH', [0,10.9,1],.65,palette['accent'])
geometry('surrounding concrete', [180, 1, 160], [0, -1.1, 0], material('concrete', [73, 86, 92]))
for y in (28, 32):
    geometry('entry approach', [7, .08, .35], [0, -.5, y], palette['amber'])


def area(name, location, energy, size):
    bpy.ops.object.light_add(type='AREA', location=location)
    obj = bpy.context.object
    obj.name = name
    obj.data.energy = energy
    obj.data.shape = 'DISK'
    obj.data.size = size
    obj.rotation_euler = (Vector((0, 0, 2)) - obj.location).to_track_quat('-Z', 'Y').to_euler()


area('key', (30, 35, 65), 95000, 50)
area('fill', (-40, 15, 35), 65000, 45)
area('rim', (5, -35, 45), 70000, 30)
bpy.ops.object.camera_add(location=(31, 46, 25))
camera = bpy.context.object
camera.rotation_euler = (Vector((0, 0, 3)) - camera.location).to_track_quat('-Z', 'Y').to_euler()
camera.data.type = 'ORTHO'
camera.data.ortho_scale = 38
scene.camera = camera
scene.render.filepath = str(ROOT / 'build/mechanic-preview.png')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / 'build/mechanic-preview.blend'))
bpy.ops.render.render(write_still=True)
