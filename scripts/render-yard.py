"""Optional Blender preview of the actual scrapyard blueprint; not a Studio screenshot."""
from pathlib import Path
import json, math, sys
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
def material(rgb,kind,transparency=0):
 key=tuple(rgb)+(kind,transparency)
 if key in materials:return materials[key]
 mat=bpy.data.materials.new(kind);mat.use_nodes=True
 rgb=[n/255 for n in rgb];linear=[n/12.92 if n<=.04045 else ((n+.055)/1.055)**2.4 for n in rgb]
 bsdf=mat.node_tree.nodes.get('Principled BSDF');bsdf.inputs['Base Color'].default_value=(*linear,1)
 bsdf.inputs['Metallic'].default_value=.5 if kind in ('Metal','CorrodedMetal') else 0
 bsdf.inputs['Roughness'].default_value=.18 if kind=='Glass' else .6
 if transparency:bsdf.inputs['Alpha'].default_value=1-transparency
 if kind in ('CorrodedMetal','Concrete','Ground','Slate'):
  noise=mat.node_tree.nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=22;noise.inputs['Detail'].default_value=2
  bump=mat.node_tree.nodes.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.15;bump.inputs['Distance'].default_value=.1
  mat.node_tree.links.new(noise.outputs['Fac'],bump.inputs['Height']);mat.node_tree.links.new(bump.outputs['Normal'],bsdf.inputs['Normal'])
 if kind=='Neon':bsdf.inputs['Emission Color'].default_value=(*linear,1);bsdf.inputs['Emission Strength'].default_value=2
 materials[key]=mat;return mat
# Allocate meshes directly for large scenes; repeated operators rebuild the depsgraph.
meshes={}
for shape in ('Block','Cylinder','Ball'):
 if shape=='Cylinder':bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=.5,depth=1)
 elif shape=='Ball':bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,radius=.5)
 else:bpy.ops.mesh.primitive_cube_add(size=1)
 template=bpy.context.object
 meshes[shape]=template.data.copy()
 bpy.data.objects.remove(template,do_unlink=True)
def part(d):
 shape=d.get('shape','Block')
 obj=bpy.data.objects.new(d['name'],meshes[shape].copy())
 scene.collection.objects.link(obj)
 p=d['position'];s=d['size']
 R=Matrix.Rotation(math.radians(d.get('pitch',0)),4,'X')@Matrix.Rotation(math.radians(d.get('yaw',0)),4,'Y')@Matrix.Rotation(math.radians(d.get('roll',0)),4,'Z')
 S=Matrix.Diagonal((*s,1))
 obj.matrix_world=Matrix.Translation(Vector((p[0],p[2],p[1])))@A@R@S@(Matrix.Rotation(math.pi/2,4,'Y') if shape=='Cylinder' else Matrix.Identity(4))
 obj.data.materials.append(material(d['color'],d.get('material','Metal'),d.get('transparency',0)))
for definition in DATA['yard']['parts']:part(definition)
for spawn in DATA['yard']['spawns']:
 visual=DATA['pickupVisuals'][spawn['rarity']]
 for detail in visual['parts']:
  position=[spawn['position'][0]+detail['position'][0],visual['clearance']+detail['position'][1],spawn['position'][2]+detail['position'][2]]
  part(dict(detail,position=position))
# Show the home plaza with its real workshop geometry, not an empty staging floor.
for index in range(8):
 side=-1 if index%2==0 else 1;angle=math.pi/2 if side==-1 else -math.pi/2
 ox,oz=side*62,-35-(index//2)*66
 for piece in DATA['base']:
  if piece['name']=='ProgressBoard':continue
  x,y,z=piece['position'];position=[ox+x*math.cos(angle)+z*math.sin(angle),y,oz-x*math.sin(angle)+z*math.cos(angle)]
  palette=piece['palette'];color=DATA['accent'] if palette=='accent' else DATA['palette'][palette]
  part(dict(name=piece['name'],position=position,size=piece['size'],color=color,material=piece['material'],yaw=math.degrees(angle)+piece['yaw']))
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
 obj.data.body=sign['text'];obj.data.align_x='CENTER';obj.data.size=1.35
 if font:obj.data.font=font
 obj.data.materials.append(material(sign['color'],'Neon'))
# Sun and fill keep distant scenery readable.
bpy.ops.object.light_add(type='SUN',location=(100,-100,200))
bpy.context.object.data.energy=3.1;bpy.context.object.data.color=(1,.86,.68);bpy.context.object.rotation_euler=(.72,-.35,-.5)
bpy.ops.object.light_add(type='AREA',location=(-80,120,160));bpy.context.object.data.energy=200000;bpy.context.object.data.size=160
bpy.ops.object.camera_add(location=(190,-100,140))
camera=bpy.context.object;camera.rotation_euler=(Vector((0,250,4))-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.lens=32;camera.data.clip_end=5000;scene.camera=camera
scene.render.filepath=str(ROOT/'build/scrapyard-preview.png')
bpy.ops.render.render(write_still=True)
# A second, eye-level view makes wall cladding and collectible detail assessable.
camera.location=(5,8,7)
camera.rotation_euler=(Vector((0,180,9))-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.lens=25
scene.render.filepath=str(ROOT/'build/scrapyard-ground-preview.png')
bpy.ops.render.render(write_still=True)
