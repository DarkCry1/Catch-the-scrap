"""Optional shared-geometry delivery asset previews; not Studio screenshots."""
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

def setup_lights():
 bpy.ops.object.light_add(type='SUN',location=(10,10,20))
 bpy.context.object.data.energy=2.4;bpy.context.object.data.color=(1,.89,.76);bpy.context.object.rotation_euler=(.4,-.2,-.6)
 bpy.ops.object.light_add(type='AREA',location=(-9,0,13))
 bpy.context.object.data.energy=1700;bpy.context.object.data.size=10
 bpy.ops.object.light_add(type='AREA',location=(8,-20,10))
 bpy.context.object.data.energy=1400;bpy.context.object.data.size=8
setup_lights()
for definition in DATA['crusher']['housing']:part(definition)
for rotor in DATA['crusher']['rotors']:
 for d in rotor['parts']:
  p=[d['position'][i]+rotor['position'][i] for i in range(3)]
  part(dict(d,position=p))
part(dict(name='DisplayFloor',position=[0,-.3,-12],size=[28,.5,24],color=[61,69,73],material='Concrete'))
# A salvage core hovering at the feed opening illustrates the grinder's scale.
for d in DATA['pickupVisuals']['Rare']['parts']:
 p=d['position'];part(dict(d,position=[p[0],p[1]+5.7,p[2]-10]))
bpy.ops.object.camera_add(location=(12,7,10))
camera=bpy.context.object;camera.rotation_euler=(Vector((0,-12,3.4))-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.type='ORTHO';camera.data.ortho_scale=23;scene.camera=camera
scene.cycles.samples=32;scene.render.filepath=str(ROOT/'build/crusher-preview-v0.7.png');bpy.ops.render.render(write_still=True)
for obj in tuple(bpy.data.objects):
 if obj.type in ('MESH','FONT'):bpy.data.objects.remove(obj,do_unlink=True)
for index,opened in enumerate((False,True)):
 cx=-3.6 if index==0 else 3.6
 for d in DATA['crate']:
  if opened and d['name']=='TopTape':continue
  p=list(d['position']);roll=0
  if opened and d['name'] in ('FlapLeft','FlapRight'):
   side=-1 if d['name']=='FlapLeft' else 1
   roll=-side*130;a=math.radians(roll)
   p=[side*2.08-side*1.04*math.cos(a),2.08-side*1.04*math.sin(a),0]
  part(dict(d,position=[p[0]+cx,p[1]+2.3,p[2]],roll=roll))
 if opened:
  color=DATA['stages'][3]['Color']
  for d in DATA['robot']:
   p=d['position'];s=d['size'];palette=d['palette'];rgb=color if palette in ('energy','amber') else DATA['palette'][palette]
   part(dict(name=d['name'],position=[p[0]*.5+cx,p[1]*.5+4.5,p[2]*.5],size=[v*.5 for v in s],color=rgb,shape=d['shape'],yaw=d.get('yaw',0),material='Neon' if palette=='energy' else 'Metal'))
part(dict(name='DisplayFloor',position=[0,-.3,0],size=[24,.5,17],color=[61,69,73],material='Concrete'))
camera.location=(12,16,12);camera.rotation_euler=(Vector((0,0,3.3))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.ortho_scale=20
scene.render.filepath=str(ROOT/'build/unboxing-preview-v0.7.png');bpy.ops.render.render(write_still=True)
