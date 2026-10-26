"""Optional Blender preview of the actual scrapyard blueprint; not a Studio screenshot."""
from pathlib import Path
import json, math
import bpy
from mathutils import Matrix, Vector
ROOT=Path(__file__).resolve().parents[1]
DATA=json.loads((ROOT/'build/blueprints.json').read_text())
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=16
scene.cycles.use_denoising=False
scene.render.resolution_x=1400;scene.render.resolution_y=900;scene.render.resolution_percentage=100
scene.world.color=(.3,.35,.4)
scene.view_settings.view_transform='AgX'
A=Matrix(((1,0,0,0),(0,0,1,0),(0,1,0,0),(0,0,0,1)))
materials={}
def material(rgb,kind):
 key=tuple(rgb)+(kind,)
 if key in materials:return materials[key]
 mat=bpy.data.materials.new(kind);mat.use_nodes=True
 rgb=[n/255 for n in rgb];linear=[n/12.92 if n<=.04045 else ((n+.055)/1.055)**2.4 for n in rgb]
 bsdf=mat.node_tree.nodes.get('Principled BSDF');bsdf.inputs['Base Color'].default_value=(*linear,1)
 bsdf.inputs['Metallic'].default_value=.5 if kind in ('Metal','CorrodedMetal') else 0
 bsdf.inputs['Roughness'].default_value=.6
 if kind=='Neon':bsdf.inputs['Emission Color'].default_value=(*linear,1);bsdf.inputs['Emission Strength'].default_value=2
 materials[key]=mat;return mat
def part(d):
 shape=d.get('shape','Block')
 if shape=='Cylinder':bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=.5,depth=1)
 elif shape=='Ball':bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,radius=.5)
 else:bpy.ops.mesh.primitive_cube_add(size=1)
 obj=bpy.context.object;obj.name=d['name']
 p=d['position'];s=d['size']
 R=Matrix.Rotation(math.radians(d.get('pitch',0)),4,'X')@Matrix.Rotation(math.radians(d.get('yaw',0)),4,'Y')@Matrix.Rotation(math.radians(d.get('roll',0)),4,'Z')
 S=Matrix.Diagonal((*s,1))
 obj.matrix_world=Matrix.Translation(Vector((p[0],p[2],p[1])))@A@R@S@(Matrix.Rotation(math.pi/2,4,'Y') if shape=='Cylinder' else Matrix.Identity(4))
 obj.data.materials.append(material(d['color'],d.get('material','Metal')))
for definition in DATA['yard']['parts']:part(definition)
lookup={item['rarity']:item for item in DATA['items']}
for spawn in DATA['yard']['spawns']:
 item=lookup[spawn['rarity']]
 part(dict(name=item['name'],position=spawn['position'],size=[2.5]*3,color=item['color'],shape=item['shape'],material='Metal'))
for z in range(65,1460,60):
 for lane,direction,color in ((7,1,[235,178,65]),(-7,-1,[100,192,190])):
  for side in (-1,1):
   a=(lane+side*2.5,z-direction*2.5);b=(lane,z+direction*2.5)
   dx,dz=b[0]-a[0],b[1]-a[1]
   part(dict(name='Arrow',position=[(a[0]+b[0])/2,.16,(a[1]+b[1])/2],size=[.65,.06,math.hypot(dx,dz)],color=color,yaw=math.degrees(math.atan2(dx,dz)),material='SmoothPlastic'))
# Floating labels have no backing boards, matching the in-game change.
fontfile=Path('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf')
font=bpy.data.fonts.load(str(fontfile)) if fontfile.is_file() else None
for sign in DATA['yard']['signs']:
 p=sign['position'];bpy.ops.object.text_add(location=(p[0],p[2],p[1]))
 obj=bpy.context.object;obj.rotation_euler=(math.pi/2,0,0)
 obj.data.body=sign['text'];obj.data.align_x='CENTER';obj.data.size=2
 if font:obj.data.font=font
 obj.data.materials.append(material(sign['color'],'Neon'))
# Sun and fill keep distant scenery readable.
bpy.ops.object.light_add(type='SUN',location=(100,-100,200))
bpy.context.object.data.energy=3;bpy.context.object.rotation_euler=(.6,-.3,-.4)
bpy.ops.object.light_add(type='AREA',location=(-80,120,160));bpy.context.object.data.energy=200000;bpy.context.object.data.size=160
bpy.ops.object.camera_add(location=(190,-100,140))
camera=bpy.context.object;camera.rotation_euler=(Vector((0,250,4))-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.lens=32;camera.data.clip_end=5000;scene.camera=camera
scene.render.filepath=str(ROOT/'build/scrapyard-preview.png')
bpy.ops.render.render(write_still=True)
